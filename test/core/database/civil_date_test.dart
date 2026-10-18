import 'package:better_muslim/core/database/civil_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const date = CivilDate();

  test('a date is yyyy-MM-dd both ways', () {
    expect(date.toSql(DateTime(2026, 10, 15)), '2026-10-15');
    expect(date.fromSql('2026-10-15'), DateTime(2026, 10, 15));
  });

  test('a single digit month and day pad to two', () {
    expect(date.toSql(DateTime(2026, 3, 9)), '2026-03-09');
  });

  /// the dst start in europe, a local midnight that some zones skip
  test('it reads back as local midnight whatever the zone', () {
    final day = date.fromSql('2026-03-29');

    expect(day.isUtc, isFalse);
    expect((day.year, day.month, day.day, day.hour), (2026, 3, 29, 0));
  });

  test('string order is date order', () {
    final days = [DateTime(2026, 12, 1), DateTime(2026, 1, 31), DateTime(2025, 12, 31)];
    final strings = days.map(date.toSql).toList()..sort();

    expect(strings, ['2025-12-31', '2026-01-31', '2026-12-01']);
  });
}
