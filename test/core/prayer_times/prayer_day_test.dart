import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../helpers/providers.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

  Location makkah() => Location(
    latitude: 21.4225,
    longitude: 39.8262,
    placeName: 'Makkah',
    countryCode: 'SA',
    zone: tz.getLocation('Asia/Riyadh'),
    mode: LocationMode.auto,
  );

  final containers = <ProviderContainer>[];

  /// flutter_test checks for pending timers before tear downs run, so each test ends with this
  Future<void> disposeAll(WidgetTester tester) async {
    for (final container in containers) {
      container.dispose();
    }
    containers.clear();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  }

  /// testWidgets for its fake time, so the ticker and drift's timers can run
  Future<ProviderContainer> containerAt(
    WidgetTester tester,
    DateTime start, {
    bool located = true,
  }) async {
    final origin = tester.binding.clock.now();
    final container = ProviderContainer(
      overrides: [
        ...testOverrides(),
        clockProvider.overrideWithValue(
          () => start.add(tester.binding.clock.now().difference(origin)),
        ),
        if (located) locationProvider.overrideWithValue(makkah()),
      ],
    );
    containers.add(container);
    container.listen(prayerDayProvider, (_, _) {});
    await tester.pump();
    return container;
  }

  /// 03:00 in makkah, fajr is about 05:00
  testWidgets('before fajr it is still yesterday', (tester) async {
    final container = await containerAt(tester, DateTime.utc(2026, 10, 15, 0));

    expect(container.read(prayerDayProvider), DateTime(2026, 10, 14));
    await disposeAll(tester);
  });

  testWidgets('from fajr until midnight it is today', (tester) async {
    final container = await containerAt(tester, DateTime.utc(2026, 10, 15, 0));
    final fajr = container.read(todayTimesProvider)!.fajr!;

    final atFajr = await containerAt(tester, fajr.toUtc());
    final lastMinute = await containerAt(tester, DateTime.utc(2026, 10, 15, 20, 59));

    expect(atFajr.read(prayerDayProvider), DateTime(2026, 10, 15));
    expect(lastMinute.read(prayerDayProvider), DateTime(2026, 10, 15));
    await disposeAll(tester);
  });

  testWidgets('it notifies once at fajr, not every second', (tester) async {
    final probe = await containerAt(tester, DateTime.utc(2026, 10, 15, 0));
    final fajr = probe.read(todayTimesProvider)!.fajr!;

    final container = await containerAt(tester, fajr.toUtc().subtract(const Duration(seconds: 5)));
    final days = <DateTime>[];
    container.listen(prayerDayProvider, (_, day) => days.add(day));

    await tester.pump(const Duration(seconds: 20));

    expect(days, [DateTime(2026, 10, 15)]);
    await disposeAll(tester);
  });

  testWidgets('with no location it is the local date', (tester) async {
    final container = await containerAt(tester, DateTime(2026, 10, 15, 3), located: false);

    expect(container.read(prayerDayProvider), DateTime(2026, 10, 15));
    await disposeAll(tester);
  });
}
