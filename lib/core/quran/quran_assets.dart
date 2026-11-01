import 'dart:convert';

import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final quranAssetsProvider = FutureProvider<QuranAssets>((ref) => QuranAssets.load());

const quranPageCount = 604;
const quranSurahCount = 114;

class QuranSurah {
  const QuranSurah({
    required this.n,
    required this.en,
    required this.ar,
    required this.medinan,
    required this.ayahs,
    required this.page,
    required this.words,
  });

  final int n;
  final String en;
  final String ar;
  final bool medinan;
  final int ayahs;

  /// the page its first ayah is on
  final int page;

  /// each ayah's word count, without its number
  final List<int> words;

  /// as the mushaf heads it, arabic in both languages
  String get title => 'سورة $ar';
}

class QuranJuz {
  const QuranJuz({required this.n, required this.start, required this.page});

  final int n;
  final AyahKey start;
  final int page;
}

class QuranPageInfo {
  const QuranPageInfo({required this.start, required this.juz, required this.hizb});

  final AyahKey start;
  final int juz;
  final int hizb;
}

/// index i is ayah i + 1
class SurahText {
  const SurahText({required this.translation, required this.tafsir});

  final List<String> translation;
  final List<String> tafsir;
}

/// the shipped mushaf (contracts/quran-assets.md). the index stays loaded, pages and surah texts
/// are read when shown and only the last few kept
class QuranAssets {
  QuranAssets._(this.surahs, this.juzs, this.pages);

  static Future<QuranAssets> load() async {
    final json = await _json('assets/quran/index.json') as Map<String, dynamic>;
    return QuranAssets._(
      [
        for (final surah in (json['surahs'] as List).cast<Map<String, dynamic>>())
          QuranSurah(
            n: surah['n'] as int,
            en: surah['en'] as String,
            ar: surah['ar'] as String,
            medinan: surah['place'] == 'medinan',
            ayahs: surah['ayahs'] as int,
            page: surah['page'] as int,
            words: (surah['words'] as List).cast<int>(),
          ),
      ],
      [
        for (final juz in (json['juz'] as List).cast<Map<String, dynamic>>())
          QuranJuz(
            n: juz['n'] as int,
            start: AyahKey(juz['surah'] as int, juz['ayah'] as int),
            page: juz['page'] as int,
          ),
      ],
      [
        for (final page in (json['pages'] as List).cast<Map<String, dynamic>>())
          QuranPageInfo(
            start: AyahKey(page['surah'] as int, page['ayah'] as int),
            juz: page['juz'] as int,
            hizb: page['hizb'] as int,
          ),
      ],
    );
  }

  final List<QuranSurah> surahs;
  final List<QuranJuz> juzs;
  final List<QuranPageInfo> pages;

  /// the current page and its two neighbours
  final _pages = <int, Map<String, dynamic>?>{};
  final _texts = <int, SurahText>{};

  QuranSurah surah(int n) => surahs[n - 1];

  QuranJuz juz(int n) => juzs[n - 1];

  QuranPageInfo pageInfo(int n) => pages[n - 1];

  /// the ayah after this one, into the next surah at a surah's end, null after the last
  AyahKey? next(AyahKey key) => key.ayah < surah(key.surah).ayahs
      ? AyahKey(key.surah, key.ayah + 1)
      : key.surah < surahs.length
      ? AyahKey(key.surah + 1, 1)
      : null;

  AyahKey? previous(AyahKey key) => key.ayah > 1
      ? AyahKey(key.surah, key.ayah - 1)
      : key.surah > 1
      ? AyahKey(key.surah - 1, surah(key.surah - 1).ayahs)
      : null;

  int pageOf(AyahKey key) => pages.lastIndexWhere((page) => page.start.compareTo(key) <= 0) + 1;

  /// the ayahs starting on the page, or the one running through it when none starts there
  List<AyahKey> pageAyahs(int n) {
    final start = pageInfo(n).start;
    final ayahs = [
      for (AyahKey? key = start; key != null && pageOf(key) == n; key = next(key)) key,
    ];
    return ayahs.isEmpty ? [start] : ayahs;
  }

  /// home's verse of the day, ayahs short enough for its card and long enough to say something
  List<AyahKey> verseCandidates() => [
    for (final surah in surahs)
      for (final (i, words) in surah.words.indexed)
        if (words >= 6 && words <= 40) AyahKey(surah.n, i + 1),
  ];

  /// the madinah pages always end on an ayah's end, so one page has all its words
  Future<String> ayahText(AyahKey key) async {
    final n = pageOf(key);

    /// the index and the page files disagree on 25 pages by an ayah or a few, a neighbour has it
    for (final at in [n, n - 1, n + 1]) {
      if (at < 1 || at > quranPageCount) continue;
      final text = [
        for (final line in ((await page(at))?['lines'] as List? ?? []).cast<Map>())
          for (final word in (line['w'] as List? ?? []).cast<List<dynamic>>())
            if (word[0] == key.surah && word[1] == key.ayah && word.length == 3) word[2] as String,
      ].join(' ');
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  /// the page's lines, null when its file is missing
  Future<Map<String, dynamic>?> page(int n) async {
    if (_pages.containsKey(n)) return _pages[n] = _pages.remove(n);
    Map<String, dynamic>? json;
    try {
      json = await _json('assets/quran/pages/${_three(n)}.json') as Map<String, dynamic>;
    } on FlutterError {
      json = null;
    }
    _pages[n] = json;
    if (_pages.length > 3) _pages.remove(_pages.keys.first);
    return json;
  }

  Future<SurahText> surahText(int n) async {
    if (_texts.remove(n) case final text?) return _texts[n] = text;
    final json = await _json('assets/quran/surahs/${_three(n)}.json') as Map<String, dynamic>;
    final text = SurahText(
      translation: (json['tr'] as List).cast<String>(),
      tafsir: (json['tafsir'] as List).cast<String>(),
    );
    _texts[n] = text;

    /// a page or its neighbour can hold two surahs, turning back and forth never decodes again
    if (_texts.length > 3) _texts.remove(_texts.keys.first);
    return text;
  }
}

/// loadString sends files over 50 kb to an isolate, slower for these than decoding them here
Future<Object?> _json(String path) async =>
    jsonDecode(utf8.decode((await rootBundle.load(path)).buffer.asUint8List()));

String _three(int n) => '$n'.padLeft(3, '0');
