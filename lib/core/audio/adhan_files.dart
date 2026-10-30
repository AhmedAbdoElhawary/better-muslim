import 'dart:io';

import 'package:better_muslim/core/database/backup_exclusion.dart';
import 'package:better_muslim/core/network/download.dart';
import 'package:better_muslim/core/settings/adhan_recording.dart';
import 'package:path_provider/path_provider.dart';

/// the downloaded recordings, out of every backup. the folder is known before anything plays or
/// schedules, so a recording's path is read without waiting
class AdhanFiles {
  AdhanFiles._();

  /// the same public repo as the tafsirs
  static final base = Uri.parse(
    'https://github.com/AhmedAbdoElhawary/better-muslim-content/releases/download/adhan-v1/',
  );

  static String? _folder;

  /// ios plays a notification sound only from the bundle or Library/Sounds
  static String? _sounds;

  static final _cancelled = <AdhanRecording>{};

  /// once in the app and once in each background engine, the folders are made on a download
  static Future<void> init() async {
    if (_folder != null) return;
    if (Platform.isIOS) _sounds = '${(await getLibraryDirectory()).path}/Sounds';
    _folder = '${(await getApplicationSupportDirectory()).path}/adhan';
  }

  static String pathOf(AdhanRecording recording) => '$_folder/${recording.file}.m4a';

  /// the clip comes first, so a full file on the phone always has its clip
  static bool isReady(AdhanRecording recording) =>
      recording.isBundled || (_folder != null && File(pathOf(recording)).existsSync());

  /// throws a DownloadException, cancelled included
  static Future<void> download(
    AdhanRecording recording, {
    void Function(double? progress)? onProgress,
  }) async {
    await init();
    final folder = Directory(_folder!);
    if (!folder.existsSync()) {
      await folder.create(recursive: true);
      await BackupExclusion.exclude(folder.path);
    }
    _cancelled.remove(recording);
    bool cancelled() => _cancelled.contains(recording);
    if (_sounds case final sounds?) {
      await Directory(sounds).create(recursive: true);
      final clip = '${recording.file}_clip.caf';
      await saveVerified(
        base.resolve(clip),
        File('$sounds/$clip'),
        sha256Hex: recording.clipSha256!,
        cancelled: cancelled,
      );
    }
    await saveVerified(
      base.resolve('${recording.file}.m4a'),
      File(pathOf(recording)),
      sha256Hex: recording.sha256!,
      cancelled: cancelled,
      onProgress: onProgress,
    );
  }

  /// the running download stops at its next chunk and deletes its .part
  static void cancel(AdhanRecording recording) => _cancelled.add(recording);
}
