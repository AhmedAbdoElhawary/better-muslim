import 'package:better_muslim/core/location/place_list.dart';
import 'package:better_muslim/features/duas/model/dua.dart';

const _marks = {
  'ā': 'a',
  'á': 'a',
  'ī': 'i',
  'í': 'i',
  'ū': 'u',
  'ú': 'u',
  'ḥ': 'h',
  'ṣ': 's',
  'ḍ': 'd',
  'ḏ': 'd',
  'ṭ': 't',
  'ṯ': 't',
  'ẓ': 'z',
  'ġ': 'g',
};

/// so "توكلت" finds تَوَكَّلْتُ, "tawakkaltu" finds tawakkaltu and "٥٠٩٥" finds 5095
String normalize(String text) =>
    normalizeArabic(text.toLowerCase())
        .replaceAllMapped(RegExp('[٠-٩]'), (match) => '${match[0]!.codeUnitAt(0) - 0x0660}')
        .replaceAllMapped(RegExp('[${_marks.keys.join()}]'), (match) => _marks[match[0]]!)
        .replaceAll(RegExp('[ʿʾ’‘\']'), '');

/// every word of the query in the dua's text, source or category names, in the content's order
List<(Dua, DuaCategory)> searchDuas(String query, List<DuaCategory> categories) {
  final words = normalize(query).split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
  if (words.isEmpty) return const [];
  final names = <String, List<String>>{};
  for (final category in categories) {
    for (final dua in category.duas) {
      (names[dua.id] ??= []).addAll([category.name.en, category.name.ar]);
    }
  }
  final seen = <String>{};
  return [
    for (final category in categories)
      for (final dua in category.duas)
        if (seen.add(dua.id) &&
            words.every(
              normalize(
                [
                  dua.arabic,
                  dua.transliteration,
                  dua.translation,
                  dua.source.en,
                  dua.source.ar,
                  ...names[dua.id]!,
                ].join('\n'),
              ).contains,
            ))
          (dua, category),
  ];
}
