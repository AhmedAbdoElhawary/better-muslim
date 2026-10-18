import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/notifications/domain/alert.dart';

// TODO(ahmed): when the 6 days run out on iOS the phone goes quiet, a last "open the app" message could go here if I design one.
const scheduleDays = 6;

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
