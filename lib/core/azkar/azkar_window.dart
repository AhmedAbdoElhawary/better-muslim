import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';

enum AzkarSet {
  morning(StringsManager.morningAzkar, StringsManager.morningAzkarSub, Prayer.fajr),
  evening(StringsManager.eveningAzkar, StringsManager.eveningAzkarSub, Prayer.asr);

  const AzkarSet(this.titleKey, this.subtitleKey, this.nudgePrayer);
  final String titleKey;

  /// "After Fajr · {done} of {total}"
  final String subtitleKey;

  /// the prayer its window starts with, its nudge comes after it
  final Prayer nudgePrayer;
}

/// the nudge comes this long after fajr and asr (5.1)
const azkarNudgeDelay = Duration(minutes: 20);

/// morning from fajr until asr, evening from asr until the next fajr
AzkarSet currentAzkarSet(Period? period) => switch (period) {
  Period.fajr || Period.duha || Period.dhuhr => AzkarSet.morning,
  _ => AzkarSet.evening,
};

/// the prayer day of the set's latest window. before asr the evening is still last night's
DateTime azkarWindowDay(AzkarSet set, DateTime prayerDay, Period? period) {
  if (set == AzkarSet.morning || period == null) return prayerDay;
  if (currentAzkarSet(period) == AzkarSet.evening) return prayerDay;
  return DateTime(prayerDay.year, prayerDay.month, prayerDay.day - 1);
}
