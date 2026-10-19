import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// wcag's ratio of the lighter to the darker relative luminance
double _ratio(Color a, Color b) {
  final (light, dark) = (a.computeLuminance(), b.computeLuminance());
  return light > dark ? (light + .05) / (dark + .05) : (dark + .05) / (light + .05);
}

void main() {
  const pairs = [
    (ThemeEnum.text, ThemeEnum.bg),
    (ThemeEnum.text, ThemeEnum.surface),
    (ThemeEnum.text2, ThemeEnum.bg),
    (ThemeEnum.text2, ThemeEnum.surface),
    (ThemeEnum.primary, ThemeEnum.bg),
    (ThemeEnum.primary, ThemeEnum.surface),
    (ThemeEnum.onPrimary, ThemeEnum.primary),
  ];

  for (final id in bmThemeOrder) {
    for (final (mode, palette) in [('dark', bmThemes[id]!.dark), ('light', bmThemes[id]!.light)]) {
      test('${id.name} $mode meets AA for body text (SC-007)', () {
        for (final (text, under) in pairs) {
          expect(
            _ratio(text.resolve(palette), under.resolve(palette)),
            greaterThanOrEqualTo(4.5),
            reason: '${text.name} on ${under.name}',
          );
        }
      });
    }
  }
}
