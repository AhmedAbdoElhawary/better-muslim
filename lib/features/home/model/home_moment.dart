import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart';

/// matched by time, so after isha's now window tomorrow's fajr lights no cell and the whole day
/// is past
({bool current, bool logged, bool past}) stripCellState(
  Prayer prayer,
  TZDateTime? time,
  (Prayer, TZDateTime)? highlighted,
  Set<Prayer> prayed,
) => (
  current:
      time != null &&
      highlighted != null &&
      highlighted.$1 == prayer &&
      highlighted.$2.isAtSameMomentAs(time),
  logged: prayed.contains(prayer),
  past: time != null && highlighted != null && time.isBefore(highlighted.$2),
);

/// 0 at the arc's start, 1 at its end. rounded, so a minute that moves it less than a step
/// rebuilds nothing
double? arcShare(DateTime now, DateTime? start, DateTime? end) {
  if (start == null || end == null || now.isBefore(start) || now.isAfter(end)) return null;
  final share = now.difference(start).inSeconds / end.difference(start).inSeconds;
  return (share * 1000).round() / 1000;
}

enum ArcKind { day, night }

typedef ArcPoint = ({String name, TZDateTime time, double share});

class ArcPoints {
  const ArcPoints({
    required this.kind,
    required this.start,
    required this.end,
    required this.points,
  });

  final ArcKind kind;
  final TZDateTime start;
  final TZDateTime end;

  /// in time order, the first and last are the arc's feet
  final List<ArcPoint> points;

  @override
  bool operator ==(Object other) =>
      other is ArcPoints &&
      other.kind == kind &&
      other.start == start &&
      other.end == end &&
      listEquals(other.points, points);

  @override
  int get hashCode => Object.hash(kind, start, end, Object.hashAll(points));
}

/// sunrise to maghrib by day, maghrib to the next sunrise by night, so before sunrise the night
/// is yesterday's. null without both ends (polar)
ArcPoints? arcPoints(DateTime now, DayTimes? yesterday, DayTimes today, DayTimes? tomorrow) {
  final sunrise = today.sunrise;
  final maghrib = today.maghrib;
  if (sunrise != null && maghrib != null && !now.isBefore(sunrise) && now.isBefore(maghrib)) {
    return _points(ArcKind.day, sunrise, maghrib, [
      (StringsManager.sunriseLabel, sunrise),
      (StringsManager.dhuhrLabel, today.dhuhr),
      (StringsManager.asrLabel, today.asr),
      (StringsManager.maghribLabel, maghrib),
    ]);
  }
  final evening = maghrib != null && !now.isBefore(maghrib);
  final night = evening ? today : yesterday;
  final start = night?.maghrib;
  final end = evening ? tomorrow?.sunrise : sunrise;
  final fajr = evening ? tomorrow?.fajr : today.fajr;
  if (start == null || end == null) return null;
  return _points(ArcKind.night, start, end, [
    (StringsManager.maghribLabel, start),
    (StringsManager.ishaLabel, night?.isha),
    (StringsManager.lastThirdLabel, night?.lastThird(fajr)),
    (StringsManager.fajrLabel, fajr),
    (StringsManager.sunriseLabel, end),
  ]);
}

ArcPoints _points(
  ArcKind kind,
  TZDateTime start,
  TZDateTime end,
  List<(String, TZDateTime?)> times,
) {
  final length = end.difference(start).inSeconds;
  return ArcPoints(
    kind: kind,
    start: start,
    end: end,
    points: [
      for (final (name, time) in times)
        if (time != null && !time.isBefore(start) && !time.isAfter(end))
          (name: name, time: time, share: time.difference(start).inSeconds / length),
    ]..sort((a, b) => a.share.compareTo(b.share)),
  );
}
