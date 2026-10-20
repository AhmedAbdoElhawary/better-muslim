import 'dart:ui' show lerpDouble;

import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/step/step_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 4.11 and 4.12's dots, the wide one slides over from the step before on the route's animation
class StepDots extends StatelessWidget {
  const StepDots({required this.step, super.key});

  /// 1 to [total]
  final int step;

  static const total = 3;

  /// the slide takes the step's background slot
  static const _slide = Interval(0, .33, curve: BmMotion.standardCurve);

  @override
  Widget build(BuildContext context) {
    final animation = StepScope.maybeOf(context)?.animation;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: context.tr(StringsManager.stepOf, {'step': '$step', 'total': '$total'}),
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: animation ?? kAlwaysCompleteAnimation,
        builder: (context, _) {
          /// the first step has no dot to slide from
          final t = animation == null || reduce || step == 1
              ? 1.0
              : _slide.transform(animation.value);
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var dot = 1; dot <= total; dot++) ...[
                if (dot > 1) const RSizedBox.horizontal(SpaceManager.stepDotGap),
                _Dot(
                  wide: dot == step ? t : (dot == step - 1 ? 1 - t : 0),
                  done: dot < step ? 1 : (dot == step ? t : 0),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.wide, required this.done});

  /// 0 small, 1 wide
  final double wide;

  /// 0 outline2, 1 primary
  final double done;

  @override
  Widget build(BuildContext context) {
    return RSizedBox(
      width: lerpDouble(SizeManager.stepDot, SizeManager.stepDotWide, wide),
      height: SizeManager.stepDot,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color.lerp(
            context.getColor(ThemeEnum.outlineStrong),
            context.getColor(ThemeEnum.primary),
            done,
          ),
          borderRadius: BorderRadius.circular(RadiusManager.stepDot.r),
        ),
      ),
    );
  }
}
