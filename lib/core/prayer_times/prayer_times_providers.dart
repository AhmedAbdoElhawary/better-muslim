import 'dart:async';

import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/hijri/hijri_date.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_method.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' show TZDateTime;

/// the time of the last boundary, worked out again at the next one. what only changes at a
/// boundary follows this instead of the ticker, so nothing wakes the app between them
final boundaryProvider = Provider<DateTime>((ref) {
  final zone = ref.watch(locationProvider.select((location) => location?.zone));
  final clock = ref.watch(clockProvider);
  final fast = ref.watch(fastDayProvider);
  final now = clock();
  final local = zone == null ? now : TZDateTime.from(now, zone);
  final midnight = zone == null
      ? DateTime(local.year, local.month, local.day + 1)
      : TZDateTime(zone, local.year, local.month, local.day + 1);

  /// yesterday too, last night's isha window can end after midnight
  final times = [
    midnight,
    for (final day in [-1, 0, 1])
      ...?ref
          .watch(dayTimesProvider(DateTime(local.year, local.month, local.day + day)))
          ?.boundaries,
  ];
  final wait = times
      .map((time) => time.difference(now))
      .where((left) => left > Duration.zero)
      .reduce((a, b) => a < b ? a : b);
  final timer = Timer(fast ? wait ~/ fastDaySpeed : wait, ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return now;
});

/// the location's local date
final todayProvider = Provider<DateTime>((ref) {
  final zone = ref.watch(locationProvider.select((location) => location?.zone));
  final now = ref.watch(boundaryProvider);
  final local = zone == null ? now : TZDateTime.from(now, zone);
  return DateTime(local.year, local.month, local.day);
});

/// null without a location. reads no clock, so the same inputs give the same times
final dayTimesProvider = Provider.family<DayTimes?, DateTime>(computeDayTimes);

/// outside the provider, so the design scenario's override can fall back to it for other dates
DayTimes? computeDayTimes(Ref ref, DateTime date) {
  final location = ref.watch(locationProvider);
  final picked = ref.watch(
    settingsProvider.select(
      (settings) => (
        method: settings.value?.method,
        asrMethod: settings.value?.asrMethod,
        hijriAdjust: settings.value?.hijriAdjust ?? 0,
      ),
    ),
  );
  if (location == null) return null;
  return dayTimesAt(
    location,
    date,
    method: picked.method,
    asrMethod: picked.asrMethod,
    hijriAdjust: picked.hijriAdjust,
  );
}

/// null method or asr = by country. plain, so the background top-up computes the same times
DayTimes dayTimesAt(
  Location location,
  DateTime date, {
  required PrayerMethod? method,
  required AsrMethod? asrMethod,
  required int hijriAdjust,
}) => DayTimes.compute(
  latitude: location.latitude,
  longitude: location.longitude,
  date: date,
  zone: location.zone,
  method: method ?? PrayerMethod.forCountry(location.countryCode),
  asrMethod: asrMethod ?? AsrMethod.forCountry(location.countryCode),
  isRamadan: HijriDate.of(date, hijriAdjust).month == 9,
);

final todayTimesProvider = Provider<DayTimes?>(
  (ref) => ref.watch(dayTimesProvider(ref.watch(todayProvider))),
);

/// fajr to the next fajr, so last night's isha and its log stay until fajr. a missing fajr
/// counts as not yet
final prayerDayProvider = Provider<DateTime>((ref) {
  final today = ref.watch(todayProvider);
  final times = ref.watch(
    todayTimesProvider.select((times) => (located: times != null, fajr: times?.fajr)),
  );
  if (!times.located) return today;
  final now = ref.watch(boundaryProvider);
  return prayerDayOf(now, today, times.fajr);
});

/// the day before until today's fajr has come
DateTime prayerDayOf(DateTime now, DateTime today, DateTime? fajr) {
  if (fajr != null && !now.isBefore(fajr)) return today;
  return DateTime(today.year, today.month, today.day - 1);
}

final periodProvider = Provider<Period?>((ref) {
  final now = ref.watch(boundaryProvider);
  return ref.watch(todayTimesProvider)?.periodAt(now);
});

final nextPrayerProvider = Provider<(Prayer, TZDateTime)?>((ref) {
  final now = ref.watch(boundaryProvider);
  final today = ref.watch(todayProvider);
  final tomorrow = DateTime(today.year, today.month, today.day + 1);
  return ref.watch(todayTimesProvider)?.next(now, ref.watch(dayTimesProvider(tomorrow)));
});

/// the prayer day's, so last night's isha keeps its window past midnight
final nowPrayerProvider = Provider<(Prayer, TZDateTime)?>((ref) {
  final now = ref.watch(boundaryProvider);
  return ref.watch(dayTimesProvider(ref.watch(prayerDayProvider)))?.inWindow(now);
});

/// what home and the prayer tab point at. after isha's window it is tomorrow's fajr, which no
/// row of the prayer day has
final highlightedPrayerProvider = Provider<(Prayer, TZDateTime)?>(
  (ref) => ref.watch(nowPrayerProvider) ?? ref.watch(nextPrayerProvider),
);
