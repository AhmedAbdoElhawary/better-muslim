import 'dart:math' as math;
import 'dart:ui';

import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/features/home/view_model/home_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the glow behind the next-prayer card. always there and still as in the PNG, it breathes only
/// in the final 10 minutes (MOTION 05, R11)
class CardGlow extends ConsumerStatefulWidget {
  const CardGlow({super.key});

  @override
  ConsumerState<CardGlow> createState() => _CardGlowState();
}

class _CardGlowState extends ConsumerState<CardGlow> with SingleTickerProviderStateMixin {
  static const _alpha = .55;
  static const _stop = .72;

  /// starts at the still look, so the breathing begins without a jump in opacity
  late final _controller = AnimationController(vsync: this, duration: BmMotion.glowLoop, value: 1);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final breathing = ref.watch(glowBreathingProvider) && !MediaQuery.disableAnimationsOf(context);
    if (breathing && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!breathing && _controller.isAnimating) {
      _controller.stop();
    }
    final glow = context.getColor(ThemeEnum.glow);
    final box = ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: SizeManager.homeGlowBlur.r,
        sigmaY: SizeManager.homeGlowBlur.r,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(RadiusManager.homeGlow.r),
          gradient: RadialGradient(
            /// css "ellipse at 50% 50%" reaches the corners, half the diagonal of a square
            radius: math.sqrt1_2,
            colors: [
              glow.withValues(alpha: _alpha),
              glow.withValues(alpha: 0),
            ],
            stops: const [0, _stop],
            transform: const _Ellipse(),
          ),
        ),
      ),
    );
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        child: box,
        builder: (context, child) {
          final t = breathing ? BmMotion.breathe.transform(_controller.value) : 1.0;
          return Opacity(
            opacity: lerpDouble(.45, 1, t)!,
            child: Transform.scale(scale: breathing ? lerpDouble(.98, 1.03, t)! : 1, child: child),
          );
        },
      ),
    );
  }
}

/// stretches the circle on the short side into the box's ellipse
class _Ellipse extends GradientTransform {
  const _Ellipse();

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final center = bounds.center;
    final aspect = bounds.width / bounds.height;
    return Matrix4.identity()
      ..translateByDouble(center.dx, center.dy, 0, 1)
      ..scaleByDouble(math.max(aspect, 1), math.max(1 / aspect, 1), 1, 1)
      ..translateByDouble(-center.dx, -center.dy, 0, 1);
  }
}
