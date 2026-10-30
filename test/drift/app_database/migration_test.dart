import 'package:better_muslim/core/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v10.dart' as v10;
import 'generated/schema_v11.dart' as v11;
import 'generated/schema_v12.dart' as v12;
import 'generated/schema_v13.dart' as v13;
import 'generated/schema_v14.dart' as v14;
import 'generated/schema_v15.dart' as v15;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;
import 'generated/schema_v4.dart' as v4;
import 'generated/schema_v5.dart' as v5;
import 'generated/schema_v6.dart' as v6;
import 'generated/schema_v7.dart' as v7;
import 'generated/schema_v8.dart' as v8;
import 'generated/schema_v9.dart' as v9;

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

  test('v4 to v5 keeps row 1 only, reads makkah for each prayer and takes 25 minutes', () async {
    const old = v4.SettingsData(
      id: 1,
      latitude: 21.4225,
      longitude: 39.8262,
      placeName: 'Makkah',
      countryCode: 'SA',
      timeZone: 'Asia/Riyadh',
      locationMode: 'auto',
      hijriAdjust: 1,
      digits: 'western',
      theme: 'iznik',
      themeMode: 'light',
      reduceMotion: 1,
      haptics: 0,
      uiSounds: 1,
      storeResetPending: 0,
      firstUse: '2026-10-01',
      fajrSound: 'adhan',
      dhuhrSound: 'silent',
      asrSound: 'tone',
      maghribSound: 'adhan',
      ishaSound: 'tone',
      reminderMinutes: 15,
      notificationsAsked: 1,
      tasbihDhikr: 2,
      tasbihCount: 12,
      morningOpenedOn: '2026-10-14',
      azkarNudges: 0,
    );
    const prayed = v4.PrayerLogData(date: '2026-10-14', prayer: 'asr');
    const qada = v4.QadaEntriesData(id: 1, prayer: 'fajr', missedOn: '2026-10-02');
    const saved = v4.SavedDuasData(dua: 'travel-1', savedAt: 1760000000);

    await verifier.testWithDataIntegrity(
      oldVersion: 4,
      newVersion: 5,
      createOld: v4.DatabaseAtV4.new,
      createNew: v5.DatabaseAtV5.new,
      openTestedDatabase: AppDatabase.forTesting,
      createItems: (batch, oldDb) {
        batch
          ..insert(oldDb.settings, old)
          ..insert(oldDb.settings, old.copyWith(id: 2))
          ..insert(oldDb.prayerLog, prayed)
          ..insert(oldDb.qadaEntries, qada)
          ..insert(oldDb.savedDuas, saved);
      },
      validateItems: (newDb) async {
        final [row] = await newDb.select(newDb.settings).get();
        expect(row.toJson(), {
          ...old.toJson(),
          'fajrRecording': 'makkah',
          'dhuhrRecording': 'makkah',
          'asrRecording': 'makkah',
          'maghribRecording': 'makkah',
          'ishaRecording': 'makkah',
        });
        expect((await newDb.select(newDb.prayerLog).get()).single.toJson(), prayed.toJson());
        expect((await newDb.select(newDb.qadaEntries).get()).single.toJson(), qada.toJson());
        expect((await newDb.select(newDb.savedDuas).get()).single.toJson(), saved.toJson());

        await newDb
            .update(newDb.settings)
            .write(const v5.SettingsCompanion(reminderMinutes: Value(25)));
        expect((await newDb.select(newDb.settings).getSingle()).reminderMinutes, 25);
        await expectLater(
          newDb.update(newDb.settings).write(const v5.SettingsCompanion(reminderMinutes: Value(7))),
          throwsA(anything),
        );
      },
    );
  });

  test('v5 to v6 keeps every row, a row with a place reads onboarded', () async {
    const placed = v5.SettingsData(
      id: 1,
      latitude: 21.4225,
      longitude: 39.8262,
      placeName: 'Makkah',
      countryCode: 'SA',
      timeZone: 'Asia/Riyadh',
      locationMode: 'auto',
      hijriAdjust: 0,
      digits: 'eastern',
      theme: 'iznik',
      themeMode: 'dark',
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
      fajrRecording: 'makkah',
      dhuhrRecording: 'madinah',
      asrRecording: 'makkah',
      maghribRecording: 'makkah',
      ishaRecording: 'makkah',
      reminderMinutes: 15,
      notificationsAsked: 1,
      tasbihDhikr: 1,
      tasbihCount: 5,
      azkarNudges: 1,
    );
    const prayed = v5.PrayerLogData(date: '2026-10-14', prayer: 'asr');

    await verifier.testWithDataIntegrity(
      oldVersion: 5,
      newVersion: 6,
      createOld: v5.DatabaseAtV5.new,
      createNew: v6.DatabaseAtV6.new,
      openTestedDatabase: AppDatabase.forTesting,
      createItems: (batch, oldDb) {
        batch
          ..insert(oldDb.settings, placed)
          ..insert(oldDb.prayerLog, prayed);
      },
      validateItems: (newDb) async {
        final row = await newDb.select(newDb.settings).getSingle();
        expect(row.toJson(), {...placed.toJson(), 'onboarded': 1});
        expect((await newDb.select(newDb.prayerLog).get()).single.toJson(), prayed.toJson());
      },
    );
  });

  test('v5 to v6 without a place reads not onboarded', () async {
    const fresh = v5.SettingsData(
      id: 1,
      hijriAdjust: 0,
      digits: 'eastern',
      theme: 'qiyamEmerald',
      themeMode: 'followSky',
      reduceMotion: 0,
      haptics: 1,
      uiSounds: 0,
      storeResetPending: 0,
      fajrSound: 'adhan',
      dhuhrSound: 'tone',
      asrSound: 'tone',
      maghribSound: 'adhan',
      ishaSound: 'tone',
      fajrRecording: 'makkah',
      dhuhrRecording: 'makkah',
      asrRecording: 'makkah',
      maghribRecording: 'makkah',
      ishaRecording: 'makkah',
      reminderMinutes: 10,
      notificationsAsked: 0,
      tasbihDhikr: 0,
      tasbihCount: 0,
      azkarNudges: 1,
    );

    await verifier.testWithDataIntegrity(
      oldVersion: 5,
      newVersion: 6,
      createOld: v5.DatabaseAtV5.new,
      createNew: v6.DatabaseAtV6.new,
      openTestedDatabase: AppDatabase.forTesting,
      createItems: (batch, oldDb) => batch.insert(oldDb.settings, fresh),
      validateItems: (newDb) async {
        final row = await newDb.select(newDb.settings).getSingle();
        expect(row.toJson(), {...fresh.toJson(), 'onboarded': 0});
      },
    );
  });

  test('v6 to v7 keeps every row, the countdown reads on', () async {
    const placed = v6.SettingsData(
      id: 1,
      latitude: 21.4225,
      longitude: 39.8262,
      placeName: 'Makkah',
      countryCode: 'SA',
      timeZone: 'Asia/Riyadh',
      locationMode: 'auto',
      hijriAdjust: 1,
      digits: 'western',
      theme: 'iznik',
      themeMode: 'dark',
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
      fajrRecording: 'makkah',
      dhuhrRecording: 'madinah',
      asrRecording: 'makkah',
      maghribRecording: 'makkah',
      ishaRecording: 'makkah',
      reminderMinutes: 15,
      notificationsAsked: 1,
      tasbihDhikr: 1,
      tasbihCount: 5,
      azkarNudges: 0,
      onboarded: 1,
    );
    const prayed = v6.PrayerLogData(date: '2026-10-14', prayer: 'asr');

    await verifier.testWithDataIntegrity(
      oldVersion: 6,
      newVersion: 7,
      createOld: v6.DatabaseAtV6.new,
      createNew: v7.DatabaseAtV7.new,
      openTestedDatabase: AppDatabase.forTesting,
      createItems: (batch, oldDb) {
        batch
          ..insert(oldDb.settings, placed)
          ..insert(oldDb.prayerLog, prayed);
      },
      validateItems: (newDb) async {
        final row = await newDb.select(newDb.settings).getSingle();
        expect(row.toJson(), {...placed.toJson(), 'prayerCountdown': 1});
        expect((await newDb.select(newDb.prayerLog).get()).single.toJson(), prayed.toJson());
      },
    );
  });

  test('v7 to v8 moves the count to the shown dhikr, Hijri and the glow on', () async {
    const placed = v7.SettingsData(
      id: 1,
      latitude: 21.4225,
      longitude: 39.8262,
      placeName: 'Makkah',
      countryCode: 'SA',
      timeZone: 'Asia/Riyadh',
      locationMode: 'auto',
      hijriAdjust: 1,
      digits: 'western',
      theme: 'iznik',
      themeMode: 'dark',
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
      fajrRecording: 'makkah',
      dhuhrRecording: 'madinah',
      asrRecording: 'makkah',
      maghribRecording: 'makkah',
      ishaRecording: 'makkah',
      reminderMinutes: 15,
      notificationsAsked: 1,
      tasbihDhikr: 1,
      tasbihCount: 12,
      azkarNudges: 0,
      prayerCountdown: 0,
      onboarded: 1,
    );
    const prayed = v7.PrayerLogData(date: '2026-10-14', prayer: 'asr');

    await verifier.testWithDataIntegrity(
      oldVersion: 7,
      newVersion: 8,
      createOld: v7.DatabaseAtV7.new,
      createNew: v8.DatabaseAtV8.new,
      openTestedDatabase: AppDatabase.forTesting,
      createItems: (batch, oldDb) {
        batch
          ..insert(oldDb.settings, placed)
          ..insert(oldDb.prayerLog, prayed);
      },
      validateItems: (newDb) async {
        final row = await newDb.select(newDb.settings).getSingle();
        final old = placed.toJson()..remove('tasbihCount');
        expect(row.toJson(), {
          ...old,
          'subhanallahCount': 0,
          'alhamdulillahCount': 12,
          'allahuAkbarCount': 0,
          'calendarMode': 'hijri',
          'topGlow': 1,
        });
        expect((await newDb.select(newDb.prayerLog).get()).single.toJson(), prayed.toJson());
      },
    );
  });

  test('v7 to v8 gives allahu akbar its count', () async {
    await verifier.testWithDataIntegrity(
      oldVersion: 7,
      newVersion: 8,
      createOld: v7.DatabaseAtV7.new,
      createNew: v8.DatabaseAtV8.new,
      openTestedDatabase: AppDatabase.forTesting,
      createItems: (batch, oldDb) => batch.insert(
        oldDb.settings,
        const v7.SettingsCompanion(tasbihDhikr: Value(2), tasbihCount: Value(34)),
      ),
      validateItems: (newDb) async {
        final row = await newDb.select(newDb.settings).getSingle();
        expect(
          (row.subhanallahCount, row.alhamdulillahCount, row.allahuAkbarCount, row.tasbihDhikr),
          (0, 0, 34, 2),
        );
      },
    );
  });

  test('v8 to v9 keeps every row, the language follows the phone', () async {
    const placed = v8.SettingsData(
      id: 1,
      latitude: 21.4225,
      longitude: 39.8262,
      placeName: 'Makkah',
      countryCode: 'SA',
      timeZone: 'Asia/Riyadh',
      locationMode: 'auto',
      hijriAdjust: 1,
      digits: 'western',
      theme: 'iznik',
      themeMode: 'dark',
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
      fajrRecording: 'makkah',
      dhuhrRecording: 'madinah',
      asrRecording: 'makkah',
      maghribRecording: 'makkah',
      ishaRecording: 'makkah',
      reminderMinutes: 15,
      notificationsAsked: 1,
      tasbihDhikr: 1,
      subhanallahCount: 0,
      alhamdulillahCount: 12,
      allahuAkbarCount: 0,
      azkarNudges: 0,
      prayerCountdown: 0,
      calendarMode: 'gregorian',
      topGlow: 0,
      onboarded: 1,
    );
    const prayed = v8.PrayerLogData(date: '2026-10-14', prayer: 'asr');

    await verifier.testWithDataIntegrity(
      oldVersion: 8,
      newVersion: 9,
      createOld: v8.DatabaseAtV8.new,
      createNew: v9.DatabaseAtV9.new,
      openTestedDatabase: AppDatabase.forTesting,
      createItems: (batch, oldDb) {
        batch
          ..insert(oldDb.settings, placed)
          ..insert(oldDb.prayerLog, prayed);
      },
      validateItems: (newDb) async {
        final row = await newDb.select(newDb.settings).getSingle();
        expect(row.toJson(), {...placed.toJson(), 'language': 'phone'});
        expect((await newDb.select(newDb.prayerLog).get()).single.toJson(), prayed.toJson());
      },
    );
  });

  test('v9 to v10 keeps every row, reads the quran defaults and two empty tables', () async {
    const placed = v9.SettingsData(
      id: 1,
      latitude: 21.4225,
      longitude: 39.8262,
      placeName: 'Makkah',
      countryCode: 'SA',
      timeZone: 'Asia/Riyadh',
      locationMode: 'auto',
      hijriAdjust: 1,
      digits: 'western',
      theme: 'iznik',
      themeMode: 'dark',
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
      fajrRecording: 'makkah',
      dhuhrRecording: 'madinah',
      asrRecording: 'makkah',
      maghribRecording: 'makkah',
      ishaRecording: 'makkah',
      reminderMinutes: 15,
      notificationsAsked: 1,
      tasbihDhikr: 1,
      subhanallahCount: 0,
      alhamdulillahCount: 12,
      allahuAkbarCount: 0,
      azkarNudges: 0,
      prayerCountdown: 0,
      calendarMode: 'gregorian',
      topGlow: 0,
      language: 'arabic',
      onboarded: 1,
    );
    const prayed = v9.PrayerLogData(date: '2026-10-14', prayer: 'asr');

    await verifier.testWithDataIntegrity(
      oldVersion: 9,
      newVersion: 10,
      createOld: v9.DatabaseAtV9.new,
      createNew: v10.DatabaseAtV10.new,
      openTestedDatabase: AppDatabase.forTesting,
      createItems: (batch, oldDb) {
        batch
          ..insert(oldDb.settings, placed)
          ..insert(oldDb.prayerLog, prayed);
      },
      validateItems: (newDb) async {
        final row = await newDb.select(newDb.settings).getSingle();
        expect(row.toJson(), {
          ...placed.toJson(),
          'lastReadSurah': 1,
          'lastReadAyah': 1,
          'lastReadPage': 1,
          'lastReadAt': null,
          'pageColor': 'followSky',
          'quranLayout': 'mushaf',
          'pageTurn': 'book',
          'keepScreenOn': 0,
          'quranArabicSize': 0,
          'quranTranslationSize': 0,
          'reciteSpeed': 1.0,
          'reciteRepeat': 1,
          'recitePause': 0,
        });
        expect((await newDb.select(newDb.prayerLog).get()).single.toJson(), prayed.toJson());
        expect(await newDb.select(newDb.quranBookmarks).get(), isEmpty);
        expect(await newDb.select(newDb.quranNotes).get(), isEmpty);
      },
    );
  });

  test('v10 to v11 keeps every row and reads amiri as the font', () async {
    await verifier.testWithDataIntegrity(
      oldVersion: 10,
      newVersion: 11,
      createOld: v10.DatabaseAtV10.new,
      createNew: v11.DatabaseAtV11.new,
      openTestedDatabase: AppDatabase.forTesting,
      createItems: (batch, oldDb) {
        batch.insert(
          oldDb.settings,
          const v10.SettingsCompanion(
            pageColor: Value('night'),
            pageTurn: Value('slide'),
            lastReadPage: Value(255),
          ),
        );
      },
      validateItems: (newDb) async {
        final row = await newDb.select(newDb.settings).getSingle();
        expect(
          (row.pageColor, row.pageTurn, row.lastReadPage, row.quranFont),
          ('night', 'slide', 255, 'amiri'),
        );
      },
    );
  });

  test('v11 to v12 turns both into translation and keeps the chosen font', () async {
    await verifier.testWithDataIntegrity(
      oldVersion: 11,
      newVersion: 12,
      createOld: v11.DatabaseAtV11.new,
      createNew: v12.DatabaseAtV12.new,
      openTestedDatabase: AppDatabase.forTesting,
      createItems: (batch, oldDb) {
        batch.insert(
          oldDb.settings,
          const v11.SettingsCompanion(
            quranLayout: Value('both'),
            quranFont: Value('amiri'),
            lastReadPage: Value(255),
          ),
        );
      },
      validateItems: (newDb) async {
        final row = await newDb.select(newDb.settings).getSingle();
        expect(
          (row.quranLayout, row.quranFont, row.lastReadPage, row.mushafSize),
          ('translation', 'amiri', 255, 0),
        );
      },
    );
  });

  test('v12 to v13 puts every prayer on madinah and keeps the rest', () async {
    await verifier.testWithDataIntegrity(
      oldVersion: 12,
      newVersion: 13,
      createOld: v12.DatabaseAtV12.new,
      createNew: v13.DatabaseAtV13.new,
      openTestedDatabase: AppDatabase.forTesting,
      createItems: (batch, oldDb) {
        batch.insert(
          oldDb.settings,
          const v12.SettingsCompanion(
            fajrRecording: Value('makkah'),
            asrRecording: Value('cairo'),
            ishaRecording: Value('takbir'),
            maghribSound: Value('tone'),
          ),
        );
      },
      validateItems: (newDb) async {
        final row = await newDb.select(newDb.settings).getSingle();
        expect(
          {
            row.fajrRecording,
            row.dhuhrRecording,
            row.asrRecording,
            row.maghribRecording,
            row.ishaRecording,
          },
          {'madinah'},
        );
        expect(row.maghribSound, 'tone');
      },
    );
  });

  test('v13 to v14 moves the removed recordings to madinah and keeps the rest', () async {
    await verifier.testWithDataIntegrity(
      oldVersion: 13,
      newVersion: 14,
      createOld: v13.DatabaseAtV13.new,
      createNew: v14.DatabaseAtV14.new,
      openTestedDatabase: AppDatabase.forTesting,
      createItems: (batch, oldDb) {
        batch.insert(
          oldDb.settings,
          const v13.SettingsCompanion(
            dhuhrRecording: Value('aaqibAzeez'),
            asrRecording: Value('andrewler'),
            maghribRecording: Value('synagda'),
            maghribSound: Value('tone'),
          ),
        );
      },
      validateItems: (newDb) async {
        final row = await newDb.select(newDb.settings).getSingle();
        expect(
          {
            row.fajrRecording,
            row.dhuhrRecording,
            row.asrRecording,
            row.maghribRecording,
            row.ishaRecording,
          },
          {'madinah'},
        );
        expect(row.maghribSound, 'tone');
      },
    );
  });

  test('v14 to v15 moves madinah to alafasy and keeps the rest', () async {
    await verifier.testWithDataIntegrity(
      oldVersion: 14,
      newVersion: 15,
      createOld: v14.DatabaseAtV14.new,
      createNew: v15.DatabaseAtV15.new,
      openTestedDatabase: AppDatabase.forTesting,
      createItems: (batch, oldDb) {
        batch.insert(
          oldDb.settings,
          const v14.SettingsCompanion(
            maghribRecording: Value('madinah'),
            maghribSound: Value('tone'),
          ),
        );
      },
      validateItems: (newDb) async {
        final row = await newDb.select(newDb.settings).getSingle();
        expect(
          {
            row.fajrRecording,
            row.dhuhrRecording,
            row.asrRecording,
            row.maghribRecording,
            row.ishaRecording,
          },
          {'alafasy'},
        );
        expect(row.maghribSound, 'tone');
      },
    );
  });
}
