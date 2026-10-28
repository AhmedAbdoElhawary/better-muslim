import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/features/home/model/verse_of_day.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final candidates = [for (var ayah = 1; ayah <= 4582; ayah++) AyahKey(2, ayah)];

  test('the same day gives the same ayah, whatever the time', () {
    expect(
      verseOfDay(DateTime(2026, 10, 15, 0, 1), candidates),
      verseOfDay(DateTime(2026, 10, 15, 23, 59), candidates),
    );
  });

  test('30 days in a row never repeat the day before', () {
    final days = [
      for (var day = 0; day < 30; day++) verseOfDay(DateTime(2026, 10, 1 + day), candidates),
    ];
    for (var i = 1; i < days.length; i++) {
      expect(days[i], isNot(days[i - 1]), reason: 'day ${i + 1}');
    }
  });

  test('always one of the candidates', () {
    final few = candidates.take(7).toList();
    for (var day = 0; day < 400; day++) {
      expect(few, contains(verseOfDay(DateTime(2026, 1, 1 + day), few)));
    }
  });

  test('no candidates throws', () {
    expect(() => verseOfDay(DateTime(2026, 10, 15), []), throwsA(anything));
  });
}
