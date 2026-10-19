import 'dart:convert';
import 'dart:io';

import 'package:better_muslim/features/duas/model/dua.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the shipped duas follow contracts/content-files.md', () async {
    final categories = await loadDuas();
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
    for (final category in await loadDuas()) {
      for (final dua in category.duas) {
        expect(byId.putIfAbsent(dua.id, () => dua.arabic), dua.arabic, reason: dua.id);
      }
    }
  });

  test('the five sample categories in the 4.14 order, each dua marked for my dataset', () async {
    final categories = await loadDuas();
    expect(
      [for (final category in categories) (category.name.en, category.duas.length)],
      [
        ('Leaving the home', 1),
        ('Waking up', 1),
        ('Before sleeping', 3),
        ('Entering and leaving the mosque', 2),
        ('Before and after eating', 2),
      ],
    );

    final json = jsonDecode(File('assets/duas/duas.json').readAsStringSync()) as Map;
    for (final category in json['categories'] as List) {
      for (final dua in (category as Map)['duas'] as List) {
        expect((dua as Map)['note'], contains('TODO(ahmed)'), reason: '${dua['id']}');
      }
    }
  });
}
