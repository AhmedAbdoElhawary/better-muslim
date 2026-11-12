import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/resources/design/bm_theme.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final dark = bmThemes[BmThemeId.qiyamEmerald]!.dark;
  final light = bmThemes[BmThemeId.iznik]!.light;

  /// every color role, the ones made in ThemeEnum from a palette color follow it
  final roles = ThemeEnum.values.where((role) => role.resolve(dark) != role.resolve(light));

  test('0 is the first palette and 1 the second', () {
    for (final role in roles) {
      expect(role.resolve(BmPalette.lerp(dark, light, 0)), role.resolve(dark), reason: role.name);
      expect(role.resolve(BmPalette.lerp(dark, light, 1)), role.resolve(light), reason: role.name);
    }
  });

  test('half way is each color half way, the stars too', () {
    final half = BmPalette.lerp(dark, light, .5);
    for (final role in roles) {
      expect(
        role.resolve(half),
        Color.lerp(role.resolve(dark), role.resolve(light), .5),
        reason: role.name,
      );
    }
    expect(half.starOpacity, (dark.starOpacity + light.starOpacity) / 2);
  });

  test('the theme extension crossfades instead of cutting at half way', () {
    final quarter = BmColors(dark).lerp(BmColors(light), .25).p;
    expect(quarter.primary, Color.lerp(dark.primary, light.primary, .25));
  });

  test('the 8 explored themes after the first 8, in the exploration order', () {
    expect(bmThemeOrder.skip(8), [
      BmThemeId.saharaSand,
      BmThemeId.zaytun,
      BmThemeId.attar,
      BmThemeId.noorMidnight,
      BmThemeId.qiyamDusk,
      BmThemeId.qiyamCopper,
      BmThemeId.qiyamLapis,
      BmThemeId.qiyamSand,
    ]);
    expect(bmThemeOrder.toSet(), BmThemeId.values.toSet());
    expect(bmThemes.keys.toSet(), BmThemeId.values.toSet());
  });
}
