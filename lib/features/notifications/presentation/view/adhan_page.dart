import 'dart:math' as math;

import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/features/notifications/presentation/providers/adhan_providers.dart';
import 'package:better_muslim/features/notifications/presentation/view/adhan_colors.dart';
import 'package:better_muslim/features/notifications/presentation/view/widgets/adhan_buttons.dart';
import 'package:better_muslim/features/notifications/presentation/view/widgets/adhan_dua_card.dart';
import 'package:better_muslim/features/notifications/presentation/view/widgets/adhan_header.dart';
import 'package:better_muslim/features/notifications/presentation/view/widgets/adhan_sky.dart';
import 'package:better_muslim/features/notifications/presentation/view/widgets/adhan_tint.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 4.03, over any screen at prayer time or from a notification
class AdhanPage extends ConsumerWidget {
  const AdhanPage({required this.prayer, required this.day, super.key});

  final Prayer prayer;
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /// leaving the screen is the same as stop, ios has no other place to stop it from
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) ref.read(adhanPlayerProvider).stop();
      },
      child: Scaffold(
        backgroundColor: AdhanColors.skyStops.first,
        body: AdhanTint(
          AdhanColors.text,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AdhanSky(prayer: prayer, day: day),
              _Content(prayer: prayer, day: day),
            ],
          ),
        ),
      ),
    );
  }
}

/// 4.03's positions at text scale 1, and a scroll instead of overlaps at 2.0
class _Content extends StatelessWidget {
  const _Content({required this.prayer, required this.day});

  final Prayer prayer;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    /// 44 from the bottom as designed, but never under a 3 button navigation bar
    final bottom = math.max(
      SpaceManager.adhanButtonsBottom,
      MediaQuery.viewPaddingOf(context).bottom / ScreenUtil().radius(1),
    );
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              children: [
                const RSizedBox.vertical(SpaceManager.adhanHeaderTop),
                _Reveal(
                  child: AdhanHeader(prayer: prayer, day: day),
                ),

                /// the free height split as on the 852 pt mockup, so the card lands at 572 there
                const Spacer(flex: 5),
                const HorizontalPadding(
                  padding: SpaceManager.screen,
                  child: _Reveal(child: AdhanDuaCard()),
                ),
                const Spacer(flex: 2),
                HorizontalPadding(
                  padding: SpaceManager.screen,
                  child: AdhanButtons(prayer: prayer, day: day),
                ),
                RSizedBox.vertical(bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// MOTION 06: the text fades and rises 300 ms after the circle starts. the route fades it all
/// with reduce motion
class _Reveal extends StatelessWidget {
  const _Reveal({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || MediaQuery.disableAnimationsOf(context)) return child;
    final text = CurvedAnimation(
      parent: animation,
      curve: Interval(adhanTextStart, 1, curve: BmMotion.decelerate),
    );
    return AnimatedBuilder(
      animation: text,
      builder: (context, child) => Opacity(
        opacity: text.value,
        child: Transform.translate(
          offset: Offset(0, (1 - text.value) * SpaceManager.adhanTextRise.r),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// the reveal takes 520 ms, the text starts 300 ms in and takes 520 ms too
final adhanReveal = BmMotion.emphasized + BmMotion.standard;
final adhanTextStart = BmMotion.standard.inMilliseconds / adhanReveal.inMilliseconds;
