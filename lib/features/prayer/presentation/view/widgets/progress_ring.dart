import 'dart:math' as math;

import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
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
            painter: _RingPainter(
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

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.share,
    required this.track,
    required this.arc,
    required this.stroke,
  });

  final double share;
  final Color track;
  final Color arc;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    /// r 24 in the 56 box, the stroke sits half inside
    final rect = Offset.zero & size;
    final circle = rect.deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawOval(circle, paint..color = track);
    if (share <= 0) return;
    canvas.drawArc(
      circle,
      -math.pi / 2,
      2 * math.pi * share,
      false,
      paint
        ..color = arc
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.share != share || old.track != track || old.arc != arc || old.stroke != stroke;
}
