// Builds assets/quran/ from Tanzil and QUL, see specs/003-milestone-7-quran/contracts/quran-assets.md.
//
//   dart run tool/quran/build_quran.dart
//
// Downloads Tanzil's metadata, Sahih International and Al-Muyassar into tool/quran/.cache/ once,
// delete the folder to refresh them. Reads the two QUL files from the same folder with sqlite3.
//
// TODO(ahmed): Ibn Kathir, As-Sa'di and Clear Quran are only 09 Quran's Al-Fatiha samples in assets/quran/samples.json, supply them once licensed.

import 'dart:convert';
import 'dart:io';

const _cache = 'tool/quran/.cache';
const _out = 'assets/quran';

// TODO(ahmed): confirm Sahih International's and Al-Muyassar's terms for the store build.
const _metadata = 'https://tanzil.net/res/text/metadata/quran-data.js';
const _translation = 'https://tanzil.net/trans/?transID=en.sahih&type=txt-2';
const _tafsir = 'https://tanzil.net/trans/?transID=ar.muyassar&type=txt-2';

// TODO(ahmed): download madinah_v2_layout.sqlite and qpc_hafs_words.sqlite from qul.tarteel.ai into tool/quran/.cache/ and confirm QUL's license and credit line, the reader has only page 1 without them.
const _layout = '$_cache/madinah_v2_layout.db';
const _words = '$_cache/qpc_hafs_words.db';

const _pageCount = 604;
const _linesPerPage = 15;

/// 09 Quran's spelling for the first six, the same style for the rest
const _englishNames = [
  'Al-Fatiha',
  'Al-Baqarah',
  "Aal-'Imran",
  "An-Nisa'",
  "Al-Ma'idah",
  "Al-An'am",
  "Al-A'raf",
  'Al-Anfal',
  'At-Tawbah',
  'Yunus',
  'Hud',
  'Yusuf',
  "Ar-Ra'd",
  'Ibrahim',
  'Al-Hijr',
  'An-Nahl',
  "Al-Isra'",
  'Al-Kahf',
  'Maryam',
  'Ta-Ha',
  "Al-Anbiya'",
  'Al-Hajj',
  "Al-Mu'minun",
  'An-Nur',
  'Al-Furqan',
  "Ash-Shu'ara'",
  'An-Naml',
  'Al-Qasas',
  "Al-'Ankabut",
  'Ar-Rum',
  'Luqman',
  'As-Sajdah',
  'Al-Ahzab',
  "Saba'",
  'Fatir',
  'Ya-Sin',
  'As-Saffat',
  'Sad',
  'Az-Zumar',
  'Ghafir',
  'Fussilat',
  'Ash-Shura',
  'Az-Zukhruf',
  'Ad-Dukhan',
  'Al-Jathiyah',
  'Al-Ahqaf',
  'Muhammad',
  'Al-Fath',
  'Al-Hujurat',
  'Qaf',
  'Adh-Dhariyat',
  'At-Tur',
  'An-Najm',
  'Al-Qamar',
  'Ar-Rahman',
  "Al-Waqi'ah",
  'Al-Hadid',
  'Al-Mujadilah',
  'Al-Hashr',
  'Al-Mumtahanah',
  'As-Saff',
  "Al-Jumu'ah",
  'Al-Munafiqun',
  'At-Taghabun',
  'At-Talaq',
  'At-Tahrim',
  'Al-Mulk',
  'Al-Qalam',
  'Al-Haqqah',
  "Al-Ma'arij",
  'Nuh',
  'Al-Jinn',
  'Al-Muzzammil',
  'Al-Muddaththir',
  'Al-Qiyamah',
  'Al-Insan',
  'Al-Mursalat',
  "An-Naba'",
  "An-Nazi'at",
  "'Abasa",
  'At-Takwir',
  'Al-Infitar',
  'Al-Mutaffifin',
  'Al-Inshiqaq',
  'Al-Buruj',
  'At-Tariq',
  "Al-A'la",
  'Al-Ghashiyah',
  'Al-Fajr',
  'Al-Balad',
  'Ash-Shams',
  'Al-Layl',
  'Ad-Duha',
  'Ash-Sharh',
  'At-Tin',
  "Al-'Alaq",
  'Al-Qadr',
  'Al-Bayyinah',
  'Az-Zalzalah',
  "Al-'Adiyat",
  "Al-Qari'ah",
  'At-Takathur',
  "Al-'Asr",
  'Al-Humazah',
  'Al-Fil',
  'Quraysh',
  "Al-Ma'un",
  'Al-Kawthar',
  'Al-Kafirun',
  'An-Nasr',
  'Al-Masad',
  'Al-Ikhlas',
  'Al-Falaq',
  'An-Nas',
];

Future<void> main() async {
  await _download(_metadata, 'quran-data.js');
  await _download(_translation, 'en.sahih.txt');
  await _download(_tafsir, 'ar.muyassar.txt');

  final metadata = File('$_cache/quran-data.js').readAsStringSync();
  final surahs = _table(metadata, 'Sura');
  final juz = _pairs(metadata, 'Juz');
  final quarters = _pairs(metadata, 'HizbQaurter');
  final pages = _pairs(metadata, 'Page');
  if (surahs.length != 114 || _englishNames.length != 114) _fail('expected 114 surahs');
  if (juz.length != 30 || quarters.length != 240 || pages.length != _pageCount) {
    _fail('expected 30 juz, 240 hizb quarters and $_pageCount pages in quran-data.js');
  }

  /// position of an ayah in the whole mushaf, so starts compare as plain numbers
  int position((int, int) ayah) => int.parse('${surahs[ayah.$1 - 1][0]}') + ayah.$2 - 1;
  int lastStartAtOrBefore(List<(int, int)> starts, int at) =>
      starts.lastIndexWhere((start) => position(start) <= at);

  final index = {
    'surahs': [
      for (final (i, surah) in surahs.indexed)
        {
          'n': i + 1,
          'en': _englishNames[i],
          'ar': surah[4],
          'place': (surah[7] as String).toLowerCase(),
          'ayahs': surah[1],
          'page': lastStartAtOrBefore(pages, position((i + 1, 1))) + 1,
        },
    ],
    'juz': [
      for (final (i, start) in juz.indexed)
        {
          'n': i + 1,
          'surah': start.$1,
          'ayah': start.$2,
          'page': lastStartAtOrBefore(pages, position(start)) + 1,
        },
    ],
    'pages': [
      for (final start in pages)
        {
          'surah': start.$1,
          'ayah': start.$2,
          'juz': lastStartAtOrBefore(juz, position(start)) + 1,
          'hizb': lastStartAtOrBefore(quarters, position(start)) ~/ 4 + 1,
        },
    ],
  };
  _write('$_out/index.json', index);

  final translation = _lines('en.sahih.txt');
  final tafsir = _lines('ar.muyassar.txt');
  for (final (i, surah) in surahs.indexed) {
    final n = i + 1;
    final count = surah[1] as int;
    String line(Map<(int, int), String> source, int ayah) =>
        source[(n, ayah)] ?? _fail('no line for $n:$ayah');
    _write('$_out/surahs/${_three(n)}.json', {
      'tr': [for (var ayah = 1; ayah <= count; ayah++) line(translation, ayah)],
      'tafsir': [for (var ayah = 1; ayah <= count; ayah++) line(tafsir, ayah)],
    });
  }
  stdout.writeln('Wrote $_out/index.json and 114 surah files.');

  if (!File(_layout).existsSync() || !File(_words).existsSync()) {
    _fail('no QUL files in $_cache, download madinah_v2_layout.db and qpc_hafs_words.db');
  }
  final words = <int, List<Object>>{};
  for (final row in await _query(_words, 'select id, surah, ayah, text from words order by id')) {
    final text = row['text'] as String;
    words[row['id'] as int] = [row['surah'] as int, row['ayah'] as int, text, ?_endMarker(text)];
  }
  final rows = await _query(
    _layout,
    'select page_number, line_number, line_type, is_centered, first_word_id, last_word_id, '
    'surah_number from pages order by page_number, line_number',
  );
  final byPage = <int, List<Map<String, Object?>>>{};
  for (final row in rows) {
    (byPage[row['page_number'] as int] ??= []).add(row);
  }
  for (var page = 1; page <= _pageCount; page++) {
    final lines = [
      for (final row in byPage[page] ?? _fail('page $page missing from the layout'))
        switch (row['line_type']) {
          'surah_name' => {'t': 's', 'surah': row['surah_number']},
          'basmallah' => {'t': 'b'},
          'ayah' => {
            't': 'a',
            'c': row['is_centered'] == 1,
            'w': [
              for (var id = row['first_word_id'] as int; id <= (row['last_word_id'] as int); id++)
                words[id] ?? _fail('word $id missing'),
            ],
          },
          final type => _fail('page $page: unknown line type $type'),
        },
    ];

    /// pages 1 and 2 have fewer lines in print, the reader still lays out 15 bands
    while (lines.length < _linesPerPage) {
      lines.add({'t': 'a', 'c': false, 'w': <Object>[]});
    }
    if (lines.length != _linesPerPage) _fail('page $page has ${lines.length} lines');
    _write('$_out/pages/${_three(page)}.json', {'lines': lines});
  }
  stdout.writeln('Wrote $_pageCount pages.');
}

/// qpc hafs puts the ayah number as its own word, written in arabic-indic digits
int? _endMarker(String text) => RegExp(r'^[٠-٩]+$').hasMatch(text) ? 1 : null;

Future<void> _download(String url, String file) async {
  Directory(_cache).createSync(recursive: true);
  if (File('$_cache/$file').existsSync()) return;
  stdout.writeln('Downloading $file');
  final result = await Process.run('curl', ['-fL', '--retry', '3', '-o', '$_cache/$file', url]);
  if (result.exitCode != 0) _fail('curl $url\n${result.stderr}');
}

Future<List<Map<String, Object?>>> _query(String path, String sql) async {
  final result = await Process.run('sqlite3', [path, '-json', sql]);
  if (result.exitCode != 0) _fail('sqlite3 $path\n${result.stderr}');
  final out = (result.stdout as String).trim();
  return out.isEmpty ? [] : (jsonDecode(out) as List).cast<Map<String, Object?>>();
}

/// the rows of `QuranData.<name> = [ ... ];` without the empty first row and the end sentinel
List<List<Object>> _table(String source, String name) {
  final start = source.indexOf('QuranData.$name = [');
  if (start < 0) _fail('QuranData.$name missing');
  final body = source.substring(start, source.indexOf('];', start)).replaceAll(RegExp('//.*'), '');
  final row = RegExp(r'\[([^\[\]]+)\]');
  return [
    for (final match in row.allMatches(body))
      [
        for (final cell in RegExp(r"""'[^']*'|"[^"]*"|-?\d+""").allMatches(match[1]!))
          int.tryParse(cell[0]!) ?? cell[0]!.substring(1, cell[0]!.length - 1),
      ],
  ]..removeLast();
}

List<(int, int)> _pairs(String source, String name) => [
  for (final row in _table(source, name)) (row[0] as int, row[1] as int),
];

/// tanzil's `sura|aya|text` lines, the comment block at the end skipped
Map<(int, int), String> _lines(String file) {
  final lines = <(int, int), String>{};
  for (final line in File('$_cache/$file').readAsLinesSync()) {
    final parts = line.split('|');
    if (parts.length < 3) continue;
    lines[(int.parse(parts[0]), int.parse(parts[1]))] = parts.sublist(2).join('|');
  }
  if (lines.length != 6236) _fail('$file has ${lines.length} ayahs, not 6236');
  return lines;
}

String _three(int n) => '$n'.padLeft(3, '0');

void _write(String path, Object data) {
  File(path)
    ..createSync(recursive: true)
    ..writeAsStringSync('${jsonEncode(data)}\n');
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(1);
}
