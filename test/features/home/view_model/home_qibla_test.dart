import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/qibla/declination.dart';
import 'package:better_muslim/core/qibla/qibla_math.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/home/view_model/home_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../../../helpers/providers.dart';
import '../../../helpers/qibla.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(tz.initializeTimeZones);

  final now = DateTime.utc(2026, 10, 15, 13, 32);
  late FakeCompassSource compass;
  late FakePositionSource position;

  ProviderContainer containerWith(Location? location) {
    final container = ProviderContainer(
      overrides: [
        ...testOverrides(positionSource: position, compass: compass),
        clockProvider.overrideWithValue(() => now),
        locationProvider.overrideWithValue(location),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    compass = FakeCompassSource();
    position = FakePositionSource();
  });

  test('the turn to the qibla from the saved place in whole degrees, never a fix', () async {
    final container = containerWith(london(mode: LocationMode.auto));
    container.listen(homeQiblaProvider, (_, _) {});
    await pumpEventQueue();
    final bearing = qiblaBearing(51.5074, -0.1278);
    final offset = declination(51.5074, -0.1278, decimalYear: decimalYear(now));
    compass.send(bearing - 20.4 - offset);
    await pumpEventQueue();
    expect(container.read(homeQiblaProvider), 20);
    expect(position.fixes, 0);
  });

  test('null with no compass or no place, the sensor stops with the dial', () async {
    final container = containerWith(london());
    final subscription = container.listen(homeQiblaProvider, (_, _) {});
    await pumpEventQueue();
    compass.none();
    await pumpEventQueue();
    expect(container.read(homeQiblaProvider), isNull);
    subscription.close();
    await pumpEventQueue();
    expect(compass.listening, isFalse);

    expect(containerWith(null).read(homeQiblaProvider), isNull);
  });
}
