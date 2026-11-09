import 'dart:io';
import 'dart:typed_data';

import 'package:better_muslim/core/network/download.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/features/quran/data/mushaf_files.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

/// a page's "font" is its number repeated, packed like the tool packs the real ones
List<int> _font(int page) => List.filled(100 + page, page % 256);

final _body = () {
  final pages = [for (var n = 1; n <= quranPageCount; n++) gzip.encode(_font(n))];
  final offsets = ByteData(4 * (quranPageCount + 1));
  var offset = offsets.lengthInBytes;
  for (var n = 0; n <= quranPageCount; n++) {
    offsets.setUint32(4 * n, offset, Endian.little);
    if (n < quranPageCount) offset += pages[n].length;
  }
  return [...offsets.buffer.asUint8List(), for (final page in pages) ...page];
}();

void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('mushaf'));

  tearDown(() => root.deleteSync(recursive: true));

  MushafFiles files({String? hash}) => MushafFiles(
    root: () async => root,
    fetch: (_) async => (
      length: _body.length,
      bytes: Stream.fromIterable([_body.sublist(0, 10), _body.sublist(10)]),
    ),
    exclude: (_) async {},
    sha256: (_) => hash ?? '${sha256.convert(_body)}',
  );

  test('a downloaded style gives each page its own font', () async {
    final mushaf = files();
    expect(await mushaf.isReady(MushafStyle.qcfV2), isFalse);
    await mushaf.download(MushafStyle.qcfV2);
    expect(await mushaf.isReady(MushafStyle.qcfV2), isTrue);
    expect(await mushaf.pageFont(MushafStyle.qcfV2, 1), _font(1));
    expect(await mushaf.pageFont(MushafStyle.qcfV2, 300), _font(300));
    expect(await mushaf.pageFont(MushafStyle.qcfV2, quranPageCount), _font(quranPageCount));
    expect(await mushaf.downloaded(), [(MushafStyle.qcfV2, _body.length)]);
  });

  test('a wrong hash leaves nothing behind', () async {
    final mushaf = files(hash: 'not it');
    await expectLater(
      mushaf.download(MushafStyle.qcfV1),
      throwsA(isA<DownloadException>().having((e) => e.failure, 'failure', DownloadFailure.failed)),
    );
    expect(await mushaf.isReady(MushafStyle.qcfV1), isFalse);
    expect(Directory('${root.path}/mushaf').listSync(), isEmpty);
  });

  test('delete takes the style off the phone, text is always on it', () async {
    final mushaf = files();
    await mushaf.download(MushafStyle.qcfV4);
    await mushaf.delete(MushafStyle.qcfV4);
    expect(await mushaf.isReady(MushafStyle.qcfV4), isFalse);
    expect(await mushaf.downloaded(), isEmpty);
    expect(await mushaf.isReady(MushafStyle.text), isTrue);
  });

  test('each qcf style downloads from mushaf-v1', () {
    for (final style in MushafStyle.values.skip(1)) {
      expect(style.address.pathSegments.reversed.take(2), [style.file, 'mushaf-v1']);
      expect(style.address.scheme, 'https');
    }
  });

  test('a palette is drawn by pointing palette 0 at it', () {
    /// a font with only a CPAL table: 2 palettes of 1 color, black then white
    final font = ByteData(12 + 16 + 24)
      ..setUint16(4, 1)
      ..setUint32(12, 0x4350414C)
      ..setUint32(20, 28)
      ..setUint16(28 + 2, 1)
      ..setUint16(28 + 4, 2)
      ..setUint16(28 + 6, 2)
      ..setUint32(28 + 8, 16)
      ..setUint16(28 + 12, 0)
      ..setUint16(28 + 14, 1)
      ..setUint32(28 + 16, 0x000000FF)
      ..setUint32(28 + 20, 0xFFFFFFFF);
    final bytes = font.buffer.asUint8List();
    final dark = ByteData.sublistView(withPalette(bytes, 1));
    expect(dark.getUint16(28 + 12), 1);
    expect(dark.getUint16(28 + 14), 1);
    expect(font.getUint16(28 + 12), 0, reason: 'the file read stays as it was');
  });

  test('the V4 fonts have the light, dark and sepia palettes the page colors take', () {
    final file = File('tool/quran/.cache/qcf_v4/p3.ttf');
    if (!file.existsSync()) return markTestSkipped('no QCF fonts in tool/quran/.cache');
    final font = file.readAsBytesSync();
    Uint8List ink(Uint8List font) {
      final data = ByteData.sublistView(font);
      for (var i = 0; i < data.getUint16(4); i++) {
        if (String.fromCharCodes(font, 12 + 16 * i, 16 + 16 * i) != 'CPAL') continue;
        final cpal = data.getUint32(20 + 16 * i);
        final first = data.getUint32(cpal + 8) + 4 * data.getUint16(cpal + 12);
        return font.sublist(cpal + first, cpal + first + 4);
      }
      throw StateError('no CPAL');
    }

    /// the text's color, bgra
    expect(ink(font), [0, 0, 0, 255]);
    expect(ink(withPalette(font, 1)), [255, 255, 255, 255]);
    expect(ink(withPalette(font, 2)), [0, 0, 0, 255]);
  });
}
