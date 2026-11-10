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
  welcomeScrim,
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
  highlightWash,
  pageHidden,
  gutter,
  pageGlass,
  shareEmerald,
  shareSky1,
  shareSky2,
  shareSky3,
  categoryGreen,
  categoryTeal,
  categoryBlue,
  categoryViolet,
  categoryRose,
  categoryAmber,
  categorySlate;

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

    /// bm_sky's 28% missed AA on the brightest drift, 38% is the least that passes
    ThemeEnum.skyScrim => const Color(0x60000000),

    /// the welcome's text block stays AA on every sky, the lightest needs 52%
    ThemeEnum.welcomeScrim => const Color(0x85000000),
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

    /// a note's highlight, the accent soft enough that the ink on it stays AA
    ThemeEnum.highlightWash => palette.accent.withValues(alpha: .2),
    ThemeEnum.pageHidden => palette.pageColors.hidden,
    ThemeEnum.gutter => palette.pageColors.gutter,

    /// GLASS in _gen/quran.js, the reader's bars over the page
    ThemeEnum.pageGlass => palette.surface.withValues(alpha: .78),
    ThemeEnum.shareEmerald => bmShareEmerald,
    ThemeEnum.shareSky1 => bmShareSky1,
    ThemeEnum.shareSky2 => bmShareSky2,
    ThemeEnum.shareSky3 => bmShareSky3,
    ThemeEnum.categoryGreen => _byMode(palette, bmCategoryGreen),
    ThemeEnum.categoryTeal => _byMode(palette, bmCategoryTeal),
    ThemeEnum.categoryBlue => _byMode(palette, bmCategoryBlue),
    ThemeEnum.categoryViolet => _byMode(palette, bmCategoryViolet),
    ThemeEnum.categoryRose => _byMode(palette, bmCategoryRose),
    ThemeEnum.categoryAmber => _byMode(palette, bmCategoryAmber),
    ThemeEnum.categorySlate => _byMode(palette, bmCategorySlate),
  };

  static Color _byMode(BmPalette palette, ({Color light, Color dark}) color) =>
      Color.lerp(color.light, color.dark, palette.pageColors.night)!;
}

/// a theme that isn't the context's yet, like the reader's before it opens
extension ThemeDataColor on ThemeData {
  Color getColor(ThemeEnum color) => color.resolve(extension<BmColors>()!.p);
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
    BmThemeId.saharaSand => StringsManager.themeSaharaSand,
    BmThemeId.zaytun => StringsManager.themeZaytun,
    BmThemeId.attar => StringsManager.themeAttar,
    BmThemeId.noorMidnight => StringsManager.themeNoorMidnight,
    BmThemeId.qiyamDusk => StringsManager.themeQiyamDusk,
    BmThemeId.qiyamCopper => StringsManager.themeQiyamCopper,
    BmThemeId.qiyamLapis => StringsManager.themeQiyamLapis,
    BmThemeId.qiyamSand => StringsManager.themeQiyamSand,
  };
}

extension CategoryTheme on CategoryColor {
  ThemeEnum get theme => switch (this) {
    CategoryColor.primary => ThemeEnum.primary,
    CategoryColor.green => ThemeEnum.categoryGreen,
    CategoryColor.teal => ThemeEnum.categoryTeal,
    CategoryColor.blue => ThemeEnum.categoryBlue,
    CategoryColor.violet => ThemeEnum.categoryViolet,
    CategoryColor.rose => ThemeEnum.categoryRose,
    CategoryColor.amber => ThemeEnum.categoryAmber,
    CategoryColor.slate => ThemeEnum.categorySlate,
  };
}

extension BmThemeModeName on BmThemeMode {
  String get nameKey => switch (this) {
    BmThemeMode.dark => StringsManager.dark,
    BmThemeMode.light => StringsManager.light,
    BmThemeMode.followSky => StringsManager.followSky,
    BmThemeMode.followPhone => StringsManager.followPhoneMode,
  };
}

abstract final class AppTheme {
  /// one per palette, a new ThemeData is never == so AnimatedTheme fades again on each rebuild
  static final _themes = <Object, ThemeData>{};

  static ThemeData light(BmThemeId id) =>
      _themes[(id, Brightness.light)] ??= _build(bmThemes[id]!.light, Brightness.light);
  static ThemeData dark(BmThemeId id) =>
      _themes[(id, Brightness.dark)] ??= _build(bmThemes[id]!.dark, Brightness.dark);

  /// the reader's chrome takes the page's palette tinted by the app's theme (research R5).
  /// follow sky is resolved before, see PageColor.resolve
  static ThemeData page(PageColor color, [BmThemeId id = BmThemeId.moonlight]) {
    final theme = bmThemes[id]!;
    final base = switch (color) {
      PageColor.white => BmPagePalette.white,
      PageColor.paper || PageColor.followSky => BmPagePalette.paper,
      PageColor.cream => BmPagePalette.cream,
      PageColor.sepia => BmPagePalette.sepia,
      PageColor.green => BmPagePalette.green,
      PageColor.night => BmPagePalette.night,
      PageColor.navy => BmPagePalette.navy,
    };
    return _themes[(color, id)] ??= color.dark
        ? _build(BmPagePalette.tint(base, theme.dark), Brightness.dark)
        : _build(BmPagePalette.tint(base, theme.light), Brightness.light);
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
