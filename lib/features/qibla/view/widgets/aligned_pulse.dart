import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/features/qibla/view_model/qibla_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Motion 10: two pulses of the accent ring on each alignment. none under reduce motion
class AlignedPulse extends ConsumerStatefulWidget {
  const AlignedPulse({super.key});

  @override
  ConsumerState<AlignedPulse> createState() => _AlignedPulseState();
}

class _AlignedPulseState extends ConsumerState<AlignedPulse> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(vsync: this, duration: BmMotion.alignPulse);

  static const _scale = .35;
  static const _opacity = .8;

  @override
  void initState() {
    super.initState();
    ref.listenManual(qiblaAlignedProvider, (_, aligned) {
      if (aligned && !MediaQuery.disableAnimationsOf(context)) {
        _pulse.repeat(count: 2);
      } else if (!aligned) {
        _pulse.reset();
      }
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            if (!_pulse.isAnimating) return const SizedBox.shrink();
            final t = BmMotion.decelerate.transform(_pulse.value);
            return CustomOpacity(
              opacity: _opacity * (1 - t),
              child: Transform.scale(scale: 1 + _scale * t, child: child),
            );
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: context.getColor(ThemeEnum.accent),
                width: SizeManager.qiblaRingAligned.r,
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// the 420 pt accent glow behind the dial, breathing while aligned (MOTION aglow). none under
/// reduce motion
class AlignedGlow extends ConsumerStatefulWidget {
  const AlignedGlow({super.key});

  @override
  ConsumerState<AlignedGlow> createState() => _AlignedGlowState();
}

class _AlignedGlowState extends ConsumerState<AlignedGlow> with SingleTickerProviderStateMixin {
  late final _breathe = AnimationController(vsync: this, duration: BmMotion.glowLoop);

  static const _low = .6;
  static const _high = 1.0;
  static const _accent = .3;
  static const _fade = .62;

  @override
  void initState() {
    super.initState();
    ref.listenManual(qiblaAlignedProvider, (_, aligned) {
      if (aligned && !MediaQuery.disableAnimationsOf(context)) {
        _breathe.repeat(reverse: true);
      } else {
        _breathe.stop();
      }
    });
  }

  @override
  void dispose() {
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aligned = ref.watch(qiblaAlignedProvider);
    if (!aligned || MediaQuery.disableAnimationsOf(context)) return const SizedBox.shrink();
    final accent = context.getColor(ThemeEnum.accent);
    final overhang = ((SizeManager.qiblaGlow - SizeManager.qiblaDial) / 2).r;
    return Positioned(
      left: -overhang,
      top: -overhang,
      right: -overhang,
      bottom: -overhang,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: Tween(
            begin: _low,
            end: _high,
          ).animate(CurvedAnimation(parent: _breathe, curve: BmMotion.breathe)),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  accent.withValues(alpha: _accent),
                  accent.withValues(alpha: 0),
                ],
                stops: const [0, _fade],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
