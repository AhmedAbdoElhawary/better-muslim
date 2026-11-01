import 'dart:convert';
import 'dart:ui';

import 'package:better_muslim/core/app/app_localizations.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/monitoring/crash_reporter.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/surfaces/surface_data.dart';
import 'package:better_muslim/core/surfaces/surfaces_channel.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/timezone.dart' show TZDateTime;

/// the same steps in the app and in the background, with no riverpod, so both write the same
/// file
Future<void> writeSurfaces(
  AppDatabase db, {
  required SurfacesChannel channel,
  required Locale locale,
  required bool use24h,
  required String? phoneZone,
  bool force = false,
  DateTime? now,
}) async {
  final at = now ?? DateTime.now();
  final settings = await db.watchSettings().first;
  final saved = savedPlaceOf(settings);
  final location = saved == null ? null : locationOf(saved, phoneZone);

  /// only the current prayer day can have marks
  final prayed = <Prayer>{};
  if (location != null) {
    final local = TZDateTime.from(at, location.zone);
    final today = DateTime(local.year, local.month, local.day);
    final fajr = dayTimesAt(
      location,
      today,
      method: settings.method,
      asrMethod: settings.asrMethod,
      hijriAdjust: settings.hijriAdjust,
    ).fajr;
    final day = prayerDayOf(at, today, fajr);
    for (final prayer in Prayer.values) {
      if (await db.isPrayed(day, prayer)) prayed.add(prayer);
    }
  }

  /// flutter_localizations loads the date symbols only inside the app, the background needs them
  await initializeDateFormatting();
  final data = buildSurfaceData(
    now: at,
    location: location,
    settings: settings,
    prayed: prayed,
    l10n: await AppLocalizations.load(locale),
    language: locale.languageCode,
    use24h: use24h,
  );
  try {
    await channel.update(jsonEncode(data), force: force);
  } on PlatformException catch (error, stack) {
    await CrashReporter.instance.recordError(error, stack, context: {'reason': 'write surfaces'});
  }
}
