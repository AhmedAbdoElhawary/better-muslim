import 'dart:convert';
import 'dart:io';

import 'package:better_muslim/core/azkar/azkar_window.dart';
import 'package:better_muslim/core/database/app_database.steps.dart';
import 'package:better_muslim/core/database/backup_exclusion.dart';
import 'package:better_muslim/core/database/civil_date.dart';
import 'package:better_muslim/core/database/database_key.dart';
import 'package:better_muslim/core/monitoring/crash_reporter.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_method.dart';
import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/resources/design/bm_theme.dart';
import 'package:better_muslim/core/settings/adhan_recording.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider is overridden in bootstrap'),
);

/// one row, id 1. enums are stored by name, so reordering one never changes saved data
@DataClassName('AppSettings')
class Settings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();

  /// null = no location yet
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  TextColumn get placeName => text().nullable()();
  TextColumn get placeNameAr => text().nullable()();
  TextColumn get regionName => text().nullable()();
  TextColumn get regionNameAr => text().nullable()();
  TextColumn get countryCode => text().nullable()();

  /// the place's zone, used in manual mode
  TextColumn get timeZone => text().nullable()();
  TextColumn get locationMode => textEnum<LocationMode>().nullable()();

  /// null = by country, a value = picked by the user and kept when the location changes
  TextColumn get method => textEnum<PrayerMethod>().nullable()();
  TextColumn get asrMethod => textEnum<AsrMethod>().nullable()();
  IntColumn get hijriAdjust =>
      // ignore: recursive_getters, drift reads the column inside its own check
      integer().withDefault(const Constant(0)).check(hijriAdjust.isBetweenValues(-2, 2))();

  /// literal names, so drift exports the schema without running flutter code (the theme enums)
  TextColumn get digits => textEnum<Digits>().withDefault(const Constant('eastern'))();
  TextColumn get theme => textEnum<BmThemeId>().withDefault(const Constant('qiyamEmerald'))();
  TextColumn get themeMode => textEnum<BmThemeMode>().withDefault(const Constant('followSky'))();
  BoolColumn get reduceMotion => boolean().withDefault(const Constant(false))();
  BoolColumn get haptics => boolean().withDefault(const Constant(true))();
  BoolColumn get uiSounds => boolean().withDefault(const Constant(false))();

  /// set by a store reset, cleared once the user has been told (milestone 10)
  BoolColumn get storeResetPending => boolean().withDefault(const Constant(false))();

  /// the strip's earliest week. the v2 migration fills it with the upgrade date
  TextColumn get firstUse => text().map(const CivilDate()).nullable()();

  TextColumn get fajrSound => textEnum<PrayerSound>().withDefault(const Constant('adhan'))();
  TextColumn get dhuhrSound => textEnum<PrayerSound>().withDefault(const Constant('tone'))();
  TextColumn get asrSound => textEnum<PrayerSound>().withDefault(const Constant('tone'))();
  TextColumn get maghribSound => textEnum<PrayerSound>().withDefault(const Constant('adhan'))();
  TextColumn get ishaSound => textEnum<PrayerSound>().withDefault(const Constant('tone'))();

  /// each prayer's own recording, android fixes a channel's sound so it can't be one for all
  TextColumn get fajrRecording =>
      textEnum<AdhanRecording>().withDefault(const Constant('makkah'))();
  TextColumn get dhuhrRecording =>
      textEnum<AdhanRecording>().withDefault(const Constant('makkah'))();
  TextColumn get asrRecording => textEnum<AdhanRecording>().withDefault(const Constant('makkah'))();
  TextColumn get maghribRecording =>
      textEnum<AdhanRecording>().withDefault(const Constant('makkah'))();
  TextColumn get ishaRecording =>
      textEnum<AdhanRecording>().withDefault(const Constant('makkah'))();

  /// minutes before each prayer, 0 is off
  IntColumn get reminderMinutes => integer()
      .withDefault(const Constant(10))
      // ignore: recursive_getters, drift reads the column inside its own check
      .check(reminderMinutes.isIn(const [0, 5, 10, 15, 20, 25, 30]))();

  /// true once 4.12 or the off line asked the phone, after that the off line opens settings
  BoolColumn get notificationsAsked => boolean().withDefault(const Constant(false))();

  /// 0 subhanallah, 1 alhamdulillah, 2 allahu akbar
  IntColumn get tasbihDhikr => integer()
      .withDefault(const Constant(0))
      // ignore: recursive_getters, drift reads the column inside its own check
      .check(tasbihDhikr.isBetweenValues(0, 2))();
  IntColumn get subhanallahCount => integer()
      .withDefault(const Constant(0))
      // ignore: recursive_getters, drift reads the column inside its own check
      .check(subhanallahCount.isBiggerOrEqualValue(0))();
  IntColumn get alhamdulillahCount => integer()
      .withDefault(const Constant(0))
      // ignore: recursive_getters, drift reads the column inside its own check
      .check(alhamdulillahCount.isBiggerOrEqualValue(0))();
  IntColumn get allahuAkbarCount => integer()
      .withDefault(const Constant(0))
      // ignore: recursive_getters, drift reads the column inside its own check
      .check(allahuAkbarCount.isBiggerOrEqualValue(0))();

  /// the window last opened, the azkar tab's badge goes once it's the current one
  TextColumn get morningOpenedOn => text().map(const CivilDate()).nullable()();
  TextColumn get eveningOpenedOn => text().map(const CivilDate()).nullable()();
  BoolColumn get azkarNudges => boolean().withDefault(const Constant(true))();

  /// Countdown before each prayer
  BoolColumn get prayerCountdown => boolean().withDefault(const Constant(true))();

  TextColumn get calendarMode => textEnum<CalendarMode>().withDefault(const Constant('hijri'))();
  BoolColumn get topGlow => boolean().withDefault(const Constant(true))();
  TextColumn get language => textEnum<Language>().withDefault(const Constant('phone'))();

  /// belongs to the phone, a backup never carries it (milestone 10 FR-030)
  BoolColumn get onboarded => boolean().withDefault(const Constant(false))();

  IntColumn get lastReadSurah => integer().withDefault(const Constant(1))();
  IntColumn get lastReadAyah => integer().withDefault(const Constant(1))();
  IntColumn get lastReadPage => integer()
      .withDefault(const Constant(1))
      // ignore: recursive_getters, drift reads the column inside its own check
      .check(lastReadPage.isBetweenValues(1, 604))();

  /// null = never read, the card shows no time
  DateTimeColumn get lastReadAt => dateTime().nullable()();
  TextColumn get pageColor => textEnum<PageColor>().withDefault(const Constant('followSky'))();
  TextColumn get quranLayout => textEnum<QuranLayout>().withDefault(const Constant('mushaf'))();
  TextColumn get pageTurn => textEnum<PageTurn>().withDefault(const Constant('book'))();
  BoolColumn get keepScreenOn => boolean().withDefault(const Constant(false))();
  TextColumn get quranFont => textEnum<QuranFont>().withDefault(const Constant('kfgqpc'))();

  /// 10% steps around the printed page, above 0 the lines rewrap
  IntColumn get mushafSize => integer()
      .withDefault(const Constant(0))
      // ignore: recursive_getters, drift reads the column inside its own check
      .check(mushafSize.isBetweenValues(-2, 5))();

  /// steps around 4.07's size
  IntColumn get quranArabicSize => integer()
      .withDefault(const Constant(0))
      // ignore: recursive_getters, drift reads the column inside its own check
      .check(quranArabicSize.isBetweenValues(-2, 3))();
  IntColumn get quranTranslationSize => integer()
      .withDefault(const Constant(0))
      // ignore: recursive_getters, drift reads the column inside its own check
      .check(quranTranslationSize.isBetweenValues(-2, 3))();
  RealColumn get reciteSpeed => real()
      .withDefault(const Constant(1.0))
      // ignore: recursive_getters, drift reads the column inside its own check
      .check(reciteSpeed.isIn(const [0.75, 1.0, 1.25, 1.5]))();

  /// 1 is off
  IntColumn get reciteRepeat => integer()
      .withDefault(const Constant(1))
      // ignore: recursive_getters, drift reads the column inside its own check
      .check(reciteRepeat.isIn(const [1, 2, 3, 5, 10]))();

  /// seconds between ayahs
  IntColumn get recitePause => integer()
      .withDefault(const Constant(0))
      // ignore: recursive_getters, drift reads the column inside its own check
      .check(recitePause.isIn(const [0, 1, 2, 3, 5]))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class PrayerLog extends Table {
  /// the prayer day the prayer belongs to, not the clock time it was marked
  TextColumn get date => text().map(const CivilDate())();
  TextColumn get prayer => textEnum<Prayer>()();

  @override
  Set<Column<Object>> get primaryKey => {date, prayer};
}

/// sqlite nulls are distinct, so dateless entries never collide on the index
@TableIndex(name: 'qada_day', columns: {#missedOn, #prayer}, unique: true)
class QadaEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get prayer => textEnum<Prayer>()();

  /// null = missed before using the app
  TextColumn get missedOn => text().map(const CivilDate()).nullable()();

  /// null = still open
  DateTimeColumn get madeUpAt => dateTime().nullable()();
}

/// only the latest window of each set, older days go on the first count of a new one
class AzkarCounts extends Table {
  TextColumn get setId => textEnum<AzkarSet>()();

  /// the window's prayer day
  TextColumn get day => text().map(const CivilDate())();

  /// the item's id in azkar.json
  TextColumn get zikr => text()();
  IntColumn get count => integer()();

  @override
  Set<Column<Object>> get primaryKey => {setId, day, zikr};
}

class SavedDuas extends Table {
  /// the dua's id in duas.json
  TextColumn get dua => text()();
  DateTimeColumn get savedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {dua};
}

/// sqlite nulls are distinct, so page bookmarks need their own index
@TableIndex(name: 'quran_bookmark_ayah', columns: {#surah, #ayah}, unique: true)
@TableIndex.sql(
  'create unique index quran_bookmark_page on quran_bookmarks (page) where surah is null',
)
class QuranBookmarks extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// null for a page bookmark
  IntColumn get surah => integer().nullable()();
  IntColumn get ayah => integer().nullable()();

  /// always set, the ayah's page for an ayah bookmark
  // ignore: recursive_getters, drift reads the column inside its own check
  IntColumn get page => integer().check(page.isBetweenValues(1, 604))();

  /// null shows the reference
  TextColumn get name => text().nullable()();
  TextColumn get color => textEnum<RibbonColor>()();
  DateTimeColumn get createdAt => dateTime()();
}

/// one note per ayah
class QuranNotes extends Table {
  IntColumn get surah => integer()();
  IntColumn get ayah => integer()();

  // ignore: recursive_getters, drift reads the column inside its own check
  TextColumn get note => text().check(note.trim().length.isBiggerThanValue(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {surah, ayah};
}

@DriftDatabase(
  tables: [Settings, PrayerLog, QadaEntries, AzkarCounts, SavedDuas, QuranBookmarks, QuranNotes],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._(super.executor);

  AppDatabase.forTesting(super.executor);

  static const _name = 'better_muslim';

  /// a store that can't be opened starts fresh instead of crashing, and remembers it (FR-024)
  static Future<AppDatabase> open() async {
    /// Documents is backed up and shown in the Files app, Application Support is not
    final directory = await getApplicationSupportDirectory();
    final file = File('${directory.path}/$_name.sqlite');
    final key = await DatabaseKey.read();
    if (key == null && file.existsSync()) {
      return _reset(file, StateError('store file without a key'), StackTrace.current, 'no key');
    }
    final db = _connect(file, key ?? await DatabaseKey.create());
    try {
      await db.customSelect('select count(*) from sqlite_master').get();
    } catch (error, stack) {
      /// a wrong key and a broken file both land here, the error itself says which
      await db.close();
      return _reset(file, error, stack, 'cannot open');
    }
    if (Platform.isIOS) await BackupExclusion.exclude(file.path);
    return db;
  }

  /// background code must never reset the store, a locked keychain there is not a lost key
  static Future<AppDatabase?> openExisting() async {
    final directory = await getApplicationSupportDirectory();
    final file = File('${directory.path}/$_name.sqlite');
    final key = await DatabaseKey.read();
    if (key == null || !file.existsSync()) return null;
    final db = _connect(file, key);
    try {
      await db.customSelect('select count(*) from sqlite_master').get();
      return db;
    } catch (_) {
      await db.close();
      return null;
    }
  }

  /// only the reason is reported, never the path or anything from the store
  static Future<AppDatabase> _reset(
    File file,
    Object error,
    StackTrace stack,
    String reason,
  ) async {
    await CrashReporter.instance.recordError(error, stack, context: {'reason': reason});
    for (final suffix in ['', '-wal', '-shm', '-journal']) {
      final leftover = File('${file.path}$suffix');
      if (leftover.existsSync()) leftover.deleteSync();
    }
    final db = _connect(file, await DatabaseKey.create());
    await db.updateSettings(const SettingsCompanion(storeResetPending: Value(true)));
    if (Platform.isIOS) await BackupExclusion.exclude(file.path);
    return db;
  }

  /// a backup's store, locked with the password (contracts/backup-file.md). hex, so any password
  /// works with no quoting
  static AppDatabase backup(File file, String password) {
    final key = utf8.encode(password).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    return AppDatabase._(
      NativeDatabase.createInBackground(
        file,
        setup: (db) => db
          ..execute("pragma cipher = 'chacha20'")
          ..execute('pragma kdf_iter = 600000')
          ..execute("pragma hexkey = '$key'"),
      ),
    );
  }

  /// its own function, so the setup closure sent to drift's isolate captures only sendable values
  static AppDatabase _connect(File file, String key) => AppDatabase._(
    driftDatabase(
      name: _name,
      native: DriftNativeOptions(
        databasePath: () async => file.path,

        /// a mark from a notification's background engine shows in the app's streams at once
        shareAcrossIsolates: true,
        setup: (db) => db.execute("pragma key = '$key'"),
      ),
    ),
  );

  @override
  int get schemaVersion => 12;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: stepByStep(
      from1To2: (m, schema) async {
        await m.createTable(schema.prayerLog);
        await m.createTable(schema.qadaEntries);
        await m.createIndex(schema.qadaDay);
        await m.addColumn(schema.settings, schema.settings.firstUse);

        /// sqlite can't add a column with a non constant default
        await customStatement("update settings set first_use = date('now', 'localtime')");
      },
      from2To3: (m, schema) async {
        for (final column in [
          schema.settings.fajrSound,
          schema.settings.dhuhrSound,
          schema.settings.asrSound,
          schema.settings.maghribSound,
          schema.settings.ishaSound,
          schema.settings.reminderMinutes,
          schema.settings.notificationsAsked,
        ]) {
          await m.addColumn(schema.settings, column);
        }
      },
      from3To4: (m, schema) async {
        for (final column in [
          schema.settings.tasbihDhikr,
          schema.settings.tasbihCount,
          schema.settings.morningOpenedOn,
          schema.settings.eveningOpenedOn,
          schema.settings.azkarNudges,
        ]) {
          await m.addColumn(schema.settings, column);
        }
        await m.createTable(schema.azkarCounts);
        await m.createTable(schema.savedDuas);
      },
      from4To5: (m, schema) async {
        /// watchSettings added a row on every open before v5, only row 1 is ever read
        await customStatement('delete from settings where id != 1');

        /// sqlite can't change a check in place, the table is remade with every row kept
        await m.alterTable(
          TableMigration(
            schema.settings,
            newColumns: [
              schema.settings.fajrRecording,
              schema.settings.dhuhrRecording,
              schema.settings.asrRecording,
              schema.settings.maghribRecording,
              schema.settings.ishaRecording,
            ],
          ),
        );
      },
      from5To6: (m, schema) async {
        await m.addColumn(schema.settings, schema.settings.onboarded);

        /// an install from before onboarding with a place has already set the app up (FR-001)
        await customStatement('update settings set onboarded = 1 where latitude is not null');
      },
      from6To7: (m, schema) async {
        await m.addColumn(schema.settings, schema.settings.prayerCountdown);
      },
      from7To8: (m, schema) async {
        /// sqlite can't drop a column with a check, the table is remade with every row kept
        await m.alterTable(
          TableMigration(
            schema.settings,
            newColumns: [schema.settings.calendarMode, schema.settings.topGlow],
            columnTransformer: {
              schema.settings.subhanallahCount: const CustomExpression<int>(
                'case when tasbih_dhikr = 0 then tasbih_count else 0 end',
              ),
              schema.settings.alhamdulillahCount: const CustomExpression<int>(
                'case when tasbih_dhikr = 1 then tasbih_count else 0 end',
              ),
              schema.settings.allahuAkbarCount: const CustomExpression<int>(
                'case when tasbih_dhikr = 2 then tasbih_count else 0 end',
              ),
            },
          ),
        );
      },
      from8To9: (m, schema) async {
        await m.addColumn(schema.settings, schema.settings.language);
      },
      from9To10: (m, schema) async {
        for (final column in [
          schema.settings.lastReadSurah,
          schema.settings.lastReadAyah,
          schema.settings.lastReadPage,
          schema.settings.lastReadAt,
          schema.settings.pageColor,
          schema.settings.quranLayout,
          schema.settings.pageTurn,
          schema.settings.keepScreenOn,
          schema.settings.quranArabicSize,
          schema.settings.quranTranslationSize,
          schema.settings.reciteSpeed,
          schema.settings.reciteRepeat,
          schema.settings.recitePause,
        ]) {
          await m.addColumn(schema.settings, column);
        }
        await m.createTable(schema.quranBookmarks);
        await m.createIndex(schema.quranBookmarkAyah);
        await m.createIndex(schema.quranBookmarkPage);
        await m.createTable(schema.quranNotes);
      },
      from10To11: (m, schema) async {
        await m.addColumn(schema.settings, schema.settings.quranFont);
      },
      from11To12: (m, schema) async {
        /// sqlite can't change a default in place, the table is remade with every row kept. Both
        /// is gone, Translation shows the page now
        await m.alterTable(
          TableMigration(
            schema.settings,
            newColumns: [schema.settings.mushafSize],
            columnTransformer: {
              schema.settings.quranLayout: const CustomExpression<String>(
                "case when quran_layout = 'both' then 'translation' else quran_layout end",
              ),
            },
          ),
        );
      },
    ),
  );

  /// an existing row keeps its first use, now is passed so tests and the scenario control it
  Stream<AppSettings> watchSettings({DateTime? now}) async* {
    /// the id is given, sqlite hands an integer primary key a new rowid instead of its default
    await into(settings).insert(
      SettingsCompanion(id: const Value(1), firstUse: Value((now ?? DateTime.now()).toLocal())),
      mode: InsertMode.insertOrIgnore,
    );
    yield* (select(settings)..where((row) => row.id.equals(1))).watchSingle();
  }

  /// only the columns in values change. Value(null) on method or asrMethod goes back to by country
  Future<void> updateSettings(SettingsCompanion values) =>
      into(settings).insertOnConflictUpdate(values.copyWith(id: const Value(1)));

  /// a plain call with no riverpod, so milestone 5 can log from a notification. twice is once
  Future<void> markPrayed(DateTime day, Prayer prayer) => into(prayerLog).insert(
    PrayerLogCompanion.insert(date: day, prayer: prayer),
    mode: InsertMode.insertOrIgnore,
  );

  /// a plain call with no riverpod, like markPrayed
  Future<bool> isPrayed(DateTime day, Prayer prayer) async =>
      await (select(prayerLog)
            ..where((row) => row.date.equalsValue(day) & row.prayer.equalsValue(prayer)))
          .getSingleOrNull() !=
      null;

  /// a plain call with no riverpod, like markPrayed
  Future<void> unmarkPrayed(DateTime day, Prayer prayer) => (delete(
    prayerLog,
  )..where((row) => row.date.equalsValue(day) & row.prayer.equalsValue(prayer))).go();

  /// a plain call with no riverpod, the background top-up reads it too. zikr id to its count
  Future<Map<String, int>> zikrCounts(AzkarSet set, DateTime day) async {
    final rows = await (select(
      azkarCounts,
    )..where((row) => row.setId.equalsValue(set) & row.day.equalsValue(day))).get();
    return {for (final row in rows) row.zikr: row.count};
  }

  /// nothing reads an older window, so they go here instead of piling up
  Future<void> setZikrCount(AzkarSet set, DateTime day, String zikr, int count) =>
      transaction(() async {
        await (delete(azkarCounts)..where(
              (row) =>
                  row.setId.equalsValue(set) &
                  row.day.isSmallerThanValue(const CivilDate().toSql(day)),
            ))
            .go();
        await into(azkarCounts).insertOnConflictUpdate(
          AzkarCountsCompanion.insert(setId: set, day: day, zikr: zikr, count: count),
        );
      });

  /// undo passes the old savedAt, so the dua goes back to its place in the list
  Future<void> saveDua(String dua, {DateTime? at}) => into(savedDuas)
      .insertOnConflictUpdate(SavedDuasCompanion.insert(dua: dua, savedAt: at ?? DateTime.now()));

  /// settings, tasbih, azkar and saved duas stay (FR-032)
  Future<void> resetPrayerJourney() => transaction(() async {
    await delete(prayerLog).go();
    await delete(qadaEntries).go();
  });

  Future<void> unsaveDua(String dua) =>
      (delete(savedDuas)..where((row) => row.dua.equals(dua))).go();
}
