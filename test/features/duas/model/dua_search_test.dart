import 'package:better_muslim/features/duas/model/dua.dart';
import 'package:better_muslim/features/duas/model/dua_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<DuaCategory> categories;
  setUpAll(() async => categories = await loadDuas());

  Set<String> found(String query) => {
    for (final (_, category) in searchDuas(query, categories)) category.name.en,
  };

  test('normalize folds case, marks, tatweel, letter forms and digits', () {
    expect(normalize('تَوَكَّلْتُ'), 'توكلت');
    expect(normalize('اللـــه'), 'الله');
    expect(normalize('أإآٱ'), 'اااا');
    expect(normalize('ة ى'), 'ه ي');
    expect(normalize('٥٠٩٥'), '5095');
    expect(normalize('Allāhumma ḥ ʿala da‘wati'), 'allahumma h ala dawati');
    expect(normalize('ARABIC'), 'arabic');
  });

  test('finds by arabic without marks, source and category', () {
    expect(found('توكلت'), contains('Leaving the home'));
    expect(found('4/325'), contains('Leaving the home'));
    expect(found('٤/٣٢٥'), contains('Leaving the home'));
    expect(found('sleeping'), {'Before sleeping'});
    expect(found('النوم'), {'Before sleeping'});
  });

  test('every word counts, in any order', () {
    expect(found('الله توكلت'), found('توكلت الله'));
    expect(found('توكلت zzz'), isEmpty);
  });

  test('a dua shows once, under its first category', () {
    final ids = [for (final (dua, _) in searchDuas('الله', categories)) dua.id];
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('no match and an empty query give nothing', () {
    expect(found('zzz'), isEmpty);
    expect(found('  '), isEmpty);
  });
}
