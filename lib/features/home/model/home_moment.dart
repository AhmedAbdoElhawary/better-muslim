import 'dart:math';

import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/resources/design/bm_sky.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:timezone/timezone.dart';

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

/// MOTION 05, the final 10 minutes before the next prayer
bool glowBreathing(Duration left) => left > Duration.zero && left <= const Duration(minutes: 10);

/// duha has no prayer, so no cell is current then
({bool current, bool logged, bool past}) stripCellState(
  Prayer prayer,
  Period? period,
  Set<Prayer> prayed,
) {
  final own = Period.values.byName(prayer.name);
  return (
    current: own == period,
    logged: prayed.contains(prayer),
    past: period != null && own.index < period.index,
  );
}

/// null = no period, the sky shows the theme's own base sky
BmSkyState? skyState(Period? period) => switch (period) {
  null => null,
  Period.fajr => BmSkyState.fajr,
  Period.duha => BmSkyState.sunrise,
  Period.dhuhr => BmSkyState.dhuhr,
  Period.asr => BmSkyState.asr,
  Period.maghrib => BmSkyState.maghrib,
  Period.isha => BmSkyState.isha,
};

bool starsOn(BmSkyState? state) =>
    state == null ||
    state == BmSkyState.fajr ||
    state == BmSkyState.maghrib ||
    state == BmSkyState.isha;

/// rounded, so the sun moves about every 40 s instead of every second
double? sunShare(DateTime now, DateTime? sunrise, DateTime? maghrib) {
  if (sunrise == null || maghrib == null || now.isBefore(sunrise) || now.isAfter(maghrib)) {
    return null;
  }
  final share = now.difference(sunrise).inSeconds / maghrib.difference(sunrise).inSeconds;
  return (share * 1000).round() / 1000;
}

typedef ArcLabels = ({String startKey, TZDateTime? start, String endKey, TZDateTime? end});

/// by night the isha that started it and the fajr that ends it, so after midnight isha is
/// yesterday's
ArcLabels arcLabels(DateTime now, DayTimes? yesterday, DayTimes today, DayTimes? tomorrow) {
  final sunrise = today.sunrise;
  final maghrib = today.maghrib;
  if (sunrise != null && maghrib != null && !now.isBefore(sunrise) && now.isBefore(maghrib)) {
    return (
      startKey: StringsManager.sunriseLabel,
      start: sunrise,
      endKey: StringsManager.maghribLabel,
      end: maghrib,
    );
  }
  final evening = maghrib != null && !now.isBefore(maghrib);
  return (
    startKey: StringsManager.ishaLabel,
    start: evening ? today.isha : yesterday?.isha,
    endKey: StringsManager.fajrLabel,
    end: evening ? tomorrow?.fajr : today.fajr,
  );
}

/// morning from fajr until asr, evening from asr until the next fajr
bool isMorningAzkar(Period? period) =>
    period == Period.fajr || period == Period.duha || period == Period.dhuhr;
