import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:flutter/material.dart';

enum ShareBackgroundStyle { page, emerald, sky, solid, gradient }

enum ShareBackground {
  // Original backgrounds.
  paper(StringsManager.paper, style: ShareBackgroundStyle.page, page: PageColor.paper),
  night(StringsManager.night, style: ShareBackgroundStyle.page),
  emerald(StringsManager.emerald, style: ShareBackgroundStyle.emerald),
  sky(StringsManager.sky, style: ShareBackgroundStyle.sky),

  // Dark backgrounds.
  midnight(
    StringsManager.midnight,
    colors: [Color(0xFF050816), Color(0xFF101B3A), Color(0xFF1B2C52)],
  ),
  ocean(StringsManager.ocean, colors: [Color(0xFF061A2B), Color(0xFF0A354B), Color(0xFF105264)]),
  deepSea(StringsManager.deepSea, style: ShareBackgroundStyle.solid, colors: [Color(0xFF062C30)]),
  aurora(StringsManager.aurora, colors: [Color(0xFF101629), Color(0xFF1D3546), Color(0xFF244D49)]),
  forest(StringsManager.forest, style: ShareBackgroundStyle.solid, colors: [Color(0xFF12372A)]),
  pine(StringsManager.pine, colors: [Color(0xFF071F18), Color(0xFF10382B), Color(0xFF174936)]),
  ruby(StringsManager.ruby, colors: [Color(0xFF260D1A), Color(0xFF45172B), Color(0xFF68233A)]),
  berry(StringsManager.berry, style: ShareBackgroundStyle.solid, colors: [Color(0xFF401638)]),
  plum(StringsManager.plum, colors: [Color(0xFF1C1028), Color(0xFF30203F), Color(0xFF493052)]),
  indigo(StringsManager.indigo, colors: [Color(0xFF101433), Color(0xFF1A2452), Color(0xFF2B356D)]),
  cobalt(StringsManager.cobalt, style: ShareBackgroundStyle.solid, colors: [Color(0xFF123B63)]),
  slate(StringsManager.slate, colors: [Color(0xFF101820), Color(0xFF263746), Color(0xFF334A5B)]),
  charcoal(StringsManager.charcoal, style: ShareBackgroundStyle.solid, colors: [Color(0xFF202124)]),
  obsidian(
    StringsManager.obsidian,
    colors: [Color(0xFF080808), Color(0xFF151515), Color(0xFF242424)],
  ),
  copper(StringsManager.copper, colors: [Color(0xFF21140E), Color(0xFF3B2519), Color(0xFF573826)]),
  golden(StringsManager.golden, style: ShareBackgroundStyle.solid, colors: [Color(0xFF302516)]),
  teal(StringsManager.teal, colors: [Color(0xFF062729), Color(0xFF0B4142), Color(0xFF145351)]),
  roseDark(
    StringsManager.roseDark,
    colors: [Color(0xFF24121C), Color(0xFF421E2D), Color(0xFF5D2B3D)],
  ),
  lavenderNight(
    StringsManager.lavenderNight,
    colors: [Color(0xFF1C172B), Color(0xFF302341), Color(0xFF443056)],
  ),
  firelight(
    StringsManager.firelight,
    colors: [Color(0xFF21120D), Color(0xFF3D2015), Color(0xFF5A2F1D)],
  ),
  storm(StringsManager.storm, colors: [Color(0xFF121B28), Color(0xFF222F42), Color(0xFF344456)]),

  // Light backgrounds.
  cream(
    StringsManager.cream,
    style: ShareBackgroundStyle.solid,
    colors: [Color(0xFFFBF6E9)],
    page: PageColor.paper,
  ),
  sand(
    StringsManager.sand,
    style: ShareBackgroundStyle.solid,
    colors: [Color(0xFFF1E3C7)],
    page: PageColor.paper,
  ),
  sage(
    StringsManager.sage,
    style: ShareBackgroundStyle.solid,
    colors: [Color(0xFFE4EBDD)],
    page: PageColor.paper,
  ),
  blush(
    StringsManager.blush,
    style: ShareBackgroundStyle.solid,
    colors: [Color(0xFFF8E7EC)],
    page: PageColor.paper,
  ),
  lavender(
    StringsManager.lavender,
    style: ShareBackgroundStyle.solid,
    colors: [Color(0xFFECE7FA)],
    page: PageColor.paper,
  ),
  mint(
    StringsManager.mint,
    style: ShareBackgroundStyle.solid,
    colors: [Color(0xFFE2F3EA)],
    page: PageColor.paper,
  ),
  skyLight(
    StringsManager.skyLight,
    style: ShareBackgroundStyle.solid,
    colors: [Color(0xFFE5F0FA)],
    page: PageColor.paper,
  ),
  pearl(
    StringsManager.pearl,
    style: ShareBackgroundStyle.solid,
    colors: [Color(0xFFF3F0E9)],
    page: PageColor.paper,
  );

  const ShareBackground(
    this.label, {
    this.style = ShareBackgroundStyle.gradient,
    this.colors = const [],
    this.page = PageColor.night,
  });

  /// a StringsManager key
  final String label;
  final ShareBackgroundStyle style;

  /// one color for solid backgrounds, three for gradients
  final List<Color> colors;

  /// the card's foreground palette, paper on the light backgrounds
  final PageColor page;

  bool get isGradient =>
      style == ShareBackgroundStyle.gradient || style == ShareBackgroundStyle.sky;

  /// the middle stop, sky's comes from the theme as ThemeEnum.shareSky2
  Color solidOf() => colors[colors.length ~/ 2];

  /// gold reads on the dark backgrounds, the light ones take their own ornament
  ThemeEnum get ornament => page == PageColor.paper ? ThemeEnum.ornament : ThemeEnum.primary;
}

enum ShareSize {
  square(StringsManager.shareSquare, SizeManager.shareSquare),
  portrait(StringsManager.sharePortrait, SizeManager.sharePortrait),
  story(StringsManager.shareStory, SizeManager.shareStory);

  const ShareSize(this.label, this._pixels);

  final String label;
  final double _pixels;

  /// in design points, the image is SizeManager.shareSquare pixels wide. the ratio first, the
  /// other order lands a hair over 1920 and the story png gets a row more
  double get height => SizeManager.shareAyahCard * (_pixels / SizeManager.shareSquare);

  /// the picked size, or the default and every larger one for the fit to try in turn
  static List<ShareSize> tried(ShareOptions options) =>
      options.sizeLocked ? [options.size] : values.sublist(options.size.index);
}

enum ShareOrnament {
  khatam(StringsManager.patternKhatam, 'assets/ornaments/pattern_khatam.svg'),
  starCross(StringsManager.patternStarCross, 'assets/ornaments/pattern_star_cross.svg'),

  /// a frame, stretched round the card instead of covering it
  arch(StringsManager.frameArch, 'assets/ornaments/frame_arch.svg', fit: BoxFit.fill);

  const ShareOrnament(this.label, this.asset, {this.fit = BoxFit.cover});

  final String label;
  final String asset;
  final BoxFit fit;

  static const patterns = [khatam, starCross];
}

/// what every share card has, a content's own choices live in the content (contracts/share-sheet)
class ShareOptions {
  const ShareOptions({
    this.background = ShareBackground.paper,
    this.size = ShareSize.square,
    this.sizeLocked = false,
    this.solid = false,
    this.ornament,
    this.font = QuranFont.kfgqpc,
    this.appName = true,
  });

  final ShareBackground background;
  final ShareSize size;

  /// true once i tap a size, the fit then never switches it
  final bool sizeLocked;
  final bool solid;

  /// null is off
  final ShareOrnament? ornament;
  final QuranFont font;
  final bool appName;

  ShareOptions copyWith({
    ShareBackground? background,
    ShareSize? size,
    bool? sizeLocked,
    bool? solid,
    ShareOrnament? Function()? ornament,
    QuranFont? font,
    bool? appName,
  }) => ShareOptions(
    background: background ?? this.background,
    size: size ?? this.size,
    sizeLocked: sizeLocked ?? this.sizeLocked,
    solid: solid ?? this.solid,
    ornament: ornament == null ? this.ornament : ornament(),
    font: font ?? this.font,
    appName: appName ?? this.appName,
  );
}
