import 'package:better_muslim/core/hijri/hijri_date.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:hijri/hijri_calendar.dart';

final _table = HijriCalendar();

/// the month the grid shows, hijri or gregorian, so the providers and the grid don't care which
sealed class CalendarMonth implements Comparable<CalendarMonth> {
  const CalendarMonth(this.year, this.month);

  /// the month holding day, kept inside the mode's range
  factory CalendarMonth.of(DateTime day, CalendarMode mode, int adjust) {
    final CalendarMonth month = switch (mode) {
      CalendarMode.hijri => HijriMonth.of(HijriDate.of(day, adjust)),
      CalendarMode.gregorian => GregorianMonth(day.year, day.month),
    };
    return month.clamp(month);
  }

  final int year;
  final int month;

  CalendarMonth get rangeFirst;
  CalendarMonth get rangeLast;

  /// the same kind of month
  CalendarMonth at(int year, int month);

  List<DateTime> days(int adjust);

  /// empty cells before the first day, the week starts on sunday
  int blanks(int adjust) => days(adjust).first.weekday % DateTime.daysPerWeek;

  CalendarMonth get previous => month == 1 ? at(year - 1, 12) : at(year, month - 1);

  CalendarMonth get next => month == 12 ? at(year + 1, 1) : at(year, month + 1);

  bool get canGoBack => compareTo(rangeFirst) > 0;

  bool get canGoForward => compareTo(rangeLast) < 0;

  bool get inRange => compareTo(rangeFirst) >= 0 && compareTo(rangeLast) <= 0;

  CalendarMonth clamp(CalendarMonth other) {
    if (other.compareTo(rangeFirst) < 0) return rangeFirst;
    if (other.compareTo(rangeLast) > 0) return rangeLast;
    return other;
  }

  @override
  int compareTo(CalendarMonth other) => (year * 12 + month) - (other.year * 12 + other.month);

  @override
  bool operator ==(Object other) =>
      other is CalendarMonth &&
      other.runtimeType == runtimeType &&
      other.year == year &&
      other.month == month;

  @override
  int get hashCode => Object.hash(runtimeType, year, month);
}

/// one month of hijri 3.0.1's umm al-qura table, the same table and adjustment as home (R5)
class HijriMonth extends CalendarMonth {
  const HijriMonth(super.year, super.month);

  HijriMonth.of(HijriDate date) : this(date.year, date.month);

  /// the first and last month the table converts
  static const first = HijriMonth(1356, 1);
  static const last = HijriMonth(1500, 12);

  @override
  CalendarMonth get rangeFirst => first;

  @override
  CalendarMonth get rangeLast => last;

  @override
  HijriMonth at(int year, int month) => HijriMonth(year, month);

  /// moved back by the adjustment, so HijriDate.of(day, adjust) reads day 1 on it
  DateTime start(int adjust) {
    final day = _table.hijriToGregorian(year, month, 1);
    return DateTime(day.year, day.month, day.day - adjust);
  }

  int get length => _table.getDaysInMonth(year, month);

  String get monthKey => HijriDate(day: 1, month: month, year: year).monthKey;

  @override
  List<DateTime> days(int adjust) {
    final first = start(adjust);
    return [for (var i = 0; i < length; i++) DateTime(first.year, first.month, first.day + i)];
  }
}

class GregorianMonth extends CalendarMonth {
  const GregorianMonth(super.year, super.month);

  /// the table converts 14 mar 1937 to 16 nov 2077, every day stays inside with a ±2 adjustment
  static const first = GregorianMonth(1937, 4);
  static const last = GregorianMonth(2077, 10);

  @override
  CalendarMonth get rangeFirst => first;

  @override
  CalendarMonth get rangeLast => last;

  @override
  GregorianMonth at(int year, int month) => GregorianMonth(year, month);

  @override
  List<DateTime> days(int adjust) => [
    for (var day = 1; day <= DateTime(year, month + 1, 0).day; day++) DateTime(year, month, day),
  ];
}
