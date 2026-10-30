import 'dart:convert';
import 'dart:isolate';

import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/features/quran/domain/quran_search.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// the whole quran is a few mb, dropped again when search closes
final searchAyahsProvider = FutureProvider.autoDispose<List<SearchAyah>>(
  (ref) => loadSearchAyahs(),
);

/// every ayah's words from the 604 shipped pages and its translation from the 114 surah files,
/// decoded off the main isolate
Future<List<SearchAyah>> loadSearchAyahs() async {
  /// one at a time, the test bundle's synchronous futures leave Future.wait empty
  Future<List<Uint8List>> load(String folder, int count) async => [
    for (var n = 1; n <= count; n++)
      Uint8List.sublistView(
        await rootBundle.load('assets/quran/$folder/${'$n'.padLeft(3, '0')}.json'),
      ),
  ];
  final pages = await load('pages', quranPageCount);
  final surahs = await load('surahs', 114);
  return Isolate.run(() {
    final words = <AyahKey, List<String>>{};
    for (final page in pages) {
      final json = jsonDecode(utf8.decode(page)) as Map<String, dynamic>;
      for (final line in (json['lines'] as List).cast<Map<String, dynamic>>()) {
        for (final word in (line['w'] as List? ?? []).cast<List<dynamic>>()) {
          if (word.length != 3) continue;
          (words[AyahKey(word[0] as int, word[1] as int)] ??= []).add(word[2] as String);
        }
      }
    }
    final translations = [
      for (final surah in surahs)
        ((jsonDecode(utf8.decode(surah)) as Map<String, dynamic>)['tr'] as List).cast<String>(),
    ];
    return [
      for (final MapEntry(:key, :value) in words.entries)
        SearchAyah(key, value, translations[key.surah - 1][key.ayah - 1]),
    ];
  });
}
