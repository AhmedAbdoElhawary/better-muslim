import 'dart:math' as math;
import 'dart:ui';

import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/ellipse_transform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the glow behind the next-prayer card, always there and still as in the PNG
class CardGlow extends StatelessWidget {
  const CardGlow({super.key});

  static const _alpha = .55;
  static const _stop = .72;

  @override
  Widget build(BuildContext context) {
    final glow = context.getColor(ThemeEnum.glow);

    return RepaintBoundary(
      child: ImageFiltered(
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
              transform: const EllipseTransform(),
            ),
          ),
        ),
      ),
    );
  }
}
