import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_method.dart';
import 'package:better_muslim/core/resources/design/bm_sky.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/features/home/model/home_moment.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

  TZDateTime at(int day, int hour, int minute) =>
      TZDateTime(getLocation('Asia/Riyadh'), 2026, 10, day, hour, minute);

  /// the handoff's times, isha left out for a polar day
  DayTimes times(int day, {bool polar = false}) => DayTimes(
    date: DateTime(2026, 10, day),
    fajr: at(day, 4, 58),
    sunrise: at(day, 6, 15),
    dhuhr: at(day, 12, 5),
    asr: at(day, 15, 27),
    maghrib: at(day, 17, 56),
    isha: polar ? null : at(day, 19, 26),
    method: PrayerMethod.ummAlQura,
    asrMethod: AsrMethod.standard,
  );

  group('bar share', () {
    test('16:32 on the scenario day is 0.436 of asr to maghrib', () {
      final now = at(15, 16, 32);
      final start = periodStart(Period.asr, now, times(15), times(14));

      expect(start, at(15, 15, 27));
      expect(barShare(now, start, at(15, 17, 56)), closeTo(.436, .001));
    });

    test('duha starts at sunrise', () {
      final now = at(15, 9, 0);
      final start = periodStart(Period.duha, now, times(15), times(14));

      expect(start, at(15, 6, 15));
      expect(barShare(now, start, at(15, 12, 5)), closeTo(165 / 350, .001));
    });

    test('before fajr isha started at yesterday\'s isha', () {
      final now = at(15, 3, 0);
      final start = periodStart(Period.isha, now, times(15), times(14));

      expect(start, at(14, 19, 26));
      expect(barShare(now, start, at(15, 4, 58)), closeTo(454 / 572, .001));
    });

    test('a polar day with no isha has no share for isha', () {
      final now = at(15, 3, 0);
      final start = periodStart(Period.isha, now, times(15, polar: true), times(14, polar: true));

      expect(start, isNull);
      expect(barShare(now, start, at(15, 4, 58)), isNull);
    });
  });

  group('countdown parts', () {
    test('hours are not padded, minutes and seconds are', () {
      expect(countdownParts(const Duration(hours: 1, minutes: 24)), (
        hours: 1,
        minutes: 24,
        seconds: 0,
      ));
      expect(countdownParts(const Duration(hours: 10, minutes: 5, seconds: 9)), (
        hours: 10,
        minutes: 5,
        seconds: 9,
      ));
    });

    test('a tick just after the second rounds to the nearest second (R5)', () {
      expect(
        countdownParts(const Duration(hours: 1, minutes: 23, seconds: 58, milliseconds: 997)),
        (hours: 1, minutes: 23, seconds: 59),
      );
    });
  });

  test('the glow breathes only in the final 10 minutes', () {
    expect(glowBreathing(const Duration(minutes: 9, seconds: 59)), isTrue);
    expect(glowBreathing(const Duration(minutes: 10)), isTrue);
    expect(glowBreathing(const Duration(minutes: 10, seconds: 1)), isFalse);
    expect(glowBreathing(Duration.zero), isFalse);
  });

  group('strip cell state', () {
    test('logged and past', () {
      expect(stripCellState(Prayer.fajr, Period.asr, {Prayer.fajr}), (
        current: false,
        logged: true,
        past: true,
      ));
    });

    test('current without a log gets the dot', () {
      expect(stripCellState(Prayer.asr, Period.asr, {}), (
        current: true,
        logged: false,
        past: false,
      ));
    });

    test('current and logged', () {
      expect(stripCellState(Prayer.asr, Period.asr, {Prayer.asr}), (
        current: true,
        logged: true,
        past: false,
      ));
    });

    test('later is plain', () {
      expect(stripCellState(Prayer.maghrib, Period.asr, {}), (
        current: false,
        logged: false,
        past: false,
      ));
    });

    test('no cell is current during duha', () {
      expect(
        Prayer.values.where((prayer) => stripCellState(prayer, Period.duha, {}).current),
        isEmpty,
      );
    });
  });

  test('each period has its sky state, no period is the theme base', () {
    expect(Period.values.map(skyState), [
      BmSkyState.fajr,
      BmSkyState.sunrise,
      BmSkyState.dhuhr,
      BmSkyState.asr,
      BmSkyState.maghrib,
      BmSkyState.isha,
    ]);
    expect(skyState(null), isNull);
  });

  test('stars only on the fajr, maghrib and isha skies, always on the theme base', () {
    expect(BmSkyState.values.where(starsOn), [
      BmSkyState.fajr,
      BmSkyState.maghrib,
      BmSkyState.isha,
    ]);
    expect(starsOn(null), isTrue);
  });

  group('sun share', () {
    late TZDateTime sunrise;
    late TZDateTime maghrib;
    setUp(() {
      sunrise = at(15, 6, 15);
      maghrib = at(15, 17, 56);
    });

    test('0 at sunrise, 1 at maghrib, rounded to 0.001', () {
      expect(sunShare(sunrise, sunrise, maghrib), 0);
      expect(sunShare(maghrib, sunrise, maghrib), 1);
      expect(sunShare(at(15, 16, 32), sunrise, maghrib), .88);
    });

    test('null at night or without sunrise or maghrib', () {
      expect(sunShare(at(15, 5, 0), sunrise, maghrib), isNull);
      expect(sunShare(at(15, 21, 0), sunrise, maghrib), isNull);
      expect(sunShare(at(15, 12, 0), null, maghrib), isNull);
    });
  });

  group('arc labels', () {
    test('sunrise and maghrib by day', () {
      expect(arcLabels(at(15, 16, 32), times(14), times(15), times(16)), (
        startKey: StringsManager.sunriseLabel,
        start: at(15, 6, 15),
        endKey: StringsManager.maghribLabel,
        end: at(15, 17, 56),
      ));
    });

    test('after maghrib, tonight\'s isha and tomorrow\'s fajr', () {
      expect(arcLabels(at(15, 21, 0), times(14), times(15), times(16)), (
        startKey: StringsManager.ishaLabel,
        start: at(15, 19, 26),
        endKey: StringsManager.fajrLabel,
        end: at(16, 4, 58),
      ));
    });

    test('after midnight, the prayer day\'s isha and today\'s fajr', () {
      expect(arcLabels(at(16, 1, 0), times(15), times(16), times(17)), (
        startKey: StringsManager.ishaLabel,
        start: at(15, 19, 26),
        endKey: StringsManager.fajrLabel,
        end: at(16, 4, 58),
      ));
    });

    test('a time that is null has no label', () {
      expect(arcLabels(at(15, 21, 0), times(14), times(15, polar: true), times(16)).start, isNull);
    });
  });
}
