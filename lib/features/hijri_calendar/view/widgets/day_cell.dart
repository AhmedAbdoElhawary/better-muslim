import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/features/hijri_calendar/model/hijri_events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the hijri day large, the gregorian day small, one look (FR-018, FR-019)
class DayCell extends StatelessWidget {
  const DayCell({
    required this.hijriDay,
    required this.gregorian,
    required this.look,
    required this.semantics,
    required this.onTap,
    super.key,
  });

  /// already in the app's digits
  final String hijriDay;
  final String gregorian;
  final DayLook look;

  /// the full hijri and gregorian date with the marks
  final String semantics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final today = look == DayLook.today;
    final ink = today ? ThemeEnum.onPrimary : ThemeEnum.text;
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
              color: today ? context.getColor(ThemeEnum.primary) : null,
              borderRadius: BorderRadius.circular(RadiusManager.dayCell.r),

              /// selected takes the components' ring, so it never looks like today's fill
              border: look == DayLook.selected
                  ? Border.all(
                      color: context.getColor(ThemeEnum.primary),
                      width: SizeManager.todayRing.r,
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
                      SemiBoldText(hijriDay, translate: false, color: ink, tabularFigures: true)
                    else
                      MediumText(
                        hijriDay,
                        translate: false,
                        fontSize: FontSizeManager.title,
                        color: ink,
                        tabularFigures: true,
                      ),
                    RegularText(
                      gregorian,
                      translate: false,
                      fontSize: FontSizeManager.calendarGregorian,
                      color: today ? ink : ThemeEnum.text2,
                      tabularFigures: true,
                      maxLines: 1,
                    ),
                  ],
                ),
                PositionedDirectional(top: SizeManager.dayMarkTop.r, child: _Mark(look)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// a cell shows one look, so today and selected show no mark
class _Mark extends StatelessWidget {
  const _Mark(this.look);
  final DayLook look;

  @override
  Widget build(BuildContext context) {
    return switch (look) {
      DayLook.whiteDay => const _Dot(ThemeEnum.accent),
      DayLook.event => const _Dot(ThemeEnum.primary),
      DayLook.sunnahFast => const _Crescent(),
      _ => const SizedBox.shrink(),
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
