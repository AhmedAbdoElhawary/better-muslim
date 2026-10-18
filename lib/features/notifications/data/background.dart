import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/notifications/data/alert_texts.dart';
import 'package:better_muslim/features/notifications/data/notification_scheduler.dart';
import 'package:better_muslim/features/notifications/domain/schedule.dart';
import 'package:flutter/widgets.dart';
import 'package:timezone/timezone.dart' show TZDateTime;

/// the same steps in the app and in the background, with no riverpod, so both write the same
/// schedule (FR-009)
Future<void> topUp(
  AppDatabase db, {
  required NotificationScheduler scheduler,
  required Locale locale,
  required bool use24h,
  required String? phoneZone,
  DateTime? now,
}) async {
  final settings = await db.watchSettings().first;
  final saved = savedPlaceOf(settings);
  final location = saved == null ? null : locationOf(saved, phoneZone);
  if (location == null) return scheduler.cancelAll();

  final at = TZDateTime.from(now ?? DateTime.now(), location.zone);
  DayTimes timesOn(DateTime date) => dayTimesAt(
    location,
    date,
    method: settings.method,
    asrMethod: settings.asrMethod,
    hijriAdjust: settings.hijriAdjust,
  );
  final today = DateTime(at.year, at.month, at.day);
  final first = prayerDayOf(at, today, timesOn(today).fajr);
  final sounds = {for (final prayer in Prayer.values) prayer: settings.soundOf(prayer)};

  final texts = await AlertTexts.load(
    locale: locale,
    use24h: use24h,
    digits: settings.digits,
    location: location,
  );
  await scheduler.apply(
    alerts: buildSchedule(
      now: at,
      days: [
        for (var i = 0; i < scheduleDays; i++)
          timesOn(DateTime(first.year, first.month, first.day + i)),
      ],
      sounds: sounds,
    ),
    sounds: sounds,
    texts: texts,
  );
}
