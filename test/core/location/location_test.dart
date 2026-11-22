import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tz.initializeTimeZones);

  Location place({String? name, String? nameAr}) => Location(
    latitude: 21.4225,
    longitude: 39.8262,
    placeName: name,
    placeNameAr: nameAr,
    zone: tz.getLocation('Asia/Riyadh'),
    mode: LocationMode.auto,
  );

  test('arabic takes the arabic name, english the english one', () {
    final makkah = place(name: 'Makkah', nameAr: 'مكة المكرمة');
    expect(makkah.nameIn('ar'), 'مكة المكرمة');
    expect(makkah.nameIn('en'), 'Makkah');
  });

  test('arabic falls back to the english name, no name is empty', () {
    expect(place(name: 'Tromsø').nameIn('ar'), 'Tromsø');
    expect(place().nameIn('en'), '');
  });
}
