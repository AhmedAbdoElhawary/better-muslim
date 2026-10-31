import 'package:better_muslim/core/resources/design/bm_colors.dart';
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
  const texts = [ThemeEnum.ink, ThemeEnum.ink2, ThemeEnum.text2, ThemeEnum.text3];
  const unders = [ThemeEnum.page, ThemeEnum.surface, ThemeEnum.bg];

  for (final (name, palette) in [
    ('paper', BmPagePalette.paper),
    ('cream', BmPagePalette.cream),
    ('sepia', BmPagePalette.sepia),
    ('green', BmPagePalette.green),
    ('night', BmPagePalette.night),
    ('navy', BmPagePalette.navy),
  ]) {
    test('$name meets AA for the reader text (SC-008)', () {
      for (final text in texts) {
        for (final under in unders) {
          expect(
            _ratio(text.resolve(palette), under.resolve(palette)),
            greaterThanOrEqualTo(4.5),
            reason: '${text.name} on ${under.name}',
          );
        }
      }
    });
  }

  test('an app palette without page colors falls back by brightness', () {
    final dark = bmThemes[BmThemeId.qiyam]!.dark;
    final light = bmThemes[BmThemeId.noor]!.light;
    expect(ThemeEnum.page.resolve(dark), BmPagePalette.night.page!.page);
    expect(ThemeEnum.page.resolve(light), BmPagePalette.paper.page!.page);
  });

  test('qiyam emerald gets the designed page back exactly', () {
    final theme = bmThemes[BmThemeId.qiyamEmerald]!;
    expect(BmPagePalette.tint(BmPagePalette.paper, theme.light), same(BmPagePalette.paper));
    expect(BmPagePalette.tint(BmPagePalette.night, theme.dark), same(BmPagePalette.night));
  });

  for (final id in BmThemeId.values) {
    test('${id.name} tints the page but keeps its paper and ink', () {
      for (final (base, theme) in [
        (BmPagePalette.paper, bmThemes[id]!.light),
        (BmPagePalette.night, bmThemes[id]!.dark),
      ]) {
        final tinted = BmPagePalette.tint(base, theme);
        expect(tinted.primary, theme.primary);
        expect(tinted.glow, theme.glow);
        for (final role in [...texts, ...unders]) {
          expect(role.resolve(tinted), role.resolve(base), reason: role.name);
        }
        expect(
          _ratio(ThemeEnum.onPrimary.resolve(tinted), ThemeEnum.primary.resolve(tinted)),
          greaterThanOrEqualTo(4.5),
          reason: 'onPrimary on primary',
        );
      }
    });
  }

  /// a theme that isn't == the last restarts the reader's 1.8 s AnimatedTheme on every rebuild
  test('the same palette gives the same theme', () {
    expect(
      AppTheme.page(PageColor.sepia, BmThemeId.iznik),
      same(AppTheme.page(PageColor.sepia, BmThemeId.iznik)),
    );
    expect(AppTheme.light(BmThemeId.noor), same(AppTheme.light(BmThemeId.noor)));
    expect(AppTheme.dark(BmThemeId.noor), same(AppTheme.dark(BmThemeId.noor)));
    expect(AppTheme.page(PageColor.night), isNot(same(AppTheme.page(PageColor.navy))));
  });
}
