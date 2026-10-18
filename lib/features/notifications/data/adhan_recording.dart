import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';

// TODO(ahmed): the audio files are placeholders until the licensed Makkah recordings come, keep the file names.
enum AdhanRecording {
  makkah(
    nameKey: StringsManager.adhanOfMakkah,
    full: 'assets/audio/adhan_makkah.m4a',
    fajrFull: 'assets/audio/adhan_makkah_fajr.m4a',
    clip: 'adhan_makkah_clip',
    fajrClip: 'adhan_makkah_fajr_clip',
  );

  const AdhanRecording({
    required this.nameKey,
    required this.full,
    required this.fajrFull,
    required this.clip,
    required this.fajrClip,
  });

  final String nameKey;
  final String full;
  final String fajrFull;

  /// 30 s or less, ios plays it as the notification sound. a .caf in ios/Runner/Sounds/ and a
  /// res/raw file on android, both without the extension here
  final String clip;
  final String fajrClip;

  String fullAsset(Prayer prayer) => prayer == Prayer.fajr ? fajrFull : full;

  String clipOf(Prayer prayer) => prayer == Prayer.fajr ? fajrClip : clip;
}
