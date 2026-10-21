import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/quran/domain/mushaf_page.dart';
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

final surahTextProvider = FutureProvider.autoDispose.family<SurahText, int>(
  (ref, surah) async => (await ref.watch(quranAssetsProvider.future)).surahText(surah),
);

final quranSamplesProvider = FutureProvider.autoDispose<Map<String, Map<String, String>>>(
  (ref) async => (await ref.watch(quranAssetsProvider.future)).samples(),
);

/// the page's color now, never followSky
final pageColorProvider = Provider<PageColor>((ref) {
  final picked = ref.watch(
    settingsProvider.select((settings) => settings.value?.pageColor ?? PageColor.followSky),
  );
  if (picked != PageColor.followSky) return picked;

  /// fajr to isha is paper, isha to fajr night. no location yet is paper
  return ref.watch(periodProvider) == Period.isha ? PageColor.night : PageColor.paper;
});
