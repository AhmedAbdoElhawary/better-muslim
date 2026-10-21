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

/// 4.30's four backgrounds. the text takes paper's colors on paper, night's on the dark three
enum ShareBackground {
  paper(StringsManager.paper),
  night(StringsManager.night),
  emerald(StringsManager.emerald),
  sky(StringsManager.sky);

  const ShareBackground(this.label);

  final String label;

  PageColor get page => this == paper ? PageColor.paper : PageColor.night;
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
                child: _Footer(
                  reference: reference,
                  appName: appName,
                  dark: background != ShareBackground.paper,
                ),
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
    return switch (background) {
      ShareBackground.paper ||
      ShareBackground.night => ColoredBox(color: context.getColor(ThemeEnum.page)),
      ShareBackground.emerald => ColoredBox(color: context.getColor(ThemeEnum.shareEmerald)),

      /// css 160deg, a picture so never mirrored
      ShareBackground.sky => DecoratedBox(
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
  const _Footer({required this.reference, required this.appName, required this.dark});

  final String reference;
  final bool appName;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final gold = dark ? ThemeEnum.primary : ThemeEnum.ornament;
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
