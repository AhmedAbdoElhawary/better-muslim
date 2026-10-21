import 'package:better_muslim/core/database/app_database.dart';
import 'package:drift/drift.dart';

/// every table a backup carries. a new table must be added here and to copyTables, the restore
/// test fails until it is
const backupTables = [
  'settings',
  'prayer_log',
  'qada_entries',
  'azkar_counts',
  'saved_duas',
  'quran_bookmarks',
  'quran_notes',
];

/// the backup's data in place of this phone's, all or nothing. the columns that belong to the
/// phone stay (data-model.md)
Future<void> restore(AppDatabase into, AppDatabase from) => into.transaction(() async {
  final mine = await (into.select(
    into.settings,
  )..where((row) => row.id.equals(1))).getSingleOrNull();
  await copyTables(from, into);
  await into.updateSettings(
    SettingsCompanion(
      onboarded: Value(mine?.onboarded ?? false),
      notificationsAsked: Value(mine?.notificationsAsked ?? false),
      storeResetPending: Value(mine?.storeResetPending ?? false),
    ),
  );
});

/// a typed copy of every table, so drift tells every stream and the screens update. the settings
/// row is replaced, never deleted, home watches it
Future<void> copyTables(AppDatabase from, AppDatabase into) async {
  final settings = await (from.select(
    from.settings,
  )..where((row) => row.id.equals(1))).getSingleOrNull();
  final log = await from.select(from.prayerLog).get();
  final qada = await from.select(from.qadaEntries).get();
  final azkar = await from.select(from.azkarCounts).get();
  final duas = await from.select(from.savedDuas).get();
  final bookmarks = await from.select(from.quranBookmarks).get();
  final notes = await from.select(from.quranNotes).get();
  await into.batch((batch) {
    if (settings != null) batch.insert(into.settings, settings, mode: InsertMode.insertOrReplace);
    batch
      ..deleteAll(into.prayerLog)
      ..deleteAll(into.qadaEntries)
      ..deleteAll(into.azkarCounts)
      ..deleteAll(into.savedDuas)
      ..deleteAll(into.quranBookmarks)
      ..deleteAll(into.quranNotes)
      ..insertAll(into.prayerLog, log)
      ..insertAll(into.qadaEntries, qada)
      ..insertAll(into.azkarCounts, azkar)
      ..insertAll(into.savedDuas, duas)
      ..insertAll(into.quranBookmarks, bookmarks)
      ..insertAll(into.quranNotes, notes);
  });
}
