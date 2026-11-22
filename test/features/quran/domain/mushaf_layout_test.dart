import 'dart:ui';

import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/features/quran/domain/mushaf_layout.dart';
import 'package:better_muslim/features/quran/domain/mushaf_page.dart';
import 'package:flutter_test/flutter_test.dart';

MushafLine _ayah(int words, {bool centered = false}) => MushafLine(
  type: MushafLineType.ayah,
  centered: centered,
  words: [for (var i = 0; i < words; i++) MushafWord(key: const AyahKey(2, 1), text: '$i')],
);

void main() {
  const area = Rect.fromLTWH(20, 100, 300, 0);
  const gap = 6.0;

  MushafLayout lay(List<MushafLine> lines, List<List<double>> widths, {double band = 45}) =>
      layoutMushaf(
        page: MushafPage(number: 3, lines: lines),
        widths: widths,
        bands: List.filled(lines.length, band),
        area: area,
        gap: gap,
      );

  test('words run right to left with equal gaps that fill the width', () {
    final layout = lay(
      [_ayah(3)],
      [
        [60, 80, 40],
      ],
    );
    final words = layout.words.single;
    expect(words.first.right, area.right);
    expect(words.last.left, area.left);
    expect(words[0].left, greaterThan(words[1].right));
    expect(words[0].left - words[1].right, closeTo(words[1].left - words[2].right, 1e-9));
    expect(layout.scales.single, 1);
  });

  test('a line wider than the page is squeezed to fit', () {
    final layout = lay(
      [_ayah(2)],
      [
        [200, 200],
      ],
    );
    final words = layout.words.single;
    expect(layout.scales.single, lessThan(1));
    expect(words.first.right, closeTo(area.right, 1e-9));
    expect(words.last.left, closeTo(area.left, 1e-9));
    expect(words.first.width, closeTo(200 * layout.scales.single, 1e-9));
  });

  test('a centered line keeps its natural gaps in the middle', () {
    final layout = lay(
      [_ayah(2, centered: true)],
      [
        [50, 50],
      ],
    );
    final words = layout.words.single;
    expect(words.first.left - words.last.right, gap);
    expect(area.right - words.first.right, closeTo(words.last.left - area.left, 1e-9));
  });

  test('every word sits inside its line band', () {
    final layout = lay(
      [_ayah(3), _ayah(4), _ayah(2, centered: true)],
      [
        [60, 80, 40],
        [50, 50, 50, 50],
        [90, 90],
      ],
    );
    for (var i = 0; i < 3; i++) {
      expect(layout.lines[i].top, area.top + 45 * i);
      for (final word in layout.words[i]) {
        expect(word.top, layout.lines[i].top);
        expect(word.bottom, layout.lines[i].bottom);
        expect(word.left, greaterThanOrEqualTo(area.left - 1e-9));
        expect(word.right, lessThanOrEqualTo(area.right + 1e-9));
      }
    }
  });

  test('a surah name and a basmallah line take their own bands, without words', () {
    final layout = lay(
      [
        const MushafLine(type: MushafLineType.surahName, surah: 2),
        const MushafLine(type: MushafLineType.basmallah),
        _ayah(2),
      ],
      [
        [],
        [],
        [100, 100],
      ],
    );
    expect(layout.lines, hasLength(3));
    expect(layout.words[0], isEmpty);
    expect(layout.words[1], isEmpty);
    expect(layout.lines[2].top, layout.lines[1].bottom);
  });

  test('a band is at least 44 pt tall on the design phone', () {
    const height =
        852 -
        SpaceManager.mushafFrameTop -
        SpaceManager.mushafFrameBottom -
        2 * SpaceManager.mushafFrameInner;
    expect(regularBands(height), hasLength(mushafLines));
    expect(regularBands(height).first, greaterThanOrEqualTo(SizeManager.hit));
  });

  group('reflowMushaf', () {
    List<String> texts(MushafLine line) => [for (final word in line.words) word.text];

    test('the words flow into lines as wide as the width, in order', () {
      final page = MushafPage(number: 3, lines: [_ayah(3), _ayah(2)]);
      final flowed = reflowMushaf(
        page,
        widths: [
          [100, 100, 100],
          [100, 100],
        ],
        width: 220,
        gap: gap,
      );
      expect(flowed.lines.map(texts), [
        ['0', '1'],
        ['2', '0'],
        ['1'],
      ]);
      expect(flowed.lines.map((line) => line.centered), [false, false, true]);
    });

    test('a surah name and the basmallah keep their own lines', () {
      const name = MushafLine(type: MushafLineType.surahName, surah: 3);
      const basmallah = MushafLine(type: MushafLineType.basmallah);
      final page = MushafPage(number: 50, lines: [_ayah(2), name, basmallah, _ayah(1)]);
      final flowed = reflowMushaf(
        page,
        widths: [
          [50, 50],
          [],
          [],
          [50],
        ],
        width: 300,
        gap: gap,
      );
      expect(flowed.lines.map((line) => line.type), [
        MushafLineType.ayah,
        MushafLineType.surahName,
        MushafLineType.basmallah,
        MushafLineType.ayah,
      ]);
      expect(flowed.lines.first.centered, isTrue, reason: 'the run before the name ends there');
      expect(flowed.lines[1].surah, 3);
    });

    test('a word wider than the line gets a line of its own', () {
      final flowed = reflowMushaf(
        MushafPage(number: 3, lines: [_ayah(2)]),
        widths: [
          [400, 50],
        ],
        width: 300,
        gap: gap,
      );
      expect(flowed.lines.map(texts), [
        ['0'],
        ['1'],
      ]);
    });
  });
}
