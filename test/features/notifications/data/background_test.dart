import 'package:better_muslim/core/azkar/azkar_content.dart';
import 'package:better_muslim/core/azkar/azkar_window.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/settings/adhan_recording.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/notifications/data/background.dart';
import 'package:better_muslim/features/notifications/domain/alert.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart';

import '../../../helpers/notifications.dart';
import '../../../helpers/phone_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;

  setUpAll(tz.initializeTimeZones);

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
  });

  String payload(Prayer prayer, DateTime day, {int hour = 17}) => payloadOf(
    Alert(
      day: day,
      prayer: prayer,
      kind: AlertKind.adhan,
      at: TZDateTime(getLocation('Asia/Riyadh'), day.year, day.month, day.day, hour),
      sound: PrayerSound.adhan,
    ),
  );

  Future<List<PrayerLogData>> log() => db.select(db.prayerLog).get();

  test('logs the payload\'s day and prayer once, twice changes nothing', () async {
    final maghrib = payload(Prayer.maghrib, DateTime(2026, 10, 15));

    await markFromPayload(maghrib, db: db);
    await markFromPayload(maghrib, db: db);

    final [row] = await log();
    expect(row.date, DateTime(2026, 10, 15));
    expect(row.prayer, Prayer.maghrib);
  });

  test('isha marked after midnight lands on the day it started', () async {
    await markFromPayload(payload(Prayer.isha, DateTime(2026, 10, 14), hour: 19), db: db);

    expect((await log()).single.date, DateTime(2026, 10, 14));
  });

  test('a prayer that has passed is logged the same way (FR-038)', () async {
    await markFromPayload(payload(Prayer.fajr, DateTime(2026, 10, 1), hour: 5), db: db);

    expect((await log()).single.prayer, Prayer.fajr);
  });

  test('no store to open does nothing and never makes one', () async {
    final folder = usePhoneStorage();

    await markFromPayload(payload(Prayer.maghrib, DateTime(2026, 10, 15)));

    expect(folder.listSync(), isEmpty);
  });

  group('the azkar nudges in the top-up (US6)', () {
    TZDateTime makkah(int hour, int minute) =>
        TZDateTime(getLocation('Asia/Riyadh'), 2026, 10, 15, hour, minute);

    Future<List<Alert>> nudgesAt(DateTime now) async {
      final scheduler = FakeScheduler();
      await topUp(
        db,
        scheduler: scheduler,
        locale: const Locale('en'),
        use24h: true,
        phoneZone: 'Asia/Riyadh',
        now: now,
      );
      return [
        for (final alert in scheduler.applied.single)
          if (alert.kind == AlertKind.azkar) alert,
      ];
    }

    setUp(() async {
      muteAdhanChannel();
      await db.watchSettings().first;
      await db.updateSettings(
        const SettingsCompanion(
          latitude: Value(21.4225),
          longitude: Value(39.8262),
          placeName: Value('Makkah'),
          countryCode: Value('SA'),
          timeZone: Value('Asia/Riyadh'),
          locationMode: Value(LocationMode.manual),
        ),
      );
    });

    test('each prayer\'s recording goes to the scheduler', () async {
      await db.updateSettings(
        const SettingsCompanion(maghribRecording: Value(AdhanRecording.madinah)),
      );
      final scheduler = FakeScheduler();
      await topUp(
        db,
        scheduler: scheduler,
        locale: const Locale('en'),
        use24h: true,
        phoneZone: 'Asia/Riyadh',
        now: makkah(9, 0),
      );
      final recordings = scheduler.appliedRecordings.single;
      expect(recordings[Prayer.maghrib], AdhanRecording.madinah);
      expect(recordings[Prayer.fajr], AdhanRecording.makkah);
    });

    test('on by default: 3 quiet nudges, tonight\'s first before asr + 20', () async {
      final nudges = await nudgesAt(makkah(15, 30));

      expect(nudges, hasLength(3));
      expect((nudges.first.day, nudges.first.prayer), (DateTime(2026, 10, 15), Prayer.asr));
      expect(nudges.every((nudge) => nudge.sound == PrayerSound.silent), isTrue);
    });

    test('a finished evening set skips tonight\'s nudge', () async {
      final content = await loadAzkarContent();
      for (final zikr in content.evening.items) {
        await db.setZikrCount(AzkarSet.evening, DateTime(2026, 10, 15), zikr.id, zikr.count);
      }
      final nudges = await nudgesAt(makkah(15, 30));

      expect((nudges.first.day, nudges.first.prayer), (DateTime(2026, 10, 16), Prayer.fajr));
    });

    test('the switch off schedules none', () async {
      await db.updateSettings(const SettingsCompanion(azkarNudges: Value(false)));

      expect(await nudgesAt(makkah(15, 30)), isEmpty);
    });
  });
}
