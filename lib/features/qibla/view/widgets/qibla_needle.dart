import 'dart:math' as math;

import 'package:better_muslim/core/qibla/qibla_math.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/features/qibla/view/widgets/qibla_dot.dart';
import 'package:better_muslim/features/qibla/view_model/qibla_providers.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// degrees from the top of the screen. without a compass the dial sits north up, so the needle
/// points at the bearing itself. null = no needle
final _targetProvider = Provider.autoDispose<double?>((ref) {
  return switch (ref.watch(qiblaStateProvider)) {
    QiblaState.ready => ref.watch(qiblaDiffProvider),
    QiblaState.noCompass => ref.watch(qiblaTargetProvider.select((target) => target?.bearing)),
    QiblaState.noLocation || QiblaState.waiting => null,
  };
});

/// MOTION ndlA, ±0.8° while aligned

/// Motion 09: each reading retargets spring.needle from where the needle is and how fast it
/// moves, never queues. reduce motion: standard 300 ms, no overshoot
class QiblaNeedle extends ConsumerStatefulWidget {
  const QiblaNeedle({super.key});

  @override
  ConsumerState<QiblaNeedle> createState() => _QiblaNeedleState();
}

class _QiblaNeedleState extends ConsumerState<QiblaNeedle> with SingleTickerProviderStateMixin {
  late final _angle = AnimationController.unbounded(vsync: this);
  var _shown = false;
  var _reduceMotion = false;
  var _started = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(_targetProvider, (_, target) => _retarget(target));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_started) return;
    _started = true;
    _retarget(ref.read(_targetProvider));
  }

  void _retarget(double? degrees) {
    if (degrees == null) {
      _angle.stop();
      if (_shown) setState(() => _shown = false);
      return;
    }

    /// the first one shows the needle where it belongs, a spin from north on opening says nothing
    if (!_shown) {
      _angle.value = degrees;
      setState(() => _shown = true);
      return;
    }
    final from = _angle.value;
    final to = from + qiblaDiff(degrees, from);
    if (_reduceMotion) {
      _angle.animateTo(to, duration: BmMotion.standard, curve: BmMotion.standardCurve);
    } else {
      _angle.animateWith(SpringSimulation(BmMotion.needle, from, to, _angle.velocity));
    }
  }

  @override
  void dispose() {
    _angle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shown) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _angle,
      builder: (context, child) =>
          Transform.rotate(angle: _angle.value * math.pi / 180, child: child),
      child: const _Needle(),
    );
  }
}

/// 2 x 106 from the center up, fading to 10% at the hub, with a 12 pt head at its tip
class _Needle extends StatelessWidget {
  const _Needle();

  static const _top = SizeManager.qiblaDial / 2 - SizeManager.qiblaNeedle;

  @override
  Widget build(BuildContext context) {
    final primary = context.getColor(ThemeEnum.primary);
    return Stack(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: TopPadding(
            padding: _top,
            child: RSizedBox(
              width: SizeManager.qiblaNeedleWidth,
              height: SizeManager.qiblaNeedle,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(RadiusManager.qiblaNeedle.r),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [primary, primary.withValues(alpha: .1)],
                  ),
                ),
              ),
            ),
          ),
        ),
        const Align(
          alignment: Alignment.topCenter,
          child: TopPadding(
            padding: _top - SizeManager.qiblaNeedleHead / 2,
            child: QiblaDot(size: SizeManager.qiblaNeedleHead, color: ThemeEnum.primary),
          ),
        ),
      ],
    );
  }
}
