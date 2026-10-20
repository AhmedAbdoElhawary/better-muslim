import 'package:better_muslim/core/azkar/azkar_window.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// a store with a row in every table, the phone's own columns on
Future<AppDatabase> seededStore() async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await db.updateSettings(
    SettingsCompanion(
      latitude: const Value(21.4225),
      longitude: const Value(39.8262),
      placeName: const Value('Makkah'),
      placeNameAr: const Value('مكة المكرمة'),
      countryCode: const Value('SA'),
      timeZone: const Value('Asia/Riyadh'),
      locationMode: const Value(LocationMode.manual),
      theme: const Value(BmThemeId.iznik),
      dhuhrSound: const Value(PrayerSound.silent),
      reminderMinutes: const Value(15),
      tasbihCount: const Value(21),
      firstUse: Value(DateTime(2026, 10, 1)),
      onboarded: const Value(true),
      notificationsAsked: const Value(true),
      storeResetPending: const Value(true),
    ),
  );
  await db.markPrayed(DateTime(2026, 10, 15), Prayer.asr);
  await db.markPrayed(DateTime(2026, 10, 14), Prayer.fajr);
  await db
      .into(db.qadaEntries)
      .insert(
        QadaEntriesCompanion.insert(
          prayer: Prayer.isha,
          missedOn: Value(DateTime(2026, 10, 13)),
          madeUpAt: Value(DateTime.utc(2026, 10, 16, 20)),
        ),
      );
  await db.into(db.qadaEntries).insert(QadaEntriesCompanion.insert(prayer: Prayer.fajr));
  await db.setZikrCount(AzkarSet.morning, DateTime(2026, 10, 15), 'ayat-kursi', 1);
  await db.saveDua('travel-1', at: DateTime.utc(2026, 10, 12, 9));
  return db;
}
