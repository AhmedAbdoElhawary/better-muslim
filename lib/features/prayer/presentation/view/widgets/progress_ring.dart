import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/ring_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the summary card's ring, today's count out of 5. it sweeps 300 ms on a change and never
/// mirrors in arabic
class ProgressRing extends ConsumerWidget {
  const ProgressRing(this.count, {super.key});
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(
      settingsProvider.select(
        (settings) => (
          reduceMotion: settings.value?.reduceMotion ?? false,
          digits: settings.value?.digits ?? Digits.eastern,
        ),
      ),
    );
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Directionality(
      textDirection: TextDirection.ltr,
      child: RSizedBox.square(
        dimension: SizeManager.ring,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: count / Prayer.values.length),
          duration: context.reduceMotion(settings.reduceMotion) ? Duration.zero : BmMotion.standard,
          curve: BmMotion.standardCurve,
          builder: (context, share, child) => CustomPaint(
            painter: RingPainter(
              share: share,
              track: context.getColor(ThemeEnum.variant),
              arc: context.getColor(ThemeEnum.primary),
              stroke: SizeManager.ringStroke.r,
            ),
            child: child,
          ),
          child: Center(
            child: SemiBoldText(
              context.formatDigits('$count', settings.digits),
              translate: false,
              fontSize: isArabic ? FontSizeManager.bodyLarge : FontSizeManager.body,
              tabularFigures: true,
            ),
          ),
        ),
      ),
    );
  }
}
