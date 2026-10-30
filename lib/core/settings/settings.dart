import 'package:better_muslim/core/audio/adhan_files.dart';
import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/settings/adhan_recording.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final settingsProvider = StreamProvider<AppSettings>(
  (ref) => ref.watch(databaseProvider).watchSettings(now: ref.read(clockProvider)()),
);

enum LocationMode { auto, manual }

/// only read when the app is in arabic
enum Digits { eastern, western }

enum CalendarMode { hijri, gregorian }

/// the names stay in their own language, so the one you need is findable in the other
enum Language {
  phone(StringsManager.followPhone),
  english(StringsManager.english),
  arabic(StringsManager.arabic);

  const Language(this.nameKey);
  final String nameKey;
}

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

  /// alafasy until the picked one is on the phone, a restored backup brings the choice only
  AdhanRecording recordingOf(Prayer prayer) {
    final recording = switch (prayer) {
      Prayer.fajr => fajrRecording,
      Prayer.dhuhr => dhuhrRecording,
      Prayer.asr => asrRecording,
      Prayer.maghrib => maghribRecording,
      Prayer.isha => ishaRecording,
    };
    return AdhanFiles.isReady(recording) ? recording : AdhanRecording.alafasy;
  }
}

SettingsCompanion soundChoice(Prayer prayer, PrayerSound sound) => switch (prayer) {
  Prayer.fajr => SettingsCompanion(fajrSound: Value(sound)),
  Prayer.dhuhr => SettingsCompanion(dhuhrSound: Value(sound)),
  Prayer.asr => SettingsCompanion(asrSound: Value(sound)),
  Prayer.maghrib => SettingsCompanion(maghribSound: Value(sound)),
  Prayer.isha => SettingsCompanion(ishaSound: Value(sound)),
};

SettingsCompanion recordingChoice(Prayer prayer, AdhanRecording recording) => switch (prayer) {
  Prayer.fajr => SettingsCompanion(fajrRecording: Value(recording)),
  Prayer.dhuhr => SettingsCompanion(dhuhrRecording: Value(recording)),
  Prayer.asr => SettingsCompanion(asrRecording: Value(recording)),
  Prayer.maghrib => SettingsCompanion(maghribRecording: Value(recording)),
  Prayer.isha => SettingsCompanion(ishaRecording: Value(recording)),
};
