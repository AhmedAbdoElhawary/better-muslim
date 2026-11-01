import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/prayer_log/prayer_log.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the qada week gives the dated entries of the 7 days by day and prayer', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(container.dispose);
    DateTime october(int day) => DateTime(2026, 10, day);
    await db.batch(
      (batch) => batch.insertAll(db.qadaEntries, [
        for (final (day, prayer) in [
          (10, Prayer.fajr),
          (11, Prayer.fajr),
          (17, Prayer.isha),
          (18, Prayer.isha),
        ])
          QadaEntriesCompanion.insert(prayer: prayer, missedOn: Value(october(day))),
        QadaEntriesCompanion.insert(prayer: Prayer.fajr),
      ]),
    );

    final week = qadaWeekProvider(october(11));
    container.listen(week, (_, _) {});
    expect((await container.read(week.future)).keys, {
      (october(11), Prayer.fajr),
      (october(17), Prayer.isha),
    });
  });
}
