import 'package:better_muslim/core/hijri/hijri_date.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/hijri_calendar/model/calendar_month.dart';
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

  group('gregorian', () {
    test('october 2026: 31 days, 4 blanks before thursday the 1st', () {
      const month = GregorianMonth(2026, 10);
      expect(month.days(0), hasLength(31));
      expect(month.days(0).first, DateTime(2026, 10));
      expect(month.blanks(0), 4);
      expect(month.days(2), month.days(0), reason: 'the adjustment moves only hijri days');
      expect(const GregorianMonth(2028, 2).days(0), hasLength(29));
      expect(const GregorianMonth(2026, 12).next, const GregorianMonth(2027, 1));
      expect(const GregorianMonth(2026, 1).previous, const GregorianMonth(2025, 12));
    });

    test('of finds the month holding a day in both modes, kept inside the range', () {
      final day = DateTime(2026, 10, 15);
      expect(CalendarMonth.of(day, CalendarMode.hijri, 0), const HijriMonth(1448, 5));
      expect(CalendarMonth.of(day, CalendarMode.gregorian, 0), const GregorianMonth(2026, 10));
      expect(
        CalendarMonth.of(DateTime(1937, 3, 20), CalendarMode.gregorian, 0),
        GregorianMonth.first,
      );
      expect(
        CalendarMonth.of(DateTime(2077, 11, 10), CalendarMode.gregorian, 0),
        GregorianMonth.last,
      );
      expect(const HijriMonth(1448, 5) == const GregorianMonth(1448, 5), isFalse);
    });

    test('april 1937 and october 2077 are the ends, every day converts with each adjustment', () {
      expect(GregorianMonth.first.canGoBack, isFalse);
      expect(GregorianMonth.first.canGoForward, isTrue);
      expect(GregorianMonth.last.canGoForward, isFalse);
      expect(GregorianMonth.last.canGoBack, isTrue);
      for (final month in [GregorianMonth.first, GregorianMonth.last]) {
        for (var adjust = -2; adjust <= 2; adjust++) {
          for (final day in month.days(adjust)) {
            expect(() => HijriDate.of(day, adjust), returnsNormally, reason: '$day $adjust');
          }
        }
      }
    });

    test('the order of months, for the slide', () {
      expect(
        const GregorianMonth(2026, 11).compareTo(const GregorianMonth(2026, 10)),
        greaterThan(0),
      );
      expect(const HijriMonth(1447, 12).compareTo(const HijriMonth(1448, 1)), lessThan(0));
    });
  });
}
