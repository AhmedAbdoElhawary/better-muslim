import 'dart:math';

import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// null without a next prayer. the only home value that changes every second
final timeLeftProvider = Provider<Duration?>((ref) {
  final next = ref.watch(nextPrayerProvider.select((next) => next?.$2));
  if (next == null) return null;
  final now = ref.watch(tickerProvider).value ?? ref.watch(clockProvider)();
  return next.difference(now);
});

/// once a minute, rounded so a minute that moves it less than a step rebuilds nothing
final barShareProvider = Provider<double?>((ref) {
  final period = ref.watch(periodProvider);
  final next = ref.watch(nextPrayerProvider.select((next) => next?.$2));
  final times = ref.watch(todayTimesProvider);
  if (period == null || next == null || times == null) return null;
  final now = ref.watch(minuteProvider).value ?? ref.watch(clockProvider)();
  final today = ref.watch(todayProvider);
  final start = periodStart(
    period,
    now,
    times,
    ref.watch(dayTimesProvider(DateTime(today.year, today.month, today.day - 1))),
  );
  final share = barShare(now, start, next);
  return share == null ? null : (share * 1000).round() / 1000;
});

/// before today's start the period began the day before, isha before fajr started last night
DateTime? periodStart(Period period, DateTime now, DayTimes today, DayTimes? yesterday) {
  final start = today.startOf(period);
  if (start != null && !now.isBefore(start)) return start;
  return yesterday?.startOf(period);
}

/// null when the period's start is not available (polar)
double? barShare(DateTime now, DateTime? start, DateTime next) {
  if (start == null) return null;
  final whole = next.difference(start).inMilliseconds;
  if (whole <= 0) return null;
  return (now.difference(start).inMilliseconds / whole).clamp(0.0, 1.0);
}

/// rounded, so a tick landing just after the second doesn't show one second too few
({int hours, int minutes, int seconds}) countdownParts(Duration left) {
  final total = max(0, (left.inMicroseconds / Duration.microsecondsPerSecond).round());
  return (hours: total ~/ 3600, minutes: total ~/ 60 % 60, seconds: total % 60);
}
