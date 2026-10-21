import 'dart:convert';

import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final quranAssetsProvider = FutureProvider<QuranAssets>((ref) => QuranAssets.load());

const quranPageCount = 604;

class QuranSurah {
  const QuranSurah({
    required this.n,
    required this.en,
    required this.ar,
    required this.medinan,
    required this.ayahs,
    required this.page,
  });

  final int n;
  final String en;
  final String ar;
  final bool medinan;
  final int ayahs;

  /// the page its first ayah is on
  final int page;

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
  Map<String, Map<String, String>>? _samples;

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

  /// the page's lines, null while the page isn't shipped yet (only page 1 until the QUL files)
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
    if (_texts[n] case final text?) return text;
    final json = await _json('assets/quran/surahs/${_three(n)}.json') as Map<String, dynamic>;
    final text = SurahText(
      translation: (json['tr'] as List).cast<String>(),
      tafsir: (json['tafsir'] as List).cast<String>(),
    );
    _texts
      ..clear()
      ..[n] = text;
    return text;
  }

  /// ibn kathir, as-sa'di and clear quran by source and "1:5", only samples until licensed
  Future<Map<String, Map<String, String>>> samples() async => _samples ??= {
    for (final MapEntry(:key, :value)
        in (await _json('assets/quran/samples.json') as Map<String, dynamic>).entries)
      key: (value as Map<String, dynamic>).cast<String, String>(),
  };
}

/// the provider keeps what it needs, and a cached load hangs the next widget test
Future<Object?> _json(String path) async =>
    jsonDecode(await rootBundle.loadString(path, cache: false));

String _three(int n) => '$n'.padLeft(3, '0');
