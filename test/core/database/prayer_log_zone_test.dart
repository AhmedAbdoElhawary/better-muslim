import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/prayer_log/prayer_log.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tz.initializeTimeZones);

  Location at(String zone) => Location(
    latitude: 21.4225,
    longitude: 39.8262,
    placeName: 'Makkah',
    countryCode: 'SA',
    zone: tz.getLocation(zone),
    mode: LocationMode.auto,
  );

  Future<Set<Prayer>> prayedOn(AppDatabase db, String zone, DateTime day) async {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        locationProvider.overrideWithValue(at(zone)),
      ],
    );
    addTearDown(container.dispose);
    final week = weekLogProvider(weekStart(day));
    container.listen(week, (_, _) {});
    await container.read(week.future);
    return container.read(prayedProvider(day));
  }

  /// the log is a date and a prayer, never an instant, so no zone can move it (FR-010)
  test('asr logged in riyadh is still on 15 oct after a move to new york', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final day = DateTime(2026, 10, 15);
    await db.markPrayed(day, Prayer.asr);

    expect(await prayedOn(db, 'Asia/Riyadh', day), {Prayer.asr});
    expect(await prayedOn(db, 'America/New_York', day), {Prayer.asr});
    expect(await prayedOn(db, 'America/New_York', DateTime(2026, 10, 14)), isEmpty);
  });
}
