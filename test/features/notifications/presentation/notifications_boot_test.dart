import 'dart:async';

import 'package:better_muslim/core/app/app.dart';
import 'package:better_muslim/core/azkar/azkar_content.dart';
import 'package:better_muslim/core/azkar/azkar_window.dart';
import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/flavor/flavor.dart';
import 'package:better_muslim/core/flavor/flavor_config.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/location/position_source.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_method.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/notifications/data/notification_scheduler.dart';
import 'package:better_muslim/features/notifications/domain/alert.dart';
import 'package:better_muslim/features/notifications/presentation/notifications_boot.dart';
import 'package:better_muslim/features/notifications/presentation/providers/adhan_providers.dart';
import 'package:better_muslim/features/notifications/presentation/view/adhan_page.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' show TZDateTime;

import '../../../helpers/fonts.dart';
import '../../../helpers/home.dart';
import '../../../helpers/notifications.dart';
import '../../../helpers/prayer.dart';
import '../../../helpers/providers.dart';

void main() {
  setUpAll(() async {
    tz.initializeTimeZones();
    await loadAppFonts();
  });

  late FakeScheduler scheduler;
  late FakePlayer player;

  setUp(() {
    scheduler = FakeScheduler();
    player = FakePlayer();
    muteAdhanChannel();
  });

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

  /// the app to the background and back, through the states flutter expects
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

  DateTime maghrib() => dayTimesAt(
    makkah(),
    DateTime(2026, 10, 15),
    method: null,
    asrMethod: null,
    hijriAdjust: 0,
  ).maghrib!;

  /// makkah with a clock that moves with the test, the app wrapped in the boot widget
  Future<void> pumpBoot(
    WidgetTester tester,
    DateTime start, {
    bool scenario = false,
    AppDatabase? store,
  }) async {
    final origin = tester.binding.clock.now();
    await pumpHome(
      tester,
      [
        databaseProvider.overrideWith((ref) {
          if (store != null) return store;
          driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
          final db = AppDatabase.forTesting(NativeDatabase.memory());
          ref.onDispose(db.close);
          return db;
        }),
        flavorProvider.overrideWithValue(
          scenario
              ? const FlavorConfig(
                  flavor: Flavor.dev,
                  appName: 'Better Muslim',
                  apiBaseUrl: '',
                  sentryDsn: '',
                  scenario: 'design',
                )
              : devConfig,
        ),
        positionSourceProvider.overrideWithValue(FakePositionSource()),
        clockProvider.overrideWithValue(
          () => start.add(tester.binding.clock.now().difference(origin)),
        ),
        locationProvider.overrideWithValue(makkah()),
        notificationSchedulerProvider.overrideWithValue(scheduler),
        adhanPlayerProvider.overrideWithValue(player),
      ],
      app: const NotificationsBoot(child: App()),
      settle: false,
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
  }

  testWidgets('maghrib coming while the app is open opens the adhan screen and plays', (
    tester,
  ) async {
    await pumpBoot(tester, maghrib().subtract(const Duration(seconds: 2)));

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(AdhanPage), findsOneWidget);
    expect(player.played.single.prayer, Prayer.maghrib);
    expect(player.played.single.day, DateTime(2026, 10, 15));
    await unmount(tester);
  });

  testWidgets('opening the app after the prayer shows no adhan screen', (tester) async {
    await pumpBoot(tester, maghrib().add(const Duration(seconds: 30)));

    await tester.pump(const Duration(seconds: 3));

    expect(find.byType(AdhanPage), findsNothing);
    expect(player.played, isEmpty);
    await unmount(tester);
  });

  testWidgets('a tone prayer only notifies', (tester) async {
    await pumpBoot(tester, maghrib().subtract(const Duration(seconds: 5)));
    await dbOf(tester)
        .updateSettings(const SettingsCompanion(maghribSound: Value(PrayerSound.tone)));
    await tester.pump();

    await tester.pump(const Duration(seconds: 6));

    expect(find.byType(AdhanPage), findsNothing);
    expect(player.played, isEmpty);
    await unmount(tester);
  });

  testWidgets('the design scenario opens nothing and schedules nothing', (tester) async {
    await pumpBoot(tester, maghrib().subtract(const Duration(seconds: 2)), scenario: true);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(AdhanPage), findsNothing);
    expect(scheduler.runs, 0);
    expect(scheduler.asks, 0);

    await dbOf(tester).updateSettings(const SettingsCompanion(reminderMinutes: Value(5)));
    backToFront(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(scheduler.runs, 0);
    await unmount(tester);
  });

  testWidgets('a logged prayer takes its delivered adhan notification away, others stay', (
    tester,
  ) async {
    final day = DateTime(2026, 10, 15);
    final maghribId = alertId(day, Prayer.maghrib, AlertKind.adhan);
    final asrId = alertId(day, Prayer.asr, AlertKind.adhan);
    scheduler.active.addAll([maghribId, asrId]);
    await pumpBoot(tester, maghrib().add(const Duration(minutes: 5)));

    await dbOf(tester).markPrayed(day, Prayer.maghrib);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(scheduler.cancelled, [maghribId]);
    expect(scheduler.active, [asrId]);

    await dbOf(tester).unmarkPrayed(day, Prayer.maghrib);
    await tester.pump(const Duration(milliseconds: 100));
    expect(scheduler.cancelled, [maghribId]);
    await unmount(tester);
  });

  testWidgets('a tap on an adhan that would still play opens the screen from that point', (
    tester,
  ) async {
    final at = maghrib();
    scheduler.launch = payloadOf(
      Alert(
        day: DateTime(2026, 10, 15),
        prayer: Prayer.maghrib,
        kind: AlertKind.adhan,
        at: TZDateTime.from(at, makkah().zone),
        sound: PrayerSound.adhan,
      ),
    );
    await pumpBoot(tester, at.add(const Duration(seconds: 40)));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(AdhanPage), findsOneWidget);
    expect(player.played.single.prayer, Prayer.maghrib);
    await unmount(tester);
  });

  testWidgets('a tap on a tone prayer opens the prayer tab at it', (tester) async {
    final at = maghrib();
    scheduler.launch = payloadOf(
      Alert(
        day: DateTime(2026, 10, 15),
        prayer: Prayer.maghrib,
        kind: AlertKind.adhan,
        at: TZDateTime.from(at, makkah().zone),
        sound: PrayerSound.tone,
      ),
    );
    await pumpBoot(tester, at.add(const Duration(seconds: 40)));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(AdhanPage), findsNothing);
    expect(
      containerOf(tester).read(routerProvider).routeInformationProvider.value.uri.toString(),
      Routes.prayerAt(DateTime(2026, 10, 15), Prayer.maghrib),
    );
    await unmount(tester);
  });

  testWidgets('a tap on an azkar nudge opens its set (FR-039)', (tester) async {
    final at = TZDateTime(makkah().zone, 2026, 10, 15, 15, 47);
    scheduler.launch = payloadOf(
      Alert(
        day: DateTime(2026, 10, 15),
        prayer: Prayer.asr,
        kind: AlertKind.azkar,
        at: at,
        sound: PrayerSound.silent,
      ),
    );
    await pumpBoot(tester, at.add(const Duration(minutes: 2)));
    await tester.pump(const Duration(seconds: 1));

    expect(
      containerOf(tester).read(routerProvider).routeInformationProvider.value.uri.toString(),
      Routes.azkarSet(AzkarSet.evening),
    );
    await unmount(tester);
  });

  group('the schedule follows every change (FR-010)', () {
    final noon = DateTime.utc(2026, 10, 15, 9);

    testWidgets('a change gives one reschedule after 500 ms, several at once too', (tester) async {
      await pumpBoot(tester, noon);

      /// the start's own reschedule and the first settings value's are both done by then
      await settle(tester, const Duration(milliseconds: 1500));
      final before = scheduler.runs;
      final db = dbOf(tester);

      for (final change in [
        const SettingsCompanion(method: Value(PrayerMethod.egyptian)),
        const SettingsCompanion(asrMethod: Value(AsrMethod.hanafi)),
        const SettingsCompanion(hijriAdjust: Value(1)),
        const SettingsCompanion(ishaSound: Value(PrayerSound.silent)),
        const SettingsCompanion(reminderMinutes: Value(20)),
        const SettingsCompanion(digits: Value(Digits.western)),
      ]) {
        final runs = scheduler.runs;
        unawaited(db.updateSettings(change));
        await settle(tester, const Duration(milliseconds: 300));
        expect(scheduler.runs, runs, reason: '$change');
        await settle(tester, const Duration(milliseconds: 400));
        expect(scheduler.runs, runs + 1, reason: '$change');
      }

      final runs = scheduler.runs;
      unawaited(db.updateSettings(const SettingsCompanion(fajrSound: Value(PrayerSound.tone))));
      unawaited(db.updateSettings(const SettingsCompanion(reminderMinutes: Value(30))));
      await settle(tester, const Duration(milliseconds: 700));
      expect(scheduler.runs, runs + 1);
      expect(scheduler.runs, greaterThan(before));
      await unmount(tester);
    });

    testWidgets('the azkar switch and finishing the current set each reschedule once', (
      tester,
    ) async {
      await pumpBoot(tester, noon);
      await settle(tester, const Duration(milliseconds: 1500));
      final db = dbOf(tester);

      var runs = scheduler.runs;
      unawaited(db.updateSettings(const SettingsCompanion(azkarNudges: Value(false))));
      await settle(tester, const Duration(milliseconds: 700));
      expect(scheduler.runs, runs + 1);

      runs = scheduler.runs;
      final content = await tester.runAsync(loadAzkarContent);
      for (final zikr in content!.morning.items) {
        await db.setZikrCount(AzkarSet.morning, DateTime(2026, 10, 15), zikr.id, zikr.count);
      }
      await settle(tester, const Duration(milliseconds: 700));
      expect(scheduler.runs, runs + 1);
      await unmount(tester);
    });

    testWidgets('coming back to the front reschedules once', (tester) async {
      await pumpBoot(tester, noon);
      await settle(tester, const Duration(milliseconds: 700));
      final runs = scheduler.runs;

      backToFront(tester);
      await settle(tester, const Duration(milliseconds: 700));

      expect(scheduler.runs, runs + 1);
      await unmount(tester);
    });
  });

  group('asked once (FR-004 to FR-006)', () {
    final noon = DateTime.utc(2026, 10, 15, 9);

    testWidgets('the first launch asks after the location, then for alarms', (tester) async {
      await pumpBoot(tester, noon);
      await settle(tester, const Duration(milliseconds: 700));

      expect(scheduler.asks, 1);
      expect(scheduler.alarmAsks, 1);
      expect(containerOf(tester).read(settingsProvider).value?.notificationsAsked, isTrue);
      expect(scheduler.runs, greaterThan(0));
      await unmount(tester);
    });

    testWidgets('refused schedules nothing, never asks again, a later grant is picked up', (
      tester,
    ) async {
      scheduler = FakeScheduler(allowed: false, grants: false);
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final store = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(store.close);
      await pumpBoot(tester, noon, store: store);
      await settle(tester, const Duration(milliseconds: 700));

      expect(scheduler.asks, 1);
      expect(scheduler.alarmAsks, 0);
      expect(scheduler.runs, 0);
      await unmount(tester);

      /// the app opened again
      scheduler = FakeScheduler(allowed: false, grants: false);
      await pumpBoot(tester, noon, store: store);
      await settle(tester, const Duration(milliseconds: 700));
      expect(scheduler.asks, 0);
      expect(scheduler.runs, 0);

      /// allowed in the phone's settings, then back to the app
      scheduler.allowed = true;
      backToFront(tester);
      await settle(tester, const Duration(milliseconds: 700));
      expect(scheduler.runs, 1);
      await unmount(tester);
    });
  });
}
