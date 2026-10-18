import 'dart:math' as math;

import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/qibla/model/compass_source.dart';
import 'package:better_muslim/features/qibla/model/declination.dart';
import 'package:better_muslim/features/qibla/model/qibla_math.dart';
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
        ...testOverrides(positionSource: position),
        clockProvider.overrideWithValue(() => now),
        compassSourceProvider.overrideWithValue(compass),
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

  group('place', () {
    Future<List<QiblaPlace?>> places(ProviderContainer container) async {
      final values = <QiblaPlace?>[];
      container.listen(
        qiblaPlaceProvider,
        (_, next) => next.whenData(values.add),
        fireImmediately: true,
      );
      await pumpEventQueue();
      return values;
    }

    const saved = (latitude: 51.5074, longitude: -0.1278, name: 'London', nameAr: 'لندن');

    test('a city picked by hand is used as it is, with no fix', () async {
      position = FakePositionSource(granted: LocationPermission.whileInUse);
      final container = containerWith(location: london());
      expect(await places(container), [saved]);
      expect(position.fixes, 0);
    });

    test('auto mode with permission takes a precise fix, keeps the name, saves nothing', () async {
      position = FakePositionSource(
        granted: LocationPermission.whileInUse,
        position: (latitude: 51.5, longitude: -.12),
      );
      final container = containerWith(location: london(mode: LocationMode.auto));
      expect(await places(container), [
        saved,
        (latitude: 51.5, longitude: -.12, name: 'London', nameAr: 'لندن'),
      ]);
      expect(position.accuracy, LocationAccuracy.high);
      final settings = await container.read(databaseProvider).watchSettings().first;
      expect(settings.latitude, isNull);
    });

    test('auto mode without permission keeps the saved place', () async {
      position = FakePositionSource(position: (latitude: 51.5, longitude: -.12));
      final container = containerWith(location: london(mode: LocationMode.auto));
      expect(await places(container), [saved]);
      expect(position.fixes, 0);
    });

    test('no location gives null', () async {
      final container = containerWith(noLocation: true);
      expect(await places(container), [null]);
      expect(container.read(qiblaStateProvider), QiblaState.noLocation);
    });
  });

  test('design scenario: london at 105°, a toggle switches to 119° and back', () async {
    final container = ProviderContainer(overrides: await designOverrides());
    addTearDown(container.dispose);
    container.listen(compassProvider, (_, _) {});
    container.listen(qiblaPlaceProvider, (_, _) {});
    await pumpEventQueue();
    expect(container.read(qiblaPlaceProvider).value?.name, 'London');
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
