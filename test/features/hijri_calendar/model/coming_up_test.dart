import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/features/hijri_calendar/model/coming_up.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hijri/hijri_calendar.dart';

void main() {
  DateTime gregorianOf(int year, int month, int day) {
    final date = HijriCalendar().hijriToGregorian(year, month, day);
    return DateTime(date.year, date.month, date.day);
  }

  test('from 15 oct 2026 it is ayyam al-bid, jumada ii begins and rajab begins (4.13)', () {
    final [white, jumada, rajab] = comingUp(DateTime(2026, 10, 15), 0);

    expect(white.titleKey, StringsManager.ayyamAlBid);
    expect((white.hijri.day, white.hijri.month), (13, 5));
    expect((white.start, white.end), (DateTime(2026, 10, 24), DateTime(2026, 10, 26)));
    expect(white.line, ComingUpLine.whiteDays);

    expect(jumada.titleKey, StringsManager.monthBegins);
    expect(jumada.monthKey, StringsManager.hijriMonth6);
    expect(jumada.start, DateTime(2026, 11, 11));
    expect(jumada.line, ComingUpLine.sighting);

    expect(rajab.monthKey, StringsManager.hijriMonth7);
    expect(rajab.start, DateTime(2026, 12, 10));
    expect(rajab.line, ComingUpLine.estimated);
  });

  test('ramadan begins shows once, as the event', () {
    final items = comingUp(gregorianOf(1448, 8, 25), 0);
    expect(items.first.titleKey, StringsManager.eventRamadan);
    expect(items.first.line, ComingUpLine.sighting);
    expect(items.where((item) => item.monthKey == StringsManager.hijriMonth9), isEmpty);
    expect(items.map((item) => item.titleKey), [
      StringsManager.eventRamadan,
      StringsManager.ayyamAlBid,
      StringsManager.eventLastTen,
    ]);
  });

  test('1 shawwal shows as eid al-fitr, not shawwal begins', () {
    final items = comingUp(gregorianOf(1448, 9, 25), 0);
    expect(items.first.titleKey, StringsManager.eventEidFitr);
    expect(items.where((item) => item.monthKey == StringsManager.hijriMonth10), isEmpty);
  });

  test('items inside the current month read their date alone', () {
    final [white, ..._] = comingUp(DateTime(2026, 10, 15), 0);
    expect(white.line, ComingUpLine.whiteDays);
    final [ashura, ..._] = comingUp(gregorianOf(1448, 1, 5), 0);
    expect(ashura.titleKey, StringsManager.eventTasua);
    expect(ashura.line, ComingUpLine.inMonth);
  });

  test('an event already started today still counts, with its first day', () {
    final [white, ..._] = comingUp(gregorianOf(1448, 5, 14), 0);
    expect(white.titleKey, StringsManager.ayyamAlBid);
    expect(white.hijri.day, 13);
  });

  test('the adjustment moves the dates', () {
    final [white, jumada, _] = comingUp(DateTime(2026, 10, 15), 1);
    expect(white.start, DateTime(2026, 10, 23));
    expect(jumada.start, DateTime(2026, 11, 10));
  });
}
