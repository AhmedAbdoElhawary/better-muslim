import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/styles_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/mushaf_star.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum ShareBackgroundStyle { page, emerald, sky, solid, gradient }

enum ShareBackground {
  // Original backgrounds.
  paper(
    StringsManager.paper,
    style: ShareBackgroundStyle.page,
    pageColor: PageColor.paper,
    isLight: true,
  ),
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
    pageColor: PageColor.paper,
    isLight: true,
  ),
  sand(
    StringsManager.sand,
    style: ShareBackgroundStyle.solid,
    colors: [Color(0xFFF1E3C7)],
    pageColor: PageColor.paper,
    isLight: true,
  ),
  sage(
    StringsManager.sage,
    style: ShareBackgroundStyle.solid,
    colors: [Color(0xFFE4EBDD)],
    pageColor: PageColor.paper,
    isLight: true,
  ),
  blush(
    StringsManager.blush,
    style: ShareBackgroundStyle.solid,
    colors: [Color(0xFFF8E7EC)],
    pageColor: PageColor.paper,
    isLight: true,
  ),
  lavender(
    StringsManager.lavender,
    style: ShareBackgroundStyle.solid,
    colors: [Color(0xFFECE7FA)],
    pageColor: PageColor.paper,
    isLight: true,
  ),
  mint(
    StringsManager.mint,
    style: ShareBackgroundStyle.solid,
    colors: [Color(0xFFE2F3EA)],
    pageColor: PageColor.paper,
    isLight: true,
  ),
  skyLight(
    StringsManager.skyLight,
    style: ShareBackgroundStyle.solid,
    colors: [Color(0xFFE5F0FA)],
    pageColor: PageColor.paper,
    isLight: true,
  ),
  pearl(
    StringsManager.pearl,
    style: ShareBackgroundStyle.solid,
    colors: [Color(0xFFF3F0E9)],
    pageColor: PageColor.paper,
    isLight: true,
  );

  const ShareBackground(
    this.label, {
    this.style = ShareBackgroundStyle.gradient,
    this.colors = const [],
    this.pageColor = PageColor.night,
    this.isLight = false,
  });

  /// Localization key displayed in the background picker.
  final String label;

  /// How the background is painted.
  final ShareBackgroundStyle style;

  /// One color for solid backgrounds, three for gradients.
  final List<Color> colors;

  /// Palette used for the ayah card's foreground and theme.
  final PageColor pageColor;

  /// Whether the background needs dark foreground text.
  final bool isLight;

  /// Compatibility with ShareCard's existing API.
  PageColor get page => pageColor;
}

enum ShareSize {
  square(StringsManager.shareSquare),
  story(StringsManager.shareStory);

  const ShareSize(this.label);

  final String label;

  /// in design points, the image is SizeManager.shareSquare pixels wide
  double get height =>
      this == square ? SizeManager.shareAyahCard : SizeManager.shareAyahCard * _storyRatio;

  static const _storyRatio = SizeManager.shareStory / SizeManager.shareSquare;
}

/// the arabic with its marker and the translation, laid out the way the card paints them
class ShareText {
  ShareText({required this.arabic, required this.marker, required this.translation});

  final String arabic;

  /// "﴿٥﴾", in the ornament's color after the ayah
  final String marker;
  final String? translation;

  /// the largest step of SizeManager.shareFit the whole ayah fits at, null when none does
  double? fit(BuildContext context, ShareSize size) {
    final width = (SizeManager.shareAyahCard - 2 * SpaceManager.shareCardPad).r;
    final height = (size.height - SpaceManager.shareCardPad - SpaceManager.shareFooterReserve).r;
    for (final scale in SizeManager.shareFit) {
      if (this.height(context, scale, width) <= height) return scale;
    }
    return null;
  }

  /// the star, the ayah and the translation with their gaps
  double height(BuildContext context, double scale, double width) {
    final (ayah, translation) = painters(context, scale, width);
    final text = ayah.height + (translation == null ? 0 : _gap + translation.height);
    ayah.dispose();
    translation?.dispose();
    return SizeManager.shareStar.r + _gap + text;
  }

  static double get _gap => SpaceManager.shareCardGap.r;

  (TextPainter, TextPainter?) painters(
    BuildContext context,
    double scale,
    double width, {
    Color? ink,
    Color? ornament,
    Color? translationColor,
  }) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final style = GetRegularStyle(
      fontSize: FontSizeManager.shareAyah.sp * scale,
      height: LineHeightManager.shareAyah,
      fontFamily: FontFamilyManager.quran,
      color: ink,
    );
    final ayah = TextPainter(
      text: TextSpan(
        style: style,
        children: [
          TextSpan(text: '$arabic '),
          TextSpan(
            text: marker,
            style: style.copyWith(color: ornament),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
    )..layout(maxWidth: width);
    final translation = this.translation;
    return (
      ayah,
      translation == null
          ? null
          : (TextPainter(
              text: TextSpan(
                text: translation,
                style: GetRegularStyle(
                  fontSize: FontSizeManager.shareTranslation.sp * scale,
                  height: LineHeightManager.shareTranslation,
                  fontFamily: isArabic ? FontEnum.body.arabic : FontEnum.body.latin,
                  color: translationColor,
                ),
              ),
              textAlign: TextAlign.center,
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            )..layout(maxWidth: width)),
    );
  }
}

/// the shared still from 4.30, never cropped or overlaid. laid out in design points and
/// captured at SizeManager.shareSquare pixels wide, so the image is the same on every phone
class ShareCard extends StatelessWidget {
  const ShareCard({
    required this.text,
    required this.reference,
    required this.background,
    required this.size,
    required this.scale,
    required this.appName,
    super.key,
  });

  final ShareText text;

  /// "Al-Fatiha · 5" in the app's language and digits
  final String reference;
  final ShareBackground background;
  final ShareSize size;
  final double scale;
  final bool appName;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withNoTextScaling(
      child: Theme(
        data: AppTheme.page(background.page),
        child: RSizedBox(
          width: SizeManager.shareAyahCard,
          height: size.height,
          child: Stack(
            children: [
              Positioned.fill(child: ShareBackgroundFill(background)),
              Positioned(
                top: SpaceManager.shareCardPad.r,
                left: SpaceManager.shareCardPad.r,
                right: SpaceManager.shareCardPad.r,
                bottom: SpaceManager.shareFooterReserve.r,
                child: _Content(
                  text: text,
                  scale: scale,
                  dark: background != ShareBackground.paper,
                ),
              ),
              PositionedDirectional(
                start: SpaceManager.shareFooterSide.r,
                end: SpaceManager.shareFooterSide.r,
                bottom: SpaceManager.shareFooterBottom.r,
                child: _Footer(reference: reference, appName: appName, background: background),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// the background alone, the share sheet's swatches show it too
class ShareBackgroundFill extends StatelessWidget {
  const ShareBackgroundFill(this.background, {super.key});

  final ShareBackground background;

  @override
  Widget build(BuildContext context) {
    return switch (background.style) {
      ShareBackgroundStyle.page => ColoredBox(color: context.getColor(ThemeEnum.page)),

      ShareBackgroundStyle.emerald => ColoredBox(color: context.getColor(ThemeEnum.shareEmerald)),

      ShareBackgroundStyle.sky => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: const Alignment(-.34, -.94),
            end: const Alignment(.34, .94),
            stops: const [0, .6, 1],
            colors: [
              context.getColor(ThemeEnum.shareSky1),
              context.getColor(ThemeEnum.shareSky2),
              context.getColor(ThemeEnum.shareSky3),
            ],
          ),
        ),
      ),

      ShareBackgroundStyle.solid => ColoredBox(color: background.colors.single),

      ShareBackgroundStyle.gradient => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: const Alignment(-.34, -.94),
            end: const Alignment(.34, .94),
            colors: background.colors,
          ),
        ),
      ),
    };
  }
}

/// the star over the ayah and its translation, centered in what the footer leaves
class _Content extends StatelessWidget {
  const _Content({required this.text, required this.scale, required this.dark});

  final ShareText text;
  final double scale;

  /// the gold on the dark backgrounds is night's primary, on paper its ornament
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final width = (SizeManager.shareAyahCard - 2 * SpaceManager.shareCardPad).r;
    final ornament = context.getColor(dark ? ThemeEnum.primary : ThemeEnum.ornament);
    final translation = text.translation;
    return Semantics(
      label: [text.arabic, text.marker, ?translation].join(' '),
      excludeSemantics: true,

      /// a last guard, the sheet already picked a size the whole ayah fits at
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: CustomPaint(
          size: Size(width, text.height(context, scale, width)),
          painter: _ShareText(
            painters: text.painters(
              context,
              scale,
              width,
              ink: context.getColor(ThemeEnum.ink),
              ornament: ornament,
              translationColor: context.getColor(ThemeEnum.ink2),
            ),
            ornament: ornament,
            star: SizeManager.shareStar.r,
            gap: SpaceManager.shareCardGap.r,
            stroke: SizeManager.starStroke.r,
          ),
        ),
      ),
    );
  }
}

class _ShareText extends CustomPainter {
  const _ShareText({
    required this.painters,
    required this.ornament,
    required this.star,
    required this.gap,
    required this.stroke,
  });

  final (TextPainter, TextPainter?) painters;
  final Color ornament;
  final double star;
  final double gap;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final (ayah, translation) = painters;
    canvas.drawPath(
      mushafStar(Offset(size.width / 2, star / 2), star),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = ornament,
    );
    var top = star + gap;
    ayah.paint(canvas, Offset((size.width - ayah.width) / 2, top));
    top += ayah.height + gap;
    translation?.paint(canvas, Offset((size.width - translation.width) / 2, top));
  }

  @override
  bool shouldRepaint(_ShareText old) => old.painters != painters || old.ornament != ornament;
}

/// "Al-Fatiha · 5" and, when it's on, the symbol with the app's name
class _Footer extends StatelessWidget {
  const _Footer({required this.reference, required this.appName, required this.background});

  final String reference;
  final bool appName;
  final ShareBackground background;

  @override
  Widget build(BuildContext context) {
    final gold = switch (background) {
      ShareBackground.paper => ThemeEnum.ornament,
      ShareBackground.sky => ThemeEnum.surface,
      _ => ThemeEnum.primary,
    };
    return Row(
      children: [
        Expanded(
          child: RegularText(
            reference,
            translate: false,
            fontSize: FontSizeManager.shareFooter,
            color: ThemeEnum.text3,
            maxLines: 1,
          ),
        ),
        if (appName) ...[
          SvgPicture.asset(
            'assets/brand/symbol_mono.svg',
            height: SizeManager.shareLogo.r,
            colorFilter: ColorFilter.mode(context.getColor(gold), BlendMode.srcIn),
          ),
          const RSizedBox.horizontal(SpaceManager.shareLogoGap),
          RegularText(StringsManager.appName, fontSize: FontSizeManager.shareFooter, color: gold),
        ],
      ],
    );
  }
}
