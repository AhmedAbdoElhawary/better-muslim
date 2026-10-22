import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/resources/design/bm_theme.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/router/page_transitions.dart';
import 'package:better_muslim/core/settings/quran.dart';
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
  transparent,
  page,
  ink,
  ink2,
  ornament,
  ornamentSoft,
  selectionWash,
  followWash,
  pageHidden,
  gutter,
  pageGlass,
  oilLight,
  oilDark,
  oilRipple,
  shareEmerald,
  shareSky1,
  shareSky2,
  shareSky3;

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
    ThemeEnum.page => palette.pageColors.page,
    ThemeEnum.ink => palette.pageColors.ink,
    ThemeEnum.ink2 => palette.pageColors.ink2,
    ThemeEnum.ornament => palette.pageColors.ornament,
    ThemeEnum.ornamentSoft => palette.pageColors.ornamentSoft,
    ThemeEnum.selectionWash => palette.pageColors.selectionWash,
    ThemeEnum.followWash => palette.pageColors.followWash,
    ThemeEnum.pageHidden => palette.pageColors.hidden,
    ThemeEnum.gutter => palette.pageColors.gutter,

    /// GLASS in _gen/quran.js, the reader's bars over the page
    ThemeEnum.pageGlass => palette.surface.withValues(alpha: .78),
    ThemeEnum.oilLight => bmOilLight,
    ThemeEnum.oilDark => bmOilDark,
    ThemeEnum.oilRipple => bmOilRipple,
    ThemeEnum.shareEmerald => bmShareEmerald,
    ThemeEnum.shareSky1 => bmShareSky1,
    ThemeEnum.shareSky2 => bmShareSky2,
    ThemeEnum.shareSky3 => bmShareSky3,
  };
}

extension ThemeExtension on BuildContext {
  bool get isThemeDark => Theme.of(this).brightness == Brightness.dark;

  Color getColor(ThemeEnum color) => color.resolve(bm);

  double get starOpacity => bm.starOpacity;
}

extension BmThemeName on BmThemeId {
  String get nameKey => switch (this) {
    BmThemeId.qiyamEmerald => StringsManager.themeQiyamEmerald,
    BmThemeId.qiyam => StringsManager.themeQiyam,
    BmThemeId.noor => StringsManager.themeNoor,
    BmThemeId.livingSky => StringsManager.themeLivingSky,
    BmThemeId.iznik => StringsManager.themeIznik,
    BmThemeId.andalus => StringsManager.themeAndalus,
    BmThemeId.moonlight => StringsManager.themeMoonlight,
    BmThemeId.qiyamRose => StringsManager.themeQiyamRose,
  };
}

extension BmThemeModeName on BmThemeMode {
  String get nameKey => switch (this) {
    BmThemeMode.dark => StringsManager.dark,
    BmThemeMode.light => StringsManager.light,
    BmThemeMode.followSky => StringsManager.followSky,
  };
}

abstract final class AppTheme {
  static ThemeData light(BmThemeId id) => _build(bmThemes[id]!.light, Brightness.light);
  static ThemeData dark(BmThemeId id) => _build(bmThemes[id]!.dark, Brightness.dark);

  /// the reader's chrome takes the page's palette tinted by the app's theme (research R5).
  /// follow sky is resolved before, see PageColor.resolve
  static ThemeData page(PageColor color, [BmThemeId id = BmThemeId.qiyamEmerald]) {
    final theme = bmThemes[id]!;
    return switch (color) {
      PageColor.night => _build(
        BmPagePalette.tint(BmPagePalette.night, theme.dark),
        Brightness.dark,
      ),
      PageColor.cream => _build(
        BmPagePalette.tint(BmPagePalette.cream, theme.light),
        Brightness.light,
      ),
      PageColor.paper || PageColor.followSky => _build(
        BmPagePalette.tint(BmPagePalette.paper, theme.light),
        Brightness.light,
      ),
    };
  }

  /// BmText.body and material 3 typography fill line height and letter spacing into every text
  /// that leaves them empty, where the specs mean the font's own metrics
  static ThemeData _build(BmPalette palette, Brightness brightness) {
    final theme = bmThemeData(palette, brightness);
    return theme.copyWith(
      typography: Typography.material2014(),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: BmPageTransitionsBuilder(),
          TargetPlatform.android: BmPageTransitionsBuilder(),
        },
      ),
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
