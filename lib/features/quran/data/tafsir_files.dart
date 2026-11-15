import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:better_muslim/core/database/backup_exclusion.dart';
import 'package:better_muslim/core/network/download.dart';
import 'package:better_muslim/core/network/download_notice.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final tafsirFilesProvider = Provider<TafsirFiles>(
  (ref) => TafsirFiles(assets: () => ref.read(quranAssetsProvider.future)),
);

/// al-muyassar ships in the surah files, the rest are downloaded once (contracts/tafsir-files)
enum TafsirSource {
  muyassar(file: '', sha256: '', release: ''),

  ibnKathir(
    file: 'ibn_kathir.json.gz',
    sha256: '2bfc4bebff51a65d4277dd5dda53c54bbf1aff5ed9e4ac1a009cd89151644673',
    release: 'tafsir-v1',
  ),
  saadi(
    file: 'saadi.json.gz',
    sha256: '168779be2ff2c428af34445bf76294518c0fb433f7c5648ed6b355ab8d7fd7ee',
    release: 'tafsir-v1',
  ),
  tabari(
    file: 'tabari.json.gz',
    sha256: '3849d44e535886ae8b085b911c0d7b4fbc0a5a85a1394a13eaf6fdaa6da55132',
    release: 'tafsir-v2',
  ),
  qurtubi(
    file: 'qurtubi.json.gz',
    sha256: '0c6823245c7d2ad4f4709ce334f4d8b94a7adbe88e0d342cb93c1aa89cf1ae77',
    release: 'tafsir-v2',
  );

  const TafsirSource({required this.file, required this.sha256, required this.release});

  final String file;
  final String sha256;

  /// a release once uploaded is never changed, a new tafsir goes in a new one
  final String release;

  Uri get address => contentReleases.resolve('$release/$file');

  /// a StringsManager key
  String get label => switch (this) {
    TafsirSource.muyassar => StringsManager.alMuyassar,
    TafsirSource.ibnKathir => StringsManager.ibnKathir,
    TafsirSource.saadi => StringsManager.asSadi,
    TafsirSource.tabari => StringsManager.atTabari,
    TafsirSource.qurtubi => StringsManager.alQurtubi,
  };
}

/// each tafsir is one file for the whole quran, kept only when its sha256 matches (research R15)
class TafsirFiles {
  TafsirFiles({
    required this._assets,
    Future<Directory> Function()? root,
    Fetch? fetch,
    Future<void> Function(String path)? exclude,
    Uri Function(TafsirSource source)? address,
    String Function(TafsirSource source)? sha256,
  }) : _root = root ?? getApplicationSupportDirectory,
       _fetch = fetch ?? fetchUri,
       _exclude = exclude ?? BackupExclusion.exclude,
       _address = address ?? ((source) => source.address),
       _sha256 = sha256 ?? ((source) => source.sha256);

  final Future<QuranAssets> Function() _assets;
  final Future<Directory> Function() _root;
  final Fetch _fetch;
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
  Future<void> download(
    TafsirSource source, {
    void Function(double? progress)? onProgress,
    DownloadNotice? notice,
  }) async {
    _cancelled.remove(source);
    bool cancelled() => _cancelled.contains(source);
    final file = await _file(source);
    await untilOnline(
      () => saveVerified(
        _address(source),
        file,
        sha256Hex: _sha256(source),
        fetch: _fetch,
        cancelled: cancelled,
        onProgress: onProgress,
        notice: notice,
      ),
      notice: notice,
      cancelled: cancelled,
    );
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
