import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:better_muslim/core/database/backup_exclusion.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/features/quran/data/recitation_files.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final tafsirFilesProvider = Provider<TafsirFiles>(
  (ref) => TafsirFiles(assets: () => ref.read(quranAssetsProvider.future)),
);

/// al-muyassar ships in the surah files, the other two are downloaded once (contracts/tafsir-files)
enum TafsirSource {
  muyassar(file: '', sha256: ''),

  ibnKathir(
    file: 'ibn_kathir.json.gz',
    sha256: '2bfc4bebff51a65d4277dd5dda53c54bbf1aff5ed9e4ac1a009cd89151644673',
  ),
  saadi(
    file: 'saadi.json.gz',
    sha256: '168779be2ff2c428af34445bf76294518c0fb433f7c5648ed6b355ab8d7fd7ee',
  );

  const TafsirSource({required this.file, required this.sha256});

  final String file;
  final String sha256;

  /// a public repo of its own, this one is private and its releases need a token
  static final base = Uri.parse(
    'https://github.com/AhmedAbdoElhawary/better-muslim-content/releases/download/tafsir-v1/',
  );

  Uri get address => base.resolve(file);
}

enum TafsirFailure { offline, failed, cancelled }

class TafsirException implements Exception {
  const TafsirException(this.failure);

  final TafsirFailure failure;

  @override
  String toString() => 'TafsirException($failure)';
}

/// each tafsir is one file for the whole quran, kept only when its sha256 matches (research R15)
class TafsirFiles {
  TafsirFiles({
    required this._assets,
    Future<Directory> Function()? root,
    Future<Fetched> Function(Uri uri)? fetch,
    Future<void> Function(String path)? exclude,
    Uri Function(TafsirSource source)? address,
    String Function(TafsirSource source)? sha256,
  }) : _root = root ?? getApplicationSupportDirectory,
       _fetch = fetch ?? RecitationFiles.download,
       _exclude = exclude ?? BackupExclusion.exclude,
       _address = address ?? ((source) => source.address),
       _sha256 = sha256 ?? ((source) => source.sha256);

  final Future<QuranAssets> Function() _assets;
  final Future<Directory> Function() _root;
  final Future<Fetched> Function(Uri uri) _fetch;
  final Future<void> Function(String path) _exclude;
  final Uri Function(TafsirSource source) _address;
  final String Function(TafsirSource source) _sha256;

  Future<Directory>? _folder;
  final _cancelled = <TafsirSource>{};

  /// about 10 mb for ibn kathir, kept while the app runs
  final _loaded = <TafsirSource, Future<Map<String, dynamic>>>{};

  Future<Directory> get folder => _folder ??= () async {
    final folder = Directory('${(await _root()).path}/tafsir');
    if (!folder.existsSync()) {
      await folder.create(recursive: true);
      await _exclude(folder.path);
    }
    return folder;
  }();

  Future<File> _file(TafsirSource source) async => File('${(await folder).path}/${source.file}');

  Future<bool> isReady(TafsirSource source) async =>
      source == TafsirSource.muyassar || (await _file(source)).existsSync();

  /// progress is 0 to 1, or null when the server sends no size
  Future<void> download(TafsirSource source, {void Function(double? progress)? onProgress}) async {
    final uri = _address(source);
    if (uri.scheme != 'https') throw const TafsirException(TafsirFailure.failed);
    _cancelled.remove(source);
    final file = await _file(source);
    final part = File('${file.path}.part');
    final Fetched fetched;
    try {
      fetched = await _fetch(uri);
    } on SocketException {
      throw const TafsirException(TafsirFailure.offline);
    } on IOException {
      throw const TafsirException(TafsirFailure.failed);
    }
    final digest = _Digest();
    final hash = sha256.startChunkedConversion(digest);
    final sink = part.openWrite();
    var written = 0;
    try {
      await for (final chunk in fetched.bytes) {
        if (_cancelled.contains(source)) throw const TafsirException(TafsirFailure.cancelled);
        hash.add(chunk);
        sink.add(chunk);
        written += chunk.length;
        final length = fetched.length;
        onProgress?.call(length == null ? null : written / length);
      }
      hash.close();
      await sink.close();
    } on Object catch (error) {
      await sink.close().catchError((_) {});
      if (part.existsSync()) part.deleteSync();
      if (error is TafsirException) rethrow;
      throw TafsirException(
        error is SocketException ? TafsirFailure.offline : TafsirFailure.failed,
      );
    }
    if ('${digest.value}' != _sha256(source)) {
      part.deleteSync();
      throw const TafsirException(TafsirFailure.failed);
    }
    part.renameSync(file.path);
  }

  /// the running download stops at its next chunk and deletes its .part
  void cancel(TafsirSource source) => _cancelled.add(source);

  Future<String> text(TafsirSource source, AyahKey key) async {
    if (source == TafsirSource.muyassar) {
      return (await (await _assets()).surahText(key.surah)).tafsir[key.ayah - 1];
    }
    final json = await (_loaded[source] ??= _read(source));
    return ((json['${key.surah}'] as List)[key.ayah - 1] as String);
  }

  /// decoded off the main isolate, the file is large
  Future<Map<String, dynamic>> _read(TafsirSource source) async {
    final path = (await _file(source)).path;
    return Isolate.run(
      () =>
          jsonDecode(utf8.decode(gzip.decode(File(path).readAsBytesSync())))
              as Map<String, dynamic>,
    );
  }
}

/// sha256's chunked conversion hands its one digest to a sink
class _Digest implements Sink<Digest> {
  Digest? value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}
