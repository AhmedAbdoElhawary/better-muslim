import 'package:better_muslim/core/database/civil_date.dart';
import 'package:better_muslim/core/prayer_log/prayer_log.dart';

/// the sundays from the week of first use to the week of today. no first use, or one after
/// today, counts as today
List<DateTime> weekPages(DateTime? firstUse, DateTime today) {
  final first = weekStart(firstUse == null || firstUse.isAfter(today) ? today : firstUse);
  final last = weekStart(today);
  return [
    /// by date, not by 7 x 24 hours, which lands on 23:00 after a dst change
    for (
      var sunday = first;
      !sunday.isAfter(last);
      sunday = DateTime(sunday.year, sunday.month, sunday.day + 7)
    )
      sunday,
  ];
}

/// the gregorian month of the day, as the stored date strings
({String from, String to}) monthRange(DateTime day) {
  const date = CivilDate();
  return (
    from: date.toSql(DateTime(day.year, day.month)),
    to: date.toSql(DateTime(day.year, day.month + 1, 0)),
  );
}
