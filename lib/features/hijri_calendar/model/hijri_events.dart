import 'package:better_muslim/core/hijri/hijri_date.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';

/// one look per cell, the first that applies in this order (FR-019)
enum DayLook { today, selected, sunnahFast, event, whiteDay, plain }

/// a mark that comes back every year on the same hijri days (FR-020)
class HijriEvent {
  const HijriEvent({
    required this.months,
    required this.from,
    required this.to,
    required this.look,
    required this.nameKey,
    this.noteKey,
  });

  final Set<int> months;
  final int from;
  final int to;
  final DayLook look;

  /// StringsManager keys
  final String nameKey;
  final String? noteKey;

  bool covers(HijriDate date) => months.contains(date.month) && date.day >= from && date.day <= to;
}

const _everyMonthButDhulHijjah = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11};

const hijriEvents = [
  HijriEvent(
    months: _everyMonthButDhulHijjah,
    from: 13,
    to: 15,
    look: DayLook.whiteDay,
    nameKey: StringsManager.ayyamAlBid,
    noteKey: StringsManager.noteWhiteDays,
  ),

  /// 13 dhu al-hijjah is a day of tashreeq, fasting isn't allowed on it
  HijriEvent(
    months: {12},
    from: 14,
    to: 15,
    look: DayLook.whiteDay,
    nameKey: StringsManager.ayyamAlBid,
    noteKey: StringsManager.noteWhiteDays,
  ),
  HijriEvent(
    months: {1},
    from: 1,
    to: 1,
    look: DayLook.event,
    nameKey: StringsManager.eventNewYear,
  ),
  HijriEvent(
    months: {1},
    from: 9,
    to: 9,
    look: DayLook.sunnahFast,
    nameKey: StringsManager.eventTasua,
    noteKey: StringsManager.noteFasting,
  ),
  HijriEvent(
    months: {1},
    from: 10,
    to: 10,
    look: DayLook.sunnahFast,
    nameKey: StringsManager.eventAshura,
    noteKey: StringsManager.noteFasting,
  ),
  HijriEvent(
    months: {9},
    from: 1,
    to: 1,
    look: DayLook.event,
    nameKey: StringsManager.eventRamadan,
  ),
  HijriEvent(
    months: {9},
    from: 21,
    to: 21,
    look: DayLook.event,
    nameKey: StringsManager.eventLastTen,
    noteKey: StringsManager.noteQadr,
  ),
  HijriEvent(
    months: {10},
    from: 1,
    to: 1,
    look: DayLook.event,
    nameKey: StringsManager.eventEidFitr,
    noteKey: StringsManager.noteNoFasting,
  ),
  HijriEvent(
    months: {12},
    from: 9,
    to: 9,
    look: DayLook.sunnahFast,
    nameKey: StringsManager.eventArafah,
    noteKey: StringsManager.noteFasting,
  ),
  HijriEvent(
    months: {12},
    from: 10,
    to: 10,
    look: DayLook.event,
    nameKey: StringsManager.eventEidAdha,
    noteKey: StringsManager.noteNoFasting,
  ),
  HijriEvent(
    months: {12},
    from: 11,
    to: 13,
    look: DayLook.event,
    nameKey: StringsManager.eventTashreeq,
    noteKey: StringsManager.noteNoFasting,
  ),
];

List<HijriEvent> eventsOn(HijriDate date) => [
  for (final event in hijriEvents)
    if (event.covers(date)) event,
];

DayLook lookOf(HijriDate date, {required bool today, required bool selected}) {
  if (today) return DayLook.today;
  if (selected) return DayLook.selected;
  final looks = {for (final event in eventsOn(date)) event.look};
  for (final look in [DayLook.sunnahFast, DayLook.event, DayLook.whiteDay]) {
    if (looks.contains(look)) return look;
  }
  return DayLook.plain;
}
