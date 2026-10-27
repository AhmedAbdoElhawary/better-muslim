import 'dart:convert';
import 'dart:io';

import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:flutter_test/flutter_test.dart';

const _cache = 'tool/quran/.cache';

/// the shipped page numbers, only page 1 until the QUL files are in
final _shipped = [
  for (var n = 1; n <= quranPageCount; n++)
    if (File('assets/quran/pages/${'$n'.padLeft(3, '0')}.json').existsSync()) n,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the index has every surah, juz and page (SC-001)', () async {
    final assets = await QuranAssets.load();
    expect(assets.surahs, hasLength(114));
    expect(assets.juzs, hasLength(30));
    expect(assets.pages, hasLength(quranPageCount));
    expect(assets.surahs.fold(0, (sum, surah) => sum + surah.ayahs), 6236);
    expect(assets.surah(2).page, 2);
    expect(assets.juz(30).page, 582);
    expect(assets.pageOf(const AyahKey(2, 255)), 42);
    expect(assets.pageOf(const AyahKey(1, 1)), 1);
    expect(assets.pageOf(const AyahKey(114, 6)), quranPageCount);
  });

  test('verse candidates are 6 to 40 words, an ayah\'s text is its words', () async {
    final assets = await QuranAssets.load();
    final candidates = assets.verseCandidates();
    expect(candidates, contains(const AyahKey(1, 7)));
    expect(candidates, isNot(contains(const AyahKey(1, 5))), reason: '4 words');
    expect(candidates, isNot(contains(const AyahKey(2, 282))), reason: 'the longest ayah');
    expect((await assets.ayahText(const AyahKey(1, 5))).split(' '), hasLength(4));
    expect((await assets.ayahText(const AyahKey(2, 255))).split(' '), hasLength(50));
  });

  test('every shipped page has 15 lines of known types, ayahs in order', () async {
    final assets = await QuranAssets.load();
    expect(_shipped, contains(1));
    AyahKey? last;
    for (final n in _shipped) {
      final lines = (await assets.page(n))!['lines'] as List;
      expect(lines, hasLength(15), reason: 'page $n');
      for (final line in lines.cast<Map<String, dynamic>>()) {
        expect(['a', 's', 'b'], contains(line['t']), reason: 'page $n');
        for (final word in (line['w'] as List? ?? []).cast<List>()) {
          expect(word.length == 3 || (word.length == 4 && word[3] == 1), isTrue, reason: '$word');
          final key = AyahKey(word[0] as int, word[1] as int);
          if (last != null) expect(key.compareTo(last), greaterThanOrEqualTo(0), reason: 'page $n');
          last = key;
        }
      }
    }
  });

  test('a page not shipped yet reads as null', () async {
    final assets = await QuranAssets.load();
    final missing = [for (var n = 1; n <= quranPageCount; n++) n]
        .where((n) => !_shipped.contains(n));
    if (missing.isEmpty) return markTestSkipped('every page is shipped');
    expect(await assets.page(missing.first), isNull);
  });

  test('Al-Fatiha has 7 translations and 7 tafsir lines', () async {
    final text = await (await QuranAssets.load()).surahText(1);
    expect(text.translation, hasLength(7));
    expect(text.tafsir, hasLength(7));
  });

  test(
    'the translation and tafsir equal their Tanzil lines',
    () async {
      final assets = await QuranAssets.load();
      final sources = {
        for (final file in ['en.sahih.txt', 'ar.muyassar.txt'])
          file: {
            for (final line in File('$_cache/$file').readAsLinesSync())
              if (line.split('|') case [final s, final a, ...final text]) '$s:$a': text.join('|'),
          },
      };
      for (final surah in assets.surahs) {
        final text = await assets.surahText(surah.n);
        for (var ayah = 1; ayah <= surah.ayahs; ayah++) {
          expect(text.translation[ayah - 1], sources['en.sahih.txt']!['${surah.n}:$ayah']);
          expect(text.tafsir[ayah - 1], sources['ar.muyassar.txt']!['${surah.n}:$ayah']);
        }
      }
    },
    skip: File('$_cache/en.sahih.txt').existsSync()
        ? false
        : 'no Tanzil files in $_cache, run tool/quran/build_quran.dart',
  );

  test(
    'every word equals its QUL word',
    () async {
      final result = await Process.run('sqlite3', [
        '$_cache/qpc_hafs_words.sqlite',
        '-json',
        'select surah, ayah, text from words order by id',
      ]);
      final source = [
        for (final row in (jsonDecode(result.stdout as String) as List).cast<Map>())
          '${row['surah']}:${row['ayah']} ${row['text']}',
      ];
      final assets = await QuranAssets.load();
      final words = [
        for (var n = 1; n <= quranPageCount; n++)
          for (final line in ((await assets.page(n))!['lines'] as List).cast<Map>())
            for (final word in (line['w'] as List? ?? []).cast<List>())
              '${word[0]}:${word[1]} ${word[2]}',
      ];
      expect(words, source);
    },
    skip: File('$_cache/qpc_hafs_words.sqlite').existsSync()
        ? false
        : 'no QUL files in $_cache, the pages are not built yet',
  );
}
