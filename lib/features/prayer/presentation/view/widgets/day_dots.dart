import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// a day's five prayers in prayer order, filled when logged. never mirrored
class DayDots extends StatelessWidget {
  const DayDots(this.prayed, {super.key});
  final Set<Prayer> prayed;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final prayer in Prayer.values) ...[
            if (prayer.index > 0) const RSizedBox.horizontal(SpaceManager.dayDotGap),
            _Dot(filled: prayed.contains(prayer)),
          ],
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.filled});
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return RSizedBox.square(
      dimension: SizeManager.dayDot,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? context.getColor(ThemeEnum.primary) : null,
          border: filled ? null : Border.all(color: context.getColor(ThemeEnum.outlineStrong)),
        ),
      ),
    );
  }
}
