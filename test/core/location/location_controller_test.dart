import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/location/location_controller.dart';
import 'package:better_muslim/core/location/place_list.dart';
import 'package:better_muslim/core/monitoring/crash_reporter.dart';
import 'package:better_muslim/core/prayer_times/prayer_method.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../helpers/providers.dart';

const _kaaba = (latitude: 21.4225, longitude: 39.8262);
const _cairo = SettingsCompanion(
  latitude: Value(30.0626),
  longitude: Value(31.2497),
  placeName: Value('Cairo'),
  countryCode: Value('EG'),
  timeZone: Value('Africa/Cairo'),
  locationMode: Value(LocationMode.auto),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(tz.initializeTimeZones);

  late PlaceList places;
  setUpAll(() async => places = await PlaceList.load());

  late _RecordingReporter reporter;
  setUp(() => CrashReporter.instance = reporter = _RecordingReporter());
  tearDown(() => CrashReporter.instance = const DebugCrashReporter());

  ProviderContainer containerWith(FakePositionSource source) {
    final container = ProviderContainer(overrides: testOverrides(positionSource: source));
    addTearDown(container.dispose);
    return container;
  }

  Future<AppSettings> saved(ProviderContainer container) =>
      container.read(databaseProvider).watchSettings().first;

  test('no location and permission granted saves an auto location, method by country', () async {
    final source = FakePositionSource(granted: LocationPermission.whileInUse, position: _kaaba);
    final container = containerWith(source);

    await container.read(locationControllerProvider).refresh();
    final settings = await saved(container);

    expect(source.requests, 0);
    expect(settings.latitude, _kaaba.latitude);
    expect(settings.placeName, 'Makkah');
    expect(settings.placeNameAr, 'مكة المكرمة');
    expect(settings.regionName, 'Mecca Region');
    expect(settings.countryCode, 'SA');
    expect(settings.timeZone, 'Asia/Riyadh');
    expect(settings.locationMode, LocationMode.auto);
    expect(settings.method, isNull);
    expect(settings.asrMethod, isNull);
  });

  test('denied keeps no location, nothing is made up', () async {
    final source = FakePositionSource(answer: LocationPermission.denied, position: _kaaba);
    final container = containerWith(source);

    await container.read(locationControllerProvider).refresh();

    expect(source.fixes, 0);
    expect((await saved(container)).latitude, isNull);
  });

  /// the location step asks after saying why (milestone 10 FR-002)
  test('no location and not asked yet never shows the dialog at launch', () async {
    final source = FakePositionSource(answer: LocationPermission.whileInUse, position: _kaaba);
    final container = containerWith(source);

    await container.read(locationControllerProvider).refresh();

    expect(source.requests, 0);
    expect(source.fixes, 0);
    expect((await saved(container)).latitude, isNull);
  });

  test('no fix in time keeps the saved location', () async {
    final source = FakePositionSource(granted: LocationPermission.whileInUse);
    final container = containerWith(source);
    await container.read(databaseProvider).updateSettings(_cairo);

    await container.read(locationControllerProvider).refresh();
    final settings = await saved(container);

    expect(source.requests, 0);
    expect(settings.placeName, 'Cairo');
    expect(settings.latitude, 30.0626);
  });

  test('a method picked by the user stays after a fix in another country (FR-012)', () async {
    final source = FakePositionSource(granted: LocationPermission.whileInUse, position: _kaaba);
    final container = containerWith(source);
    await container
        .read(databaseProvider)
        .updateSettings(_cairo.copyWith(method: const Value(PrayerMethod.egyptian)));

    await container.read(locationControllerProvider).refresh();
    final settings = await saved(container);

    expect(settings.countryCode, 'SA');
    expect(settings.method, PrayerMethod.egyptian);
  });

  test('no location data ever reaches the crash reporter', () async {
    final source = FakePositionSource(answer: LocationPermission.whileInUse, position: _kaaba);
    final container = containerWith(source);

    await container.read(locationControllerProvider).refresh();

    final reported = reporter.everything.join('\n');
    for (final secret in ['21.42', '39.82', 'Makkah', 'مكة', 'Mecca', 'Riyadh']) {
      expect(reported, isNot(contains(secret)));
    }
  });

  group('manual (FR-006)', () {
    test('choosing a place saves a manual location with its own zone', () async {
      final container = containerWith(FakePositionSource());
      final tanta = places.search('tanta').first;

      await container.read(locationControllerProvider).choose(tanta);
      final settings = await saved(container);

      expect(settings.placeName, 'Tanta');
      expect(settings.placeNameAr, 'طنطا');
      expect(settings.countryCode, 'EG');
      expect(settings.timeZone, 'Africa/Cairo');
      expect(settings.locationMode, LocationMode.manual);
    });

    test('refresh takes no fix while manual', () async {
      final source = FakePositionSource(granted: LocationPermission.whileInUse, position: _kaaba);
      final container = containerWith(source);
      await container.read(locationControllerProvider).choose(places.search('tanta').first);

      await container.read(locationControllerProvider).refresh();

      expect(source.fixes, 0);
      expect((await saved(container)).placeName, 'Tanta');
    });

    test('new york picked on a phone in riyadh gives new york times', () async {
      final container = ProviderContainer(
        overrides: [
          ...testOverrides(),
          phoneZoneProvider.overrideWith(() => PhoneZone('Asia/Riyadh')),
        ],
      );
      addTearDown(container.dispose);
      final times = container.listen(todayTimesProvider, (_, _) {});

      await container.read(locationControllerProvider).choose(places.search('new york').first);
      await pumpEventQueue();

      expect(container.read(locationProvider)!.zone.name, 'America/New_York');
      expect(times.read()!.dhuhr!.location.name, 'America/New_York');
      expect(times.read()!.dhuhr!.hour, inInclusiveRange(11, 13));
    });

    test('use auto goes back to gps', () async {
      final source = FakePositionSource(granted: LocationPermission.whileInUse, position: _kaaba);
      final container = containerWith(source);
      await container.read(locationControllerProvider).choose(places.search('tanta').first);

      final done = await container.read(locationControllerProvider).useAuto();
      final settings = await saved(container);

      expect(done, isTrue);
      expect(settings.locationMode, LocationMode.auto);
      expect(settings.placeName, 'Makkah');
    });
  });

  group('use my location from the sheet asks and reports back (R12)', () {
    Future<ProviderContainer> manualTanta(FakePositionSource source) async {
      final container = containerWith(source);
      await container.read(locationControllerProvider).choose(places.search('tanta').first);
      return container;
    }

    test('denied with a manual place saved, it asks, and allowed saves the new place', () async {
      final source = FakePositionSource(answer: LocationPermission.whileInUse, position: _kaaba);
      final container = await manualTanta(source);

      final done = await container.read(locationControllerProvider).useAuto();
      final settings = await saved(container);

      expect(source.requests, 1);
      expect(done, isTrue);
      expect(settings.locationMode, LocationMode.auto);
      expect(settings.placeName, 'Makkah');
    });

    test('denied after asking changes nothing', () async {
      final source = FakePositionSource(answer: LocationPermission.denied, position: _kaaba);
      final container = await manualTanta(source);

      final done = await container.read(locationControllerProvider).useAuto();
      final settings = await saved(container);

      expect(done, isFalse);
      expect(source.fixes, 0);
      expect(settings.locationMode, LocationMode.manual);
      expect(settings.placeName, 'Tanta');
    });

    test('denied forever does not ask', () async {
      final source = FakePositionSource(granted: LocationPermission.deniedForever);
      final container = await manualTanta(source);

      final done = await container.read(locationControllerProvider).useAuto();

      expect(done, isFalse);
      expect(source.requests, 0);
      expect((await saved(container)).placeName, 'Tanta');
    });

    test('no fix, location off or too slow, changes nothing', () async {
      final source = FakePositionSource(granted: LocationPermission.whileInUse);
      final container = await manualTanta(source);

      final done = await container.read(locationControllerProvider).useAuto();
      final settings = await saved(container);

      expect(done, isFalse);
      expect(settings.locationMode, LocationMode.manual);
      expect(settings.placeName, 'Tanta');
    });

    test('refresh still never asks with a location saved', () async {
      final source = FakePositionSource(answer: LocationPermission.whileInUse, position: _kaaba);
      final container = containerWith(source);
      await container.read(databaseProvider).updateSettings(_cairo);

      await container.read(locationControllerProvider).refresh();

      expect(source.requests, 0);
      expect((await saved(container)).placeName, 'Cairo');
    });
  });

  group('travel (FR-008)', () {
    /// geolocator's earth is 6378137 m, so a degree of latitude is 111.32 km
    SettingsCompanion savedNorthOfMakkah(double km) => SettingsCompanion(
      latitude: Value(_kaaba.latitude + km / 111.32),
      longitude: const Value(39.8262),
      placeName: const Value('Old place'),
      countryCode: const Value('EG'),
      timeZone: const Value('Africa/Cairo'),
      locationMode: const Value(LocationMode.auto),
    );

    test('31 km away updates the place, the zone and the method by country', () async {
      final source = FakePositionSource(granted: LocationPermission.whileInUse, position: _kaaba);
      final container = containerWith(source);
      final times = container.listen(todayTimesProvider, (_, _) {});
      await container.read(databaseProvider).updateSettings(savedNorthOfMakkah(31));

      await container.read(locationControllerProvider).refresh();
      await pumpEventQueue();
      final settings = await saved(container);

      expect(settings.placeName, 'Makkah');
      expect(settings.timeZone, 'Asia/Riyadh');
      expect(times.read()!.method, PrayerMethod.ummAlQura);
    });

    test('29 km away changes nothing', () async {
      final source = FakePositionSource(granted: LocationPermission.whileInUse, position: _kaaba);
      final container = containerWith(source);
      await container.read(databaseProvider).updateSettings(savedNorthOfMakkah(29));

      await container.read(locationControllerProvider).refresh();

      expect((await saved(container)).placeName, 'Old place');
    });

    group('on resume', () {
      late DateTime now;
      late FakePositionSource source;
      late ProviderContainer container;

      setUp(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('flutter_timezone'),
          (_) async => 'Asia/Riyadh',
        );
        now = DateTime.utc(2026, 10, 15, 9);
        source = FakePositionSource(granted: LocationPermission.whileInUse, position: _kaaba);
        container = ProviderContainer(
          overrides: [
            ...testOverrides(positionSource: source),
            clockProvider.overrideWithValue(() => now),
          ],
        );
        addTearDown(container.dispose);
      });

      Future<void> resume() async {
        final binding = TestWidgetsFlutterBinding.instance;
        binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await pumpEventQueue();
      }

      test('a second resume within 30 minutes takes no fix', () async {
        await container.read(locationControllerProvider).refresh();
        expect(source.fixes, 1);

        now = now.add(const Duration(minutes: 20));
        await resume();
        expect(source.fixes, 1);

        now = now.add(const Duration(minutes: 11));
        await resume();
        expect(source.fixes, 2);
      });

      test('manual takes no fix on resume', () async {
        await container.read(locationControllerProvider).choose(places.search('tanta').first);

        now = now.add(const Duration(hours: 1));
        await resume();

        expect(source.fixes, 0);
      });
    });
  });
}

class _RecordingReporter implements CrashReporter {
  final everything = <String>[];

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
    Map<String, Object?>? context,
  }) async => everything.add('$error $context');

  @override
  void addBreadcrumb(String message, {String? category}) => everything.add(message);
}
