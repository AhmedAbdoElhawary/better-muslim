import 'dart:convert';

import 'package:better_muslim/core/app/app.dart';
import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/flavor/flavor_config.dart';
import 'package:better_muslim/core/location/position_source.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_method.dart';
import 'package:better_muslim/core/qibla/compass_source.dart';
import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/resources/design/bm_theme.dart';
import 'package:better_muslim/core/settings/onboarding.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/surfaces/surfaces_channel.dart';
import 'package:better_muslim/features/surfaces/presentation/surfaces_boot.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../../helpers/fonts.dart';
import '../../../helpers/home.dart';
import '../../../helpers/notifications.dart';
import '../../../helpers/prayer.dart';
import '../../../helpers/providers.dart';
import '../../../helpers/qibla.dart';
import '../../../helpers/surfaces.dart';

void main() {
  setUpAll(() async {
    tz.initializeTimeZones();
    await loadAppFonts();
  });

  setUp(muteAdhanChannel);

  const makkahPlace = SettingsCompanion(
    latitude: Value(21.4225),
    longitude: Value(39.8262),
    placeName: Value('Makkah'),
    placeNameAr: Value('مكة المكرمة'),
    countryCode: Value('SA'),
    timeZone: Value('Asia/Riyadh'),
    locationMode: Value(LocationMode.manual),
  );

  /// drift's in-memory store answers on the real event loop, the timers run on the test's fake
  /// clock, so both move on together
  Future<void> settle(
    WidgetTester tester, [
    Duration time = const Duration(milliseconds: 100),
  ]) async {
    const step = Duration(milliseconds: 50);
    for (var waited = Duration.zero; waited < time; waited += step) {
      await tester.runAsync(() => Future<void>.delayed(step));
      await tester.pump(step);
    }
  }

  void backToFront(WidgetTester tester) {
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
  }

  FakeSurfacesChannel channelOf(WidgetTester tester) =>
      containerOf(tester).read(surfacesChannelProvider) as FakeSurfacesChannel;

  /// makkah in the store, 16:32 on 15 oct by default, a clock that moves with the test
  Future<FakeSurfacesChannel> pumpBoot(
    WidgetTester tester, {
    int hour = 16,
    int minute = 32,
  }) async {
    final start = tz.TZDateTime(tz.getLocation('Asia/Riyadh'), 2026, 10, 15, hour, minute);
    final origin = tester.binding.clock.now();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.updateSettings(makkahPlace);
    await pumpHome(
      tester,
      [
        databaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        flavorProvider.overrideWithValue(devConfig),
        positionSourceProvider.overrideWithValue(FakePositionSource()),
        compassSourceProvider.overrideWithValue(FakeCompassSource()),
        onboardingProvider.overrideWith(() => OnboardingNotifier(done: true)),
        surfacesChannelProvider.overrideWithValue(FakeSurfacesChannel()),
        clockProvider.overrideWithValue(
          () => start.add(tester.binding.clock.now().difference(origin)),
        ),
      ],
      app: const SurfacesBoot(child: App()),
      settle: false,
    );
    await settle(tester, const Duration(milliseconds: 700));
    return channelOf(tester);
  }

  testWidgets('one write after launch, with the store\'s place', (tester) async {
    final channel = await pumpBoot(tester);

    expect(channel.updates, hasLength(1));
    final data = jsonDecode(channel.updates.single.json) as Map<String, Object?>;
    expect(data['place'], true);
    expect(channel.updates.single.force, false);
    await unmount(tester);
  });

  testWidgets('one write 500 ms after a burst of changes', (tester) async {
    final channel = await pumpBoot(tester);
    final db = dbOf(tester);

    await db.updateSettings(
      const SettingsCompanion(
        latitude: Value(41.0082),
        longitude: Value(28.9784),
        placeName: Value('Istanbul'),
        countryCode: Value('TR'),
        timeZone: Value('Europe/Istanbul'),
      ),
    );
    await db.updateSettings(const SettingsCompanion(method: Value(PrayerMethod.turkiye)));
    await db.updateSettings(const SettingsCompanion(asrMethod: Value(AsrMethod.hanafi)));
    await db.updateSettings(const SettingsCompanion(hijriAdjust: Value(1)));
    await db.updateSettings(const SettingsCompanion(digits: Value(Digits.western)));
    await db.updateSettings(const SettingsCompanion(reminderMinutes: Value(5)));
    await settle(tester, const Duration(milliseconds: 300));
    expect(channel.updates, hasLength(1));

    await settle(tester, const Duration(milliseconds: 500));
    expect(channel.updates, hasLength(2));
    final data = jsonDecode(channel.updates.last.json) as Map<String, Object?>;
    expect(data['reminderMinutes'], 5);
    expect((data['texts']! as Map)['liveNext'], 'Next prayer · Istanbul');
    await unmount(tester);
  });

  testWidgets('one write after a theme change and one after a mode change', (tester) async {
    final channel = await pumpBoot(tester);

    await dbOf(tester).updateSettings(const SettingsCompanion(theme: Value(BmThemeId.andalus)));
    await settle(tester, const Duration(milliseconds: 700));
    expect(channel.updates, hasLength(2));
    final data = jsonDecode(channel.updates.last.json) as Map<String, Object?>;
    expect(
      ((data['colors']! as Map)['dark'] as Map)['text'],
      bmThemes[BmThemeId.andalus]!.dark.text.toARGB32(),
    );

    await dbOf(tester).updateSettings(const SettingsCompanion(themeMode: Value(BmThemeMode.dark)));
    await settle(tester, const Duration(milliseconds: 700));
    expect(channel.updates, hasLength(3));
    expect(jsonDecode(channel.updates.last.json)['mode'], 'dark');
    await unmount(tester);
  });

  testWidgets('one write after a mark and one after an unmark', (tester) async {
    final channel = await pumpBoot(tester);
    final day = DateTime(2026, 10, 15);

    await dbOf(tester).markPrayed(day, Prayer.asr);
    await settle(tester, const Duration(milliseconds: 700));
    expect(channel.updates, hasLength(2));
    expect(channel.updates.last.json, contains('1 of 5 prayed today'));

    await dbOf(tester).unmarkPrayed(day, Prayer.asr);
    await settle(tester, const Duration(milliseconds: 700));
    expect(channel.updates, hasLength(3));
    expect(channel.updates.last.json, contains('0 of 5 prayed today'));
    await unmount(tester);
  });

  testWidgets('one write after reset prayer journey', (tester) async {
    final channel = await pumpBoot(tester);
    final db = dbOf(tester);
    await db.markPrayed(DateTime(2026, 10, 15), Prayer.asr);
    await settle(tester, const Duration(milliseconds: 700));
    final before = channel.updates.length;

    await db.resetPrayerJourney();
    await settle(tester, const Duration(milliseconds: 700));
    expect(channel.updates, hasLength(before + 1));
    await unmount(tester);
  });

  testWidgets('one write on resume', (tester) async {
    final channel = await pumpBoot(tester);

    backToFront(tester);
    await settle(tester);

    expect(channel.updates, hasLength(2));
    await unmount(tester);
  });

  testWidgets('the design scenario writes nothing', (tester) async {
    await pumpHome(
      tester,
      await designOverrides(),
      app: const SurfacesBoot(child: App()),
      settle: false,
    );
    await settle(tester, const Duration(milliseconds: 300));
    final channel = channelOf(tester);

    await dbOf(tester).updateSettings(const SettingsCompanion(reminderMinutes: Value(5)));
    await dbOf(tester).markPrayed(DateTime(2026, 10, 15), Prayer.maghrib);
    backToFront(tester);
    await settle(tester, const Duration(milliseconds: 700));

    expect(channel.updates, isEmpty);
    await unmount(tester);
  });
}
