import 'package:better_muslim/core/hijri/hijri_date.dart';
import 'package:better_muslim/features/hijri_calendar/model/hijri_month.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hijri/hijri_calendar.dart';

void main() {
  test('every month 1440 to 1460 AH, each adjustment, matches the table (SC-003)', () {
    final table = HijriCalendar();
    for (var year = 1440; year <= 1460; year++) {
      for (var month = 1; month <= 12; month++) {
        final shown = HijriMonth(year, month);
        final start = table.hijriToGregorian(year, month, 1);
        for (var adjust = -2; adjust <= 2; adjust++) {
          final days = shown.days(adjust);
          expect(
            days.first,
            DateTime(start.year, start.month, start.day - adjust),
            reason: '$year/$month $adjust',
          );
          expect(days, hasLength(table.getDaysInMonth(year, month)));
          for (final (index, day) in days.indexed) {
            final hijri = HijriDate.of(day, adjust);
            expect((hijri.day, hijri.month, hijri.year), (index + 1, month, year));
          }
        }
      }
    }
  });

  test('1 jumada i 1448 is monday 12 oct 2026, one blank before it', () {
    const month = HijriMonth(1448, 5);
    expect(month.start(0), DateTime(2026, 10, 12));
    expect(month.start(0).weekday, DateTime.monday);
    expect(month.blanks(0), 1);
    expect(month.length, 30);
    expect(month.start(1), DateTime(2026, 10, 11));
    expect(month.blanks(1), 0);
  });

  test('the arrows step through the years', () {
    expect(const HijriMonth(1448, 12).next, const HijriMonth(1449, 1));
    expect(const HijriMonth(1448, 1).previous, const HijriMonth(1447, 12));
    expect(HijriMonth.of(const HijriDate(day: 4, month: 5, year: 1448)), const HijriMonth(1448, 5));
  });

  test('the first and last month the table converts, the step past them refused', () {
    expect(HijriMonth.first.canGoBack, isFalse);
    expect(HijriMonth.first.canGoForward, isTrue);
    expect(HijriMonth.last.canGoForward, isFalse);
    expect(HijriMonth.last.canGoBack, isTrue);
    for (var adjust = -2; adjust <= 2; adjust++) {
      expect(HijriMonth.first.days(adjust), isNotEmpty);
      expect(HijriMonth.last.days(adjust), isNotEmpty);
    }
    expect(() => HijriMonth.first.previous.days(0), throwsArgumentError);
    expect(() => HijriMonth.last.next.days(0), throwsArgumentError);
  });
}
