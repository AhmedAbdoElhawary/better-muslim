import 'dart:async';

import 'package:better_muslim/core/quran/ayah_key.dart';
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

  /// throws a TafsirException, cancelled included
  Future<void> download() async {
    if (state.ready || state.downloading) return;
    state = (ready: false, downloading: true, progress: null);
    try {
      await ref
          .read(tafsirFilesProvider)
          .download(
            source,
            onProgress: (progress) => state = (ready: false, downloading: true, progress: progress),
          );
      state = _ready;
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
