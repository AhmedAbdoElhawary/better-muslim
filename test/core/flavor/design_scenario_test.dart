import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/flavor/design_scenario.dart';
import 'package:better_muslim/core/flavor/flavor.dart';
import 'package:better_muslim/core/flavor/flavor_config.dart';
import 'package:better_muslim/core/hijri/hijri_date.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/location/location_controller.dart';
import 'package:better_muslim/core/prayer_log/prayer_log.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_method.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/design/bm_theme.dart';
import 'package:better_muslim/core/settings/appearance.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(tz.initializeTimeZones);

  test('only dev with SCENARIO=design turns it on (FR-026)', () {
    FlavorConfig config(Flavor flavor, String scenario) => FlavorConfig(
      flavor: flavor,
      appName: 'Better Muslim',
      apiBaseUrl: '',
      sentryDsn: '',
      scenario: scenario,
    );

    expect(config(Flavor.dev, 'design').isDesignScenario, isTrue);
    expect(config(Flavor.dev, '').isDesignScenario, isFalse);
    expect(config(Flavor.staging, 'design').isDesignScenario, isFalse);
    expect(config(Flavor.production, 'design').isDesignScenario, isFalse);
  });

  group('the overrides', () {
    late ProviderContainer container;
    var storeCalls = 0;

    setUp(() async {
      /// AppDatabase.open asks path_provider for its folder first
      storeCalls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => '${storeCalls++}',
      );
      final db = await designScenarioStore();
      container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db), ...designScenarioOverrides()],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
    });

    test('freeze 16:32 in makkah with umm al-qura and the handoff times (SC-001)', () {
      final times = container.read(todayTimesProvider)!;
      String hhmm(DateTime? time) =>
          '${time!.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

      expect(container.read(clockProvider)(), DateTime.utc(2026, 10, 15, 13, 32));
      expect(container.read(locationProvider)!.placeName, 'Makkah');
      expect(container.read(locationProvider)!.zone.name, 'Asia/Riyadh');
      expect(times.method, PrayerMethod.ummAlQura);
      expect(times.asrMethod, AsrMethod.standard);
      expect(
        [times.fajr, times.sunrise, times.dhuhr, times.asr, times.maghrib, times.isha].map(hhmm),
        ['04:58', '06:15', '12:05', '15:27', '17:56', '19:26'],
      );
    });

    test('the prayer day has the handoff times, other days compute', () {
      final prayerDay = container.read(prayerDayProvider);
      final tomorrow = container.read(dayTimesProvider(DateTime(2026, 10, 16)))!;

      expect(prayerDay, DateTime(2026, 10, 15));
      expect(container.read(dayTimesProvider(prayerDay)), same(container.read(todayTimesProvider)));

      /// a real umm al-qura calculation, the handoff's fixed times end on the 15th
      expect(tomorrow.date, DateTime(2026, 10, 16));
      expect((tomorrow.fajr!.hour, tomorrow.fajr!.minute), (5, 0));
    });

    test('follow sky follows the phone, dark and light stay as saved (FR-041)', () async {
      container.listen(themeModeProvider, (_, _) {});
      await container.read(settingsProvider.future);
      expect(container.read(themeModeProvider), ThemeMode.system);
      final db = container.read(databaseProvider);
      for (final (mode, expected) in [
        (BmThemeMode.dark, ThemeMode.dark),
        (BmThemeMode.light, ThemeMode.light),
      ]) {
        await db.updateSettings(SettingsCompanion(themeMode: Value(mode)));
        await pumpEventQueue();
        expect(container.read(themeModeProvider), expected);
      }
    });

    test('maghrib is next in 1:24:00 and the date is 4 jumada i 1448', () {
      final (prayer, time) = container.read(nextPrayerProvider)!;
      final hijri = container.read(hijriDateProvider(container.read(todayProvider)));

      expect(prayer, Prayer.maghrib);
      expect(
        time.difference(container.read(clockProvider)()),
        const Duration(hours: 1, minutes: 24),
      );
      expect(container.read(periodProvider), Period.asr);
      expect((hijri.day, hijri.month, hijri.year), (4, 5, 1448));
    });

    test('the store has the 4.04 week, first use 1 oct and 3 open qada entries (FR-031)', () async {
      final db = container.read(databaseProvider);
      final provider = weekLogProvider(DateTime(2026, 10, 11));
      container.listen(provider, (_, _) {});
      final week = await container.read(provider.future);
      final qada = await db.select(db.qadaEntries).get();

      expect(
        {for (final MapEntry(:key, :value) in week.entries) key.day: value.length},
        {11: 5, 12: 5, 13: 4, 14: 5, 15: 2},
      );
      expect(week[DateTime(2026, 10, 13)], isNot(contains(Prayer.isha)));
      expect(week[DateTime(2026, 10, 15)], {Prayer.fajr, Prayer.dhuhr});
      expect(qada.map((entry) => (entry.missedOn, entry.prayer, entry.madeUpAt)), [
        (DateTime(2026, 10, 13), Prayer.isha, null),
        (DateTime(2026, 10, 6), Prayer.fajr, null),
        (DateTime(2026, 10, 8), Prayer.fajr, null),
      ]);
      expect((await db.watchSettings().first).firstUse, DateTime(2026, 10, 1));
      expect(storeCalls, 0);
    });

    test('tasbih at subhanallah 16, nothing counted or saved (FR-036)', () async {
      final db = container.read(databaseProvider);
      final settings = await db.watchSettings().first;

      expect((settings.tasbihDhikr, settings.tasbihCount), (0, 16));
      expect(await db.select(db.azkarCounts).get(), isEmpty);
      expect(await db.select(db.savedDuas).get(), isEmpty);
    });

    /// the real PositionSource would throw MissingPluginException in a host test
    test('geolocator is never reached and nothing is saved', () async {
      await container.read(locationControllerProvider).refresh();

      expect((await container.read(databaseProvider).watchSettings().first).latitude, isNull);
    });
  });
}
