import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/features/quran/data/search_text.dart';
import 'package:better_muslim/features/quran/domain/quran_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late QuranAssets assets;
  late List<SearchAyah> ayahs;
  setUpAll(() async {
    assets = await QuranAssets.load();
    ayahs = await loadSearchAyahs();
  });

  QuranJump? jump(String query) => searchQuran(query, ayahs, assets).jump;

  List<AyahKey> found(String query, {SearchScope scope = SearchScope.all}) => [
    for (final hits in searchQuran(query, ayahs, assets, scope: scope).groups.values)
      for (final hit in hits) hit.ayah.key,
  ];

  /// the indexes of the words washed in one ayah
  List<int> washed(String query, AyahKey key) {
    final hit = searchQuran(
      query,
      ayahs,
      assets,
    ).groups[key.surah]!.firstWhere((hit) => hit.ayah.key == key);
    return hit.arabic.toList()..sort();
  }

  test('root finds every word of that root, spaced or not, and washes only them', () {
    final hits = searchQuran('رحم', ayahs, assets, scope: SearchScope.root).groups;
    final first = hits[1]!.first;
    expect(first.ayah.key, const AyahKey(1, 1));
    expect(first.arabic.toList()..sort(), [2, 3]);
    expect(found('ر ح م', scope: SearchScope.root), found('رحم', scope: SearchScope.root));
    expect(found('رحم', scope: SearchScope.root), hasLength(greaterThan(300)));
    expect(found('أله', scope: SearchScope.root), contains(const AyahKey(112, 1)));
    expect(found('zzz', scope: SearchScope.root), isEmpty);
  });

  test('every ayah is read, without its number', () {
    expect(ayahs, hasLength(6236));
    expect(ayahs.first.words, hasLength(4));
    expect(ayahs.last.key, const AyahKey(114, 6));
  });

  test('"2:255" jumps to the ayah, out of range gives no card', () {
    expect(jump('2:255'), (
      kind: JumpKind.ayah,
      surah: 2,
      page: assets.pageOf(const AyahKey(2, 255)),
      ayah: const AyahKey(2, 255),
    ));
    expect(jump('٢:٢٥٥')?.ayah, const AyahKey(2, 255));
    expect(jump('2:300'), isNull);
    expect(jump('115:1'), isNull);
  });

  test('"p 50" jumps to the page, out of range gives no card', () {
    expect(jump('p 50'), (kind: JumpKind.page, surah: 3, page: 50, ayah: null));
    expect(jump('P50')?.page, 50);
    expect(jump('page 604')?.page, 604);
    expect(jump('p 700'), isNull);
    expect(jump('p 0'), isNull);
  });

  test('a surah name in either language jumps to the surah', () {
    const rahman = (kind: JumpKind.surah, surah: 55, page: 531, ayah: null);
    expect(jump('الرحمن'), rahman);
    expect(jump('الرَّحْمَٰن'), rahman);
    expect(jump('Ar-Rahman'), rahman);
    expect(jump('rahman'), rahman);
    expect(jump('surah ar rahman'), rahman);
    expect(jump('baqarah')?.surah, 2);
    expect(jump('البقرة')?.surah, 2);
    expect(jump('آل عمران')?.surah, 3);
    expect(jump('عمران')?.surah, 3);
    expect(jump('سورة الكهف')?.surah, 18);
    expect(jump('mercy'), isNull);

    /// only a whole name, the start of an ayah's word is no surah
    expect(jump('baqara'), isNull);
    expect(jump('الم'), isNull);
    expect(jump('رحم'), isNull);
  });

  test('arabic is found without diacritics, dagger alef either way', () {
    expect(
      found('بسم الله الرحمن الرحيم'),
      containsAll([const AyahKey(1, 1), const AyahKey(27, 30)]),
    );
    expect(found('الرحمن'), contains(const AyahKey(1, 3)));
    expect(found('الكتاب'), contains(const AyahKey(2, 2)));
    expect(
      found('اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ'),
      contains(const AyahKey(2, 255)),
    );
  });

  test('every hamza and alef form folds', () {
    /// أ إ آ ٱ typed with or without the hamza
    expect(found('انزل'), found('أنزل'));
    expect(found('اياك'), contains(const AyahKey(1, 5)));
    expect(found('إياك'), contains(const AyahKey(1, 5)));
    expect(found('آمنوا'), contains(const AyahKey(2, 9)));
    expect(found('الحمد'), contains(const AyahKey(1, 2)));

    /// ؤ ئ ء and the seatless hamza of شَيۡـًٔا
    expect(found('المؤمنون'), contains(const AyahKey(23, 1)));
    expect(found('شيئا'), contains(const AyahKey(2, 48)));
    expect(found('السماء'), contains(const AyahKey(2, 19)));
  });

  test('the matched word is washed whole, every time it is in the ayah', () {
    expect(washed('رحم', const AyahKey(1, 1)), [2]);
    expect(washed('لرح', const AyahKey(1, 1)), [2, 3]);
    expect(washed('الله الرحمن', const AyahKey(1, 1)), [1, 2]);
  });

  test('hits are grouped by surah in mushaf order', () {
    final groups = searchQuran('الرحمن', ayahs, assets).groups;
    expect(groups.keys.first, 1);
    expect(groups[1]!.map((hit) => hit.ayah.key), [const AyahKey(1, 1), const AyahKey(1, 3)]);
    expect(groups.keys.toList(), [...groups.keys]..sort());
  });

  test('translation is searched case-insensitive, its matched words washed', () {
    expect(found('MERCIFUL', scope: SearchScope.translation), contains(const AyahKey(1, 1)));
    expect(found('the entirely merciful', scope: SearchScope.translation).take(2), [
      const AyahKey(1, 1),
      const AyahKey(1, 3),
    ]);
    final hit = searchQuran(
      'merciful',
      ayahs,
      assets,
      scope: SearchScope.translation,
    ).groups[1]!.first;
    expect(
      [for (final i in hit.translation.toList()..sort()) hit.ayah.translation[i]],
      ['Merciful,', 'Merciful.'],
    );
    expect(hit.arabic, isEmpty);
  });

  test('each chip searches only its own text', () {
    expect(found('merciful', scope: SearchScope.arabic), isEmpty);
    expect(found('الرحمن', scope: SearchScope.translation), isEmpty);
    expect(found('الرحمن', scope: SearchScope.arabic), found('الرحمن'));
  });

  test('all searches both, an ayah found in both is listed once', () {
    expect(found('merciful'), found('merciful', scope: SearchScope.translation));
    for (final query in ['الله', 'allah', 'a']) {
      final keys = found(query);
      expect(keys.toSet(), hasLength(keys.length), reason: query);
    }

    expect(found('الله'), found('الله', scope: SearchScope.arabic));
    expect(found('allah'), found('allah', scope: SearchScope.translation));
  });

  test('no typo guessing, and an empty query gives nothing', () {
    expect(found('الرحمنن'), isEmpty);
    expect(searchQuran('  ', ayahs, assets).groups, isEmpty);
    expect(searchQuran('  ', ayahs, assets).jump, isNull);
  });
}
