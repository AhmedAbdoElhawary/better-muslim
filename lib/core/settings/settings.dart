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

/// on top of the phone's own text size, still capped at bmMaxTextScale
enum TextSize {
  small(StringsManager.textSizeSmall, 0.85),
  standard(StringsManager.textSizeDefault, 1),
  large(StringsManager.textSizeLarge, 1.15),
  larger(StringsManager.textSizeLarger, 1.3),
  largest(StringsManager.textSizeLargest, 1.5);

  const TextSize(this.nameKey, this.scale);
  final String nameKey;
  final double scale;
}

/// how each prayer's reminder and time reach the phone. silent still shows both, with no sound
enum PrayerSound {
  adhan(StringsManager.soundAdhan),
  tone(StringsManager.soundTone),
  silent(StringsManager.soundSilent);

  const PrayerSound(this.nameKey);
  final String nameKey;
}

/// the phone's own notification sound, or one shipped in the app
enum PrayerTone {
  phone(StringsManager.tonePhone),
  calm(StringsManager.toneCalm, file: 'tone_calm'),
  glass(StringsManager.toneGlass, file: 'tone_glass'),
  bright(StringsManager.toneBright, file: 'tone_bright'),
  echo(StringsManager.toneEcho, file: 'tone_echo');

  const PrayerTone(this.nameKey, {this.file});
  final String nameKey;

  /// the same name in assets/audio, res/raw and ios/Runner/Sounds
  final String? file;
}

extension PrayerSoundOf on AppSettings {
  PrayerSound soundOf(Prayer prayer) => switch (prayer) {
    Prayer.fajr => fajrSound,
    Prayer.dhuhr => dhuhrSound,
    Prayer.asr => asrSound,
    Prayer.maghrib => maghribSound,
    Prayer.isha => ishaSound,
  };

  /// alafasy until the picked one is on the phone
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

  PrayerTone toneOf(Prayer prayer) => switch (prayer) {
    Prayer.fajr => fajrTone,
    Prayer.dhuhr => dhuhrTone,
    Prayer.asr => asrTone,
    Prayer.maghrib => maghribTone,
    Prayer.isha => ishaTone,
  };
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

SettingsCompanion toneChoice(Prayer prayer, PrayerTone tone) => switch (prayer) {
  Prayer.fajr => SettingsCompanion(fajrTone: Value(tone)),
  Prayer.dhuhr => SettingsCompanion(dhuhrTone: Value(tone)),
  Prayer.asr => SettingsCompanion(asrTone: Value(tone)),
  Prayer.maghrib => SettingsCompanion(maghribTone: Value(tone)),
  Prayer.isha => SettingsCompanion(ishaTone: Value(tone)),
};
