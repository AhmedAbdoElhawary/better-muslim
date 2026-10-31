import 'package:better_muslim/core/audio/adhan_files.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';

const _fajrFull = 'assets/audio/adhan_fajr.m4a';
const _fajrClip = 'adhan_fajr_clip';

/// madinah ships in the app, the others are downloaded once. fajr always plays the one fajr
/// recording, an adhan without "as-salatu khayrun min an-nawm" is wrong at fajr
enum AdhanRecording {
  madinah(
    file: 'adhan_madinah',
    nameKey: StringsManager.recordingMadinah,
    subtitleKey: StringsManager.adhanOfMadinah,
    lengthLabel: '3:06',
  ),
  aaqibAzeez(
    file: 'adhan_aaqib_azeez',
    nameKey: StringsManager.recordingAaqibAzeez,
    lengthLabel: '1:27',
    sha256: 'c0f5a75479a48c76b861218de649e36fe73a6a8dc0914f270a5ea07dfe1114b9',
    clipSha256: '5b99fa9bbe489e1cec5508fd8017a44330e7c8c03a24a332d388b356ecdbe442',
  ),
  andrewler(
    file: 'adhan_andrewler',
    nameKey: StringsManager.recordingAndrewler,
    lengthLabel: '2:38',
    sha256: '7479c5548f5c434c46055082479f8e656a8af21167de90d169fdc70ba75bc853',
    clipSha256: '67c8153a5b2e88bf1e1628cf1a00e06d532ed75adc58dd7726a3f1ebb0a88f42',
  ),
  synagda(
    file: 'adhan_synagda',
    nameKey: StringsManager.recordingSynagda,
    lengthLabel: '2:34',
    sha256: 'b394a49124d737472785f1d6e7ae24ea91673d1b34a223520af07a35de1ea0ce',
    clipSha256: '593ca85247b96bbfc23137ac9662bf28a6287da7a17d88ddb6401a0706805bb0',
  );

  const AdhanRecording({
    required this.file,
    required this.nameKey,
    required this.lengthLabel,
    String? subtitleKey,
    this.sha256,
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
