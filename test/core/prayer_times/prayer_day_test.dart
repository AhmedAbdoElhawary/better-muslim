import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_method.dart';
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

  group('endOf', () {
    final zone = tz.UTC;
    tz.TZDateTime at(int day, int hour) => tz.TZDateTime(zone, 2026, 10, day, hour);
    DayTimes times(
      int day, {
      bool fajr = true,
      bool asr = true,
      bool maghrib = true,
      bool isha = true,
    }) => DayTimes(
      date: DateTime(2026, 10, day),
      fajr: fajr ? at(day, 5) : null,
      sunrise: at(day, 6),
      dhuhr: at(day, 12),
      asr: asr ? at(day, 15) : null,
      maghrib: maghrib ? at(day, 18) : null,
      isha: isha ? at(day, 19) : null,
      method: PrayerMethod.ummAlQura,
      asrMethod: AsrMethod.standard,
    );

    test('each prayer ends where the next period starts, isha at tomorrow fajr', () {
      final today = times(15);
      final tomorrow = times(16);

      expect(today.endOf(Prayer.fajr, tomorrow), at(15, 6));
      expect(today.endOf(Prayer.dhuhr, tomorrow), at(15, 15));
      expect(today.endOf(Prayer.asr, tomorrow), at(15, 18));
      expect(today.endOf(Prayer.maghrib, tomorrow), at(15, 19));
      expect(today.endOf(Prayer.isha, tomorrow), at(16, 5));
    });

    test('a missing time is skipped, and with nothing left it is null', () {
      final polar = times(15, asr: false, isha: false);

      expect(polar.endOf(Prayer.dhuhr, times(16)), at(15, 18));
      expect(polar.endOf(Prayer.maghrib, times(16)), at(16, 5));
      expect(polar.endOf(Prayer.maghrib, times(16, fajr: false)), isNull);
      expect(polar.endOf(Prayer.isha, null), isNull);
    });

    /// 1 ramadan 1448 is about 10 feb 2027
    test('in ramadan with umm al-qura maghrib stays open 120 minutes', () {
      final ramadan = DayTimes.compute(
        latitude: 21.4225,
        longitude: 39.8262,
        date: DateTime(2027, 2, 20),
        zone: tz.getLocation('Asia/Riyadh'),
        method: PrayerMethod.ummAlQura,
        asrMethod: AsrMethod.standard,
        isRamadan: true,
      );

      expect(
        ramadan.endOf(Prayer.maghrib, null)!.difference(ramadan.maghrib!),
        const Duration(minutes: 120),
      );
    });
  });

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

  /// 23:59 and 00:01 in makkah
  testWidgets('midnight changes nothing, the day runs until fajr (SC-004)', (tester) async {
    final before = await containerAt(tester, DateTime.utc(2026, 10, 15, 20, 59));
    final after = await containerAt(tester, DateTime.utc(2026, 10, 15, 21, 1));

    expect(before.read(prayerDayProvider), DateTime(2026, 10, 15));
    expect(after.read(prayerDayProvider), DateTime(2026, 10, 15));
    await disposeAll(tester);
  });

  testWidgets('with no location it is the local date', (tester) async {
    final container = await containerAt(tester, DateTime(2026, 10, 15, 3), located: false);

    expect(container.read(prayerDayProvider), DateTime(2026, 10, 15));
    await disposeAll(tester);
  });
}
