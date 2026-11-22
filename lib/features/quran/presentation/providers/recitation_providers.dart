import 'dart:async';

import 'package:better_muslim/core/app/app_localizations.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/network/download_notice.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/quran/recitation_files.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/quran/domain/recitation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// the app's own run overrides it with AudioServiceRecitation, the design scenario never plays
final recitationProvider = Provider<Recitation>((ref) => const IdleRecitation());

final recitationStateProvider = StreamProvider<RecitationState>((ref) async* {
  final recitation = ref.watch(recitationProvider);
  yield recitation.current;
  yield* recitation.state;
});

/// the follow wash's item, null when nothing plays
final playingAyahProvider = Provider<AyahKey?>(
  (ref) => ref.watch(
    recitationStateProvider.select((state) {
      final value = state.value;
      return value != null && value.active ? value.ayah : null;
    }),
  ),
);

/// the reader turns the page with the recitation while true (FR-024)
final followingProvider = NotifierProvider<Following, bool>(Following.new);

class Following extends Notifier<bool> {
  @override
  bool build() => true;

  void set(bool on) => state = on;
}

/// from an ayah to the end of its surah or to, the media texts in the app's language and digits
Future<void> playFrom(BuildContext context, WidgetRef ref, AyahKey from, {AyahKey? to}) async {
  final assets = await ref.read(quranAssetsProvider.future);
  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context);
  final language = Localizations.localeOf(context).languageCode;
  final digits = ref.read(settingsProvider).value?.digits ?? Digits.eastern;
  final surah = assets.surah(from.surah);
  ref.read(followingProvider.notifier).set(true);
  await ref
      .read(recitationProvider)
      .play(
        from,
        to: to ?? AyahKey(from.surah, surah.ayahs),
        media: (
          title: (ayah) => l10n.tr(StringsManager.quranAyahN, {
            'surah': language == 'ar' ? surah.ar : surah.en,
            'n': formatDigitsIn('${ayah.ayah}', language: language, digits: digits),
          }),
          artist: (reciter) => l10n.tr(reciter.label, const {}),
        ),
      );
}

/// progress is null until the first file is in
typedef SurahDownload = ({bool ready, bool downloading, double? progress});

const SurahDownload _idle = (ready: false, downloading: false, progress: null);
const SurahDownload _ready = (ready: true, downloading: false, progress: null);

/// one surah in one voice, checked again on each open since playing a surah keeps its files too
final surahDownloadProvider = NotifierProvider.autoDispose
    .family<SurahDownloadNotifier, SurahDownload, (Reciter, int)>(SurahDownloadNotifier.new);

class SurahDownloadNotifier extends Notifier<SurahDownload> {
  SurahDownloadNotifier(this.surah);

  final (Reciter, int) surah;

  Future<List<AyahKey>> get _files async {
    final assets = await ref.read(quranAssetsProvider.future);
    return surahFiles(surah.$2, assets.surah(surah.$2).ayahs);
  }

  @override
  SurahDownload build() {
    unawaited(() async {
      final ready = await ref.read(recitationFilesProvider).isSurahReady(surah.$1, await _files);
      if (ready && ref.mounted) state = _ready;
    }());
    return _idle;
  }

  /// throws a RecitationException, offline included, what came in stays for the next tap. a
  /// pause from the notification leaves it idle
  Future<void> download() async {
    if (state.ready || state.downloading) return;
    state = (ready: false, downloading: true, progress: null);

    /// the sheet may close, the download and its progress go on
    final link = ref.keepAlive();
    try {
      final (reciter, number) = surah;
      final info = (await ref.read(quranAssetsProvider.future)).surah(number);
      final done = await DownloadNotice.run(
        key: 'surah ${reciter.name} $number',
        title: (l10n, arabic) => l10n.tr(StringsManager.surahByReciter, {
          'surah': arabic ? info.ar : info.en,
          'reciter': l10n.tr(reciter.short, const {}),
        }),
        settings: ref.read(settingsProvider).value,
        resume: download,
        job: (notice) async => ref
            .read(recitationFilesProvider)
            .downloadSurah(
              reciter,
              await _files,
              onProgress: (progress) =>
                  state = (ready: false, downloading: true, progress: progress),
              notice: notice,
            ),
      );
      state = done ? _ready : _idle;
    } on Object {
      state = _idle;
      rethrow;
    } finally {
      link.close();
      ref.invalidate(downloadsProvider);
    }
  }

  /// the downloads page only reads it for this call, so it lives until the files are gone
  Future<void> delete() async {
    final link = ref.keepAlive();
    await ref.read(recitationFilesProvider).deleteSurah(surah.$1, surah.$2);
    state = _idle;
    ref.invalidate(downloadsProvider);
    link.close();
  }
}

/// More's Downloads page, the reciters with nothing downloaded left out.
/// read again on each open, playing a surah fills the folder too
final downloadsProvider = FutureProvider.autoDispose<Map<Reciter, List<({int surah, int bytes})>>>((
  ref,
) async {
  final assets = await ref.watch(quranAssetsProvider.future);
  final files = ref.watch(recitationFilesProvider);
  return {
    for (final reciter in Reciter.values)
      if (await files.downloaded(reciter, (surah) => assets.surah(surah).ayahs) case final surahs
          when surahs.isNotEmpty)
        reciter: surahs,
  };
});
