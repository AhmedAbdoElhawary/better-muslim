import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:better_muslim/core/network/download.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/features/quran/data/tafsir_files.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

/// two surahs are enough for the reader, the build tool checks all 114
final _body = gzip.encode(
  utf8.encode(
    jsonEncode({
      '1': ['al-fatiha 1', 'al-fatiha 2'],
      '2': ['al-baqarah 1'],
    }),
  ),
);

void main() {
  late Directory root;
  late List<double?> progress;

  setUp(() {
    root = Directory.systemTemp.createTempSync('tafsir');
    progress = [];
  });

  tearDown(() => root.deleteSync(recursive: true));

  TafsirFiles files(
    Future<Fetched> Function(Uri uri) fetch, {
    String? hash,
    String address = 'https://example.com/ibn_kathir.json.gz',
  }) => TafsirFiles(
    assets: () async => throw UnimplementedError(),
    root: () async => root,
    fetch: fetch,
    exclude: (_) async {},
    address: (_) => Uri.parse(address),
    sha256: (_) => hash ?? '${sha256.convert(_body)}',
  );

  Future<Fetched> serve(List<int> body, {int? length}) async =>
      (length: length, bytes: Stream.fromIterable([body.sublist(0, 10), body.sublist(10)]));

  List<String> left() =>
      Directory('${root.path}/tafsir')
          .listSync()
          .map((file) => file.uri.pathSegments.last)
          .toList();

  Future<DownloadFailure> failure(Future<Object?> future) async {
    try {
      await future;
    } on DownloadException catch (error) {
      return error.failure;
    }
    fail('no error');
  }

  Future<void> download(TafsirFiles tafsir) =>
      tafsir.download(TafsirSource.ibnKathir, onProgress: progress.add);

  test('a body with the right hash is kept and read', () async {
    final tafsir = files((_) => serve(_body, length: _body.length));
    expect(await tafsir.isReady(TafsirSource.ibnKathir), isFalse);
    await download(tafsir);
    expect(left(), ['ibn_kathir.json.gz']);
    expect(await tafsir.isReady(TafsirSource.ibnKathir), isTrue);
    expect(progress.last, 1);
    expect(await tafsir.text(TafsirSource.ibnKathir, const AyahKey(1, 2)), 'al-fatiha 2');
  });

  test('a wrong hash leaves no file and no .part', () async {
    final tafsir = files((_) => serve(_body), hash: 'not it');
    expect(await failure(download(tafsir)), DownloadFailure.failed);
    expect(left(), isEmpty);
  });

  test('no size header still downloads, with no progress number', () async {
    await download(files((_) => serve(_body)));
    expect(progress, [null, null]);
    expect(left(), ['ibn_kathir.json.gz']);
  });

  test('offline throws offline', () async {
    final tafsir = files((_) => throw const SocketException('offline'));
    expect(await failure(download(tafsir)), DownloadFailure.offline);
  });

  test('a plain http address is refused before anything is fetched', () async {
    var asked = 0;
    final tafsir = files((_) {
      asked++;
      return serve(_body);
    }, address: 'http://example.com/ibn_kathir.json.gz');
    expect(await failure(download(tafsir)), DownloadFailure.failed);
    expect(asked, 0);
  });

  test('cancel stops at the next chunk and deletes the .part', () async {
    final chunks = StreamController<List<int>>();
    final tafsir = files((_) async => (length: _body.length, bytes: chunks.stream));
    final running = failure(download(tafsir));
    chunks.add(_body.sublist(0, 10));
    await pumpEventQueue();
    expect(left(), ['ibn_kathir.json.gz.part']);
    tafsir.cancel(TafsirSource.ibnKathir);
    chunks.add(_body.sublist(10));
    expect(await running, DownloadFailure.cancelled);
    expect(left(), isEmpty);
    await chunks.close();
  });

  test('tabari and qurtubi download from tafsir-v2 with their own sha256', () {
    expect(
      TafsirSource.tabari.address.toString(),
      'https://github.com/AhmedAbdoElhawary/better-muslim-content/releases/download/tafsir-v2/tabari.json.gz',
    );
    expect(
      TafsirSource.qurtubi.address.toString(),
      'https://github.com/AhmedAbdoElhawary/better-muslim-content/releases/download/tafsir-v2/qurtubi.json.gz',
    );
    expect(TafsirSource.ibnKathir.address.pathSegments.reversed.take(2), [
      'ibn_kathir.json.gz',
      'tafsir-v1',
    ]);
    final hashes = {for (final source in TafsirSource.values.skip(1)) source.sha256};
    expect(hashes, hasLength(4));
    expect(hashes.every(RegExp(r'^[0-9a-f]{64}$').hasMatch), isTrue);
  });

  test('al-muyassar is always ready, from the shipped surah files', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final tafsir = TafsirFiles(assets: QuranAssets.load, root: () async => root);
    expect(await tafsir.isReady(TafsirSource.muyassar), isTrue);
    expect(await tafsir.text(TafsirSource.muyassar, const AyahKey(1, 1)), isNotEmpty);
  });
}
