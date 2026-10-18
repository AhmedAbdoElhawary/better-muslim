import 'package:better_muslim/core/app/app.dart';
import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/flavor/flavor.dart';
import 'package:better_muslim/core/flavor/flavor_config.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/location/position_source.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
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

  DateTime maghrib() => dayTimesAt(
    makkah(),
    DateTime(2026, 10, 15),
    method: null,
    asrMethod: null,
    hijriAdjust: 0,
  ).maghrib!;

  /// makkah with a clock that moves with the test, the app wrapped in the boot widget
  Future<void> pumpBoot(WidgetTester tester, DateTime start, {bool scenario = false}) async {
    final origin = tester.binding.clock.now();
    await pumpHome(
      tester,
      [
        databaseProvider.overrideWith((ref) {
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
    expect(scheduler.applied, isEmpty);
    expect(scheduler.asks, 0);
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
}
