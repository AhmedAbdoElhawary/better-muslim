import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/quran/domain/mushaf_page.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// null while the page isn't shipped yet, it shows its frame and placeholder lines
final mushafPageProvider = FutureProvider.autoDispose.family<MushafPage?, int>((ref, n) async {
  final json = await (await ref.watch(quranAssetsProvider.future)).page(n);
  return json == null ? null : MushafPage.fromJson(n, json);
});

/// the arabic of one ayah. pageOf gives the page an ayah ends on, it may start on the one before
final ayahTextProvider = FutureProvider.autoDispose.family<String, AyahKey>((ref, key) async {
  final page = (await ref.watch(quranAssetsProvider.future)).pageOf(key);
  final pages = [
    for (final n in [page - 1, page])
      if (n >= 1) await ref.watch(mushafPageProvider(n).future),
  ];
  return ayahText(pages.nonNulls, key);
});

/// an ayah's words in the qcf glyphs of the pages it is on, its end marker last
final ayahGlyphsProvider = FutureProvider.autoDispose
    .family<List<({int page, String glyph, bool end})>, AyahKey>((ref, key) async {
      final page = (await ref.watch(quranAssetsProvider.future)).pageOf(key);
      return [
        for (final n in [page - 1, page])
          if (n >= 1)
            for (final line in (await ref.watch(mushafPageProvider(n).future))?.lines ?? [])
              for (final word in line.words)
                if (word.key == key && word.glyph.isNotEmpty)
                  (page: n, glyph: word.glyph, end: word.end),
      ];
    });

final surahTextProvider = FutureProvider.autoDispose.family<SurahText, int>(
  (ref, surah) async => (await ref.watch(quranAssetsProvider.future)).surahText(surah),
);

/// a surah's ayahs in a translation, index i is ayah i + 1
final translationProvider = FutureProvider.autoDispose.family<List<String>, (Translation, int)>(
  (ref, args) async => (await ref.watch(quranAssetsProvider.future)).translation(args.$1, args.$2),
);

/// the translation shown, the app language's own until one is picked
Translation shownTranslation(BuildContext context, WidgetRef ref) => Translation.of(
  ref.watch(settingsProvider.select((settings) => settings.value?.translation)),
  arabic: Localizations.localeOf(context).languageCode == 'ar',
);

/// what the reader picked, follow sky is resolved with the app's mode where it's drawn
final pageColorProvider = Provider<PageColor>(
  (ref) => ref.watch(
    settingsProvider.select((settings) => settings.value?.pageColor ?? PageColor.followSky),
  ),
);
