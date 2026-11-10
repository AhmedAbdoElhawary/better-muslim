import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/features/quran/presentation/providers/saved_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// data-ribbon of _gen/quran.js, hung from the page's top edge in the newest bookmark's color.
/// on the page itself, so it turns with the leaf
class PageRibbon extends ConsumerWidget {
  const PageRibbon(this.page, {super.key});

  final int page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = ref.watch(pageRibbonProvider(page).select((bookmark) => bookmark?.color));
    final reduce = MediaQuery.disableAnimationsOf(context);

    /// the mushaf's page is never mirrored, so the ribbon keeps its side in arabic
    return Positioned(
      left: SpaceManager.ribbonLeft.r,
      top: 0,
      child: AnimatedSwitcher(
        duration: bmMotion(reduce, BmMotion.standard),
        switchInCurve: BmMotion.decelerate,
        switchOutCurve: BmMotion.accelerate,
        transitionBuilder: (child, animation) => reduce
            ? FadeTransition(opacity: animation, child: child)
            : ClipRect(
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, -1), end: Offset.zero).animate(animation),
                  child: child,
                ),
              ),
        child: color == null
            ? const SizedBox.shrink()
            : RibbonShape(
                key: const ValueKey('ribbon'),
                color: color.theme,
                width: SizeManager.ribbonW,
                height: SizeManager.ribbonH,
                notch: SizeManager.ribbonNotch,
                shadow: true,
              ),
      ),
    );
  }
}

/// the ribbon's cut end, on the page and in Saved's rows. a new color crossfades
class RibbonShape extends StatelessWidget {
  const RibbonShape({
    required this.color,
    required this.width,
    required this.height,
    required this.notch,
    this.shadow = false,
    super.key,
  });

  final ThemeEnum color;
  final double width;
  final double height;
  final double notch;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final scrim = context.getColor(ThemeEnum.scrim);
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: context.getColor(color)),
      duration: bmMotion(MediaQuery.disableAnimationsOf(context), BmMotion.micro),
      builder: (context, color, _) => CustomPaint(
        size: Size(width.r, height.r),
        painter: _Ribbon(
          color: color!,
          notch: notch,
          shadow: shadow ? scrim.withValues(alpha: .2) : null,
          shadowY: SizeManager.ribbonShadowY.r,
          shadowBlur: SizeManager.ribbonShadowBlur.r,
        ),
      ),
    );
  }
}

class _Ribbon extends CustomPainter {
  const _Ribbon({
    required this.color,
    required this.notch,
    required this.shadow,
    required this.shadowY,
    required this.shadowBlur,
  });

  final Color color;
  final double notch;
  final Color? shadow;
  final double shadowY;
  final double shadowBlur;

  @override
  void paint(Canvas canvas, Size size) {
    final path = ribbonPath(Offset.zero & size, notch);
    if (shadow case final shadow?) {
      canvas.drawPath(
        path.shift(Offset(0, shadowY)),
        Paint()
          ..color = shadow
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowBlur / 2),
      );
    }
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_Ribbon old) =>
      old.color != color || old.notch != notch || old.shadow != shadow;
}

/// the ribbon's outline in rect
Path ribbonPath(Rect rect, double notch) => Path()
  ..addPolygon([
    rect.topLeft,
    rect.topRight,
    rect.bottomRight,
    Offset(rect.center.dx, rect.top + rect.height * notch),
    rect.bottomLeft,
  ], true);
