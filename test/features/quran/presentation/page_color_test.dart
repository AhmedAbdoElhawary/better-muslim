import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/resources/design/bm_theme.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// wcag's ratio of the lighter to the darker relative luminance
double _ratio(Color a, Color b) {
  final (light, dark) = (a.computeLuminance(), b.computeLuminance());
  return light > dark ? (light + .05) / (dark + .05) : (dark + .05) / (light + .05);
}

void main() {
  test("follow sky is night in the app's dark mode and paper in its light mode", () {
    expect(PageColor.followSky.resolve(dark: true), PageColor.night);
    expect(PageColor.followSky.resolve(dark: false), PageColor.paper);
  });

  test('a picked palette is kept in either mode', () {
    for (final picked in PageColor.values.where((color) => color != PageColor.followSky)) {
      expect(picked.resolve(dark: true), picked);
      expect(picked.resolve(dark: false), picked);
    }
  });

  for (final color in PageColor.values.where((color) => color != PageColor.followSky)) {
    test('${color.name} keeps its ink at 7:1 and its ornament at 3:1 in every theme', () {
      for (final id in BmThemeId.values) {
        final page = AppTheme.page(color, id).extension<BmColors>()!.p.pageColors;
        expect(_ratio(page.ink, page.page), greaterThanOrEqualTo(7), reason: '${id.name} ink');

        /// paper and night keep the designer's gold, their frames are decoration
        if (color != PageColor.paper && color != PageColor.night) {
          expect(
            _ratio(page.ornament, page.page),
            greaterThanOrEqualTo(3),
            reason: '${id.name} ornament',
          );
        }
      }
    });
  }
}
