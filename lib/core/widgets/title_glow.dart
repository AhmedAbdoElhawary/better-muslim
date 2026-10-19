import 'dart:math' as math;

import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/ellipse_transform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the sky3 glow behind a large title (4.04, 4.09), put first in the header's Stack
class TitleGlow extends StatelessWidget {
  const TitleGlow({super.key});

  static const _alpha = .7;
  static const _stop = .65;

  @override
  Widget build(BuildContext context) {
    final sky3 = context.getColor(ThemeEnum.sky3);
    return PositionedDirectional(
      start: -SpaceManager.prayerGlowSide.r,
      end: -SpaceManager.prayerGlowSide.r,
      top: -SpaceManager.prayerGlowTop.r,
      height: SizeManager.prayerGlow.r,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              /// css "ellipse at 50% 50%" reaches the corners, half the diagonal of a square
              radius: math.sqrt1_2,
              colors: [
                sky3.withValues(alpha: _alpha),
                sky3.withValues(alpha: 0),
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
