import 'dart:async';
import 'dart:io';

import 'package:better_muslim/core/database/backup_exclusion.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/features/quran/domain/recitation.dart';
import 'package:path_provider/path_provider.dart';

/// a download's length from its header and its body
typedef Fetched = ({int? length, Stream<List<int>> bytes});

class RecitationException implements Exception {
  const RecitationException(this.failure);

  final RecitationFailure failure;

  @override
  String toString() => 'RecitationException($failure)';
}

/// one file per ayah, checked before it ever plays and kept to play offline (research R9)
class RecitationFiles {
  RecitationFiles({
    Future<Directory> Function()? root,
    Future<Fetched> Function(Uri uri)? fetch,
    Future<void> Function(String path)? exclude,
  }) : _root = root ?? getApplicationSupportDirectory,
       _fetch = fetch ?? download,
       _exclude = exclude ?? BackupExclusion.exclude;

  static final base = Uri.parse('https://everyayah.com/data/Alafasy_128kbps/');

  final Future<Directory> Function() _root;
  final Future<Fetched> Function(Uri uri) _fetch;
  final Future<void> Function(String path) _exclude;

  Future<Directory>? _folder;

  /// one download at a time, the playing ayah goes before the next file ahead
  Future<void> _lock = Future.value();
  final _ahead = <AyahKey>[];
  bool _running = false;

  static String name(AyahKey key) =>
      '${'${key.surah}'.padLeft(3, '0')}${'${key.ayah}'.padLeft(3, '0')}.mp3';

  static Uri address(AyahKey key) => base.resolve(name(key));

  Future<Directory> get folder => _folder ??= () async {
    final folder = Directory('${(await _root()).path}/recitations/alafasy');
    if (!folder.existsSync()) {
      await folder.create(recursive: true);
      await _exclude(folder.path);
    }
    return folder;
  }();

  Future<File> _file(AyahKey key) async => File('${(await folder).path}/${name(key)}');

  /// the checked file, downloaded now when it isn't on the phone yet
  Future<File> file(AyahKey key) async {
    final file = await _file(key);
    if (file.existsSync()) return file;
    return _one(() async {
      if (!file.existsSync()) await _download(key, file);
      return file;
    });
  }

  /// the rest of the surah, in order, after whatever plays now
  void ahead(Iterable<AyahKey> keys) {
    _ahead
      ..clear()
      ..addAll(keys);
    if (_running) return;
    _running = true;
    unawaited(_runAhead());
  }

  Future<void> _runAhead() async {
    while (_ahead.isNotEmpty) {
      try {
        await file(_ahead.removeAt(0));
      } on RecitationException {
        /// offline or a bad file, the next play asks again
        _ahead.clear();
      }
    }
    _running = false;
  }

  Future<bool> isSurahReady(List<AyahKey> keys) async {
    for (final key in keys) {
      if (!(await _file(key)).existsSync()) return false;
    }
    return true;
  }

  Future<T> _one<T>(Future<T> Function() job) {
    final done = _lock.then((_) => job());
    _lock = done.then<void>((_) {}, onError: (_) {});
    return done;
  }

  /// to .part first, renamed only when complete and an mp3, anything else deleted
  Future<void> _download(AyahKey key, File file) async {
    final part = File('${file.path}.part');
    final Fetched fetched;
    try {
      fetched = await _fetch(address(key));
    } on SocketException {
      throw const RecitationException(RecitationFailure.offline);
    } on IOException {
      throw const RecitationException(RecitationFailure.failed);
    }
    final sink = part.openWrite();
    var written = 0;
    final head = <int>[];
    try {
      await for (final chunk in fetched.bytes) {
        if (head.length < 3) head.addAll(chunk.take(3 - head.length));
        written += chunk.length;
        sink.add(chunk);
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

  /// https only and no headers beyond the defaults (FR-034)
  static Future<Fetched> download(Uri uri) async {
    final client = HttpClient()..userAgent = null;
    try {
      final response = await (await client.getUrl(uri)).close();
      if (response.statusCode != HttpStatus.ok) throw HttpException('${response.statusCode}');
      final length = response.contentLength;
      return (length: length < 0 ? null : length, bytes: response);
    } finally {
      /// not forced, the open response still finishes
      client.close();
    }
  }
}
