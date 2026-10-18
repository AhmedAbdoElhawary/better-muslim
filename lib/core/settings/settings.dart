import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final settingsProvider = StreamProvider<AppSettings>(
  (ref) => ref.watch(databaseProvider).watchSettings(now: ref.read(clockProvider)()),
);

enum LocationMode { auto, manual }

/// only read when the app is in arabic
enum Digits { eastern, western }

/// how each prayer reaches the phone. silent still shows the notification, with no sound
enum PrayerSound { adhan, tone, silent }

extension PrayerSoundOf on AppSettings {
  PrayerSound soundOf(Prayer prayer) => switch (prayer) {
    Prayer.fajr => fajrSound,
    Prayer.dhuhr => dhuhrSound,
    Prayer.asr => asrSound,
    Prayer.maghrib => maghribSound,
    Prayer.isha => ishaSound,
  };
}
