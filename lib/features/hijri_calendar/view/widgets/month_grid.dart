import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/hijri/hijri_date.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/features/hijri_calendar/model/hijri_events.dart';
import 'package:better_muslim/features/hijri_calendar/view/widgets/calendar_format.dart';
import 'package:better_muslim/features/hijri_calendar/view/widgets/day_cell.dart';
import 'package:better_muslim/features/hijri_calendar/view/widgets/day_sheet.dart';
import 'package:better_muslim/features/hijri_calendar/view_model/calendar_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' show DateFormat;

/// any sunday, the week starts there like the prayer tab's strip
final _sunday = DateTime(2026, 10, 11);

/// the weekday letters and the shown month, sunday first, five or six rows (FR-018)
class MonthGrid extends ConsumerWidget {
  const MonthGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(shownMonthProvider);
    final adjust = ref.watch(hijriAdjustProvider);
    final days = month.days(adjust);
    final cells = <DateTime?>[for (var i = 0; i < month.blanks(adjust); i++) null, ...days];
    final locale = Localizations.localeOf(context).languageCode;
    return Column(
      children: [
        _Week(
          children: [
            for (var i = 0; i < DateTime.daysPerWeek; i++)
              RSizedBox(
                height: SizeManager.weekdayRow,
                child: RegularText(
                  DateFormat('EEEEE', locale).format(_sunday.add(Duration(days: i))),
                  translate: false,
                  fontSize: FontSizeManager.weekday,
                  color: ThemeEnum.text2,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
        for (var start = 0; start < cells.length; start += DateTime.daysPerWeek) ...[
          const RSizedBox.vertical(SpaceManager.gridGap),
          _Week(
            children: [
              for (var i = start; i < start + DateTime.daysPerWeek; i++)
                if (i < cells.length && cells[i] != null)
                  _Day(cells[i]!, first: cells[i] == days.first)
                else
                  const SizedBox.shrink(),
            ],
          ),
        ],
      ],
    );
  }
}

class _Week extends StatelessWidget {
  const _Week({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, child) in children.indexed) ...[
          if (index > 0) const RSizedBox.horizontal(SpaceManager.gridGap),
          Expanded(child: child),
        ],
      ],
    );
  }
}

/// reads its own look, so a selection or a new today rebuilds one cell
class _Day extends ConsumerWidget {
  const _Day(this.day, {required this.first});
  final DateTime day;

  /// the month's first cell shows the short month like a gregorian 1st does
  final bool first;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hijri = ref.watch(hijriDateProvider(day));
    final isToday = ref.watch(todayProvider.select((today) => today == day));
    final selected = ref.watch(selectedDayProvider.select((selected) => selected == day));
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final look = lookOf(hijri, today: isToday, selected: selected);
    final gregorian = first || day.day == 1
        ? context.dayMonth(day, digits)
        : context.formatDigits('${day.day}', digits);
    return DayCell(
      hijriDay: context.formatDigits('${hijri.day}', digits),
      gregorian: gregorian,
      look: look,
      semantics: _semantics(context, hijri, isToday, digits),
      onTap: () => showDaySheet(context, day),
    );
  }

  String _semantics(BuildContext context, HijriDate hijri, bool isToday, Digits digits) {
    final locale = Localizations.localeOf(context).languageCode;
    return [
      context.hijriFull(hijri, digits),
      context.formatDigits(DateFormat.yMMMMEEEEd(locale).format(day), digits),
      if (isToday) context.tr(StringsManager.today),
      for (final event in eventsOn(hijri)) context.tr(event.nameKey),
    ].join(', ');
  }
}
