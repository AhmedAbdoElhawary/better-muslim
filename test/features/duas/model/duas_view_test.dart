import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/features/duas/model/dua.dart';
import 'package:better_muslim/features/duas/model/duas_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<DuaCategory> categories;
  setUpAll(() async => categories = await loadDuas(await QuranAssets.load()));

  /// the card's category first, then the rows
  List<String?> view(DuaChip chip) {
    final (:card, :cardCategory, :rows) = duasViewFor(chip, categories);
    return [if (card != null) cardCategory!.name.en, for (final row in rows) row.name.en];
  }

  test('all: the 4.14 card, its category\'s row and the four rows', () {
    expect(view(DuaChip.all), [
      'Leaving the home',
      'Leaving the home',
      'Waking up',
      'Before sleeping',
      'Entering and leaving the mosque',
      'Before and after eating',
      'Rabbana duas from the Quran',
    ]);
  });

  test('home: its first dua on the card, the other home categories as rows', () {
    expect(view(DuaChip.home), [
      'Leaving the home',
      'Leaving the home',
      'Entering and leaving the mosque',
      'Before and after eating',
    ]);
  });

  test('a first category with more than the card\'s dua keeps its row', () {
    expect(view(DuaChip.sleep), ['Before sleeping', 'Before sleeping']);
  });

  test('travel has nothing yet', () {
    expect(view(DuaChip.travel), isEmpty);
    expect(duasViewFor(DuaChip.travel, categories).card, isNull);
  });
}
