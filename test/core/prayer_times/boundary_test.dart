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

  /// the clock gives utc, a prayer time is in the place's zone
  DateTime utc(DateTime time) =>
      DateTime.fromMicrosecondsSinceEpoch(time.microsecondsSinceEpoch, isUtc: true);

  /// testWidgets for its fake time, so the boundary timer can be run forward
  testWidgets('wakes at the prayer time and at its now window end, nothing in between', (
    tester,
  ) async {
    /// 10:00 in makkah
    final start = DateTime.utc(2026, 10, 15, 7);
    final origin = tester.binding.clock.now();
    final container = ProviderContainer(
      overrides: [
        ...testOverrides(),
        clockProvider.overrideWithValue(
          () => start.add(tester.binding.clock.now().difference(origin)),
        ),
        locationProvider.overrideWithValue(makkah()),
      ],
    );
    final wakes = <DateTime>[];
    container.listen(boundaryProvider, (_, now) => wakes.add(now));
    final period = container.listen(periodProvider, (_, _) {});
    await tester.pump();
    final dhuhr = container.read(todayTimesProvider)!.dhuhr!;

    expect(period.read(), Period.duha);

    await tester.pump(dhuhr.difference(start) - const Duration(seconds: 1));
    expect(wakes, isEmpty);

    await tester.pump(const Duration(seconds: 1));
    expect(wakes, [utc(dhuhr)]);
    expect(period.read(), Period.dhuhr);
    expect(container.read(nowPrayerProvider)?.$1, Prayer.dhuhr);

    await tester.pump(DayTimes.nowWindow);
    expect(wakes, [utc(dhuhr), utc(dhuhr.add(DayTimes.nowWindow))]);
    expect(container.read(nowPrayerProvider), isNull);
    expect(container.read(nextPrayerProvider)?.$1, Prayer.asr);

    container.dispose();
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('last night\'s isha window ends after midnight', (tester) async {
    final zone = tz.getLocation('Asia/Riyadh');
    tz.TZDateTime at(int hour, int minute) => tz.TZDateTime(zone, 2026, 10, 14, hour, minute);
    final late = DayTimes(
      date: DateTime(2026, 10, 14),
      fajr: at(4, 58),
      sunrise: at(6, 15),
      dhuhr: at(12, 5),
      asr: at(15, 27),
      maghrib: at(17, 56),
      isha: at(23, 50),
      method: PrayerMethod.ummAlQura,
      asrMethod: AsrMethod.standard,
    );

    /// 00:05 in makkah, the window ends 00:10
    final start = DateTime.utc(2026, 10, 14, 21, 5);
    final origin = tester.binding.clock.now();
    final container = ProviderContainer(
      overrides: [
        ...testOverrides(),
        clockProvider.overrideWithValue(
          () => start.add(tester.binding.clock.now().difference(origin)),
        ),
        locationProvider.overrideWithValue(makkah()),
        dayTimesProvider.overrideWith(
          (ref, date) => date == DateTime(2026, 10, 14) ? late : computeDayTimes(ref, date),
        ),
      ],
    );
    final wakes = <DateTime>[];
    container.listen(boundaryProvider, (_, now) => wakes.add(now));
    await tester.pump();

    expect(container.read(nowPrayerProvider)?.$1, Prayer.isha);

    await tester.pump(const Duration(minutes: 5));
    expect(wakes, [utc(late.isha!.add(DayTimes.nowWindow))]);
    expect(container.read(nowPrayerProvider), isNull);

    container.dispose();
    await tester.pump(const Duration(milliseconds: 1));
  });
}
