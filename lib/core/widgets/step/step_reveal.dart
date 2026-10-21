import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/widgets/step/step_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// where a part builds in the step's 900 ms (contracts/onboarding-routes.md)
enum StepSlot {
  background(0, .33),
  title(.33, .60, rises: true),
  body(.40, .67),
  cards(.47, .80),
  buttons(.60, 1, rises: true);

  const StepSlot(this.start, this.end, {this.rises = false});
  final double start;
  final double end;
  final bool rises;
}

/// a step's part fading in on its slot, and out when the next step covers it. plain without a
/// scope, so the theme page from More is untouched
class StepReveal extends StatelessWidget {
  const StepReveal({required this.slot, required this.child, super.key});

  final StepSlot slot;
  final Widget child;

  /// 150 of the next step's 900 ms
  static const _covered = Interval(0, .17);

  @override
  Widget build(BuildContext context) {
    final scope = StepScope.maybeOf(context);
    if (scope == null) return child;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final enter = reduce
        ? Curves.linear
        : Interval(slot.start, slot.end, curve: BmMotion.decelerate);
    final secondary = scope.secondaryAnimation;
    return AnimatedBuilder(
      animation: Listenable.merge([scope.animation, secondary]),
      builder: (context, child) {
        final t = enter.transform(scope.animation.value);
        if (slot == StepSlot.background) return CustomOpacity(opacity: t, child: child);

        /// a pop is the next step's 150 ms out, so the content comes back over all of it
        final out = secondary.status == AnimationStatus.reverse
            ? secondary.value
            : _covered.transform(secondary.value);
        final opacity = t * (1 - out);
        return CustomOpacity(
          opacity: opacity,
          child: slot.rises && !reduce
              ? Transform.translate(
                  offset: Offset(0, (1 - t) * SpaceManager.stepRise.r),
                  child: child,
                )
              : child,
        );
      },
      child: child,
    );
  }
}
