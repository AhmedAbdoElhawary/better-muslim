import 'dart:ui' show ImageFilter;

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
Future<T?> showBmSheet<T>(
  BuildContext context, {
  bool applyBlur = true,
  bool maxSheetHeight = false,
  required WidgetBuilder builder,
}) {
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
  final route = _BlurredModalBottomSheetRoute<T>(
    applyBlur: applyBlur,
    builder: (context) =>
        _Sheet(fade: reduceMotion, enableCustomCurve: !maxSheetHeight, child: builder(context)),
    capturedThemes: InheritedTheme.capture(from: context, to: navigator.context),
    barrierLabel: MaterialLocalizations.of(context).scrimLabel,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.getColor(ThemeEnum.transparent),
    elevation: 0,
    constraints: maxSheetHeight ? null : BoxConstraints(maxHeight: SizeManager.sheetMax.r),
    modalBarrierColor: context.getColor(ThemeEnum.scrim).withValues(alpha: BmOpacity.pressed),
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

class _BlurredModalBottomSheetRoute<T> extends ModalBottomSheetRoute<T> {
  _BlurredModalBottomSheetRoute({
    required super.builder,
    super.capturedThemes,
    super.barrierLabel,
    required super.isScrollControlled,
    super.useSafeArea,
    super.backgroundColor,
    super.elevation,
    super.constraints,
    super.modalBarrierColor,
    super.transitionAnimationController,
    super.sheetAnimationStyle,
    this.applyBlur = true,
  });
  final bool applyBlur;

  @override
  Widget buildModalBarrier() {
    if (!applyBlur) return super.buildModalBarrier();

    final routeAnimation = animation!;

    return AnimatedBuilder(
      animation: routeAnimation,
      child: super.buildModalBarrier(),
      builder: (context, barrier) {
        final sigma = (SizeManager.backdropBlur * routeAnimation.value)
            .clamp(0.0, SizeManager.backdropBlur)
            .toDouble();

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: barrier,
        );
      },
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({this.enableCustomCurve = true, required this.fade, required this.child});
  final bool fade;
  final Widget child;
  final bool enableCustomCurve;
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
            const VerticalPadding(padding: SpaceManager.s2, child: Grabber()),
            Flexible(child: child),
          ],
        ),
      ),
    );
    final animation = ModalRoute.of(context)!.animation!;

    if (fade) {
      return FadeTransition(opacity: animation, child: sheet);
    }

    final position = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: animation,
        curve: enableCustomCurve ? const _OvershootCurve() : Curves.easeOutExpo,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    return SlideTransition(position: position, child: sheet);
  }
}

class _OvershootCurve extends Curve {
  const _OvershootCurve();

  @override
  double transformInternal(double t) {
    final value = t.clamp(0.0, 1.0).toDouble();

    if (value < 0.7) {
      return 1.08 * Curves.easeOutCubic.transform(value / 0.7);
    }

    final progress = Curves.easeInOut.transform((value - 0.7) / 0.3);

    return 1.08 - (0.08 * progress);
  }
}

/// the sheets' handle, the reader's own sheets use it too
class Grabber extends StatelessWidget {
  const Grabber({super.key});

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
