import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/hijri/hijri_date.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/sliding_selection.dart';
import 'package:better_muslim/features/hijri_calendar/model/calendar_month.dart';
import 'package:better_muslim/features/hijri_calendar/model/hijri_events.dart';
import 'package:better_muslim/features/hijri_calendar/view/widgets/calendar_format.dart';
import 'package:better_muslim/features/hijri_calendar/view/widgets/day_cell.dart';
import 'package:better_muslim/features/hijri_calendar/view_model/calendar_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' show DateFormat;

/// any sunday, the week starts there like the prayer tab's strip
final _sunday = DateTime(2026, 10, 11);

/// the weekday letters and the shown month, sunday first, five or six rows (FR-018). a new month
/// slides in the way it travels, a new mode crossfades (FR-004, FR-008)
class MonthGrid extends ConsumerStatefulWidget {
  const MonthGrid({super.key});

  @override
  ConsumerState<MonthGrid> createState() => _MonthGridState();
}

class _MonthGridState extends ConsumerState<MonthGrid> {
  CalendarMonth? _shown;

  /// 1 forward, -1 back, 0 for a mode change
  var _direction = 0;

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(calendarPageProvider.select((page) => page.month));
    final last = _shown;
    if (last != month) {
      _direction = last == null || last.runtimeType != month.runtimeType
          ? 0
          : month.compareTo(last).sign;
      _shown = month;
    }
    final reduce = MediaQuery.disableAnimationsOf(context);
    final textDirection = Directionality.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final switcher = ClipRect(
      child: AnimatedSwitcher(
        duration: reduce ? BmMotion.micro : BmMotion.standard,
        switchInCurve: BmMotion.standardCurve,
        switchOutCurve: BmMotion.standardCurve,
        layoutBuilder: (current, previous) =>
            Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
        transitionBuilder: (child, animation) {
          final fade = FadeTransition(opacity: animation, child: child);
          if (reduce || _direction == 0) return fade;
          final incoming = child.key == ValueKey(month);
          return SlideTransition(
            position: Tween(
              begin: Offset((incoming ? _direction : -_direction).toDouble(), 0),
              end: Offset.zero,
            ).animate(animation),
            textDirection: textDirection,
            child: fade,
          );
        },
        child: _Days(month, key: ValueKey(month)),
      ),
    );
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

        /// AnimatedSize asserts on a zero duration, so reduce motion leaves it out
        if (reduce)
          switcher
        else
          AnimatedSize(
            duration: BmMotion.standard,
            curve: BmMotion.standardCurve,
            alignment: Alignment.topCenter,
            child: switcher,
          ),
      ],
    );
  }
}

class _Days extends ConsumerWidget {
  const _Days(this.month, {super.key});
  final CalendarMonth month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adjust = ref.watch(hijriAdjustProvider);
    final days = month.days(adjust);
    final selected = ref.watch(selectedDayProvider.select(days.indexOf));
    return SlidingSelection(
      selected: selected < 0 ? null : selected,
      front: true,
      highlight: const DayRing(),
      layout: (children) {
        final cells = <Widget?>[for (var i = 0; i < month.blanks(adjust); i++) null, ...children];
        return Column(
          children: [
            for (var start = 0; start < cells.length; start += DateTime.daysPerWeek) ...[
              const RSizedBox.vertical(SpaceManager.gridGap),
              _Week(
                children: [
                  for (var i = start; i < start + DateTime.daysPerWeek; i++)
                    if (i < cells.length)
                      cells[i] ?? const SizedBox.shrink()
                    else
                      const SizedBox.shrink(),
                ],
              ),
            ],
          ],
        );
      },
      children: [
        for (final day in days)
          _Day(day, first: day == days.first, gregorian: month is GregorianMonth),
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
  const _Day(this.day, {required this.first, required this.gregorian});
  final DateTime day;

  /// the month's first cell shows the other calendar's short month, like its own 1st does
  final bool first;
  final bool gregorian;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hijri = ref.watch(hijriDateProvider(day));
    final isToday = ref.watch(todayProvider.select((today) => today == day));
    final selected = ref.watch(selectedDayProvider.select((selected) => selected == day));
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final look = lookOf(hijri, today: isToday, selected: selected);
    final (big, small) = gregorian
        ? (
            context.formatDigits('${day.day}', digits),
            first || hijri.day == 1
                ? context.hijriDayMonth(hijri, digits)
                : context.formatDigits('${hijri.day}', digits),
          )
        : (
            context.formatDigits('${hijri.day}', digits),
            first || day.day == 1
                ? context.dayMonth(day, digits)
                : context.formatDigits('${day.day}', digits),
          );
    return DayCell(
      day: big,
      other: small,
      look: look,
      semantics: _semantics(context, hijri, isToday, digits),
      onTap: () {
        if (selected) return;
        BmHaptics.selection();
        ref.read(selectedDayProvider.notifier).select(day);
      },
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
