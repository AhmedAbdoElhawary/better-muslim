import 'dart:convert';

import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// the 1421H print, or the 1405H one while QCF V1 is picked, its page numbers everywhere
final quranAssetsProvider = FutureProvider<QuranAssets>((ref) async {
  final v1 = ref.watch(
    settingsProvider.select((settings) => settings.value?.mushafStyle == MushafStyle.qcfV1),
  );
  final assets = await ref.watch(_printsProvider.future);
  return v1 ? assets.v1 : assets;
});

/// the index is read once for both prints
final _printsProvider = FutureProvider<QuranAssets>((ref) => QuranAssets.load());

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
  QuranAssets._(this.surahs, this.juzs, this.pages, {this.folder = 'pages', this._stored});

  static Future<QuranAssets> load() async {
    final json = await _json('assets/quran/index.json') as Map<String, dynamic>;
    final surahs = [
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
    ];
    final juzs = [
      for (final juz in (json['juz'] as List).cast<Map<String, dynamic>>())
        QuranJuz(
          n: juz['n'] as int,
          start: AyahKey(juz['surah'] as int, juz['ayah'] as int),
          page: juz['page'] as int,
        ),
    ];
    final assets = QuranAssets._(surahs, juzs, _infos(json['pages'] as List));

    /// the 1405H print has the same ayahs on its own pages
    final v1 = json['v1'] as Map<String, dynamic>;
    final surahPages = (v1['surahs'] as List).cast<int>();
    final juzPages = (v1['juz'] as List).cast<int>();
    return assets
      ..v1 = QuranAssets._(
        [
          for (final surah in surahs)
            QuranSurah(
              n: surah.n,
              en: surah.en,
              ar: surah.ar,
              medinan: surah.medinan,
              ayahs: surah.ayahs,
              page: surahPages[surah.n - 1],
              words: surah.words,
            ),
        ],
        [for (final juz in juzs) QuranJuz(n: juz.n, start: juz.start, page: juzPages[juz.n - 1])],
        _infos(v1['pages'] as List),
        folder: 'pages_v1',
        stored: assets,
      );
  }

  static List<QuranPageInfo> _infos(List pages) => [
    for (final page in pages.cast<Map<String, dynamic>>())
      QuranPageInfo(
        start: AyahKey(page['surah'] as int, page['ayah'] as int),
        juz: page['juz'] as int,
        hizb: page['hizb'] as int,
      ),
  ];

  final List<QuranSurah> surahs;
  final List<QuranJuz> juzs;
  final List<QuranPageInfo> pages;

  /// where the page files are, pages/ for 1421H and pages_v1/ for 1405H
  final String folder;

  /// the 1405H print, only on the 1421H one
  late final QuranAssets v1;

  final QuranAssets? _stored;

  /// the current page and its two neighbours
  final _pages = <int, Map<String, dynamic>?>{};
  final _texts = <int, SurahText>{};

  /// the last translation read from its own file, the whole quran in it
  (Translation, List<List<String>>)? _translation;

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

  /// the 1421H print, the database keeps its page numbers whatever print is shown
  QuranAssets get stored => _stored ?? this;

  /// a page the database kept, here the page with that 1421H page's first ayah
  int shownPage(int stored) => pageOf(this.stored.pageInfo(stored).start);

  /// the 1421H page with this page's first ayah, or the next one when only that one shows again
  /// as this page
  int storedPage(int n) {
    final page = stored.pageOf(pageInfo(n).start);
    return page < quranPageCount && shownPage(page) != n && shownPage(page + 1) == n
        ? page + 1
        : page;
  }

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
  Future<String> ayahText(AyahKey key) async => [
    for (final line in ((await page(pageOf(key)))?['lines'] as List? ?? []).cast<Map>())
      for (final word in (line['w'] as List? ?? []).cast<List<dynamic>>())
        if (word[0] == key.surah && word[1] == key.ayah && word.length == 3) word[2] as String,
  ].join(' ');

  /// the page's lines, null when its file is missing
  Future<Map<String, dynamic>?> page(int n) async {
    if (_pages.containsKey(n)) return _pages[n] = _pages.remove(n);
    Map<String, dynamic>? json;
    try {
      json = await _json('assets/quran/$folder/${_three(n)}.json') as Map<String, dynamic>;
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

  /// the surah's ayahs in the translation, index i is ayah i + 1
  Future<List<String>> translation(Translation translation, int surah) async {
    if (translation == Translation.sahih) return (await surahText(surah)).translation;
    if (translation == Translation.muyassar) return (await surahText(surah)).tafsir;
    if (_translation case (final kept, final surahs) when kept == translation) {
      return surahs[surah - 1];
    }
    final json = await _json('assets/quran/translations/${translation.file}.json') as List;
    final surahs = [for (final ayahs in json) (ayahs as List).cast<String>()];
    _translation = (translation, surahs);
    return surahs[surah - 1];
  }
}

/// loadString sends files over 50 kb to an isolate, slower for these than decoding them here
Future<Object?> _json(String path) async =>
    jsonDecode(utf8.decode((await rootBundle.load(path)).buffer.asUint8List()));

String _three(int n) => '$n'.padLeft(3, '0');
