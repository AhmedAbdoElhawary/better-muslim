import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/next_prayer.dart';
import 'package:better_muslim/core/prayer_times/prayer_method.dart';
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

  group('arc share', () {
    late TZDateTime sunrise;
    late TZDateTime maghrib;
    setUp(() {
      sunrise = at(15, 6, 15);
      maghrib = at(15, 17, 56);
    });

    test('0 at the start, 1 at the end, rounded to 0.001', () {
      expect(arcShare(sunrise, sunrise, maghrib), 0);
      expect(arcShare(maghrib, sunrise, maghrib), 1);
      expect(arcShare(at(15, 16, 32), sunrise, maghrib), .88);
    });

    test('null outside the arc or without an end', () {
      expect(arcShare(at(15, 5, 0), sunrise, maghrib), isNull);
      expect(arcShare(at(15, 21, 0), sunrise, maghrib), isNull);
      expect(arcShare(at(15, 12, 0), null, maghrib), isNull);
    });
  });

  group('arc points', () {
    List<String> names(ArcPoints points) => [for (final point in points.points) point.name];

    test('by day sunrise, dhuhr, asr and maghrib, dhuhr near the top', () {
      final arc = arcPoints(at(15, 16, 32), times(14), times(15), times(16))!;

      expect(arc.kind, ArcKind.day);
      expect(names(arc), [
        StringsManager.sunriseLabel,
        StringsManager.dhuhrLabel,
        StringsManager.asrLabel,
        StringsManager.maghribLabel,
      ]);
      expect(arc.points.first.share, 0);
      expect(arc.points[1].share, closeTo(.5, .01));
      expect(arc.points.last.share, 1);
      expect(arcShare(at(15, 16, 32), arc.start, arc.end), greaterThan(arc.points[2].share));
    });

    test('at 23:00 the night to tomorrow\'s sunrise, the marker between isha and last third', () {
      final now = at(15, 23, 0);
      final arc = arcPoints(now, times(14), times(15), times(16))!;

      expect(arc.kind, ArcKind.night);
      expect(names(arc), [
        StringsManager.maghribLabel,
        StringsManager.ishaLabel,
        StringsManager.lastThirdLabel,
        StringsManager.fajrLabel,
        StringsManager.sunriseLabel,
      ]);
      expect(arc.start, at(15, 17, 56));
      expect(arc.end, at(16, 6, 15));
      expect(arc.points[2].time, at(16, 4, 58).subtract(const Duration(minutes: 662) ~/ 3));
      final shares = [for (final point in arc.points) point.share];
      expect(shares, [...shares]..sort());
      final marker = arcShare(now, arc.start, arc.end)!;
      expect(marker, greaterThan(arc.points[1].share));
      expect(marker, lessThan(arc.points[2].share));
    });

    test('at 05:00 the night is yesterday\'s maghrib to today\'s sunrise', () {
      final arc = arcPoints(at(16, 5, 0), times(15), times(16), times(17))!;

      expect(arc.kind, ArcKind.night);
      expect(arc.start, at(15, 17, 56));
      expect(arc.end, at(16, 6, 15));
      expect(arc.points[1].time, at(15, 19, 26));
      expect(arc.points[3].time, at(16, 4, 58));
    });

    test('a null time drops its point, a null end drops the arc', () {
      final polar = DayTimes(
        date: DateTime(2026, 10, 15),
        fajr: at(15, 4, 58),
        sunrise: at(15, 6, 15),
        dhuhr: at(15, 12, 5),
        asr: null,
        maghrib: at(15, 17, 56),
        isha: null,
        method: PrayerMethod.ummAlQura,
        asrMethod: AsrMethod.standard,
      );

      expect(names(arcPoints(at(15, 16, 32), times(14), polar, times(16))!), [
        StringsManager.sunriseLabel,
        StringsManager.dhuhrLabel,
        StringsManager.maghribLabel,
      ]);
      expect(
        names(arcPoints(at(15, 21, 0), times(14), polar, times(16))!),
        isNot(contains(StringsManager.ishaLabel)),
      );
      expect(arcPoints(at(15, 21, 0), times(14), times(15), null), isNull);
    });

    test('the same times are equal, so the provider only notifies at sunrise and maghrib', () {
      expect(
        arcPoints(at(15, 16, 32), times(14), times(15), times(16)),
        arcPoints(at(15, 16, 33), times(14), times(15), times(16)),
      );
    });
  });
}
