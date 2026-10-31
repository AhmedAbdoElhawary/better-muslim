import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/resources/design/bm_tokens.dart';
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
      /// aa for graphics, the ribbons sit on the theme's page and Saved's cards, and on each
      /// reader page of the same mode
      test('${id.name} $mode: every category color meets 3:1 on its pages', () {
        final dark = palette.bg.computeLuminance() < .5;
        final pages = [
          palette,
          for (final base in [
            BmPagePalette.paper,
            BmPagePalette.cream,
            BmPagePalette.sepia,
            BmPagePalette.green,
            BmPagePalette.night,
            BmPagePalette.navy,
          ])
            if ((base.bg.computeLuminance() < .5) == dark) BmPagePalette.tint(base, palette),
        ];
        for (final page in pages) {
          for (final color in CategoryColor.values) {
            for (final under in [ThemeEnum.page, ThemeEnum.surface]) {
              expect(
                _ratio(color.theme.resolve(page), under.resolve(page)),
                greaterThanOrEqualTo(3),
                reason: '${color.name} on ${under.name}',
              );
            }
          }
        }
      });

      test('${id.name} $mode meets AA for body text (SC-007)', () {
        for (final (text, under) in pairs) {
          expect(
            _ratio(text.resolve(palette), under.resolve(palette)),
            greaterThanOrEqualTo(4.5),
            reason: '${text.name} on ${under.name}',
          );
        }
      });

      /// the glass bar over the glow's strongest point and over a card under it, the card's text
      /// blurred away by the bar (FR-041)
      test('${id.name} $mode: the bar title over the glow meets AA', () {
        Color glass(Color under) => Color.alphaBlend(
          ThemeEnum.surface.resolve(palette).withValues(alpha: BmGlass.surfaceOpacity),
          under,
        );
        final bg = ThemeEnum.bg.resolve(palette);
        final glow = Color.alphaBlend(ThemeEnum.sky3.resolve(palette).withValues(alpha: .7), bg);
        for (final (name, under) in [
          ('glow', glow),
          ('bg', bg),
          ('raised', ThemeEnum.raised.resolve(palette)),
        ]) {
          expect(
            _ratio(ThemeEnum.text.resolve(palette), glass(under)),
            greaterThanOrEqualTo(4.5),
            reason: 'text on the glass over $name',
          );
        }
      });

      /// the tab labels on the glass nav bar over the pages and cards under it, the sky is only at
      /// home's top (FR-003)
      test('${id.name} $mode: the nav labels on the glass meet AA', () {
        Color glass(Color under) => Color.alphaBlend(
          ThemeEnum.surface.resolve(palette).withValues(alpha: BmGlass.surfaceOpacity),
          under,
        );
        for (final under in [ThemeEnum.bg, ThemeEnum.raised]) {
          for (final label in [ThemeEnum.primary, ThemeEnum.text2]) {
            expect(
              _ratio(label.resolve(palette), glass(under.resolve(palette))),
              greaterThanOrEqualTo(4.5),
              reason: '${label.name} on the glass over ${under.name}',
            );
          }
        }
      });
    }
  }
}
