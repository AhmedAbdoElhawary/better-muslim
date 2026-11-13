import 'dart:async';

import 'package:better_muslim/core/network/download_notice.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/quran/data/tafsir_files.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// progress is null while the size is unknown
typedef TafsirStatus = ({bool ready, bool downloading, double? progress});

const TafsirStatus _idle = (ready: false, downloading: false, progress: null);
const TafsirStatus _ready = (ready: true, downloading: false, progress: null);

final tafsirStatusProvider =
    NotifierProvider.family<TafsirStatusNotifier, TafsirStatus, TafsirSource>(
      TafsirStatusNotifier.new,
    );

class TafsirStatusNotifier extends Notifier<TafsirStatus> {
  TafsirStatusNotifier(this.source);

  final TafsirSource source;

  @override
  TafsirStatus build() {
    if (source == TafsirSource.muyassar) return _ready;
    unawaited(
      ref.read(tafsirFilesProvider).isReady(source).then((ready) {
        if (ready) state = _ready;
      }),
    );
    return _idle;
  }

  /// throws a DownloadException, cancelled included. a pause from the notification leaves it idle
  Future<void> download() async {
    if (state.ready || state.downloading) return;
    state = (ready: false, downloading: true, progress: null);
    try {
      final done = await DownloadNotice.run(
        key: 'tafsir ${source.name}',
        title: (l10n, _) => l10n.tr(source.label, const {}),
        settings: ref.read(settingsProvider).value,
        resume: download,
        job: (notice) => ref
            .read(tafsirFilesProvider)
            .download(
              source,
              onProgress: (progress) =>
                  state = (ready: false, downloading: true, progress: progress),
              notice: notice,
            ),
      );
      state = done ? _ready : _idle;
    } on Object {
      state = _idle;
      rethrow;
    }
  }

  void cancel() => ref.read(tafsirFilesProvider).cancel(source);
}

final tafsirTextProvider = FutureProvider.autoDispose.family<String, (TafsirSource, AyahKey)>(
  (ref, args) => ref.watch(tafsirFilesProvider).text(args.$1, args.$2),
);
