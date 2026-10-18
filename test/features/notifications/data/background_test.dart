import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/notifications/data/background.dart';
import 'package:better_muslim/features/notifications/domain/alert.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart';

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
}
