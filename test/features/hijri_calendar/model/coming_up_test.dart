import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/hijri_calendar/model/coming_up.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hijri/hijri_calendar.dart';

void main() {
  DateTime gregorianOf(int year, int month, int day) {
    final date = HijriCalendar().hijriToGregorian(year, month, day);
    return DateTime(date.year, date.month, date.day);
  }

  final today = DateTime(2026, 10, 15);

  /// utc, a daylight saving night would cut a day off
  int fromToday(DateTime day) =>
      DateTime.utc(day.year, day.month, day.day).difference(DateTime.utc(2026, 10, 15)).inDays;

  test('from 4 jumada i 1448: this month first with the white days, later months in order', () {
    final list = comingUp(today, today, 0, CalendarMode.hijri);
    expect((list.year, list.next), (1448, false));

    final [thisMonth, ...later] = list.groups;
    expect((thisMonth.month, thisMonth.current), (5, true));
    final [white] = thisMonth.items;
    expect(white.event.nameKey, StringsManager.ayyamAlBid);
    expect(
      (white.hijri.day, white.first, white.last),
      (13, DateTime(2026, 10, 24), DateTime(2026, 10, 26)),
    );
    expect(white.daysAway, 9);
    expect(white.estimated, isFalse);

    expect(later.map((group) => group.month), [6, 7, 8, 9, 10, 11, 12]);
    expect(later.every((group) => !group.current), isTrue);
    final ramadan = later.firstWhere((group) => group.month == 9);
    expect(ramadan.items.map((item) => item.event.nameKey), [
      StringsManager.eventRamadan,
      StringsManager.ayyamAlBid,
      StringsManager.eventLastTen,
    ]);
    expect(ramadan.items.first.estimated, isTrue);
    expect(ramadan.items.first.first, gregorianOf(1448, 9, 1));
  });

  test('an event running on the selected day isn\'t listed', () {
    final list = comingUp(gregorianOf(1448, 5, 14), today, 0, CalendarMode.hijri);
    expect(list.groups.first.month, 6);
    expect(list.groups.first.current, isFalse);
  });

  test('the last day of dhu al-hijjah 1447 gives next year, islamic new year first', () {
    final last = gregorianOf(1448, 1, 1).subtract(const Duration(days: 1));
    final list = comingUp(last, today, 0, CalendarMode.hijri);
    expect((list.year, list.next), (1448, true));
    expect(list.groups.first.items.first.event.nameKey, StringsManager.eventNewYear);
    expect(list.groups.first.items.first.daysAway, fromToday(gregorianOf(1448, 1, 1)));
    expect(list.groups.first.current, isFalse);
  });

  test('each count is from today, whichever day is selected', () {
    final past = comingUp(gregorianOf(1448, 4, 1), today, 0, CalendarMode.hijri);
    final [white, ...] = past.groups.first.items;
    expect(white.first, gregorianOf(1448, 4, 13));
    expect(white.daysAway, fromToday(gregorianOf(1448, 4, 13)));
    expect(white.daysAway, isNegative);

    final onToday = comingUp(today, DateTime(2026, 10, 24), 0, CalendarMode.hijri);
    expect(onToday.groups.first.items.first.daysAway, 0);

    final future = comingUp(gregorianOf(1448, 5, 14), today, 0, CalendarMode.hijri);
    final first = future.groups.first.items.first;
    expect(first.daysAway, fromToday(first.first));
    expect(first.daysAway, greaterThan(30));

    final gregorian = comingUp(DateTime(2026, 11, 1), today, 0, CalendarMode.gregorian);
    final next = gregorian.groups.first.items.first;
    expect(next.daysAway, fromToday(next.first));
  });

  test('past the last event of 1500 there is nothing', () {
    final list = comingUp(gregorianOf(1500, 12, 20), today, 0, CalendarMode.hijri);
    expect(list.next, isTrue);
    expect(list.groups, isEmpty);
  });

  test('gregorian mode walks to 31 december by gregorian month', () {
    final list = comingUp(today, today, 0, CalendarMode.gregorian);
    expect((list.year, list.next), (2026, false));
    expect(list.groups.map((group) => group.month), [10, 11, 12]);
    expect(list.groups.first.current, isTrue);
    expect(list.groups.last.items.last.first.year, 2026);

    final last = comingUp(DateTime(2026, 12, 31), today, 0, CalendarMode.gregorian);
    expect((last.year, last.next), (2027, true));
    expect(last.groups.first.month, 1);
    expect(last.groups.first.items.first.first.year, 2027);
  });

  test('each adjustment moves the dates and never throws at the ends', () {
    for (var adjust = -2; adjust <= 2; adjust++) {
      final list = comingUp(today, today, adjust, CalendarMode.hijri);
      expect(
        list.groups.first.items.first.first,
        DateTime(2026, 10, 24 - adjust),
        reason: '$adjust',
      );
      expect(list.groups.first.items.first.daysAway, 9 - adjust, reason: '$adjust');
      for (final mode in CalendarMode.values) {
        comingUp(DateTime(1937, 4, 1), DateTime(1937, 4, 1), adjust, mode);
        comingUp(DateTime(2077, 10, 31), today, adjust, mode);
      }
    }
  });
}
