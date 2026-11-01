import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/features/duas/model/dua.dart';
import 'package:better_muslim/features/duas/model/dua_search.dart';
import 'package:better_muslim/features/duas/model/duas_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the shipped duas follow contracts/content-files.md', () async {
    final categories = await loadDuas(await QuranAssets.load());
    final categoryIds = <String>{};
    for (final category in categories) {
      expect(categoryIds.add(category.id), isTrue, reason: category.id);
      expect(category.name.en, isNotEmpty);
      expect(category.name.ar, isNotEmpty);
      expect(category.chip, isNot(DuaChip.saved), reason: category.id);
      expect(category.duas, isNotEmpty, reason: category.id);
      for (final dua in category.duas) {
        expect(dua.source.en, isNotEmpty, reason: dua.id);
        expect(dua.source.ar, isNotEmpty, reason: dua.id);
        if (dua.quran && dua.ayahs.isNotEmpty) continue;
        expect(dua.audio, endsWith('.mp3'), reason: dua.id);
        expect(dua.sha256, hasLength(64), reason: dua.id);
      }
    }
  });

  test('one id is one dua: a dua in two categories has the same text in both', () async {
    final byId = <String, String>{};
    for (final category in await loadDuas(await QuranAssets.load())) {
      for (final dua in category.duas) {
        expect(byId.putIfAbsent(dua.id, () => dua.arabic), dua.arabic, reason: dua.id);
      }
    }
  });

  test('the 4.14 five first with their ids, then every other hisn al-muslim chapter', () async {
    final categories = await loadDuas(await QuranAssets.load());
    expect(
      [for (final category in categories.take(5)) (category.name.en, category.duas.length)],
      [
        ('Leaving the home', 2),
        ('Waking up', 4),
        ('Before sleeping', 13),
        ('Entering and leaving the mosque', 3),
        ('Before and after eating', 4),
      ],
    );
    expect(categories.last.chip, DuaChip.quranic);
    expect(categories.where((category) => category.id.startsWith('hisn-')), hasLength(123));
    final ids = {for (final category in categories) ...category.duas.map((dua) => dua.id)};
    for (var n = 1; n <= 20; n++) {
      expect(ids, contains('d${'$n'.padLeft(3, '0')}'), reason: 'a saved dua keeps its id');
    }
    final eating = categories.singleWhere((category) => category.id == 'eating');
    expect(eating.chip, DuaChip.food);
  });

  test('every chip has duas', () async {
    final categories = await loadDuas(await QuranAssets.load());
    for (final chip in DuaChip.values.where((chip) => chip != DuaChip.saved)) {
      expect(duasViewFor(chip, categories).card, isNotNull, reason: chip.name);
    }
  });

  test('every quranic dua is whole ayahs that say rabbana, with sahih international', () async {
    final quran = await QuranAssets.load();
    final category = (await loadDuas(quran)).singleWhere((c) => c.chip == DuaChip.quranic);
    for (final dua in category.duas) {
      expect(dua.quran, isTrue, reason: dua.id);
      expect(dua.listenable, isTrue, reason: dua.id);
      expect(normalize(dua.arabic), contains('ربنا'), reason: dua.id);
      expect(dua.translation, contains('Lord'), reason: dua.id);
      final key = dua.ayahs.first;
      expect(dua.source.en, startsWith('${quran.surah(key.surah).en} ${key.surah}:${key.ayah}'));
    }
    final range = category.duas.singleWhere((dua) => dua.id == 'q10-85-86');
    expect(range.ayahs, [const AyahKey(10, 85), const AyahKey(10, 86)]);
    expect(range.source.ar, 'يونس ١٠:٨٥-٨٦');
  });
}
