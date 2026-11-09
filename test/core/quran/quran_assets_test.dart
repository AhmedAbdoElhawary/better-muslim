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

    /// one of the pages where the 1405H print starts an ayah earlier
    expect(assets.pageOf(const AyahKey(5, 77)), 120);
  });

  test('the 1405H pages have the 1421H words in order, a glyph for every word', () {
    List<String> words(String folder) {
      final words = <String>[];
      for (var n = 1; n <= quranPageCount; n++) {
        final file = File('assets/quran/$folder/${'$n'.padLeft(3, '0')}.json');
        final lines = (jsonDecode(file.readAsStringSync()) as Map)['lines'] as List;
        expect(lines, hasLength(15), reason: '$folder $n');
        for (final line in lines.cast<Map>().where((line) => line['t'] == 'a')) {
          expect((line['g'] as List).length, (line['w'] as List).length, reason: '$folder $n');
          for (final word in (line['w'] as List).cast<List>()) {
            words.add('${word[0]}:${word[1]} ${word[2]}');
          }
        }
      }
      return words;
    }

    expect(words('pages_v1'), words('pages'));
  });

  test('the 1405H index has its own page starts', () {
    final index = jsonDecode(File('assets/quran/index.json').readAsStringSync()) as Map;
    final v1 = index['v1'] as Map;
    expect(v1['pages'], hasLength(quranPageCount));
    expect(v1['surahs'], hasLength(114));
    expect(v1['juz'], hasLength(30));
    expect((v1['pages'] as List)[120], containsPair('ayah', 77));
    expect((index['pages'] as List)[120], containsPair('ayah', 78));
  });

  test(
    'the 1405H print has its own pages, a kept 1421H page maps through its first ayah',
    () async {
      final assets = await QuranAssets.load();
      final v1 = assets.v1;
      expect(v1.stored, assets);
      expect(assets.stored, assets);

      /// 5:77 opens page 121 in 1405H and ends page 120 in 1421H
      expect(v1.pageOf(const AyahKey(5, 77)), 121);
      expect(assets.pageOf(const AyahKey(5, 77)), 120);
      final line = ((await v1.page(121))!['lines'] as List).first as Map;
      expect((line['w'] as List).first, [5, 77, 'قُلۡ']);

      /// 1421H 121 starts at 5:78, on 1405H 121. kept back as 121, which shows again as itself
      expect(v1.shownPage(121), 121);
      expect(v1.storedPage(121), 121);

      /// 1421H 586 starts at 80:41, still on 1405H 585. 1405H 586 starts at 81:1, on 1421H 586
      expect(v1.shownPage(586), 585);
      expect(v1.storedPage(586), 586);
      expect(v1.shownPage(585), 585);
      expect(v1.storedPage(585), 585);

      /// only where no 1421H page starts on the 1405H one does a kept page show one page before
      expect(
        [
          for (var n = 1; n <= quranPageCount; n++)
            if (v1.shownPage(v1.storedPage(n)) != n) n,
        ],
        [145, 586, 590, 600],
      );
      for (var n = 1; n <= quranPageCount; n++) {
        expect((assets.shownPage(n), assets.storedPage(n)), (n, n), reason: 'page $n');
      }
      expect(v1.surah(81).page, 586);
      expect(v1.juz(30).page, 582);
    },
  );

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
        '$_cache/qpc_hafs_words.db',
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
    skip: File('$_cache/qpc_hafs_words.db').existsSync()
        ? false
        : 'no QUL files in $_cache, the pages are not built yet',
  );
}
