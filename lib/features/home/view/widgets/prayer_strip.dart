import 'package:better_muslim/core/extensions/window_size.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/features/home/view/widgets/strip_cell.dart';
import 'package:better_muslim/features/home/view/widgets/strip_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the prayer day's five times, from fajr to the next fajr
class PrayerStrip extends StatelessWidget {
  const PrayerStrip({super.key});

  @override
  Widget build(BuildContext context) {
    /// "12:05 PM" needs about 73 pt and a cell is 69, so 12 hour phones always get rows (R15)
    if (context.isLargeText || !MediaQuery.alwaysUse24HourFormatOf(context)) {
      return Column(
        children: [
          for (final prayer in Prayer.values) ...[
            if (prayer.index > 0) const RSizedBox.vertical(SpaceManager.stripCellGap),
            StripRow(prayer.index),
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final prayer in Prayer.values) ...[
          if (prayer.index > 0) const RSizedBox.horizontal(SpaceManager.stripCellGap),
          Expanded(child: StripCell(prayer.index)),
        ],
      ],
    );
  }
}
