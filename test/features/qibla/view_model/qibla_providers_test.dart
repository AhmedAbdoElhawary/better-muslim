import 'dart:math' as math;

import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/location/place_list.dart';
import 'package:better_muslim/core/qibla/compass.dart';
import 'package:better_muslim/core/qibla/compass_source.dart';
import 'package:better_muslim/core/qibla/declination.dart';
import 'package:better_muslim/core/qibla/qibla_math.dart';
import 'package:better_muslim/core/qibla/qibla_place.dart';
import 'package:better_muslim/features/qibla/model/qibla_tracker.dart';
import 'package:better_muslim/features/qibla/view_model/qibla_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../../../helpers/providers.dart';
import '../../../helpers/qibla.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(tz.initializeTimeZones);

  late DateTime now;
  late FakeCompassSource compass;
  late FakePositionSource position;

  ProviderContainer containerWith({Location? location, bool noLocation = false}) {
    final container = ProviderContainer(
      overrides: [
        ...testOverrides(positionSource: position, compass: compass),
        clockProvider.overrideWithValue(() => now),
        if (location != null || noLocation) locationProvider.overrideWithValue(location),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    now = DateTime.utc(2026, 10, 15, 13, 32);
    compass = FakeCompassSource();
    position = FakePositionSource();
  });

  double? heading(ProviderContainer container) => container.read(compassProvider).value?.heading;

  /// degrees between two headings, the short way
  double apart(double a, double b) => qiblaDiff(a, b).abs();

  group('smoothing', () {
    test('359° then 1° stays near north', () async {
      final container = containerWith(noLocation: true);
      container.listen(compassProvider, (_, _) {});
      compass.send(359);
      await pumpEventQueue();
      now = now.add(const Duration(milliseconds: 50));
      compass.send(1);
      await pumpEventQueue();
      expect(apart(heading(container)!, 0), lessThan(1.5));
    });

    test('a still phone moves the heading less than 1° (SC-004)', () async {
      final container = containerWith(noLocation: true);
      container.listen(compassProvider, (_, _) {});
      final random = math.Random(3);
      for (var i = 0; i < 100; i++) {
        compass.send(120 + random.nextDouble() - .5);
        await pumpEventQueue();
        expect(apart(heading(container)!, 120), lessThan(1));
        now = now.add(const Duration(milliseconds: 20));
      }
    });
  });

  test('true heading = magnetic + the declination at the place, today', () async {
    final container = containerWith(location: london());
    container.listen(compassProvider, (_, _) {});
    await pumpEventQueue();
    compass.send(100, accuracy: 25);
    await pumpEventQueue();
    final expected = 100 + declination(51.5074, -0.1278, decimalYear: decimalYear(now));
    expect(heading(container), closeTo(expected, 1e-9));
    expect(container.read(compassProvider).value?.accuracy, CompassAccuracy.medium);
  });

  group('place, where the phone is (spec 027)', () {
    late PlaceList list;
    setUpAll(() async => list = await PlaceList.load());

    ProviderContainer following(Location? location) {
      final container = ProviderContainer(
        overrides: [
          ...testOverrides(positionSource: position, compass: compass),
          clockProvider.overrideWithValue(() => now),
          locationProvider.overrideWithValue(location),
          placeListProvider.overrideWith((ref) => list),
        ],
      );
      addTearDown(container.dispose);
      container.listen(qiblaFollowProvider, (_, _) {});
      container.listen(qiblaPlaceProvider, (_, _) {});
      return container;
    }

    const riyadh = (latitude: 24.7136, longitude: 46.6753);

    test(
      'a city picked by hand until the fix comes, then the fix and its city, saved nowhere',
      () async {
        position = FakePositionSource(granted: LocationPermission.whileInUse);
        final container = following(london());
        await pumpEventQueue();
        expect(container.read(qiblaPlaceProvider)?.name, 'London');

        position.followed.add(riyadh);
        await pumpEventQueue();
        expect(container.read(qiblaPlaceProvider), (
          latitude: riyadh.latitude,
          longitude: riyadh.longitude,
          name: 'Riyadh',
          nameAr: container.read(qiblaPlaceProvider)?.nameAr,
        ));
        expect(container.read(qiblaPlaceProvider)?.nameAr, isNotNull);

        /// a few hundred metres on, the same city without a new search
        position.followed.add((latitude: 24.7156, longitude: 46.6753));
        await pumpEventQueue();
        expect(container.read(qiblaPlaceProvider)?.latitude, 24.7156);
        expect(container.read(qiblaPlaceProvider)?.name, 'Riyadh');

        final settings = await container.read(databaseProvider).watchSettings().first;
        expect(settings.latitude, isNull);
      },
    );

    test('north comes from the fix, not the saved place', () async {
      position = FakePositionSource(granted: LocationPermission.whileInUse);
      final container = following(london());
      container.listen(compassProvider, (_, _) {});
      await pumpEventQueue();
      position.followed.add(riyadh);
      await pumpEventQueue();
      compass.send(100);
      await pumpEventQueue();
      final expected =
          100 + declination(riyadh.latitude, riyadh.longitude, decimalYear: decimalYear(now));
      expect(heading(container), closeTo(expected, 1e-9));
    });

    test('asks once without permission, the saved place stays', () async {
      position = FakePositionSource(answer: LocationPermission.denied);
      final container = following(london());
      await pumpEventQueue();
      toBackground(binding);
      toFront(binding);
      await pumpEventQueue();
      expect(position.requests, 1);
      expect(position.followed.hasListener, isFalse);
      expect(container.read(qiblaPlaceProvider)?.name, 'London');
    });

    test('follows only while in front', () async {
      position = FakePositionSource(granted: LocationPermission.whileInUse);
      following(london());
      await pumpEventQueue();
      expect(position.followed.hasListener, isTrue);
      toBackground(binding);
      expect(position.followed.hasListener, isFalse);
      toFront(binding);
      await pumpEventQueue();
      expect(position.followed.hasListener, isTrue);
    });

    test('no location and no fix gives null', () async {
      final container = containerWith(noLocation: true);
      container.listen(qiblaStateProvider, (_, _) {});
      expect(container.read(qiblaPlaceProvider), isNull);
      expect(container.read(qiblaStateProvider), QiblaState.noLocation);
    });
  });

  test('design scenario: london at 105°, a toggle switches to 119° and back', () async {
    final container = ProviderContainer(overrides: await designOverrides());
    addTearDown(container.dispose);
    container.listen(compassProvider, (_, _) {});
    container.listen(qiblaPlaceProvider, (_, _) {});
    await pumpEventQueue();
    expect(container.read(qiblaPlaceProvider)?.name, 'London');
    expect(container.read(compassProvider).value, (heading: 105.0, accuracy: CompassAccuracy.high));
    expect(container.read(turnDegreesProvider), 14);

    container.read(designHeadingProvider.notifier).toggle();
    await pumpEventQueue();
    expect(heading(container), 119);
    container.read(designHeadingProvider.notifier).toggle();
    await pumpEventQueue();
    expect(heading(container), 105);
  });

  group('tracker', () {
    test('aligns after 400 ms with no new reading, resets on pause', () async {
      final container = containerWith(location: london());
      container.listen(qiblaTrackerProvider, (_, _) {});
      await pumpEventQueue();
      final bearing = container.read(qiblaTargetProvider)!.bearing;
      final offset = declination(51.5074, -0.1278, decimalYear: decimalYear(now));
      compass.send(bearing - 2 - offset);
      await pumpEventQueue();
      expect(container.read(qiblaTrackerProvider).phase, QiblaPhase.turning);

      await Future<void>.delayed(const Duration(milliseconds: 450));
      expect(container.read(qiblaTrackerProvider), (
        phase: QiblaPhase.aligned,
        approaches: 0,
        alignments: 1,
      ));

      toBackground(binding);
      expect(container.read(qiblaTrackerProvider).phase, QiblaPhase.turning);
      toFront(binding);
    });
  });

  group('the sensor runs only while needed (FR-006, SC-007)', () {
    test('cancelled when the page goes and on pause, listened again on resume', () async {
      final container = containerWith(noLocation: true);
      final subscription = container.listen(compassProvider, (_, _) {});
      await pumpEventQueue();
      expect(compass.listening, isTrue);

      toBackground(binding);
      expect(compass.listening, isFalse);
      toFront(binding);
      expect(compass.listening, isTrue);
      expect(compass.listens, 2);

      subscription.close();
      await pumpEventQueue();
      expect(compass.listening, isFalse);
    });
  });
}
