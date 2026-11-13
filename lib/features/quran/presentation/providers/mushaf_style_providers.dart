import 'dart:async';
import 'dart:ui' show Color, Rect;

import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/network/download_notice.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/quran/data/mushaf_files.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// progress is null while the size is unknown
typedef MushafStyleStatus = ({bool ready, bool downloading, double? progress});

const MushafStyleStatus _idle = (ready: false, downloading: false, progress: null);
const MushafStyleStatus _ready = (ready: true, downloading: false, progress: null);

final mushafStyleStatusProvider =
    NotifierProvider.family<MushafStyleStatusNotifier, MushafStyleStatus, MushafStyle>(
      MushafStyleStatusNotifier.new,
    );

class MushafStyleStatusNotifier extends Notifier<MushafStyleStatus> {
  MushafStyleStatusNotifier(this.style);

  final MushafStyle style;

  /// a second pick waits on the running download instead of starting one
  Future<void>? _running;

  @override
  MushafStyleStatus build() {
    if (style == MushafStyle.text) return _ready;
    unawaited(
      ref.read(mushafFilesProvider).isReady(style).then((ready) {
        if (ready) state = _ready;
      }),
    );
    return _idle;
  }

  /// throws a DownloadException, cancelled included. a pause from the notification leaves it idle
  Future<void> download() => _running ??= _download().whenComplete(() => _running = null);

  Future<void> _download() async {
    final files = ref.read(mushafFilesProvider);

    /// the check in build may not be back yet, the file is 50 to 135 mb
    if (await files.isReady(style)) {
      state = _ready;
      return;
    }
    state = (ready: false, downloading: true, progress: null);
    try {
      final done = await DownloadNotice.run(
        key: 'mushaf ${style.name}',
        title: (l10n, _) => l10n.tr(style.label, const {}),
        settings: ref.read(settingsProvider).value,
        resume: download,
        job: (notice) => files.download(
          style,
          onProgress: (progress) => state = (ready: false, downloading: true, progress: progress),
          notice: notice,
        ),
      );
      state = done ? _ready : _idle;
      if (done) ref.invalidate(mushafDownloadsProvider);
    } on Object {
      state = _idle;
      rethrow;
    }
  }

  void cancel() => ref.read(mushafFilesProvider).cancel(style);

  /// the picked style goes back to text
  Future<void> delete() async {
    await ref.read(mushafFilesProvider).delete(style);
    state = _idle;
    ref.invalidate(mushafDownloadsProvider);
    if (ref.read(settingsProvider).value?.mushafStyle == style) {
      await ref
          .read(databaseProvider)
          .updateSettings(const SettingsCompanion(mushafStyle: Value(MushafStyle.text)));
    }
  }
}

/// the style waiting for its download. it's picked when the download is done, closed sheet or
/// not, unless another style was picked meanwhile
final mushafStylePickProvider = NotifierProvider<MushafStylePick, MushafStyle?>(
  MushafStylePick.new,
);

class MushafStylePick extends Notifier<MushafStyle?> {
  @override
  MushafStyle? build() => null;

  /// throws a DownloadException, cancelled included
  Future<void> pick(MushafStyle style) async {
    state = style;
    try {
      await ref.read(mushafStyleStatusProvider(style).notifier).download();
    } on Object {
      if (state == style) state = null;
      rethrow;
    }
    if (state != style) return;
    state = null;

    /// paused from the notification
    if (!ref.read(mushafStyleStatusProvider(style)).ready) return;
    await ref.read(databaseProvider).updateSettings(SettingsCompanion(mushafStyle: Value(style)));
  }
}

/// More's Downloads page, read again on each open
final mushafDownloadsProvider = FutureProvider.autoDispose<List<(MushafStyle, int)>>(
  (ref) => ref.watch(mushafFilesProvider).downloaded(),
);

/// the page's qcf font family in a palette, null for a style not on the phone, the page then draws
/// as text
final qcfFontProvider = FutureProvider.autoDispose.family<String?, (MushafStyle, int, int)>((
  ref,
  args,
) async {
  final (style, page, palette) = args;
  final files = ref.watch(mushafFilesProvider);
  if (!await files.isReady(style)) return null;
  return files.family(style, page, palette: palette);
});

/// V4's palette for a page and palette, its tajweed key reads its colors
final tajweedColorsProvider = FutureProvider.autoDispose.family<List<Color>, (int, int)>(
  (ref, args) =>
      ref.watch(mushafFilesProvider).colors(MushafStyle.qcfV4, args.$1, palette: args.$2),
);

/// a qcf page's glyphs' ink boxes, read only for a page with a bookmarked ayah on it
final glyphInksProvider = FutureProvider.autoDispose.family<Map<int, Rect>, (MushafStyle, int)>(
  (ref, args) => ref.watch(mushafFilesProvider).inks(args.$1, args.$2),
);
