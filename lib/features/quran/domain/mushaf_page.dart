import 'package:better_muslim/core/quran/ayah_key.dart';

enum MushafLineType { ayah, surahName, basmallah }

class MushafWord {
  const MushafWord({required this.key, required this.text, this.end = false});

  final AyahKey key;
  final String text;

  /// the ayah's end marker, its text is the ayah number
  final bool end;
}

class MushafLine {
  const MushafLine({required this.type, this.centered = false, this.surah, this.words = const []});

  final MushafLineType type;
  final bool centered;

  /// set on a surah name line
  final int? surah;
  final List<MushafWord> words;
}

/// one page of the madinah mushaf, always 15 lines (contracts/quran-assets.md)
class MushafPage {
  const MushafPage({required this.number, required this.lines});

  factory MushafPage.fromJson(int number, Map<String, dynamic> json) => MushafPage(
    number: number,
    lines: [
      for (final line in (json['lines'] as List).cast<Map<String, dynamic>>())
        switch (line['t']) {
          's' => MushafLine(type: MushafLineType.surahName, surah: line['surah'] as int),
          'b' => const MushafLine(type: MushafLineType.basmallah),
          _ => MushafLine(
            type: MushafLineType.ayah,
            centered: line['c'] == true,
            words: [
              for (final word in (line['w'] as List).cast<List<dynamic>>())
                MushafWord(
                  key: AyahKey(word[0] as int, word[1] as int),
                  text: word[2] as String,
                  end: word.length > 3 && word[3] == 1,
                ),
            ],
          ),
        },
    ],
  );

  final int number;
  final List<MushafLine> lines;

  /// pages 1 and 2 are the illuminated opening, laid out on 4.19's 58 pt lines
  bool get opening => number <= 2;

  AyahKey? get firstAyah => lines.expand((line) => line.words).firstOrNull?.key;

  bool has(AyahKey key) => lines.any((line) => line.words.any((word) => word.key == key));
}

/// an ayah's words from the pages it sits on, in reading order, an ayah can run onto the next page
String ayahText(Iterable<MushafPage> pages, AyahKey key) => [
  for (final page in pages)
    for (final line in page.lines)
      for (final word in line.words)
        if (word.key == key && !word.end) word.text,
].join(' ');

/// the mushaf is arabic in both languages
const mushafSurahWord = 'سُورَةُ';
const mushafJuzWord = 'الجزء';
const mushafBasmallah = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';
