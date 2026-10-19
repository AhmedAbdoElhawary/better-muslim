import 'package:better_muslim/core/hijri/hijri_date.dart';
import 'package:hijri/hijri_calendar.dart';

final _table = HijriCalendar();

/// one month of hijri 3.0.1's umm al-qura table, the same table and adjustment as home (R5)
class HijriMonth {
  const HijriMonth(this.year, this.month);

  HijriMonth.of(HijriDate date) : this(date.year, date.month);

  final int year;
  final int month;

  /// the first and last month the table converts
  static const first = HijriMonth(1356, 1);
  static const last = HijriMonth(1500, 12);

  /// moved back by the adjustment, so HijriDate.of(day, adjust) reads day 1 on it
  DateTime start(int adjust) {
    final day = _table.hijriToGregorian(year, month, 1);
    return DateTime(day.year, day.month, day.day - adjust);
  }

  int get length => _table.getDaysInMonth(year, month);

  String get monthKey => HijriDate(day: 1, month: month, year: year).monthKey;

  /// empty cells before day 1, the week starts on sunday
  int blanks(int adjust) => start(adjust).weekday % DateTime.daysPerWeek;

  List<DateTime> days(int adjust) {
    final first = start(adjust);
    return [for (var i = 0; i < length; i++) DateTime(first.year, first.month, first.day + i)];
  }

  HijriMonth get previous => month == 1 ? HijriMonth(year - 1, 12) : HijriMonth(year, month - 1);

  HijriMonth get next => month == 12 ? HijriMonth(year + 1, 1) : HijriMonth(year, month + 1);

  bool get canGoBack => this != first;

  bool get canGoForward => this != last;

  @override
  bool operator ==(Object other) =>
      other is HijriMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);
}
