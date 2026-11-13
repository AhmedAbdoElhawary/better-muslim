import 'dart:io';

import 'package:better_muslim/core/database/backup_exclusion.dart';
import 'package:better_muslim/core/network/download.dart';
import 'package:better_muslim/core/network/download_notice.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/settings/adhan_recording.dart';
import 'package:path_provider/path_provider.dart';

/// the downloaded recordings, out of every backup. the folder is known before anything plays or
/// schedules, so a recording's path is read without waiting
class AdhanFiles {
  AdhanFiles._();

  /// the same public repo as the tafsirs
  static final base = Uri.parse(
    'https://github.com/AhmedAbdoElhawary/better-muslim-content/releases/download/adhan-v2/',
  );

  static String? _folder;

  /// ios plays a notification sound only from the bundle or Library/Sounds
  static String? _sounds;

  static final _cancelled = <AdhanRecording>{};

  /// taken out of the app, a phone that downloaded them still has the files
  static const _removed = ['adhan_aaqib_azeez', 'adhan_andrewler', 'adhan_synagda'];

  /// once in the app and once in each background engine, the folders are made on a download
  static Future<void> init() async {
    if (_folder != null) return;
    if (Platform.isIOS) _sounds = '${(await getLibraryDirectory()).path}/Sounds';
    _folder = '${(await getApplicationSupportDirectory()).path}/adhan';
  }

  static Future<void> deleteRemoved() async {
    await init();
    for (final name in _removed) {
      for (final path in [
        '$_folder/$name.m4a',
        if (_sounds case final sounds?) '$sounds/${name}_clip.caf',
      ]) {
        final file = File(path);
        if (file.existsSync()) await file.delete();
      }
    }
  }

  static String pathOf(String file) => '$_folder/$file.m4a';

  /// the fajr comes last, so its file on the phone means the whole recording is there
  static bool isReady(AdhanRecording recording) =>
      recording.isBundled ||
      (_folder != null && File(pathOf(recording.fileOf(Prayer.fajr))).existsSync());

  /// throws a DownloadException, cancelled included
  static Future<void> download(
    AdhanRecording recording, {
    void Function(double? progress)? onProgress,
    DownloadNotice? notice,
  }) async {
    await init();
    final folder = Directory(_folder!);
    if (!folder.existsSync()) {
      await folder.create(recursive: true);
      await BackupExclusion.exclude(folder.path);
    }
    _cancelled.remove(recording);
    bool cancelled() => _cancelled.contains(recording);
    final files = [
      for (final prayer in [Prayer.dhuhr, Prayer.fajr]) recording.fileOf(prayer),
    ];
    if (_sounds case final sounds?) {
      await Directory(sounds).create(recursive: true);
      for (final file in files) {
        final clip = '${file}_clip.caf';

        /// a resume after a pause keeps what is done
        if (File('$sounds/$clip').existsSync()) continue;
        await saveVerified(
          base.resolve(clip),
          File('$sounds/$clip'),
          sha256Hex: recording.sha256![clip]!,
          cancelled: cancelled,
        );
      }
    }
    for (final (index, file) in files.indexed) {
      if (File(pathOf(file)).existsSync()) continue;
      notice?.part = '${pathOf(file)}.part';
      await saveVerified(
        base.resolve('$file.m4a'),
        File(pathOf(file)),
        sha256Hex: recording.sha256!['$file.m4a']!,
        cancelled: cancelled,
        onProgress: (progress) {
          final all = progress == null ? null : (index + progress) / files.length;
          if (all != null) notice?.share(all);
          onProgress?.call(all);
        },
      );
    }
  }

  /// the running download stops at its next chunk and deletes its .part
  static void cancel(AdhanRecording recording) => _cancelled.add(recording);
}
