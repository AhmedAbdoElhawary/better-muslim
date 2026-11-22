import 'package:better_muslim/core/prayer_log/prayer_log.dart';
import 'package:better_muslim/features/prayer/domain/week.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a week starts on the sunday on or before the day', () {
    expect(weekStart(DateTime(2026, 10, 15)), DateTime(2026, 10, 11));
    expect(weekStart(DateTime(2026, 10, 11)), DateTime(2026, 10, 11));
    expect(weekStart(DateTime(2026, 10, 17)), DateTime(2026, 10, 11));
  });

  test('pages run from the week of first use to this week', () {
    expect(weekPages(DateTime(2026, 10, 1), DateTime(2026, 10, 15)), [
      DateTime(2026, 9, 27),
      DateTime(2026, 10, 4),
      DateTime(2026, 10, 11),
    ]);
  });

  test('a first use after today, or none, counts as today', () {
    expect(weekPages(DateTime(2026, 11, 1), DateTime(2026, 10, 15)), [DateTime(2026, 10, 11)]);
    expect(weekPages(null, DateTime(2026, 10, 15)), [DateTime(2026, 10, 11)]);
  });

  /// europe's dst ends on 25 oct 2026, a sunday
  test('pages stay on sundays across a dst change', () {
    expect(weekPages(DateTime(2026, 10, 20), DateTime(2026, 11, 2)), [
      DateTime(2026, 10, 18),
      DateTime(2026, 10, 25),
      DateTime(2026, 11, 1),
    ]);
  });

  test('the month range of 15 oct 2026', () {
    expect(monthRange(DateTime(2026, 10, 15)), (from: '2026-10-01', to: '2026-10-31'));
    expect(monthRange(DateTime(2028, 2, 3)), (from: '2028-02-01', to: '2028-02-29'));
  });
}
