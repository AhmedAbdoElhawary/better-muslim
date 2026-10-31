import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/features/hijri_calendar/model/hijri_events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the mode's day large, the other calendar's day small, one look (FR-002, FR-003, FR-019)
class DayCell extends StatelessWidget {
  const DayCell({
    required this.day,
    required this.other,
    required this.look,
    required this.semantics,
    required this.onTap,
    this.prayed = 0,
    super.key,
  });

  /// already in the app's digits
  final String day;
  final String other;
  final DayLook look;

  /// the full hijri and gregorian date with the marks
  final String semantics;
  final VoidCallback onTap;

  /// how many of the day's five were logged, today keeps its own fill
  final int prayed;

  @override
  Widget build(BuildContext context) {
    final today = look == DayLook.today;
    final full = !today && prayed == Prayer.values.length;
    final some = !today && !full && prayed > 0;
    final ink = today
        ? ThemeEnum.onPrimary
        : full
        ? ThemeEnum.onPrimaryContainer
        : ThemeEnum.text;
    return Semantics(
      button: true,
      selected: look == DayLook.selected,
      label: semantics,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: SizeManager.dayCell.r),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: today
                  ? context.getColor(ThemeEnum.primary)
                  : full
                  ? context.getColor(ThemeEnum.primaryContainer)
                  : null,
              borderRadius: BorderRadius.circular(RadiusManager.dayCell.r),
              border: some
                  ? Border.all(
                      color: context.getColor(ThemeEnum.primary),
                      width: SizeManager.divider.r,
                    )
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (today)
                      SemiBoldText(day, translate: false, color: ink, tabularFigures: true)
                    else
                      MediumText(
                        day,
                        translate: false,
                        fontSize: FontSizeManager.title,
                        color: ink,
                        tabularFigures: true,
                      ),
                    RegularText(
                      other,
                      translate: false,
                      fontSize: FontSizeManager.calendarGregorian,
                      color: today || full ? ink : ThemeEnum.text2,
                      tabularFigures: true,
                      maxLines: 1,
                    ),
                    AnimatedSwitcher(
                      duration: BmMotion.micro,
                      child: _Mark(look, key: ValueKey(look)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// the selected day's ring, it slides from cell to cell over the grid (FR-009)
class DayRing extends StatelessWidget {
  const DayRing({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(RadiusManager.dayCell.r),
        border: Border.all(
          color: context.getColor(ThemeEnum.primary),
          width: SizeManager.todayRing.r,
        ),
      ),
    );
  }
}

/// a cell shows one look, so today and selected show no mark
class _Mark extends StatelessWidget {
  const _Mark(this.look, {super.key});
  final DayLook look;

  @override
  Widget build(BuildContext context) {
    return switch (look) {
      DayLook.whiteDay => const _Dot(ThemeEnum.accent),
      DayLook.event => const _Dot(ThemeEnum.primary),
      DayLook.sunnahFast => const _Crescent(),
      _ => const RSizedBox.square(dimension: SizeManager.dayMark),
    };
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.color);
  final ThemeEnum color;

  @override
  Widget build(BuildContext context) {
    return RSizedBox.square(
      dimension: SizeManager.dayMark,
      child: DecoratedBox(
        decoration: BoxDecoration(color: context.getColor(color), shape: BoxShape.circle),
      ),
    );
  }
}

class _Crescent extends StatelessWidget {
  const _Crescent();

  @override
  Widget build(BuildContext context) {
    return BmIcon(
      BmIconName.night,
      size: SizeManager.fastMark.r,
      color: context.getColor(ThemeEnum.accent),
    );
  }
}
