import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';

const _full = 'assets/audio/adhan_makkah.m4a';
const _fajrFull = 'assets/audio/adhan_makkah_fajr.m4a';
const _clip = 'adhan_makkah_clip';
const _fajrClip = 'adhan_makkah_fajr_clip';

// TODO(ahmed): each recording needs its own licensed files, adhan_{name}.m4a and adhan_{name}_fajr.m4a in assets/audio/, adhan_{name}_clip and adhan_{name}_fajr_clip (.caf in ios/Runner/Sounds/, .m4a in android res/raw/, 30 s or less). until then all six play the makkah placeholders.
enum AdhanRecording {
  makkah(
    nameKey: StringsManager.recordingMakkah,
    subtitleKey: StringsManager.adhanOfMakkah,
    lengthLabel: '3:52',
    full: _full,
    fajrFull: _fajrFull,
    clip: _clip,
    fajrClip: _fajrClip,
  ),
  madinah(nameKey: StringsManager.recordingMadinah, lengthLabel: '4:10'),
  alAqsa(nameKey: StringsManager.recordingAlAqsa, lengthLabel: '3:31'),
  cairo(nameKey: StringsManager.recordingCairo, lengthLabel: '3:44'),
  istanbul(nameKey: StringsManager.recordingIstanbul, lengthLabel: '4:02'),
  takbir(nameKey: StringsManager.recordingTakbir, lengthLabel: '0:12');

  const AdhanRecording({
    required this.nameKey,
    required this.lengthLabel,
    String? subtitleKey,
    this.full = _full,
    this.fajrFull = _fajrFull,
    this.clip = _clip,
    this.fajrClip = _fajrClip,
  }) : subtitleKey = subtitleKey ?? nameKey;

  final String nameKey;

  /// the adhan screen's line under the prayer
  final String subtitleKey;

  /// the brand board's length for the sheet, the adhan screen reads the file's own
  final String lengthLabel;
  final String full;
  final String fajrFull;

  /// 30 s or less, ios plays it as the notification sound. a .caf in ios/Runner/Sounds/ and a
  /// res/raw file on android, both without the extension here
  final String clip;
  final String fajrClip;

  bool get isShort => this == takbir;

  String fullAsset(Prayer prayer) => prayer == Prayer.fajr ? fajrFull : full;

  String clipOf(Prayer prayer) => prayer == Prayer.fajr ? fajrClip : clip;
}
