// Builds assets/quran/ from Tanzil and QUL, see specs/003-milestone-7-quran/contracts/quran-assets.md.
//
//   dart run tool/quran/build_quran.dart
//
// Downloads Tanzil's metadata, Sahih International and Al-Muyassar, quran.com's QCF glyphs and the
// QCF V1 and V2 page fonts (about 300 MB) into tool/quran/.cache/ once, delete the folder to
// refresh them. Reads the two QUL files from the same folder with sqlite3.
//
//   dart run tool/quran/build_quran.dart --tafsir
//
// Builds the downloadable tafsirs into build/tafsir/ instead, from quran.com's api into the same
// cache, see specs/008-enhancements/contracts/tafsir-files.md.
//
//   dart run tool/quran/build_quran.dart --translations
//
// Writes the translations past Sahih International and Al-Muyassar into
// assets/quran/translations/, one file each from Tanzil, see specs/019-reader-polish.
//
//   dart run tool/quran/build_quran.dart --fonts
//
// Builds the downloadable QCF styles into build/mushaf/ instead, qcf_v1.bin, qcf_v2.bin and
// qcf_v4.bin from the page fonts in the same cache (V4 adds about 165 MB), see
// specs/016-mushaf-styles.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

const _cache = 'tool/quran/.cache';
const _out = 'assets/quran';

// tanzil's translations are for non-commercial use only, fine while the app is free with no ads.
const _metadata = 'https://tanzil.net/res/text/metadata/quran-data.js';
const _translation = 'https://tanzil.net/trans/?transID=en.sahih&type=txt-2';
const _tafsir = 'https://tanzil.net/trans/?transID=ar.muyassar&type=txt-2';

// madinah_v2_layout.sqlite and qpc_hafs_words.sqlite from qul.tarteel.ai, saved under these names.
const _layout = '$_cache/madinah_v2_layout.db';
const _words = '$_cache/qpc_hafs_words.db';

// each word's QCF V1 and V2 glyphs with its 1405H and 1421H page and line, and the V1 page fonts
// that tell a short line from a full one, see specs/016-mushaf-styles.
String _qcfWords(int surah) =>
    'https://api.quran.com/api/v4/verses/by_chapter/$surah?words=true&word_fields=code_v1,code_v2,'
    'v1_page,v2_page,line_v1,line_v2,text_qpc_hafs&per_page=300&fields=';
const _qcfFonts = 'https://verses.quran.foundation/fonts/quran/hafs';

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

Future<void> main(List<String> args) async {
  if (args.contains('--tafsir')) return _tafsirs();
  if (args.contains('--fonts')) return _styles();
  if (args.contains('--translations')) return _translations();
  await _download(_metadata, 'quran-data.js');
  await _download(_translation, 'en.sahih.txt');
  await _download(_tafsir, 'ar.muyassar.txt');

  final metadata = File('$_cache/quran-data.js').readAsStringSync();
  final surahs = _table(metadata, 'Sura');
  final juz = _pairs(metadata, 'Juz');
  final quarters = _pairs(metadata, 'HizbQaurter');
  if (surahs.length != 114 || _englishNames.length != 114) _fail('expected 114 surahs');
  if (juz.length != 30 || quarters.length != 240) {
    _fail('expected 30 juz and 240 hizb quarters in quran-data.js');
  }

  /// position of an ayah in the whole mushaf, so starts compare as plain numbers
  int position((int, int) ayah) => int.parse('${surahs[ayah.$1 - 1][0]}') + ayah.$2 - 1;
  int lastStartAtOrBefore(List<(int, int)> starts, int at) =>
      starts.lastIndexWhere((start) => position(start) <= at);

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
  stdout.writeln('Wrote 114 surah files.');

  if (!File(_layout).existsSync() || !File(_words).existsSync()) {
    _fail('no QUL files in $_cache, download madinah_v2_layout.db and qpc_hafs_words.db');
  }
  final words = <int, List<Object>>{};
  for (final row in await _query(_words, 'select id, surah, ayah, text from words order by id')) {
    final text = row['text'] as String;
    words[row['id'] as int] = [row['surah'] as int, row['ayah'] as int, text, ?_endMarker(text)];
  }

  /// home's verse of the day picks ayahs by length
  final counts = [for (final surah in surahs) List.filled(surah[1] as int, 0)];
  for (final [surah as int, ayah as int, _, ...end] in words.values) {
    if (end.isEmpty) counts[surah - 1][ayah - 1]++;
  }

  final glyphs = await _glyphs(words);
  await _pageFonts('v1');
  await _pageFonts('v2');
  final rows = await _query(
    _layout,
    'select page_number, line_number, line_type, is_centered, first_word_id, last_word_id, '
    'surah_number from pages order by page_number, line_number',
  );

  /// quran.com's 1421H lines rebroken and centered like the 1405H ones, then checked against qul's.
  /// they agree but for a word where the QCF V2 widths show qul is off, and the widths win
  final v2 = _byLine(glyphs.v2);
  _rebreak('v2', v2, glyphs.v2);
  final v2Centered = _centered('v2', v2, glyphs.v2, words);
  for (final row in rows.where((row) => row['line_type'] == 'ayah')) {
    final (page, line) = (row['page_number'] as int, row['line_number'] as int);
    final ids = [
      for (var id = row['first_word_id'] as int; id <= (row['last_word_id'] as int); id++) id,
    ];
    final ours = v2[page]?[line] ?? _fail('QCF V2 has no words on 1421H line $page:$line');
    if (ours.join(',') != ids.join(',')) {
      stdout.writeln('1421H line $page:$line keeps QCF V2 widths over qul: $ours, qul $ids');
    }
    if ((row['is_centered'] == 1) != v2Centered.contains((page, line))) {
      _fail('_centered gets 1421H line $page:$line wrong');
    }
  }

  /// the 1405H print, read by page and line
  final v1 = _byLine(glyphs.v1);
  _rebreak('v1', v1, glyphs.v1);

  /// each print's page of every ayah and the start of every page. tanzil's pages are the 1405H
  /// print's, so both come from the lines
  ({Map<(int, int), int> pageOf, List<Map<String, int>> pages}) paging(
    Map<int, Map<int, List<int>>> lines,
  ) {
    final pageOf = <(int, int), int>{};
    final pages = <Map<String, int>>[];
    for (var page = 1; page <= _pageCount; page++) {
      final ids = (lines[page] ?? _fail('page $page has no words')).values.expand((ids) => ids);
      for (final id in ids) {
        pageOf.putIfAbsent((words[id]![0] as int, words[id]![1] as int), () => page);
      }
      final start = (words[ids.first]![0] as int, words[ids.first]![1] as int);
      pages.add({
        'surah': start.$1,
        'ayah': start.$2,
        'juz': lastStartAtOrBefore(juz, position(start)) + 1,
        'hizb': lastStartAtOrBefore(quarters, position(start)) ~/ 4 + 1,
      });
    }
    return (pageOf: pageOf, pages: pages);
  }

  final (pageOf: v2PageOf, pages: v2Starts) = paging(v2);
  final (pageOf: v1PageOf, pages: v1Starts) = paging(v1);
  final index = {
    'surahs': [
      for (final (i, surah) in surahs.indexed)
        {
          'n': i + 1,
          'en': _englishNames[i],
          'ar': surah[4],
          'place': (surah[7] as String).toLowerCase(),
          'ayahs': surah[1],
          'page': v2PageOf[(i + 1, 1)]!,
          'words': counts[i],
        },
    ],
    'juz': [
      for (final (i, start) in juz.indexed)
        {'n': i + 1, 'surah': start.$1, 'ayah': start.$2, 'page': v2PageOf[start]!},
    ],
    'pages': v2Starts,
    'v1': {
      'surahs': [for (var surah = 1; surah <= 114; surah++) v1PageOf[(surah, 1)]],
      'juz': [for (final start in juz) v1PageOf[start]],
      'pages': v1Starts,
    },
  };
  _write('$_out/index.json', index);
  stdout.writeln('Wrote $_out/index.json.');
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
            'w': [for (final id in v2[page]![row['line_number']]!) words[id]!],
            'g': [for (final id in v2[page]![row['line_number']]!) glyphs.v2[id]!.code],
          },
          final type => _fail('page $page: unknown line type $type'),
        },
    ];

    /// pages 1 and 2 have fewer lines in print, the reader still lays out 15 bands
    while (lines.length < _linesPerPage) {
      lines.add({'t': 'a', 'c': false, 'w': <Object>[], 'g': <String>[]});
    }
    if (lines.length != _linesPerPage) _fail('page $page has ${lines.length} lines');
    _write('$_out/pages/${_three(page)}.json', {'lines': lines});
  }
  stdout.writeln('Wrote $_pageCount pages.');

  /// a surah's name and basmallah are the empty lines above its first word, al-fatiha's basmallah
  /// is its first ayah and at-tawbah has none
  final headers = <(int, int), Map<String, Object>>{};
  final firsts = <Object, (int, int)>{
    for (final MapEntry(key: page, value: lines) in v1.entries.toList().reversed)
      for (final MapEntry(key: line, value: ids) in lines.entries.toList().reversed)
        for (final id in ids.reversed) words[id]![0]: (page, line),
  };
  for (var surah = 1; surah <= 114; surah++) {
    var (page, line) = firsts[surah]!;
    for (final header in [
      if (surah != 1 && surah != 9) {'t': 'b'},
      {'t': 's', 'surah': surah},
    ]) {
      (page, line) = line > 1 ? (page, line - 1) : (page - 1, _linesPerPage);
      headers[(page, line)] = header;
    }
  }
  final v1Centered = _centered('v1', v1, glyphs.v1, words);
  for (var page = 1; page <= _pageCount; page++) {
    final lines = v1[page]!;
    final last = lines.keys.reduce(math.max);
    _write('$_out/pages_v1/${_three(page)}.json', {
      'lines': [
        for (var line = 1; line <= _linesPerPage; line++)
          if (lines[line] case final ids?)
            {
              't': 'a',
              'c': v1Centered.contains((page, line)),
              'w': [for (final id in ids) words[id]!],
              'g': [for (final id in ids) glyphs.v1[id]!.code],
            }
          else if (headers[(page, line)] case final header?)
            header
          else if (page <= 2 && line > last)
            {'t': 'a', 'c': false, 'w': <Object>[], 'g': <String>[]}
          else
            _fail('page $page line $line is empty in QCF V1'),
      ],
    });
  }
  stdout.writeln('Wrote $_pageCount 1405H pages.');
}

/// the lines print centers: the opening pages, and one of a surah's last two lines when it's under
/// 0.92 of its page's usual line. it gives qul's 1421H flags exactly, the 1405H print has none
Set<(int, int)> _centered(
  String version,
  Map<int, Map<int, List<int>>> pages,
  Map<int, _Glyph> glyphs,
  Map<int, List<Object>> words,
) {
  final surahs = <Object, List<(int, int)>>{};
  for (final MapEntry(key: page, value: lines) in pages.entries) {
    for (final MapEntry(key: line, value: ids) in lines.entries) {
      for (final id in ids) {
        final at = surahs[words[id]![0]] ??= [];
        if (at.lastOrNull != (page, line)) at.add((page, line));
      }
    }
  }
  final ends = {for (final lines in surahs.values) ...lines.sublist(math.max(0, lines.length - 2))};
  final centered = <(int, int)>{};
  for (final MapEntry(key: page, value: lines) in pages.entries) {
    final (:width, :usual) = _widths(version, page, lines, glyphs);
    for (final MapEntry(key: line, value: ids) in lines.entries) {
      if (page <= 2 || ends.contains((page, line)) && width(ids) < usual * 0.92) {
        centered.add((page, line));
      }
    }
  }
  return centered;
}

/// quran.com puts a few words a line early or late: a line is wider than the page's lines by one
/// word and its neighbour short by the same. on the 1421H lines moving it back gives qul's exactly
void _rebreak(String version, Map<int, Map<int, List<int>>> pages, Map<int, _Glyph> glyphs) {
  for (final MapEntry(key: page, value: lines) in pages.entries) {
    if (page <= 2) continue;
    final (:width, :usual) = _widths(version, page, lines, glyphs);
    bool fits(List<int> ids) => (width(ids) / usual - 1).abs() < 0.03;
    for (final line in lines.keys.toList()) {
      final ids = lines[line]!;
      if (width(ids) < usual * 1.03) continue;

      /// a word without glyphs is drawn with the one before, they move together
      final last = ids.lastIndexWhere((id) => glyphs[id]!.code.isNotEmpty);
      var first = 1;
      while (first < ids.length && glyphs[ids[first]]!.code.isEmpty) {
        first++;
      }
      final (next, previous) = (lines[line + 1], lines[line - 1]);
      if (next != null && fits(ids.sublist(0, last)) && fits([...ids.sublist(last), ...next])) {
        lines[line + 1] = [...ids.sublist(last), ...next];
        lines[line] = ids.sublist(0, last);
      } else if (previous != null &&
          fits([...previous, ...ids.sublist(0, first)]) &&
          fits(ids.sublist(first))) {
        lines[line - 1] = [...previous, ...ids.sublist(0, first)];
        lines[line] = ids.sublist(first);
      } else {
        continue;
      }
      stdout.writeln('QCF ${version.toUpperCase()} page $page: moved a word off line $line');
    }
  }
}

/// a line's width in ems in its page font, and the page's median line, a full line
({double Function(List<int> ids) width, double usual}) _widths(
  String version,
  int page,
  Map<int, List<int>> lines,
  Map<int, _Glyph> glyphs,
) {
  final advance = _advances('$_cache/qcf_$version/p$page.ttf');
  double width(List<int> ids) =>
      ids.expand((id) => glyphs[id]!.code.runes).fold(0, (sum, char) => sum + advance(char));
  final widths = lines.values.map(width).toList()..sort();
  return (width: width, usual: widths[widths.length ~/ 2]);
}

/// page to line to word ids, in reading order
Map<int, Map<int, List<int>>> _byLine(Map<int, _Glyph> glyphs) {
  final pages = <int, Map<int, List<int>>>{};
  var (page, line) = (0, 0);
  for (final MapEntry(key: id, value: glyph) in glyphs.entries) {
    /// a word is never above the one before it, quran.com puts 84:21's V2 end marker a line up
    if (glyph.page > page || glyph.page == page && glyph.line > line) {
      (page, line) = (glyph.page, glyph.line);
    }
    ((pages[page] ??= {})[line] ??= []).add(id);
  }
  return pages;
}

/// a word's glyphs in one print and where it sits. quran.com keeps three pairs like بَعۡدَ مَا as
/// one word, each gets its own glyph, and where the pair is one glyph the second gets none
typedef _Glyph = ({String code, int page, int line});

/// qul's word ids to quran.com's V1 and V2 glyphs, matched by their qpc hafs text
Future<({Map<int, _Glyph> v1, Map<int, _Glyph> v2})> _glyphs(Map<int, List<Object>> words) async {
  final ids = <(int, int), List<int>>{};
  for (final MapEntry(key: id, value: word) in words.entries) {
    (ids[(word[0] as int, word[1] as int)] ??= []).add(id);
  }
  final v1 = <int, _Glyph>{};
  final v2 = <int, _Glyph>{};
  for (var surah = 1; surah <= 114; surah++) {
    final file = 'qcf_words_${_three(surah)}.json';
    await _download(_qcfWords(surah), file);
    final json = jsonDecode(File('$_cache/$file').readAsStringSync()) as Map<String, dynamic>;
    for (final verse in (json['verses'] as List).cast<Map<String, dynamic>>()) {
      final ayah = int.parse((verse['verse_key'] as String).split(':').last);
      final queue = [...?ids[(surah, ayah)]];
      for (final word in (verse['words'] as List).cast<Map<String, dynamic>>()) {
        final text = word['text_qpc_hafs'] as String;
        final taken = <int>[];
        while (taken.map((id) => words[id]![2]).join(' ') != text) {
          if (queue.isEmpty || taken.length == text.split(' ').length) {
            _fail('$surah:$ayah: qul has no words for "$text"');
          }
          taken.add(queue.removeAt(0));
        }
        for (final (version, glyphs) in [('v1', v1), ('v2', v2)]) {
          final code = word['code_$version'] as String;
          final each = [
            for (final char in code.replaceAll(' ', '').runes) String.fromCharCode(char),
          ];
          for (final (i, id) in taken.indexed) {
            glyphs[id] = (
              code: each.length == taken.length
                  ? each[i]
                  : i == 0
                  ? code
                  : '',
              page: word['${version}_page'] as int,
              line: word['line_$version'] as int,
            );
          }
        }
      }
      if (queue.isNotEmpty) _fail('$surah:$ayah has fewer words on quran.com than in qul');
    }
  }
  return (v1: v1, v2: v2);
}

/// one QCF set's 604 page fonts, eight at a time
Future<void> _pageFonts(String version) async {
  Directory('$_cache/qcf_$version').createSync(recursive: true);
  final folder = version == 'v4' ? 'v4/colrv1' : version;
  for (var page = 1; page <= _pageCount; page += 8) {
    await Future.wait([
      for (var n = page; n < page + 8 && n <= _pageCount; n++)
        _download('$_qcfFonts/$folder/ttf/p$n.ttf', 'qcf_$version/p$n.ttf'),
    ]);
  }
}

/// each character's advance in ems, from a ttf's format 4 cmap and its hmtx
double Function(int char) _advances(String path) {
  final data = ByteData.sublistView(File(path).readAsBytesSync());
  final tables = <String, int>{
    for (var i = 0; i < data.getUint16(4); i++)
      String.fromCharCodes([for (var j = 0; j < 4; j++) data.getUint8(12 + 16 * i + j)]): data
          .getUint32(20 + 16 * i),
  };
  final units = data.getUint16(tables['head']! + 18);
  final metrics = data.getUint16(tables['hhea']! + 34);
  final cmap = tables['cmap']!;
  final glyphs = <int, int>{};
  for (var i = 0; i < data.getUint16(cmap + 2); i++) {
    final at = cmap + data.getUint32(cmap + 8 + 8 * i);
    if (data.getUint16(at) != 4) continue;
    final count = data.getUint16(at + 6) ~/ 2;
    final ends = at + 14;
    final starts = ends + 2 * count + 2;
    final deltas = starts + 2 * count;
    final offsets = deltas + 2 * count;
    for (var s = 0; s < count; s++) {
      final start = data.getUint16(starts + 2 * s);
      final delta = data.getInt16(deltas + 2 * s);
      final offset = data.getUint16(offsets + 2 * s);
      for (var char = start; char <= data.getUint16(ends + 2 * s) && char != 0xFFFF; char++) {
        final glyph = offset == 0
            ? char + delta
            : data.getUint16(offsets + 2 * s + offset + 2 * (char - start));
        glyphs[char] = (offset != 0 && glyph != 0 ? glyph + delta : glyph) & 0xFFFF;
      }
    }
  }
  final hmtx = tables['hmtx']!;
  return (char) => data.getUint16(hmtx + 4 * math.min(glyphs[char] ?? 0, metrics - 1)) / units;
}

/// one file per QCF style: 605 little endian uint32 offsets, then each page's ttf gzipped on its
/// own from offset n - 1 to n, so the app unzips only the page it opens
Future<void> _styles() async {
  for (final version in ['v1', 'v2', 'v4']) {
    await _pageFonts(version);
    final pages = [
      for (var n = 1; n <= _pageCount; n++)
        GZipCodec(level: 9).encode(File('$_cache/qcf_$version/p$n.ttf').readAsBytesSync()),
    ];
    final offsets = ByteData(4 * (_pageCount + 1));
    var offset = offsets.lengthInBytes;
    for (var n = 0; n <= _pageCount; n++) {
      offsets.setUint32(4 * n, offset, Endian.little);
      if (n < _pageCount) offset += pages[n].length;
    }
    final bytes = BytesBuilder(copy: false)..add(offsets.buffer.asUint8List());
    pages.forEach(bytes.add);
    final file = bytes.takeBytes();
    File('build/mushaf/qcf_$version.bin')
      ..createSync(recursive: true)
      ..writeAsBytesSync(file);
    stdout.writeln('qcf_$version.bin ${file.length} bytes sha256 ${sha256.convert(file)}');
  }
}

/// one file per translation, `[[surah 1's ayahs], ...]`, in the app like Sahih International
Future<void> _translations() async {
  for (final id in _translationIds) {
    await _download('https://tanzil.net/trans/?transID=$id&type=txt-2', '$id.txt');
    final lines = _lines('$id.txt');
    final index = jsonDecode(File('$_out/index.json').readAsStringSync()) as Map<String, dynamic>;
    _write('$_out/translations/$id.json', [
      for (final (i, surah) in (index['surahs'] as List).indexed)
        [
          for (var ayah = 1; ayah <= (surah['ayahs'] as int); ayah++)
            lines[(i + 1, ayah)] ?? _fail('$id has no ${i + 1}:$ayah'),
        ],
    ]);
    stdout.writeln('Wrote $id.json');
  }
}

/// Translation's files, tanzil's ids
const _translationIds = ['en.pickthall', 'en.yusufali', 'en.hilali', 'ar.jalalayn'];

/// one gzipped file per tafsir, `{"1": [ayah 1, ...], ...}`
Future<void> _tafsirs() async {
  final index = jsonDecode(File('$_out/index.json').readAsStringSync()) as Map<String, dynamic>;
  final counts = [for (final surah in index['surahs'] as List) surah['ayahs'] as int];
  for (final name in _tafsirIds.keys) {
    final rows = await _apiTafsir(name, counts.length);
    final surahs = <String, List<String>>{};
    for (final (i, count) in counts.indexed) {
      final texts = <String>[];
      for (var ayah = 1; ayah <= count; ayah++) {
        /// quran.com leaves out or empties some grouped ayahs, the ayah before already covers them
        final text = _plain(rows['${i + 1}:$ayah'] ?? '');
        texts.add(
          text.isNotEmpty
              ? text
              : ayah > 1
              ? texts.last
              : _fail('$name has no ${i + 1}:$ayah'),
        );
      }
      surahs['${i + 1}'] = texts;
    }
    final bytes = gzip.encode(utf8.encode(jsonEncode(surahs)));
    File('build/tafsir/$name.json.gz')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes);
    stdout.writeln('$name.json.gz ${bytes.length} bytes sha256 ${sha256.convert(bytes)}');
  }
}

/// quran.com's ids, the same texts qul exports
const _tafsirIds = {'ibn_kathir': 14, 'saadi': 91, 'tabari': 15, 'qurtubi': 90};

/// ayah key to text
Future<Map<String, String>> _apiTafsir(String name, int surahs) async {
  final texts = <String, String>{};
  for (var surah = 1; surah <= surahs; surah++) {
    final file = '${name}_${_three(surah)}.json';
    await _download(
      'https://api.quran.com/api/v4/tafsirs/${_tafsirIds[name]}/by_chapter/$surah?per_page=300',
      file,
    );
    final json = jsonDecode(File('$_cache/$file').readAsStringSync()) as Map<String, dynamic>;
    for (final row in json['tafsirs'] as List) {
      texts[row['verse_key'] as String] = row['text'] as String;
    }
  }
  return texts;
}

/// qul's html without tags and footnote markers
String _plain(String html) => html
    .replaceAll(RegExp(r'<sup[^>]*>.*?</sup>', dotAll: true), '')
    .replaceAll(RegExp(r'<br\s*/?>|</p>'), '\n')
    .replaceAll(RegExp('<[^>]+>'), '')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&quot;', '"')
    .replaceAll('&amp;', '&')
    .replaceAll(RegExp(r'[ \t]+'), ' ')
    .replaceAll(RegExp(r'\s*\n\s*'), '\n')
    .trim();

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
