import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';

class VerseOfDay {
  const VerseOfDay({
    required this.key,
    required this.surah,
    required this.text,
    required this.translation,
  });

  final AyahKey key;
  final QuranSurah surah;
  final String text;
  final String translation;
}

/// knuth's multiplier, so days next to each other land far apart in the list
const _spread = 2654435761;
const _wrap = 0x100000000;

/// the same ayah all day on every phone, a new one each day
AyahKey verseOfDay(DateTime date, List<AyahKey> candidates) {
  final day = date.year * 10000 + date.month * 100 + date.day;
  return candidates[day * _spread % _wrap % candidates.length];
}
