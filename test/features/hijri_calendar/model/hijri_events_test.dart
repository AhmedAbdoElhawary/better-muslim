import 'package:better_muslim/core/hijri/hijri_date.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/features/hijri_calendar/model/hijri_events.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  HijriDate on(int day, int month) => HijriDate(day: day, month: month, year: 1448);

  DayLook look(int day, int month) => lookOf(on(day, month), today: false, selected: false);

  test('each FR-020 row has its look', () {
    expect(look(13, 5), DayLook.whiteDay);
    expect(look(15, 5), DayLook.whiteDay);
    expect(look(16, 5), DayLook.plain);
    expect(look(1, 1), DayLook.event);
    expect(look(9, 1), DayLook.sunnahFast);
    expect(look(10, 1), DayLook.sunnahFast);
    expect(look(1, 9), DayLook.event);
    expect(look(21, 9), DayLook.event);
    expect(look(1, 10), DayLook.event);
    expect(look(9, 12), DayLook.sunnahFast);
    expect(look(10, 12), DayLook.event);
    expect(look(11, 12), DayLook.event);
  });

  test('13 dhu al-hijjah is tashreeq with no white day, 14 and 15 are white days', () {
    expect(eventsOn(on(13, 12)).map((event) => event.nameKey), [StringsManager.eventTashreeq]);
    expect(look(13, 12), DayLook.event);
    expect(look(14, 12), DayLook.whiteDay);
  });

  test('not marked: mondays and thursdays, the mawlid, isra and miraj, 15 shaban', () {
    expect(eventsOn(on(12, 3)), isEmpty);
    expect(eventsOn(on(27, 7)), isEmpty);
    expect(eventsOn(on(15, 8)).map((event) => event.nameKey), [StringsManager.ayyamAlBid]);
  });

  test('today over selected over sunnah fast over event over white day', () {
    final ashura = on(10, 1);
    expect(lookOf(ashura, today: true, selected: true), DayLook.today);
    expect(lookOf(ashura, today: false, selected: true), DayLook.selected);
    expect(lookOf(on(13, 5), today: true, selected: false), DayLook.today);
  });
}
