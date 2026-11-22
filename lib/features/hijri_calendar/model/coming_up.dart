import 'package:better_muslim/core/hijri/hijri_date.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/hijri_calendar/model/calendar_month.dart';
import 'package:better_muslim/features/hijri_calendar/model/hijri_events.dart';

/// what is left of the selected day's year, or the next year's when nothing is (FR-012, FR-016)
class ComingUp {
  const ComingUp({required this.year, required this.next, required this.groups});

  /// hijri in hijri mode, gregorian in gregorian mode
  final int year;
  final bool next;

  /// empty past the table's end, "No more events"
  final List<ComingUpGroup> groups;
}

class ComingUpGroup {
  const ComingUpGroup({
    required this.year,
    required this.month,
    required this.current,
    required this.items,
  });

  /// in the mode's calendar
  final int year;
  final int month;

  /// the selected day's month, "This month"
  final bool current;
  final List<ComingUpItem> items;
}

class ComingUpItem {
  const ComingUpItem({
    required this.event,
    required this.first,
    required this.hijri,
    required this.daysAway,
    required this.estimated,
  });

  final HijriEvent event;
  final DateTime first;
  final HijriDate hijri;

  /// from today, so 0 is today and below 0 already passed
  final int daysAway;

  /// a later hijri month than today's, its start waits on the moon sighting
  final bool estimated;

  DateTime get last => DateTime(first.year, first.month, first.day + event.to - event.from);
}

ComingUp comingUp(DateTime selected, DateTime today, int adjust, CalendarMode mode) {
  final hijri = HijriDate.of(selected, adjust);
  final year = mode == CalendarMode.hijri ? hijri.year : selected.year;
  final groups = _walk(
    DateTime(selected.year, selected.month, selected.day + 1),
    year,
    selected: selected,
    today: today,
    adjust: adjust,
    mode: mode,
  );
  if (groups.isNotEmpty) return ComingUp(year: year, next: false, groups: groups);
  final next = year + 1;
  final start = switch (mode) {
    CalendarMode.hijri when next <= HijriMonth.last.year => HijriMonth(next, 1).start(adjust),
    CalendarMode.gregorian => DateTime(next),
    _ => null,
  };
  return ComingUp(
    year: next,
    next: true,
    groups: start == null
        ? const []
        : _walk(start, next, selected: selected, today: today, adjust: adjust, mode: mode),
  );
}

/// from start to the last day of year, never past the table's last day
List<ComingUpGroup> _walk(
  DateTime start,
  int year, {
  required DateTime selected,
  required DateTime today,
  required int adjust,
  required CalendarMode mode,
}) {
  final todayHijri = HijriDate.of(today, adjust);
  final end = HijriMonth.last.days(adjust).last;
  final selectedMonth = CalendarMonth.of(selected, mode, adjust);
  final groups = <ComingUpGroup>[];
  for (var day = start; !day.isAfter(end); day = DateTime(day.year, day.month, day.day + 1)) {
    final hijri = HijriDate.of(day, adjust);
    final (dayYear, dayMonth) = mode == CalendarMode.hijri
        ? (hijri.year, hijri.month)
        : (day.year, day.month);
    if (dayYear != year) break;
    final items = [
      for (final event in hijriEvents)
        if (event.covers(hijri) && hijri.day == event.from)
          ComingUpItem(
            event: event,
            first: day,
            hijri: hijri,
            daysAway: _utc(day).difference(_utc(today)).inDays,
            estimated: hijri.year * 12 + hijri.month > todayHijri.year * 12 + todayHijri.month,
          ),
    ];
    if (items.isEmpty) continue;
    final last = groups.lastOrNull;
    if (last != null && last.year == dayYear && last.month == dayMonth) {
      last.items.addAll(items);
    } else {
      groups.add(
        ComingUpGroup(
          year: dayYear,
          month: dayMonth,
          current: selectedMonth.year == dayYear && selectedMonth.month == dayMonth,
          items: items,
        ),
      );
    }
  }
  return groups;
}

/// a daylight saving night is 23 or 25 hours, utc days are always 24
DateTime _utc(DateTime day) => DateTime.utc(day.year, day.month, day.day);
