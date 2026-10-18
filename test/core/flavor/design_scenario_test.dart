import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/flavor/design_scenario.dart';
import 'package:better_muslim/core/flavor/flavor.dart';
import 'package:better_muslim/core/flavor/flavor_config.dart';
import 'package:better_muslim/core/hijri/hijri_date.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/location/location_controller.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_method.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:drift/native.dart';
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

    setUp(() {
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWith((ref) {
            final db = AppDatabase.forTesting(NativeDatabase.memory());
            ref.onDispose(db.close);
            return db;
          }),
          ...designScenarioOverrides(),
        ],
      );
      addTearDown(container.dispose);
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

    /// the real PositionSource would throw MissingPluginException in a host test
    test('geolocator is never reached and nothing is saved', () async {
      await container.read(locationControllerProvider).refresh();

      expect((await container.read(databaseProvider).watchSettings().first).latitude, isNull);
    });
  });
}
