import 'package:better_muslim/core/location/place_list.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PlaceList places;

  setUpAll(() async => places = await PlaceList.load());

  group('nearest', () {
    test('the asset loads, biggest place first', () {
      expect(places.length, greaterThan(150000));
      expect(places[0].population, greaterThanOrEqualTo(places[1].population));
    });

    test('the kaaba is named makkah, with its arabic name', () {
      final place = places.nearest(21.4225, 39.8262);

      expect(place.name, 'Makkah');
      expect(place.nameAr, 'مكة المكرمة');
      expect(place.countryCode, 'SA');
      expect(place.timeZone, 'Asia/Riyadh');
    });

    test('a point at sea is named by the nearest listed place', () {
      expect(places.nearest(21.55, 38.9).name, 'Jeddah');
    });
  });

  group('search (FR-005)', () {
    test('tanta in english or arabic puts tanta, egypt first', () {
      for (final query in ['tanta', 'Tanta', 'طنطا']) {
        final first = places.search(query).first;
        expect((first.name, first.countryCode), ('Tanta', 'EG'), reason: query);
      }
    });

    test('arabic with or without harakat and alef or taa forms finds the same place', () {
      for (final query in ['مكة', 'مكه', 'مَكَّة']) {
        expect(places.search(query).map((place) => place.name), contains('Makkah'), reason: query);
      }
      for (final query in ['أسيوط', 'اسيوط']) {
        expect(places.search(query).first.name, 'Assiut', reason: query);
      }
    });

    test('alexandria lists the egyptian one first, region and country tell them apart', () {
      final results = places.search('alexandria');

      expect((results[0].countryCode, results[0].region), ('EG', 'Alexandria'));
      expect((results[1].countryCode, results[1].region), ('US', 'Virginia'));
      expect(results[1].country, 'United States');
    });

    test('at most 30 results, biggest first', () {
      final results = places.search('a');

      expect(results, hasLength(30));
      for (var i = 1; i < results.length; i++) {
        expect(results[i - 1].population, greaterThanOrEqualTo(results[i].population));
      }
      expect(places.search('a', limit: 5), hasLength(5));
      expect(places.search('  '), isEmpty);
    });

    test('a search on the full list takes under 100 ms on average (SC-004)', () {
      const queries = ['t', 'ta', 'tan', 'tant', 'tanta', 'م', 'مك', 'مكة', 'zzzz', 'قرية'];
      final watch = Stopwatch()..start();
      for (var i = 0; i < 50; i++) {
        places.search(queries[i % queries.length]);
      }
      expect(watch.elapsedMilliseconds / 50, lessThan(100));
    });
  });
}
