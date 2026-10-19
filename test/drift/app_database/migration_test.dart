import 'package:better_muslim/core/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;
import 'generated/schema_v4.dart' as v4;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('every upgrade gives the schema in code', () {
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase.forTesting(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  /// the dev phone already has a v1 store (milestone 2 FR-022)
  test('v1 to v2 keeps every settings value and fills first use', () async {
    const old = v1.SettingsData(
      id: 1,
      latitude: 30.0626,
      longitude: 31.2497,
      placeName: 'Cairo',
      placeNameAr: 'القاهرة',
      regionName: 'Cairo Governorate',
      regionNameAr: 'محافظة القاهرة',
      countryCode: 'EG',
      timeZone: 'Africa/Cairo',
      locationMode: 'manual',
      method: 'muslimWorldLeague',
      asrMethod: 'hanafi',
      hijriAdjust: -1,
      digits: 'western',
      theme: 'andalus',
      themeMode: 'light',
      reduceMotion: 1,
      haptics: 0,
      uiSounds: 1,
      storeResetPending: 1,
    );
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDatabase.forTesting,
      createItems: (batch, oldDb) => batch.insert(oldDb.settings, old),
      validateItems: (newDb) async {
        final [row] = await newDb.select(newDb.settings).get();
        expect(row.toJson()..remove('firstUse'), old.toJson());
        expect(row.firstUse, today);
      },
    );
  });

  test('v2 to v3 keeps every settings value and reads the notification defaults', () async {
    const old = v2.SettingsData(
      id: 1,
      latitude: 21.4225,
      longitude: 39.8262,
      placeName: 'Makkah',
      placeNameAr: 'مكة المكرمة',
      regionName: 'Mecca Region',
      countryCode: 'SA',
      timeZone: 'Asia/Riyadh',
      locationMode: 'auto',
      hijriAdjust: 1,
      digits: 'western',
      theme: 'andalus',
      themeMode: 'dark',
      reduceMotion: 1,
      haptics: 0,
      uiSounds: 1,
      storeResetPending: 0,
      firstUse: '2026-10-01',
    );

    await verifier.testWithDataIntegrity(
      oldVersion: 2,
      newVersion: 3,
      createOld: v2.DatabaseAtV2.new,
      createNew: v3.DatabaseAtV3.new,
      openTestedDatabase: AppDatabase.forTesting,
      createItems: (batch, oldDb) => batch.insert(oldDb.settings, old),
      validateItems: (newDb) async {
        final [row] = await newDb.select(newDb.settings).get();
        expect(row.toJson(), {
          ...old.toJson(),
          'fajrSound': 'adhan',
          'dhuhrSound': 'tone',
          'asrSound': 'tone',
          'maghribSound': 'adhan',
          'ishaSound': 'tone',
          'reminderMinutes': 10,
          'notificationsAsked': 0,
        });
      },
    );
  });

  test('v3 to v4 keeps every row, adds the azkar defaults and two empty tables', () async {
    const old = v3.SettingsData(
      id: 1,
      latitude: 21.4225,
      longitude: 39.8262,
      placeName: 'Makkah',
      countryCode: 'SA',
      timeZone: 'Asia/Riyadh',
      locationMode: 'auto',
      hijriAdjust: 0,
      digits: 'eastern',
      theme: 'qiyamEmerald',
      themeMode: 'followSky',
      reduceMotion: 0,
      haptics: 1,
      uiSounds: 0,
      storeResetPending: 0,
      firstUse: '2026-10-01',
      fajrSound: 'adhan',
      dhuhrSound: 'silent',
      asrSound: 'tone',
      maghribSound: 'adhan',
      ishaSound: 'tone',
      reminderMinutes: 15,
      notificationsAsked: 1,
    );
    const prayed = v3.PrayerLogData(date: '2026-10-14', prayer: 'asr');
    const qada = v3.QadaEntriesData(id: 1, prayer: 'fajr', missedOn: '2026-10-02');

    await verifier.testWithDataIntegrity(
      oldVersion: 3,
      newVersion: 4,
      createOld: v3.DatabaseAtV3.new,
      createNew: v4.DatabaseAtV4.new,
      openTestedDatabase: AppDatabase.forTesting,
      createItems: (batch, oldDb) {
        batch
          ..insert(oldDb.settings, old)
          ..insert(oldDb.prayerLog, prayed)
          ..insert(oldDb.qadaEntries, qada);
      },
      validateItems: (newDb) async {
        final [row] = await newDb.select(newDb.settings).get();
        expect(row.toJson(), {
          ...old.toJson(),
          'tasbihDhikr': 0,
          'tasbihCount': 0,
          'morningOpenedOn': null,
          'eveningOpenedOn': null,
          'azkarNudges': 1,
        });
        expect((await newDb.select(newDb.prayerLog).get()).single.toJson(), prayed.toJson());
        expect((await newDb.select(newDb.qadaEntries).get()).single.toJson(), qada.toJson());
        expect(await newDb.select(newDb.azkarCounts).get(), isEmpty);
        expect(await newDb.select(newDb.savedDuas).get(), isEmpty);
      },
    );
  });
}
