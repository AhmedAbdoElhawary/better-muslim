import 'package:better_muslim/core/azkar/azkar_window.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_method.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

  TZDateTime at(int day, int hour, int minute) =>
      TZDateTime(getLocation('Asia/Riyadh'), 2026, 10, day, hour, minute);

  /// the handoff's times
  DayTimes times(int day) => DayTimes(
    date: DateTime(2026, 10, day),
    fajr: at(day, 4, 58),
    sunrise: at(day, 6, 15),
    dhuhr: at(day, 12, 5),
    asr: at(day, 15, 27),
    maghrib: at(day, 17, 56),
    isha: at(day, 19, 26),
    method: PrayerMethod.ummAlQura,
    asrMethod: AsrMethod.standard,
  );

  DayTimes london(int day) => DayTimes.compute(
    latitude: 51.5072,
    longitude: -0.1276,
    date: DateTime(2026, 10, day),
    zone: getLocation('Europe/London'),
    method: PrayerMethod.muslimWorldLeague,
    asrMethod: AsrMethod.standard,
    isRamadan: false,
  );

  /// what the providers do with the local date's times
  ({AzkarSet current, DateTime morning, DateTime evening}) window(DateTime now, DayTimes today) {
    final period = today.periodAt(now);
    final day = prayerDayOf(now, today.date, today.fajr);
    return (
      current: currentAzkarSet(period),
      morning: azkarWindowDay(AzkarSet.morning, day, period),
      evening: azkarWindowDay(AzkarSet.evening, day, period),
    );
  }

  test('morning in fajr, duha and dhuhr, evening from asr and without a period', () {
    expect(Period.values.where((period) => currentAzkarSet(period) == AzkarSet.morning), [
      Period.fajr,
      Period.duha,
      Period.dhuhr,
    ]);
    expect(currentAzkarSet(null), AzkarSet.evening);
  });

  test('the set keys and the prayer each nudge follows', () {
    expect(AzkarSet.morning.nudgePrayer, Prayer.fajr);
    expect(AzkarSet.evening.nudgePrayer, Prayer.asr);
  });

  group('the latest window (SC-004)', () {
    test('one minute before fajr is still last night\'s evening', () {
      expect(window(at(15, 4, 57), times(15)), (
        current: AzkarSet.evening,
        morning: DateTime(2026, 10, 14),
        evening: DateTime(2026, 10, 14),
      ));
    });

    test('one minute after fajr the morning is today\'s, the evening still last night\'s', () {
      expect(window(at(15, 4, 59), times(15)), (
        current: AzkarSet.morning,
        morning: DateTime(2026, 10, 15),
        evening: DateTime(2026, 10, 14),
      ));
    });

    test('one minute before asr the morning goes on', () {
      expect(window(at(15, 15, 26), times(15)).current, AzkarSet.morning);
      expect(window(at(15, 15, 26), times(15)).evening, DateTime(2026, 10, 14));
    });

    test('one minute after asr both are today\'s', () {
      expect(window(at(15, 15, 28), times(15)), (
        current: AzkarSet.evening,
        morning: DateTime(2026, 10, 15),
        evening: DateTime(2026, 10, 15),
      ));
    });

    test('at 00:30 it is the evening of the day before', () {
      expect(window(at(16, 0, 30), times(16)), (
        current: AzkarSet.evening,
        morning: DateTime(2026, 10, 15),
        evening: DateTime(2026, 10, 15),
      ));
    });

    test('at 10:00 the morning is today\'s and the evening yesterday\'s', () {
      expect(window(at(15, 10, 0), times(15)), (
        current: AzkarSet.morning,
        morning: DateTime(2026, 10, 15),
        evening: DateTime(2026, 10, 14),
      ));
    });

    test('at 16:32, the design scenario, both are today\'s', () {
      expect(window(at(15, 16, 32), times(15)), (
        current: AzkarSet.evening,
        morning: DateTime(2026, 10, 15),
        evening: DateTime(2026, 10, 15),
      ));
    });

    test('without a period both sets use the day given', () {
      expect(
        azkarWindowDay(AzkarSet.evening, DateTime(2026, 10, 15), null),
        DateTime(2026, 10, 15),
      );
    });
  });

  test('the london clock change day keeps its fajr and asr boundaries', () {
    final day = london(25);
    const minute = Duration(minutes: 1);

    expect(window(day.fajr!.subtract(minute), day).evening, DateTime(2026, 10, 24));
    expect(window(day.fajr!.add(minute), day).morning, DateTime(2026, 10, 25));
    expect(window(day.asr!.subtract(minute), day).current, AzkarSet.morning);
    expect(window(day.asr!.add(minute), day), (
      current: AzkarSet.evening,
      morning: DateTime(2026, 10, 25),
      evening: DateTime(2026, 10, 25),
    ));
  });

  test('flying from makkah to london the evening stays on its prayer day', () {
    final now = at(15, 21, 0);

    expect(window(now, times(15)).evening, DateTime(2026, 10, 15));
    expect(
      window(TZDateTime.from(now, getLocation('Europe/London')), london(15)).evening,
      DateTime(2026, 10, 15),
    );
  });
}
