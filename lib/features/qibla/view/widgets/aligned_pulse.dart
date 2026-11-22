import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/custom_opacity.dart';
import 'package:better_muslim/features/qibla/view_model/qibla_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

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

/// the 420 pt accent glow behind the dial while aligned. none under reduce motion
class AlignedGlow extends ConsumerWidget {
  const AlignedGlow({super.key});

  static const _accent = .3;
  static const _fade = .62;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    );
  }
}
