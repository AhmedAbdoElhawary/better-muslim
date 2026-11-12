import 'dart:io';

import 'package:better_muslim/core/qibla/qibla_math.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('20 places within 0.5° and 0.5% of the WGS84 reference (SC-002)', () {
    final rows = File('test/fixtures/qibla_places.csv').readAsLinesSync().skip(1);
    expect(rows, hasLength(20));
    for (final row in rows) {
      final [name, latitude, longitude, bearing, km] = row.split(',');
      final lat = double.parse(latitude);
      final lon = double.parse(longitude);
      final expectedKm = double.parse(km);
      expect(qiblaBearing(lat, lon), closeTo(double.parse(bearing), .5), reason: name);
      expect(kaabaDistanceKm(lat, lon), closeTo(expectedKm, expectedKm * .005), reason: name);
    }
  });

  test('london shows 119° and 4,790 km', () {
    const lat = 51.5074;
    const lon = -0.1278;
    expect(qiblaBearing(lat, lon).round(), 119);
    final km = kaabaDistanceKm(lat, lon);
    expect(formatDistance(km, language: 'en', digits: Digits.eastern), (
      key: StringsManager.distanceKm,
      value: '4,790',
    ));
    expect(formatDistance(km, language: 'ar', digits: Digits.eastern), (
      key: StringsManager.distanceKm,
      value: '٤٬٧٩٠',
    ));
    expect(formatDistance(km, language: 'ar', digits: Digits.western).value, '4,790');
  });

  test('rounding picks the unit after rounding (FR-009)', () {
    String shown(double km) {
      final (:key, :value) = formatDistance(km, language: 'en', digits: Digits.western);
      return '$value ${key == StringsManager.distanceKm ? 'km' : 'm'}';
    }

    expect(shown(99.6), '100 km');
    expect(shown(100.4), '100 km');
    expect(shown(104.9), '100 km');
    expect(shown(105), '110 km');
    expect(shown(12.4), '12 km');
    expect(shown(.999), '1 km');
    expect(shown(.994), '990 m');
    expect(shown(.0004), '0 m');
  });

  test('the difference is the short way, never −180', () {
    expect(qiblaDiff(119, 105), 14);
    expect(qiblaDiff(105, 119), -14);
    expect(qiblaDiff(10, 350), 20);
    expect(qiblaDiff(350, 10), -20);
    expect(qiblaDiff(0, 180), 180);
    expect(qiblaDiff(180, 0), 180);
  });

  test('the turn never reads 0°', () {
    expect(turnDegrees(.3), 1);
    expect(turnDegrees(14.4), 14);
    expect(turnDegrees(-179.6), 180);
  });
}
