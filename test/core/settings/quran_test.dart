import 'dart:convert';
import 'dart:io';

import 'package:better_muslim/core/settings/quran.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// page 10 as shipped, with 2:67's open fathatan and 2:69's open dammatan
  final page = jsonDecode(File('assets/quran/pages/010.json').readAsStringSync()) as Map;
  final words = [
    for (final line in (page['lines'] as List).cast<Map<String, dynamic>>())
      for (final word in (line['w'] as List?) ?? const []) (word as List)[2] as String,
  ];

  test('amiri and scheherazade draw open tanween at U+08F0 to U+08F2', () {
    const text = 'بَقَرَةٗ بَقَرَةٞ قَوۡمٖ';
    for (final font in [QuranFont.amiri, QuranFont.scheherazade]) {
      expect(font.drawn(text), 'بَقَرَةࣰ بَقَرَةࣱ قَوۡمࣲ', reason: font.name);
    }
    final drawn = QuranFont.amiri.drawn(words.join(' '));
    expect(drawn, contains('بَقَرَةࣱ'));
    expect(drawn, isNot(contains('ٞ')));
  });

  test('kfgqpc draws the text as stored', () {
    for (final word in words) {
      expect(QuranFont.kfgqpc.drawn(word), word);
    }
  });

  test('V4 takes its dark palette on night and navy, sepia on sepia, light on the rest', () {
    expect(
      {for (final color in PageColor.values.skip(1)) color: MushafStyle.qcfV4.palette(color)},
      {
        PageColor.white: 0,
        PageColor.paper: 0,
        PageColor.cream: 0,
        PageColor.sepia: 2,
        PageColor.green: 0,
        PageColor.night: 1,
        PageColor.navy: 1,
      },
    );
    for (final style in [MushafStyle.text, MushafStyle.qcfV2, MushafStyle.qcfV1]) {
      expect(style.palette(PageColor.night), 0, reason: style.name);
    }
  });
}
