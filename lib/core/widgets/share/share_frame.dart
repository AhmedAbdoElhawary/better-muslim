import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/appearance.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/share/share_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// the box a content lays its text out in, between the card's padding and the footer
Size shareBox(ShareSize size) => Size(
  (SizeManager.shareAyahCard - 2 * SpaceManager.shareCardPad).r,
  (size.height - SpaceManager.shareCardPad - SpaceManager.shareFooterReserve).r,
);

/// the shared still, never cropped or overlaid. laid out in design points and captured at
/// SizeManager.shareSquare pixels wide, so the image is the same on every phone
class ShareFrame extends ConsumerWidget {
  const ShareFrame({
    required this.options,
    required this.size,
    required this.footer,
    required this.child,
    super.key,
  });

  final ShareOptions options;

  /// the layout's size, it may differ from the one picked
  final ShareSize size;

  /// "Al-Fatiha 5" or the dua's source, in the app's language and digits
  final String footer;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final background = options.background;
    final ornament = options.ornament;
    final pad = SpaceManager.shareCardPad.r;
    return MediaQuery.withNoTextScaling(
      child: Theme(
        data: AppTheme.page(background.page, ref.watch(themeIdProvider)),
        child: RSizedBox(
          width: SizeManager.shareAyahCard,
          height: size.height,
          child: Stack(
            children: [
              Positioned.fill(child: ShareBackgroundFill(background, solid: options.solid)),
              if (ornament != null) Positioned.fill(child: _Ornament(ornament, background)),
              Positioned(
                top: pad,
                left: pad,
                right: pad,
                bottom: SpaceManager.shareFooterReserve.r,
                child: Center(child: child),
              ),
              PositionedDirectional(
                start: SpaceManager.shareFooterSide.r,
                end: SpaceManager.shareFooterSide.r,
                bottom: SpaceManager.shareFooterBottom.r,
                child: _Footer(footer, appName: options.appName, background: background),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// the background alone, the sheet's swatches show it too
class ShareBackgroundFill extends StatelessWidget {
  const ShareBackgroundFill(this.background, {this.solid = false, super.key});

  final ShareBackground background;

  /// a gradient filled with its middle color
  final bool solid;

  @override
  Widget build(BuildContext context) {
    return switch (background.style) {
      ShareBackgroundStyle.page => ColoredBox(color: context.getColor(ThemeEnum.page)),

      ShareBackgroundStyle.emerald => ColoredBox(color: context.getColor(ThemeEnum.shareEmerald)),

      ShareBackgroundStyle.sky when solid => ColoredBox(
        color: context.getColor(ThemeEnum.shareSky2),
      ),

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

      ShareBackgroundStyle.gradient when solid => ColoredBox(color: background.solidOf()),

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

/// a faint texture under the text, so the text keeps its contrast (FR-009)
class _Ornament extends StatelessWidget {
  const _Ornament(this.ornament, this.background);

  final ShareOrnament ornament;
  final ShareBackground background;

  @override
  Widget build(BuildContext context) {
    final color = context
        .getColor(background.ornament)
        .withValues(alpha: SizeManager.shareOrnamentOpacity);
    return SvgPicture.asset(
      ornament.asset,
      fit: ornament.fit,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

/// the content's line and, when it's on, the symbol with the app's name
class _Footer extends StatelessWidget {
  const _Footer(this.footer, {required this.appName, required this.background});

  final String footer;
  final bool appName;
  final ShareBackground background;

  @override
  Widget build(BuildContext context) {
    final gold = background == ShareBackground.sky ? ThemeEnum.surface : background.ornament;
    return Row(
      children: [
        Expanded(
          child: RegularText(
            footer,
            translate: false,
            fontSize: FontSizeManager.shareFooter,
            color: ThemeEnum.text3,
            maxLines: 2,
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
