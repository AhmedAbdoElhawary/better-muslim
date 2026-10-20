import 'dart:convert';
import 'dart:ui';

import 'package:better_muslim/core/app/app_localizations.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/monitoring/crash_reporter.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/surfaces/surface_data.dart';
import 'package:better_muslim/core/surfaces/write_surfaces.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../helpers/home.dart';
import '../../helpers/surfaces.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FakeSurfacesChannel channel;
  late tz.Location riyadh;

  setUpAll(() async {
    tz.initializeTimeZones();
    await initializeDateFormatting();
    riyadh = tz.getLocation('Asia/Riyadh');
  });

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    channel = FakeSurfacesChannel();
  });

  tearDown(() async {
    CrashReporter.instance = const DebugCrashReporter();
    await db.close();
  });

  Future<void> placeInMakkah() => db.updateSettings(
    const SettingsCompanion(
      latitude: Value(21.4225),
      longitude: Value(39.8262),
      placeName: Value('Makkah'),
      placeNameAr: Value('مكة المكرمة'),
      countryCode: Value('SA'),
      timeZone: Value('Asia/Riyadh'),
      locationMode: Value(LocationMode.manual),
    ),
  );

  DateTime at(int day, int hour, int minute) => tz.TZDateTime(riyadh, 2026, 10, day, hour, minute);

  Future<DateTime?> write(DateTime now, {bool force = false}) => writeSurfaces(
    db,
    channel: channel,
    locale: const Locale('en'),
    use24h: true,
    phoneZone: 'Asia/Riyadh',
    force: force,
    now: now,
  );

  test('one update with the builder\'s json for the store, the prayer day\'s marks', () async {
    await placeInMakkah();
    final day = DateTime(2026, 10, 15);
    await db.markPrayed(day, Prayer.fajr);
    await db.markPrayed(day, Prayer.dhuhr);
    await db.markPrayed(DateTime(2026, 10, 14), Prayer.asr);
    final now = at(15, 16, 32);

    await write(now);

    final settings = await db.watchSettings().first;
    final expected = buildSurfaceData(
      now: now,
      location: locationOf(savedPlaceOf(settings)!, 'Asia/Riyadh'),
      settings: settings,
      prayed: {Prayer.fajr, Prayer.dhuhr},
      l10n: await AppLocalizations.load(const Locale('en')),
      language: 'en',
      use24h: true,
    );
    expect(channel.updates, hasLength(1));
    expect(channel.updates.single.json, jsonEncode(expected));
    expect(channel.updates.single.force, false);
  });

  test('after midnight the marks are still the prayer day\'s', () async {
    await placeInMakkah();
    await db.markPrayed(DateTime(2026, 10, 15), Prayer.isha);

    await write(at(16, 1, 0));

    final data = jsonDecode(channel.updates.single.json) as Map<String, Object?>;
    final entry = (data['entries']! as List).first as Map<String, Object?>;
    expect(entry['prayedLine'], '1 of 5 prayed today');
  });

  test('force is passed through', () async {
    await placeInMakkah();
    await write(at(15, 16, 32), force: true);
    expect(channel.updates.single.force, true);
  });

  test('no place hands the no place json and nothing to wait for', () async {
    final next = await write(at(15, 16, 32));
    final data = jsonDecode(channel.updates.single.json) as Map<String, Object?>;
    expect(data['place'], false);
    expect(data['entries'], isEmpty);
    expect(next, isNull);
  });

  test('a channel error is reported once and nothing throws', () async {
    await placeInMakkah();
    final reporter = _RecordingReporter();
    CrashReporter.instance = reporter;
    channel.error = PlatformException(code: 'surfaces_failed', message: 'IOException');

    await write(at(15, 16, 32));

    expect(reporter.contexts, [
      {'reason': 'write surfaces'},
    ]);
  });

  test('returns the next countdown start or end after now', () async {
    await placeInMakkah();
    final maghrib = tz.TZDateTime(riyadh, 2026, 10, 15, 17, 56);

    /// maghrib's runs, it ends where isha's starts
    expect((await write(at(15, 16, 32)))?.millisecondsSinceEpoch, maghrib.millisecondsSinceEpoch);
    final asr = dayTimesAt(
      makkah(),
      DateTime(2026, 10, 15),
      method: null,
      asrMethod: null,
      hijriAdjust: 0,
    ).asr!;
    expect(
      (await write(asr.add(const Duration(minutes: 1))))?.millisecondsSinceEpoch,
      maghrib.subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
    );

    await db.updateSettings(const SettingsCompanion(prayerCountdown: Value(false)));
    expect(await write(at(15, 16, 32)), isNull);
  });
}

class _RecordingReporter implements CrashReporter {
  final contexts = <Map<String, Object?>?>[];

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
    Map<String, Object?>? context,
  }) async => contexts.add(context);

  @override
  void addBreadcrumb(String message, {String? category}) {}
}
