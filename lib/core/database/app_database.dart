import 'dart:io';

import 'package:better_muslim/core/database/app_database.steps.dart';
import 'package:better_muslim/core/database/backup_exclusion.dart';
import 'package:better_muslim/core/database/civil_date.dart';
import 'package:better_muslim/core/database/database_key.dart';
import 'package:better_muslim/core/monitoring/crash_reporter.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_method.dart';
import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/resources/design/bm_theme.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:drift/drift.dart';
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

@DriftDatabase(tables: [Settings, PrayerLog, QadaEntries])
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

  /// its own function, so the setup closure sent to drift's isolate captures only sendable values
  static AppDatabase _connect(File file, String key) => AppDatabase._(
    driftDatabase(
      name: _name,
      native: DriftNativeOptions(
        databasePath: () async => file.path,
        setup: (db) => db.execute("pragma key = '$key'"),
      ),
    ),
  );

  @override
  int get schemaVersion => 2;

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
    ),
  );

  /// an existing row keeps its first use, now is passed so tests and the scenario control it
  Stream<AppSettings> watchSettings({DateTime? now}) async* {
    await into(settings).insert(
      SettingsCompanion(firstUse: Value((now ?? DateTime.now()).toLocal())),
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
  Future<void> unmarkPrayed(DateTime day, Prayer prayer) => (delete(
    prayerLog,
  )..where((row) => row.date.equalsValue(day) & row.prayer.equalsValue(prayer))).go();
}
