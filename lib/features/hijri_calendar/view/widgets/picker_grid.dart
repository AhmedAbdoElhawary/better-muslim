import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/hijri/hijri_date.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/design/bm_tokens.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/custom_opacity.dart';
import 'package:better_muslim/core/widgets/sliding_selection.dart';
import 'package:better_muslim/features/hijri_calendar/model/calendar_month.dart';
import 'package:better_muslim/features/hijri_calendar/view/widgets/calendar_format.dart';
import 'package:better_muslim/features/hijri_calendar/view/widgets/day_cell.dart';
import 'package:better_muslim/features/hijri_calendar/view_model/calendar_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

const _columns = 4;

/// the 12 months of the shown year, or the page of 12 years, in place of the days (FR-007)
class PickerGrid extends ConsumerWidget {
  const PickerGrid({required this.years, super.key});

  final bool years;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(calendarPageProvider.select((page) => page.month));
    final today = CalendarMonth.of(
      ref.watch(todayProvider),
      ref.watch(calendarModeProvider),
      ref.watch(hijriAdjustProvider),
    );
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final pager = ref.read(calendarPageProvider.notifier);
    final start = pager.pageStart(month.year);
    final items = [
      for (var i = 0; i < 12; i++)
        if (years)
          _Item(
            label: context.formatDigits('${start + i}', digits),
            current: today.year == start + i,
            enabled: start + i <= month.rangeLast.year,
            onTap: () => pager.openYear(start + i),
          )
        else
          _Item(
            label: switch (month) {
              HijriMonth() => context.tr(
                HijriDate(day: 1, month: i + 1, year: month.year).monthKey,
              ),
              GregorianMonth() => context.gregorianMonthName(i + 1),
            },
            current: today == month.at(month.year, i + 1),
            enabled: month.at(month.year, i + 1).inRange,
            onTap: () => pager.open(month.at(month.year, i + 1)),
          ),
    ];
    return SlidingSelection(
      selected: years ? month.year - start : month.month - 1,
      front: true,
      highlight: const DayRing(),
      layout: (children) => Column(
        children: [
          for (var row = 0; row < children.length; row += _columns) ...[
            if (row > 0) const RSizedBox.vertical(SpaceManager.gridGap),
            Row(
              children: [
                for (var i = row; i < row + _columns; i++) ...[
                  if (i > row) const RSizedBox.horizontal(SpaceManager.gridGap),
                  Expanded(child: children[i]),
                ],
              ],
            ),
          ],
        ],
      ),
      children: items,
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.label,
    required this.current,
    required this.enabled,
    required this.onTap,
  });

  final String label;

  /// today's month or year, marked like today
  final bool current;

  /// past the table's ends
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled
            ? () {
                BmHaptics.selection();
                onTap();
              }
            : null,
        child: CustomOpacity(
          opacity: enabled ? 1 : BmOpacity.disabled,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: SizeManager.dayCell.r),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: current ? context.getColor(ThemeEnum.primary) : null,
                borderRadius: BorderRadius.circular(RadiusManager.dayCell.r),
              ),
              child: Center(
                child: HorizontalPadding(
                  padding: SpaceManager.s1,
                  child: MediumText(
                    label,
                    translate: false,
                    color: current ? ThemeEnum.onPrimary : ThemeEnum.text,
                    textAlign: TextAlign.center,
                    tabularFigures: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
