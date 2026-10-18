import 'dart:ui';

import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/notifications/data/alert_texts.dart';
import 'package:better_muslim/features/notifications/data/notification_scheduler.dart';
import 'package:better_muslim/features/notifications/domain/alert.dart';
import 'package:better_muslim/features/notifications/domain/schedule.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

const markPrayedAction = 'mark_prayed';

/// milestone 4's markPrayed, on the payload's prayer day, so isha after midnight lands on the day
/// it started (FR-038). a store that can't be opened stays as it is, the user can mark in the app
Future<void> markFromPayload(String payload, {AppDatabase? db}) async {
  final alert = alertFromPayload(payload);
  if (alert == null) return;
  final store = db ?? await AppDatabase.openExisting();
  if (store == null) return;
  try {
    await store.markPrayed(alert.day, alert.prayer);
  } finally {
    if (db == null) await store.close();
  }
}

/// mark prayed on a notification the plugin shows, on ios and android
@pragma('vm:entry-point')
Future<void> onNotificationActionInBackground(NotificationResponse response) async {
  final payload = response.payload;
  if (response.actionId != markPrayedAction || payload == null) return;
  DartPluginRegistrant.ensureInitialized();
  await markFromPayload(payload);
}

/// kotlin's MarkPrayedReceiver runs this in a headless engine, args = [payload]
@pragma('vm:entry-point')
Future<void> markPrayedInBackground(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  try {
    await markFromPayload(args.first);
  } finally {
    /// kotlin destroys the engine on this
    await const MethodChannel('better_muslim/adhan/background').invokeMethod<void>('done');
  }
}
