import 'dart:io';

import 'package:better_muslim/core/qibla/declination.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final rows = File('test/fixtures/wmm2025_test_values.txt')
      .readAsLinesSync()
      .where((line) => line.trim().isNotEmpty && !line.startsWith('#'))
      .map((line) => line.trim().split(RegExp(r'\s+')).map(double.parse).toList());

  test('every NOAA WMM2025 test value within 0.01°', () {
    for (final [year, altitude, latitude, longitude, expected] in rows) {
      expect(
        declination(latitude, longitude, altitudeKm: altitude, decimalYear: year),
        closeTo(expected, .01),
        reason: '$year $altitude km $latitude, $longitude',
      );
    }
  });

  /// the model is valid until 2030, this fails a month early so a release never ships it stale
  test('WMM2025 is still valid, swap in WMM2030 from NOAA before 2030', () {
    expect(DateTime.now().isBefore(DateTime(2029, 12)), isTrue);
  });

  test('mid year', () {
    expect(decimalYear(DateTime(2027, 7, 2)), closeTo(2027.5, .01));
  });
}
