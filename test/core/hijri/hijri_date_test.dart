import 'package:better_muslim/core/hijri/hijri_date.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  (int, int, int) dayMonthYear(DateTime date, [int adjust = 0]) {
    final hijri = HijriDate.of(date, adjust);
    return (hijri.day, hijri.month, hijri.year);
  }

  test('the scenario day is 4 jumada i 1448 (umm al-qura)', () {
    expect(dayMonthYear(DateTime(2026, 10, 15)), (4, 5, 1448));
  });

  test('1 jumada i 1448 is 12 oct 2026, the check OVERVIEW asks for', () {
    expect(dayMonthYear(DateTime(2026, 10, 12)), (1, 5, 1448));
  });

  test('the adjustment moves the date by up to two days either way (FR-018)', () {
    final date = DateTime(2026, 10, 15);
    expect(dayMonthYear(date, 1), (5, 5, 1448));
    expect(dayMonthYear(date, -2), (2, 5, 1448));
    expect(dayMonthYear(date, 2), (6, 5, 1448));
  });

  test('the month name comes from the arb key', () {
    expect(HijriDate.of(DateTime(2026, 10, 15), 0).monthKey, StringsManager.hijriMonth5);
  });
}
