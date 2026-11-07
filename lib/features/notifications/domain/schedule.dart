import 'package:better_muslim/core/azkar/azkar_window.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/notifications/domain/alert.dart';
import 'package:timezone/timezone.dart';

const scheduleDays = 6;

/// ios may never run the top-up, so a while after the last alert one asks to open the app
TZDateTime? quietNoticeAt(List<Alert> alerts) => alerts.isEmpty
    ? null
    : alerts.map((alert) => alert.at).reduce((a, b) => a.isAfter(b) ? a : b).add(quietNoticeDelay);

const quietNoticeDelay = Duration(minutes: 30);

/// calendar prayer days, not 144 hours: fajr gets earlier each day, so 144 hours can hold 7 fajrs.
/// days are the prayer day of now and the ones after it, null where there is no location.
/// reminders come for all five whatever their sound, 0 minutes is off. 60 at most, under ios's 64
List<Alert> buildSchedule({
  required DateTime now,
  required List<DayTimes?> days,
  required Map<Prayer, PrayerSound> sounds,
  required int reminderMinutes,
}) {
  final before = Duration(minutes: reminderMinutes);
  return [
    for (final day in days.nonNulls)
      for (final prayer in Prayer.values)
        if (day.timeOf(prayer) case final time?) ...[
          if (reminderMinutes > 0 && time.subtract(before).isAfter(now))
            Alert(
              day: day.date,
              prayer: prayer,
              kind: AlertKind.reminder,
              at: time.subtract(before),
              sound: sounds[prayer]!,
              before: before,
            ),
          if (time.isAfter(now))
            Alert(
              day: day.date,
              prayer: prayer,
              kind: AlertKind.adhan,
              at: time,
              sound: sounds[prayer]!,
            ),
        ],
  ];
}

/// ios holds 64 pending, the prayers take 60 and the quiet one, so only the next 3 nudges.
/// the dev test one makes 65, ios then drops the latest, the quiet one
const nudgeCount = 3;

/// the next nudges after now, 20 minutes after fajr and asr, none for a window already done.
/// days as in buildSchedule, done holds (set, window day)
List<Alert> buildNudges({
  required DateTime now,
  required List<DayTimes?> days,
  required Set<(AzkarSet, DateTime)> done,
}) {
  final slots = [
    for (final day in days.nonNulls)
      for (final set in AzkarSet.values)
        if (day.timeOf(set.nudgePrayer)?.add(azkarNudgeDelay) case final at?) (day, set, at),
  ];
  return [
    for (final (index, (day, set, at)) in slots.indexed)
      if (at.isAfter(now) && !done.contains((set, day.date)))
        Alert(
          day: day.date,
          prayer: set.nudgePrayer,
          kind: AlertKind.azkar,
          at: at,
          sound: PrayerSound.silent,
          lasts: index + 1 < slots.length ? slots[index + 1].$3.difference(at) : null,
        ),
  ].take(nudgeCount).toList();
}
