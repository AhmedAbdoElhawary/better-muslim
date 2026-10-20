import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:timezone/timezone.dart';

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
