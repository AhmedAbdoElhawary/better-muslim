import 'dart:ui';

import 'package:better_muslim/core/app/app_localizations.dart';
import 'package:better_muslim/core/audio/adhan_files.dart';
import 'package:better_muslim/core/azkar/azkar_content.dart';
import 'package:better_muslim/core/azkar/azkar_window.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/surfaces/surfaces_channel.dart';
import 'package:better_muslim/core/surfaces/write_surfaces.dart';
import 'package:better_muslim/features/notifications/data/adhan_channel.dart';
import 'package:better_muslim/features/notifications/data/alert_texts.dart';
import 'package:better_muslim/features/notifications/data/notification_scheduler.dart';
import 'package:better_muslim/features/notifications/domain/alert.dart';
import 'package:better_muslim/features/notifications/domain/schedule.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' show TZDateTime;
import 'package:workmanager/workmanager.dart';

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
  final recordings = {for (final prayer in Prayer.values) prayer: settings.recordingOf(prayer)};
  final lengths = {for (final prayer in Prayer.values) prayer: settings.adhanLengthOf(prayer)};
  final tones = {for (final prayer in Prayer.values) prayer: settings.toneOf(prayer)};

  final texts = await AlertTexts.load(
    locale: locale,
    use24h: use24h,
    digits: settings.digits,
    location: location,
  );
  final days = [
    for (var i = 0; i < scheduleDays; i++)
      timesOn(DateTime(first.year, first.month, first.day + i)),
  ];
  await scheduler.apply(
    alerts: [
      ...buildSchedule(
        now: at,
        days: days,
        sounds: sounds,
        reminderMinutes: settings.reminderMinutes,
      ),
      if (settings.azkarNudges)
        ...buildNudges(
          now: at,
          days: days,
          done: await _doneWindows(db, texts.azkar, first, timesOn(today).periodAt(at)),
        ),
    ],
    sounds: sounds,
    recordings: recordings,
    lengths: lengths,
    tones: tones,
    texts: texts,
  );
}

/// only the latest windows can hold counts, a later one always starts from 0
Future<Set<(AzkarSet, DateTime)>> _doneWindows(
  AppDatabase db,
  AzkarContent? content,
  DateTime prayerDay,
  Period? period,
) async {
  if (content == null) return const {};
  final done = <(AzkarSet, DateTime)>{};
  for (final set in AzkarSet.values) {
    final day = azkarWindowDay(set, prayerDay, period);
    final items = content.setOf(set);
    if (items.doneIn(await db.zikrCounts(set, day)) == items.total) done.add((set, day));
  }
  return done;
}

const markPrayedAction = 'mark_prayed';

/// milestone 4's markPrayed, on the payload's prayer day, so isha after midnight lands on the day
/// it started (FR-038). a store that can't be opened stays as it is, the user can mark in the app.
/// in the app the boot writes the surfaces, in the background `surfaces` does
Future<void> markFromPayload(String payload, {AppDatabase? db, SurfacesChannel? surfaces}) async {
  final alert = alertFromPayload(payload);
  if (alert == null) return;
  final store = db ?? await AppDatabase.openExisting();
  if (store == null) return;
  try {
    await store.markPrayed(alert.day, alert.prayer);
    if (surfaces != null) {
      await writeSurfaces(
        store,
        channel: surfaces,
        locale: AppLocalizations.localeOf((await store.watchSettings().first).language),
        use24h: PlatformDispatcher.instance.alwaysUse24HourFormat,
        phoneZone: await PhoneZone.read(),
      );
    }
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
  tz.initializeTimeZones();
  await markFromPayload(payload, surfaces: SurfacesChannel());
}

/// kotlin's MarkPrayedReceiver runs this in a headless engine, args = [payload]
@pragma('vm:entry-point')
Future<void> markPrayedInBackground(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  tz.initializeTimeZones();
  try {
    await markFromPayload(args.first, surfaces: SurfacesChannel());
  } finally {
    /// kotlin destroys the engine on this
    await const MethodChannel('better_muslim/adhan/background').invokeMethod<void>('done');
  }
}

/// the surfaces first, so the widgets keep their 7 days with notifications refused (FR-002)
Future<void> backgroundTopUp(
  AppDatabase db, {
  required NotificationScheduler scheduler,
  required SurfacesChannel surfaces,
  required Locale locale,
  required bool use24h,
  required String? phoneZone,
  DateTime? now,
}) async {
  await writeSurfaces(
    db,
    channel: surfaces,
    locale: locale,
    use24h: use24h,
    phoneZone: phoneZone,
    now: now,
  );
  if (!await scheduler.isAllowed()) return;
  await topUp(
    db,
    scheduler: scheduler,
    locale: locale,
    use24h: use24h,
    phoneZone: phoneZone,
    now: now,
  );
}

/// the same name on both platforms, ios only runs a task listed in BGTaskSchedulerPermittedIdentifiers
const topUpTask = 'better_muslim.topup';

/// the phone left alone still gets 6 days: android every 12 h, ios when it allows (FR-009).
/// errors aren't reported from here, the next launch tries again (research R14)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, input) async {
    DartPluginRegistrant.ensureInitialized();
    tz.initializeTimeZones();
    final db = await AppDatabase.openExisting();
    if (db == null) return true;
    try {
      await AdhanFiles.init();
      final locale = AppLocalizations.localeOf((await db.watchSettings().first).language);
      final l10n = await AppLocalizations.load(locale);
      final scheduler = NotificationScheduler(AdhanChannel());
      await scheduler.init(markPrayed: l10n.tr(StringsManager.markPrayed, const {}));
      await backgroundTopUp(
        db,
        scheduler: scheduler,
        surfaces: SurfacesChannel(),
        locale: locale,
        use24h: PlatformDispatcher.instance.alwaysUse24HourFormat,
        phoneZone: await PhoneZone.read(),
      );
    } finally {
      await db.close();
    }
    return true;
  });
}
