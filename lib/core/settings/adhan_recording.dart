import 'package:better_muslim/core/audio/adhan_files.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';

/// alafasy ships in the app, a downloadable one comes with its sha256s. fajr always plays the same
/// muezzin's fajr, an adhan without "as-salatu khayrun min an-nawm" is wrong at fajr
enum AdhanRecording {
  alafasy(
    file: 'adhan_alafasy',
    nameKey: StringsManager.recordingAlafasy,
    fajrSubtitleKey: StringsManager.alafasyFajr,
    lengthLabel: '2:34',
    fajrLengthLabel: '3:41',
    clipLength: Duration(milliseconds: 19800),
    fajrClipLength: Duration(milliseconds: 22400),
  );

  const AdhanRecording({
    required this.file,
    required this.nameKey,
    required this.fajrSubtitleKey,
    required this.lengthLabel,
    required this.fajrLengthLabel,
    required this.clipLength,
    required this.fajrClipLength,
    // ignore: unused_element_parameter, al-qatami's download comes once he sends his fajr
    this.sha256,
  });

  /// the file name without its extension, the same in the app, the release and the phone
  final String file;

  /// the sheet's name and the adhan screen's line under the prayer
  final String nameKey;
  final String fajrSubtitleKey;

  /// the sheet's length, the adhan screen reads the file's own
  final String lengthLabel;
  final String fajrLengthLabel;

  /// the notification clip is the opening takbir, the takbir preview stops the full file here
  final Duration clipLength;
  final Duration fajrClipLength;

  /// by the release file's name
  final Map<String, String>? sha256;

  bool get isBundled => sha256 == null;

  String fileOf(Prayer prayer) => prayer == Prayer.fajr ? '${file}_fajr' : file;

  String subtitleOf(Prayer prayer) => prayer == Prayer.fajr ? fajrSubtitleKey : nameKey;

  String lengthOf(Prayer prayer) => prayer == Prayer.fajr ? fajrLengthLabel : lengthLabel;

  Duration clipLengthOf(Prayer prayer) => prayer == Prayer.fajr ? fajrClipLength : clipLength;

  /// m:ss like the length labels
  String clipLabelOf(Prayer prayer) {
    final seconds = (clipLengthOf(prayer).inMilliseconds / 1000).round();
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  /// a flutter asset, or the downloaded file's path
  String fullAsset(Prayer prayer) =>
      isBundled ? 'assets/audio/${fileOf(prayer)}.m4a' : AdhanFiles.pathOf(fileOf(prayer));

  /// 30 s or less, without the extension. a .caf in ios/Runner/Sounds/ or Library/Sounds/
  String clipOf(Prayer prayer) => '${fileOf(prayer)}_clip';

  /// the res/raw clip, a downloaded recording's isn't there
  String androidClipOf(Prayer prayer) => isBundled ? clipOf(prayer) : alafasy.clipOf(prayer);
}
