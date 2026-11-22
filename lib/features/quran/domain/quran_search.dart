import 'package:better_muslim/core/location/place_list.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';

/// 4.27's chips
enum SearchScope { all, exact, arabic, translation, root }

enum JumpKind { surah, page, ayah }

/// where the jump card opens the reader, ayah only for an ayah
typedef QuranJump = ({JumpKind kind, int surah, int page, AyahKey? ayah});

typedef _Form = ({String text, List<int> starts});

/// one ayah as the search reads it, its words without the end marker
class SearchAyah {
  SearchAyah(this.key, this.words, String translation, {List<String> roots = const []})
    : translation = translation.split(' '),
      _roots = [for (final root in roots) _fold(root)],
      _arabic = _forms(words, _fold),
      _hamza = _forms(words, _foldHamza),
      _translation = _form(translation.toLowerCase().split(' '));

  final AyahKey key;
  final List<String> words;

  /// split on spaces, a matched word is washed whole
  final List<String> translation;

  /// the dagger alef dropped and as an alef, so الرحمن and الكتاب both find their ayahs
  final List<_Form> _arabic;

  /// the same with every hamza kept as ء, for a query that has one
  final List<_Form> _hamza;
  final _Form _translation;

  /// each word's root from the quranic arabic corpus, '' for a word without one
  final List<String> _roots;

  static List<_Form> _forms(List<String> words, String Function(String) fold) => [
    _form([for (final word in words) fold(word.replaceAll('\u0670', ''))]),
    _form([for (final word in words) fold(word.replaceAll('\u0670', 'ا'))]),
  ];

  static _Form _form(List<String> words) {
    final text = StringBuffer();
    final starts = <int>[];
    for (final word in words) {
      if (text.isNotEmpty) text.write(' ');
      starts.add(text.length);
      text.write(word);
    }
    return (text: '$text', starts: starts);
  }
}

/// a comma or a bracket ends a word as a space does, "Merciful," is a whole Merciful
bool _letter(String text, int at) => at >= 0 && at < text.length && _letters.hasMatch(text[at]);

final _letters = RegExp(r'[\p{L}\p{M}\p{N}]', unicode: true);

/// the words a match touches, a match inside a word washes the whole word. a word counts one
/// match however many it holds, so العالمين is one ال
/// [whole] keeps only a match that starts and ends on a word's edge, Exact's
({Set<int> words, int count}) _matched(List<_Form> forms, String query, {bool whole = false}) {
  final words = <int>{};
  final starts = <int>{};
  for (final form in forms) {
    var word = 0;
    for (var at = form.text.indexOf(query); at != -1; at = form.text.indexOf(query, at + 1)) {
      while (word + 1 < form.starts.length && form.starts[word + 1] <= at) {
        word++;
      }
      if (whole && (_letter(form.text, at - 1) || _letter(form.text, at + query.length))) {
        continue;
      }
      starts.add(word);
      for (var i = word; i < form.starts.length && form.starts[i] < at + query.length; i++) {
        words.add(i);
      }
    }
  }
  return (words: words, count: starts.length);
}

class SearchHit {
  const SearchHit(
    this.ayah, {
    required this.count,
    this.arabic = const {},
    this.translation = const {},
  });

  final SearchAyah ayah;

  /// how many times the query is in this ayah
  final int count;

  /// indexes into ayah.words and ayah.translation
  final Set<int> arabic;
  final Set<int> translation;
}

const _none = (words: <int>{}, count: 0);

/// no typo guessing, a guess would wash words that aren't what was typed
({QuranJump? jump, Map<int, List<SearchHit>> groups}) searchQuran(
  String query,
  List<SearchAyah> ayahs,
  QuranAssets assets, {
  SearchScope scope = SearchScope.all,
}) {
  final text = query.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (text.isEmpty) return (jump: null, groups: const {});
  final hamza = _foldHamza(text).contains('ء');
  final arabic = hamza ? _foldHamza(text) : _fold(text);
  final english = text.toLowerCase();
  final groups = <int, List<SearchHit>>{};
  if (scope == SearchScope.root) {
    /// "ر ح م" and "رحم" are the same root
    final root = arabic.replaceAll(' ', '');
    for (final ayah in ayahs) {
      final words = {
        for (final (i, word) in ayah._roots.indexed)
          if (word == root && i < ayah.words.length) i,
      };
      if (words.isEmpty) continue;
      (groups[ayah.key.surah] ??= []).add(SearchHit(ayah, count: words.length, arabic: words));
    }
    return (jump: null, groups: groups);
  }
  for (final ayah in ayahs) {
    final whole = scope == SearchScope.exact;
    final words = scope == SearchScope.translation
        ? _none
        : _matched(hamza ? ayah._hamza : ayah._arabic, arabic, whole: whole);
    final translation = scope == SearchScope.arabic
        ? _none
        : _matched([ayah._translation], english, whole: whole);
    if (words.words.isEmpty && translation.words.isEmpty) continue;
    (groups[ayah.key.surah] ??= []).add(
      SearchHit(
        ayah,
        count: words.count + translation.count,
        arabic: words.words,
        translation: translation.words,
      ),
    );
  }
  return (jump: _jump(text, assets), groups: groups);
}

/// "2:255", "p 50" or a surah's name in either language, out of range is no jump
QuranJump? _jump(String query, QuranAssets assets) {
  final text = query.toLowerCase().replaceAllMapped(
    RegExp('[٠-٩]'),
    (match) => '${match[0]!.codeUnitAt(0) - 0x0660}',
  );
  if (RegExp(r'^(\d+)\s*:\s*(\d+)$').firstMatch(text) case final match?) {
    final (surah, ayah) = (int.parse(match[1]!), int.parse(match[2]!));
    if (surah < 1 || surah > assets.surahs.length || ayah < 1) return null;
    if (ayah > assets.surah(surah).ayahs) return null;
    final key = AyahKey(surah, ayah);
    return (kind: JumpKind.ayah, surah: surah, page: assets.pageOf(key), ayah: key);
  }
  if (RegExp(r'^p(?:age)?\.?\s*(\d+)$').firstMatch(text) case final match?) {
    final page = int.parse(match[1]!);
    if (page < 1 || page > quranPageCount) return null;
    return (kind: JumpKind.page, surah: assets.pageInfo(page).start.surah, page: page, ayah: null);
  }
  final name = _nameKey(text.replaceFirst(RegExp(r'^(surah|sura|سورة|سوره)\s+'), ''));
  if (name.isEmpty) return null;
  for (final surah in assets.surahs) {
    final names = [
      _nameKey(surah.en),
      _nameKey(surah.en.replaceFirst(RegExp(r'^a[a-z]{1,2}-', caseSensitive: false), '')),
      _nameKey(surah.ar),
      _nameKey(surah.ar).replaceFirst(RegExp('^ال'), ''),
    ];
    if (names.contains(name)) {
      return (kind: JumpKind.surah, surah: surah.n, page: surah.page, ayah: null);
    }
  }
  return null;
}

/// letters only, so "Ar-Rahman", "ar rahman" and "arrahman" are one name
String _nameKey(String name) =>
    _fold(name.toLowerCase()).replaceAll(RegExp('[^a-z\u0621-\u064A]'), '');

/// the mushaf often writes a hamza with no seat (شَيۡـًٔا), so hamza goes on both sides. a seat
/// stays its letter, so مومن finds مؤمن
String _fold(String text) => normalizeArabic(text.replaceAll('ء', ''));

/// a typed hamza has to be there, so الرجاء never finds الرجال
String _foldHamza(String text) => normalizeArabic(text.replaceAll(RegExp('[ؤئ\u0654\u0655]'), 'ء'));
