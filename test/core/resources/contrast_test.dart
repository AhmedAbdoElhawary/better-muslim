import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/resources/design/bm_tokens.dart';
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

  /// the trees' own always dark values, the same as SurfaceColors.swift and surfaces_colors.xml.
  /// a tint is worked out over the darkest it sits on. the accessories are tinted by the system
  const surfaces = [
    ('5.6 text on the sky top', Color(0xFFD9D3C2), Color(0xFF000000)),
    ('5.6 text on the sky bottom', Color(0xFFD9D3C2), Color(0xFF173328)),
    ('5.6 label on the sky top', Color(0xFFB9B3A2), Color(0xFF000000)),
    ('5.6 label on the sky bottom', Color(0xFFB9B3A2), Color(0xFF173328)),
    ('5.6 gold on the sky top', Color(0xFFD9C08A), Color(0xFF000000)),
    ('5.6 gold on the sky bottom', Color(0xFFD9C08A), Color(0xFF173328)),
    ('5.6 label on a cell', Color(0xFFB9B3A2), Color(0xFF233D33)),
    ('5.6 text on a cell', Color(0xFFD9D3C2), Color(0xFF233D33)),
    ('5.6 gold on the next cell', Color(0xFFD9C08A), Color(0xFF344430)),
    ('5.6 text on the next cell', Color(0xFFD9D3C2), Color(0xFF344430)),
    ('5.6 large text on its bottom', Color(0xFFD9D3C2), Color(0xFF0B1E17)),
    ('5.6 large label on its bottom', Color(0xFFB9B3A2), Color(0xFF0B1E17)),
    ('5.6 large gold on its bottom', Color(0xFFD9C08A), Color(0xFF0B1E17)),
    ('5.6 large gold on the next row', Color(0xFFD9C08A), Color(0xFF2A3423)),
    ('5.6 large text on the next row', Color(0xFFD9D3C2), Color(0xFF2A3423)),
    ('5.8 text on the row', Color(0xFFD9D3C2), Color(0xFF07100D)),
    ('5.8 label on the row', Color(0xFFB9B3A2), Color(0xFF07100D)),
    ('5.8 past on the row', Color(0xFF878C82), Color(0xFF07100D)),
    ('5.8 gold on the next cell', Color(0xFFD9C08A), Color(0xFF221C10)),
    ('5.8 text on the next cell', Color(0xFFD9D3C2), Color(0xFF221C10)),
    ('5.3 prayer on black', Color(0xFFFFFFFF), Color(0xFF000000)),
    ('5.3 label on black', Color(0xFFB9B3A2), Color(0xFF000000)),
    ('5.3 countdown on black', Color(0xFFE9D7AE), Color(0xFF000000)),
    ('5.4 chip on its tint', Color(0xFFD9C08A), Color(0xFF221C10)),
  ];

  test('the widgets and the live activity meet AA (FR-031)', () {
    for (final (name, text, under) in surfaces) {
      expect(_ratio(text, under), greaterThanOrEqualTo(4.5), reason: name);
    }
  });

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
    }
  }
}
