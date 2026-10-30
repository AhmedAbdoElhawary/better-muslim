import 'package:better_muslim/core/audio/adhan_files.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';

const _fajrFull = 'assets/audio/adhan_fajr.m4a';
const _fajrClip = 'adhan_fajr_clip';

/// madinah ships in the app, a downloadable one comes with its sha256. fajr always plays the one fajr
/// recording, an adhan without "as-salatu khayrun min an-nawm" is wrong at fajr
enum AdhanRecording {
  madinah(
    file: 'adhan_madinah',
    nameKey: StringsManager.recordingMadinah,
    subtitleKey: StringsManager.adhanOfMadinah,
    lengthLabel: '3:06',
  );

  const AdhanRecording({
    required this.file,
    required this.nameKey,
    required this.lengthLabel,
    String? subtitleKey,
    // ignore: unused_element_parameter, al-qatami's download comes back in 010 ticket 03
    this.sha256,
    // ignore: unused_element_parameter, same
    this.clipSha256,
  }) : subtitleKey = subtitleKey ?? nameKey;

  /// the file name without its extension, the same in the app, the release and the phone
  final String file;
  final String nameKey;

  /// the adhan screen's line under the prayer
  final String subtitleKey;

  /// the sheet's length, the adhan screen reads the file's own
  final String lengthLabel;

  /// null for madinah, it ships in the app
  final String? sha256;

  /// the ios notification sound, android has no folder a downloaded channel sound plays from
  final String? clipSha256;

  bool get isBundled => sha256 == null;

  String subtitleOf(Prayer prayer) =>
      prayer == Prayer.fajr ? StringsManager.adhanOfFajr : subtitleKey;

  String lengthOf(Prayer prayer) => prayer == Prayer.fajr ? '4:02' : lengthLabel;

  /// a flutter asset, or the downloaded file's path
  String fullAsset(Prayer prayer) {
    if (prayer == Prayer.fajr) return _fajrFull;
    return isBundled ? 'assets/audio/$file.m4a' : AdhanFiles.pathOf(this);
  }

  /// 30 s or less, without the extension. a .caf in ios/Runner/Sounds/ or Library/Sounds/
  String clipOf(Prayer prayer) => prayer == Prayer.fajr ? _fajrClip : '${file}_clip';

  /// the res/raw clip, a downloaded recording's isn't there
  String androidClipOf(Prayer prayer) => isBundled ? clipOf(prayer) : madinah.clipOf(prayer);
}
