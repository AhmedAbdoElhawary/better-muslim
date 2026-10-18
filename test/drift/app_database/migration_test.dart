import 'package:better_muslim/core/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

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
}
