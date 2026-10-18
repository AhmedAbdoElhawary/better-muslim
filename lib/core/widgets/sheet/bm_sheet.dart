import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/design/bm_tokens.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// MOTION 15: in on the gentle spring, out in 300 ms accelerate. with reduce motion the sheet
/// stays in place and fades for 150 ms. a release that snaps it back open gives the detent haptic
Future<T?> showBmSheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  final reduceMotion = MediaQuery.disableAnimationsOf(context);

  /// the root one, so the sheet and its scrim cover the nav bar too
  final navigator = Navigator.of(context, rootNavigator: true);

  /// our own controller, so its status shows a snap back after a drag
  final controller = BottomSheet.createAnimationController(navigator)
    ..duration = reduceMotion ? BmMotion.micro : BmMotion.emphasized
    ..reverseDuration = reduceMotion ? BmMotion.micro : BmMotion.standard;
  var opened = false;
  controller.addStatusListener((status) {
    if (status != AnimationStatus.completed) return;

    /// the first time is the opening, which has no haptic
    if (opened) BmHaptics.selection();
    opened = true;
  });

  /// the sheet stays put while the barrier and the content fade
  const still = Threshold(0);
  final route = ModalBottomSheetRoute<T>(
    builder: (context) => _Sheet(fade: reduceMotion, child: builder(context)),
    capturedThemes: InheritedTheme.capture(from: context, to: navigator.context),
    barrierLabel: MaterialLocalizations.of(context).scrimLabel,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.getColor(ThemeEnum.transparent),
    elevation: 0,
    modalBarrierColor: context
        .getColor(ThemeEnum.scrim)
        .withValues(alpha: context.isThemeDark ? BmOpacity.scrimDark : BmOpacity.scrimLight),
    transitionAnimationController: controller,
    sheetAnimationStyle: AnimationStyle(
      curve: reduceMotion ? still : _SpringCurve(BmMotion.gentle, BmMotion.emphasized),
      reverseCurve: reduceMotion ? still : BmMotion.accelerate,
    ),
  );

  /// the route lets go of the controller only once its exit animation is over
  route.completed.whenComplete(controller.dispose);
  return navigator.push(route);
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.fade, required this.child});
  final bool fade;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final sheet = KeyboardPadding(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.getColor(ThemeEnum.surface),
          borderRadius: BorderRadius.vertical(top: Radius.circular(RadiusManager.sheet.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const VerticalPadding(padding: SpaceManager.s2, child: _Grabber()),
            Flexible(child: child),
          ],
        ),
      ),
    );
    if (!fade) return sheet;
    return FadeTransition(opacity: ModalRoute.of(context)!.animation!, child: sheet);
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RSizedBox(
        width: SizeManager.grabberW,
        height: SizeManager.grabberH,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.getColor(ThemeEnum.outlineStrong),
            borderRadius: BorderRadius.circular(RadiusManager.pill.r),
          ),
        ),
      ),
    );
  }
}

/// a spring as a curve over its duration, AnimationStyle only takes curves
class _SpringCurve extends Curve {
  const _SpringCurve(this.spring, this.duration);
  final SpringDescription spring;
  final Duration duration;

  @override
  double transformInternal(double t) => SpringSimulation(
    spring,
    0,
    1,
    0,
  ).x(t * duration.inMicroseconds / Duration.microsecondsPerSecond);
}
