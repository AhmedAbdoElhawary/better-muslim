import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/features/duas/model/dua.dart';
import 'package:better_muslim/features/duas/model/dua_search.dart';
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
      expect(category.chip, isNot(anyOf(DuaChip.all, DuaChip.saved)), reason: category.id);
      expect(category.duas, isNotEmpty, reason: category.id);
      for (final dua in category.duas) {
        expect(dua.source.en, isNotEmpty, reason: dua.id);
        expect(dua.source.ar, isNotEmpty, reason: dua.id);
        final audio = dua.audio;
        if (audio != null) expect(audio, startsWith('assets/duas/audio/'), reason: dua.id);
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

  test('the five categories in the 4.14 order from hisn al-muslim', () async {
    final categories = await loadDuas(await QuranAssets.load());
    expect(
      [for (final category in categories) (category.name.en, category.duas.length)],
      [
        ('Leaving the home', 2),
        ('Waking up', 3),
        ('Before sleeping', 9),
        ('Entering and leaving the mosque', 2),
        ('Before and after eating', 4),
        ('Rabbana duas from the Quran', 38),
      ],
    );
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
