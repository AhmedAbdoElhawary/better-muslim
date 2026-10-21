import 'dart:math' as math;

import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/ellipse_transform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the sky3 glow of 4.04 and 4.09 pinned at the top of a page, under its bar and content (FR-040).
/// the Top glow switch fades it out
class TitleGlow extends ConsumerWidget {
  const TitleGlow({required this.child, super.key});
  final Widget child;

  static const _alpha = .7;
  static const _stop = .65;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(topGlowProvider);
    final sky3 = context.getColor(ThemeEnum.sky3);
    return Stack(
      fit: StackFit.passthrough,
      children: [
        PositionedDirectional(
          start: -SpaceManager.prayerGlowSide.r,
          end: -SpaceManager.prayerGlowSide.r,
          top: -SpaceManager.prayerGlowTop.r,
          height: SizeManager.prayerGlow.r,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: on ? 1 : 0,
              duration: MediaQuery.disableAnimationsOf(context)
                  ? BmMotion.micro
                  : BmMotion.standard,
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
          ),
        ),
        child,
      ],
    );
  }
}

/// on until the store says otherwise, so a first frame never flashes without it
final topGlowProvider = Provider<bool>(
  (ref) => ref.watch(settingsProvider.select((settings) => settings.value?.topGlow ?? true)),
);
