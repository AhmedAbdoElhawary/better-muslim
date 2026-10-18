import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/resources/design/bm_theme.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:flutter/material.dart';

/// every color in the app goes through this, the active BmPalette fills it so all 8 themes work
enum ThemeEnum {
  bg,
  surface,
  raised,
  variant,
  outline,
  outlineStrong,
  text,
  text2,
  text3,
  primary,
  onPrimary,
  primaryContainer,
  onPrimaryContainer,
  accent,
  accentContainer,
  onAccentContainer,
  success,
  warning,
  error,
  onError,
  glow,
  sky1,
  sky2,
  sky3,
  onSky,
  sun,
  onSkyMuted,
  onSkyBright,
  skyScrim,
  glass,
  glassHighlight,
  scrim,
  toastAction,
  transparent;

  Color resolve(BmPalette palette) => switch (this) {
    ThemeEnum.bg => palette.bg,
    ThemeEnum.surface => palette.surface,
    ThemeEnum.raised => palette.raised,
    ThemeEnum.variant => palette.variant,
    ThemeEnum.outline => palette.outline,
    ThemeEnum.outlineStrong => palette.outlineStrong,
    ThemeEnum.text => palette.text,
    ThemeEnum.text2 => palette.text2,
    ThemeEnum.text3 => palette.text3,
    ThemeEnum.primary => palette.primary,
    ThemeEnum.onPrimary => palette.onPrimary,
    ThemeEnum.primaryContainer => palette.primaryContainer,
    ThemeEnum.onPrimaryContainer => palette.onPrimaryContainer,
    ThemeEnum.accent => palette.accent,
    ThemeEnum.accentContainer => palette.accentContainer,
    ThemeEnum.onAccentContainer => palette.onAccentContainer,
    ThemeEnum.success => palette.success,
    ThemeEnum.warning => palette.warning,
    ThemeEnum.error => palette.error,
    ThemeEnum.onError => palette.onError,
    ThemeEnum.glow => palette.glow,
    ThemeEnum.sky1 => palette.sky1,
    ThemeEnum.sky2 => palette.sky2,
    ThemeEnum.sky3 => palette.sky3,
    ThemeEnum.onSky => palette.onSky,
    ThemeEnum.sun => palette.sun,

    /// the secondary header lines sit at 85% on the sky (4.01)
    ThemeEnum.onSkyMuted => palette.onSky.withValues(alpha: .85),

    /// bm_sky's numbers, the same on every theme and mode since the sky keeps its own palette
    ThemeEnum.onSkyBright => const Color(0xEBFFFFFF),
    ThemeEnum.skyScrim => const Color(0x47000000),
    ThemeEnum.glass => const Color(0x6607100D),
    ThemeEnum.glassHighlight => const Color(0x1AFFFFFF),

    /// black in every theme, the sheet sets its opacity by mode
    ThemeEnum.scrim => const Color(0xFF000000),

    /// the toast's undo, primary mixed 25% toward bg so it reads on the inverted toast
    ThemeEnum.toastAction => Color.lerp(palette.primary, palette.bg, .25)!,
    ThemeEnum.transparent => Colors.transparent,
  };
}

extension ThemeExtension on BuildContext {
  bool get isThemeDark => Theme.of(this).brightness == Brightness.dark;

  Color getColor(ThemeEnum color) => color.resolve(bm);

  double get starOpacity => bm.starOpacity;
}

abstract final class AppTheme {
  static ThemeData light(BmThemeId id) => _build(bmThemes[id]!.light, Brightness.light);
  static ThemeData dark(BmThemeId id) => _build(bmThemes[id]!.dark, Brightness.dark);

  /// BmText.body and material 3 typography fill line height and letter spacing into every text
  /// that leaves them empty, where the specs mean the font's own metrics
  static ThemeData _build(BmPalette palette, Brightness brightness) {
    final theme = bmThemeData(palette, brightness);
    return theme.copyWith(
      typography: Typography.material2014(),
      textTheme: theme.textTheme.copyWith(
        bodyMedium: TextStyle(
          fontFamily: FontFamilyManager.body,
          fontSize: FontSizeManager.body,
          color: palette.text,
        ),
      ),
    );
  }
}
