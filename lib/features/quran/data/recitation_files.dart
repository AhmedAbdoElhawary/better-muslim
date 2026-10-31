import 'dart:async';
import 'dart:io';

import 'package:better_muslim/core/database/backup_exclusion.dart';
import 'package:better_muslim/core/network/download.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/features/quran/domain/recitation.dart';
import 'package:path_provider/path_provider.dart';

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
       _fetch = fetch ?? fetchUri,
       _exclude = exclude ?? BackupExclusion.exclude;

  static final base = Uri.parse('https://everyayah.com/data/');

  final Future<Directory> Function() _root;
  final Future<Fetched> Function(Uri uri) _fetch;
  final Future<void> Function(String path) _exclude;

  final _folders = <Reciter, Future<Directory>>{};

  /// one download at a time, the playing ayah goes before the next file ahead
  Future<void> _lock = Future.value();
  final _ahead = <AyahKey>[];
  Reciter _aheadReciter = Reciter.alafasy;
  bool _running = false;

  static String name(AyahKey key) =>
      '${'${key.surah}'.padLeft(3, '0')}${'${key.ayah}'.padLeft(3, '0')}.mp3';

  static Uri address(Reciter reciter, AyahKey key) =>
      base.resolve('${reciter.folder}/${name(key)}');

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

  /// the checked file, downloaded now when it isn't on the phone yet
  Future<File> file(Reciter reciter, AyahKey key) async {
    final file = await _file(reciter, key);
    if (file.existsSync()) return file;
    return _one(() async {
      if (!file.existsSync()) await _download(address(reciter, key), file);
      return file;
    });
  }

  /// the rest of the surah, in order, after whatever plays now
  void ahead(Reciter reciter, Iterable<AyahKey> keys) {
    _aheadReciter = reciter;
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
        await file(_aheadReciter, _ahead.removeAt(0));
      } on RecitationException {
        /// offline or a bad file, the next play asks again
        _ahead.clear();
      }
    }
    _running = false;
  }

  Future<bool> isSurahReady(Reciter reciter, List<AyahKey> keys) async {
    for (final key in keys) {
      if (!(await _file(reciter, key)).existsSync()) return false;
    }
    return true;
  }

  Future<T> _one<T>(Future<T> Function() job) {
    final done = _lock.then((_) => job());
    _lock = done.then<void>((_) {}, onError: (_) {});
    return done;
  }

  /// to .part first, renamed only when complete and an mp3, anything else deleted
  Future<void> _download(Uri address, File file) async {
    final part = File('${file.path}.part');
    final Fetched fetched;
    try {
      fetched = await _fetch(address);
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
}
