import 'package:better_muslim/core/hijri/hijri_date.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/features/hijri_calendar/model/hijri_events.dart';

const _count = 3;

/// a little over a year, so ten events always give three items
const _reach = 400;

/// how the item's date line reads (FR-022)
enum ComingUpLine { whiteDays, inMonth, sighting, estimated }

class ComingUpItem {
  const ComingUpItem({
    required this.hijri,
    required this.titleKey,
    required this.start,
    required this.end,
    required this.line,
    this.monthKey,
  });

  /// the left column: the hijri day and its short month
  final HijriDate hijri;

  /// a StringsManager key, monthBegins takes the month's name
  final String titleKey;
  final String? monthKey;
  final DateTime start;
  final DateTime end;
  final ComingUpLine line;
}

/// the next three things from today, whatever month the calendar shows. the white days show once,
/// the nearest, as 4.13 does
List<ComingUpItem> comingUp(DateTime today, int adjust) {
  final current = HijriDate.of(today, adjust);
  final items = <ComingUpItem>[];
  var whiteDays = false;
  var sighting = false;
  for (var i = 0; i < _reach && items.length < _count; i++) {
    final day = DateTime(today.year, today.month, today.day + i);
    final hijri = HijriDate.of(day, adjust);
    final inMonth = hijri.month == current.month && hijri.year == current.year;

    ComingUpLine lineFor({required bool monthStart}) {
      if (inMonth) return ComingUpLine.inMonth;
      if (monthStart && !sighting) {
        sighting = true;
        return ComingUpLine.sighting;
      }
      return ComingUpLine.estimated;
    }

    /// on today an event that already started still counts, after it only its first day does
    final starting = [
      for (final event in hijriEvents)
        if (event.covers(hijri) && (i == 0 || hijri.day == event.from)) event,
    ];
    if (hijri.day == 1 && !starting.any((event) => event.from == 1)) {
      items.add(
        ComingUpItem(
          hijri: hijri,
          titleKey: StringsManager.monthBegins,
          monthKey: hijri.monthKey,
          start: day,
          end: day,
          line: lineFor(monthStart: true),
        ),
      );
    }
    for (final event in starting) {
      final isWhite = event.look == DayLook.whiteDay;
      if (isWhite && whiteDays) continue;
      whiteDays = whiteDays || isWhite;
      final first = DateTime(day.year, day.month, day.day - (hijri.day - event.from));
      items.add(
        ComingUpItem(
          hijri: HijriDate.of(first, adjust),
          titleKey: event.nameKey,
          start: first,
          end: DateTime(first.year, first.month, first.day + event.to - event.from),
          line: isWhite ? ComingUpLine.whiteDays : lineFor(monthStart: event.from == 1),
        ),
      );
    }
  }
  return items.take(_count).toList();
}
