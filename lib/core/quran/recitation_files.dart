import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:better_muslim/core/database/backup_exclusion.dart';
import 'package:better_muslim/core/network/download.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// one for the player and the downloads, so they share the one download at a time
final recitationFilesProvider = Provider<RecitationFiles>((ref) => RecitationFiles());

/// missing is a surah the reciter's files don't hold right
enum RecitationFailure { offline, failed, missing }

class RecitationException implements Exception {
  const RecitationException(this.failure);

  final RecitationFailure failure;

  @override
  String toString() => 'RecitationException($failure)';
}

/// a file or an https address, with the ayah's part of it when it holds the whole surah
typedef AyahAudio = ({String path, Duration? start, Duration? end});

typedef AyahTiming = ({Duration start, Duration end});

/// one file per ayah, checked before it ever plays and kept to play offline (research R9). an
/// mp3quran reciter has one per surah, cut into ayahs by its timings (ADR 0005)
class RecitationFiles {
  RecitationFiles({
    Future<Directory> Function()? root,
    Future<Fetched> Function(Uri uri)? fetch,
    Future<void> Function(String path)? exclude,
  }) : _root = root ?? getApplicationSupportDirectory,
       _fetch = fetch ?? fetchUri,
       _exclude = exclude ?? BackupExclusion.exclude;

  static final base = Uri.parse('https://everyayah.com/data/');
  static final surahBase = Uri.parse('https://cdn.mp3quran.net/audio/');
  static final timingsBase = Uri.parse('https://www.mp3quran.net/api/v3/ayat_timing');

  final Future<Directory> Function() _root;
  final Future<Fetched> Function(Uri uri) _fetch;
  final Future<void> Function(String path) _exclude;

  final _folders = <Reciter, Future<Directory>>{};
  final _timings = <(Reciter, int), Future<List<AyahTiming>>>{};

  /// one download at a time, the playing ayah goes before the next file ahead
  Future<void> _lock = Future.value();
  final _ahead = <AyahKey>[];
  Reciter _aheadReciter = Reciter.alafasy;
  bool _running = false;

  static String name(AyahKey key) =>
      '${'${key.surah}'.padLeft(3, '0')}${'${key.ayah}'.padLeft(3, '0')}.mp3';

  static Uri address(Reciter reciter, AyahKey key) =>
      base.resolve('${reciter.folder}/${name(key)}');

  static String _surahName(int surah) => '$surah'.padLeft(3, '0');

  static Uri surahAddress(Reciter reciter, int surah) =>
      surahBase.resolve('${reciter.folder}/${_surahName(surah)}.mp3');

  static Uri timingsAddress(Reciter reciter, int surah) =>
      timingsBase.replace(queryParameters: {'surah': '$surah', 'read': '${reciter.read}'});

  /// named after the reciter, so alafasy's files from before stay where they are
  Future<Directory> folder(Reciter reciter) => _folders[reciter] ??= () async {
    final folder = Directory('${(await _root()).path}/recitations/${reciter.name}');
    if (!folder.existsSync()) {
      await folder.create(recursive: true);
      await _exclude(folder.path);
    }
    return folder;
  }();

  Future<File> _file(Reciter reciter, AyahKey key) async =>
      File('${(await folder(reciter)).path}/${name(key)}');

  /// on everyayah the bismillah, ayah 0, is al-fatiha's first ayah
  static AyahKey _ayahFile(AyahKey key) => key.ayah == 0 ? const AyahKey(1, 1) : key;

  Future<File> _surahFile(Reciter reciter, int surah, String extension) async =>
      File('${(await folder(reciter)).path}/${_surahName(surah)}.$extension');

  /// what plays for an ayah. in a surah file the bismillah is what comes before its first ayah, a
  /// surah not downloaded plays from the address
  Future<AyahAudio> audio(Reciter reciter, AyahKey key) async {
    if (reciter.read == null) {
      final file = await this.file(reciter, _ayahFile(key));
      return (path: file.path, start: null, end: null);
    }
    if (reciter.missing.contains(key.surah)) {
      throw const RecitationException(RecitationFailure.missing);
    }
    final timings = await _timingsOf(reciter, key.surah);
    if (key.ayah > timings.length) throw const RecitationException(RecitationFailure.failed);
    final file = await _surahFile(reciter, key.surah, 'mp3');
    return (
      path: file.existsSync() ? file.path : '${surahAddress(reciter, key.surah)}',
      start: key.ayah == 0 ? Duration.zero : timings[key.ayah - 1].start,
      end: key.ayah == 0 ? timings.first.start : timings[key.ayah - 1].end,
    );
  }

  /// kept next to the surah's file, so a downloaded surah plays offline
  Future<List<AyahTiming>> _timingsOf(Reciter reciter, int surah) =>
      _timings[(reciter, surah)] ??= _loadTimings(reciter, surah);

  Future<List<AyahTiming>> _loadTimings(Reciter reciter, int surah) async {
    try {
      final file = await _surahFile(reciter, surah, 'json');
      if (!file.existsSync()) {
        final fetched = await _get(timingsAddress(reciter, surah));
        final List<int> body;
        try {
          body = await fetched.bytes.expand((chunk) => chunk).toList();
        } on Object {
          throw const RecitationException(RecitationFailure.failed);
        }
        final timings = parseTimings(utf8.decode(body, allowMalformed: true));
        final part = File('${file.path}.part')
          ..writeAsStringSync(
            jsonEncode([
              for (final timing in timings)
                [timing.start.inMilliseconds, timing.end.inMilliseconds],
            ]),
          );
        part.renameSync(file.path);
        return timings;
      }
      return [
        for (final [int start, int end] in jsonDecode(file.readAsStringSync()) as List)
          (start: Duration(milliseconds: start), end: Duration(milliseconds: end)),
      ];
    } on Object {
      /// asked again on the next play
      _timings.remove((reciter, surah));
      rethrow;
    }
  }

  /// mp3quran's list: every ayah from 1 in order, each ending after it starts
  static List<AyahTiming> parseTimings(String body) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw const RecitationException(RecitationFailure.failed);
    }
    if (decoded is! List || decoded.isEmpty) {
      throw const RecitationException(RecitationFailure.failed);
    }
    final timings = <AyahTiming>[];
    for (final (index, entry) in decoded.indexed) {
      if (entry
          case {'ayah': final int ayah, 'start_time': final int start, 'end_time': final int end}
          when ayah == index + 1 &&
              start < end &&
              (timings.isEmpty || start >= timings.last.start.inMilliseconds)) {
        timings.add((start: Duration(milliseconds: start), end: Duration(milliseconds: end)));
      } else {
        throw const RecitationException(RecitationFailure.failed);
      }
    }
    return timings;
  }

  /// the checked file, downloaded now when it isn't on the phone yet
  Future<File> file(Reciter reciter, AyahKey key) async {
    final file = await _file(reciter, key);
    if (file.existsSync()) return file;
    return _one(() async {
      if (!file.existsSync()) await _download(address(reciter, key), file);
      return file;
    });
  }

  /// the rest of the queue, in order, after whatever plays now. a surah file streams instead
  void ahead(Reciter reciter, Iterable<AyahKey> queue) {
    if (reciter.read != null) return;
    _aheadReciter = reciter;
    _ahead
      ..clear()
      ..addAll({for (final key in queue) _ayahFile(key)});
    if (_running) return;
    _running = true;
    unawaited(_runAhead());
  }

  Future<void> _runAhead() async {
    while (_ahead.isNotEmpty) {
      try {
        await file(_aheadReciter, _ahead.removeAt(0));
      } on RecitationException {
        /// offline or a bad file, the next play asks again
        _ahead.clear();
      }
    }
    _running = false;
  }

  /// keys are the surah's files, the bismillah first
  Future<bool> isSurahReady(Reciter reciter, List<AyahKey> keys) async {
    if (reciter.read != null) {
      final surah = keys.last.surah;
      return (await _surahFile(reciter, surah, 'mp3')).existsSync() &&
          (await _surahFile(reciter, surah, 'json')).existsSync();
    }
    for (final key in keys) {
      if (!(await _file(reciter, key)).existsSync()) return false;
    }
    return true;
  }

  /// what's already here is kept, so after a lost connection a new tap goes on from there
  Future<void> downloadSurah(
    Reciter reciter,
    List<AyahKey> keys, {
    void Function(double progress)? onProgress,
  }) async {
    if (reciter.read != null) {
      final surah = keys.last;
      if (reciter.missing.contains(surah.surah)) {
        throw const RecitationException(RecitationFailure.missing);
      }
      if ((await _timingsOf(reciter, surah.surah)).length != surah.ayah) {
        throw const RecitationException(RecitationFailure.failed);
      }
      final file = await _surahFile(reciter, surah.surah, 'mp3');

      /// not one at a time with the ayah files, a whole surah would hold them back for minutes
      if (!file.existsSync()) {
        await _download(surahAddress(reciter, surah.surah), file, onProgress: onProgress);
      }
      onProgress?.call(1);
      return;
    }
    for (final (i, key) in keys.indexed) {
      await file(reciter, key);
      onProgress?.call((i + 1) / keys.length);
    }
  }

  /// the surahs with every file on the phone and their size, the bismillah counts for al-fatiha
  Future<List<({int surah, int bytes})>> downloaded(
    Reciter reciter,
    int Function(int surah) ayahs,
  ) async {
    /// listing makes no folder
    final folder = Directory('${(await _root()).path}/recitations/${reciter.name}');
    if (!folder.existsSync()) return [];
    if (reciter.read != null) {
      return [
        for (var surah = 1; surah <= 114; surah++)
          if (File('${folder.path}/${_surahName(surah)}.mp3') case final file
              when file.existsSync() &&
                  File('${folder.path}/${_surahName(surah)}.json').existsSync())
            (surah: surah, bytes: file.lengthSync()),
      ];
    }
    final counts = <int, int>{};
    final sizes = <int, int>{};
    for (final entry in folder.listSync().whereType<File>()) {
      final name = entry.uri.pathSegments.last;
      if (!name.endsWith('.mp3')) continue;
      final surah = int.parse(name.substring(0, 3));
      counts[surah] = (counts[surah] ?? 0) + 1;
      sizes[surah] = (sizes[surah] ?? 0) + entry.lengthSync();
    }
    final bismillah = File('${folder.path}/${name(const AyahKey(1, 1))}').existsSync();
    return [
      for (final surah in counts.keys.toList()..sort())
        if (counts[surah] == ayahs(surah) && (bismillah || surah == 9))
          (surah: surah, bytes: sizes[surah]!),
    ];
  }

  /// al-fatiha's first ayah stays while another surah needs it as its bismillah
  Future<void> deleteSurah(Reciter reciter, int surah) async {
    final prefix = '$surah'.padLeft(3, '0');
    final entries = (await folder(reciter)).listSync().whereType<File>().toList();
    final others = entries.any((entry) => !entry.uri.pathSegments.last.startsWith('001'));
    for (final entry in entries) {
      final name = entry.uri.pathSegments.last;
      if (name.startsWith(prefix) &&
          !(others && name == RecitationFiles.name(const AyahKey(1, 1)))) {
        entry.deleteSync();
      }
    }
  }

  Future<T> _one<T>(Future<T> Function() job) {
    final done = _lock.then((_) => job());
    _lock = done.then<void>((_) {}, onError: (_) {});
    return done;
  }

  Future<Fetched> _get(Uri address) async {
    try {
      return await _fetch(address);
    } on SocketException {
      throw const RecitationException(RecitationFailure.offline);
    } on IOException {
      throw const RecitationException(RecitationFailure.failed);
    }
  }

  /// to .part first, renamed only when complete and an mp3, anything else deleted
  Future<void> _download(
    Uri address,
    File file, {
    void Function(double progress)? onProgress,
  }) async {
    final part = File('${file.path}.part');
    final fetched = await _get(address);
    final sink = part.openWrite();
    var written = 0;
    final head = <int>[];
    try {
      await for (final chunk in fetched.bytes) {
        if (head.length < 3) head.addAll(chunk.take(3 - head.length));
        written += chunk.length;
        sink.add(chunk);
        if (fetched.length case final length?) onProgress?.call(written / length);
      }
      await sink.close();
    } on Object {
      await sink.close().catchError((_) {});
      if (part.existsSync()) part.deleteSync();
      throw const RecitationException(RecitationFailure.failed);
    }

    /// no length header, the mp3 check alone decides
    final length = fetched.length;
    if ((length != null && written != length) || !isMp3(head)) {
      part.deleteSync();
      throw const RecitationException(RecitationFailure.failed);
    }
    part.renameSync(file.path);
  }

  /// an ID3 tag or an mpeg frame sync
  static bool isMp3(List<int> head) =>
      (head.length >= 3 && head[0] == 0x49 && head[1] == 0x44 && head[2] == 0x33) ||
      (head.length >= 2 && head[0] == 0xFF && (head[1] & 0xE0) == 0xE0);
}
