import 'dart:async';

import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/hijri/hijri_date.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_method.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' show TZDateTime;

/// the location's local date. rebuilds itself at the next local midnight
final todayProvider = Provider<DateTime>((ref) {
  final zone = ref.watch(locationProvider.select((location) => location?.zone));
  final clock = ref.watch(clockProvider);
  final now = zone == null ? clock() : TZDateTime.from(clock(), zone);
  final midnight = zone == null
      ? DateTime(now.year, now.month, now.day + 1)
      : TZDateTime(zone, now.year, now.month, now.day + 1);
  final timer = Timer(midnight.difference(now), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return DateTime(now.year, now.month, now.day);
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
/// counts as not yet. follows the ticker, but only notifies when the day changes
final prayerDayProvider = Provider<DateTime>((ref) {
  final today = ref.watch(todayProvider);
  final times = ref.watch(
    todayTimesProvider.select((times) => (located: times != null, fajr: times?.fajr)),
  );
  if (!times.located) return today;
  final now = ref.watch(tickerProvider).value ?? ref.watch(clockProvider)();
  return prayerDayOf(now, today, times.fajr);
});

/// the day before until today's fajr has come
DateTime prayerDayOf(DateTime now, DateTime today, DateTime? fajr) {
  if (fajr != null && !now.isBefore(fajr)) return today;
  return DateTime(today.year, today.month, today.day - 1);
}

/// follows the ticker, but only notifies when the period changes
final periodProvider = Provider<Period?>((ref) {
  final now = ref.watch(tickerProvider).value ?? ref.watch(clockProvider)();
  return ref.watch(todayTimesProvider)?.periodAt(now);
});

final nextPrayerProvider = Provider<(Prayer, TZDateTime)?>((ref) {
  final now = ref.watch(tickerProvider).value ?? ref.watch(clockProvider)();
  final today = ref.watch(todayProvider);
  final tomorrow = DateTime(today.year, today.month, today.day + 1);
  return ref.watch(todayTimesProvider)?.next(now, ref.watch(dayTimesProvider(tomorrow)));
});

/// the prayer day's, so last night's isha keeps its window past midnight
final nowPrayerProvider = Provider<(Prayer, TZDateTime)?>((ref) {
  final now = ref.watch(tickerProvider).value ?? ref.watch(clockProvider)();
  return ref.watch(dayTimesProvider(ref.watch(prayerDayProvider)))?.inWindow(now);
});

/// what home and the prayer tab point at. after isha's window it is tomorrow's fajr, which no
/// row of the prayer day has
final highlightedPrayerProvider = Provider<(Prayer, TZDateTime)?>(
  (ref) => ref.watch(nowPrayerProvider) ?? ref.watch(nextPrayerProvider),
);
