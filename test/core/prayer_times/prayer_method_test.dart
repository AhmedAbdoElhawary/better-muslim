import 'package:adhan_dart/adhan_dart.dart';
import 'package:better_muslim/core/prayer_times/prayer_method.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the method follows the country (FR-010)', () {
    const expected = {
      'SA': PrayerMethod.ummAlQura,
      'EG': PrayerMethod.egyptian,
      'AE': PrayerMethod.dubai,
      'QA': PrayerMethod.qatar,
      'KW': PrayerMethod.kuwait,
      'TR': PrayerMethod.turkiye,
      'SG': PrayerMethod.singapore,
      'MY': PrayerMethod.singapore,
      'ID': PrayerMethod.singapore,
      'PK': PrayerMethod.karachi,
      'IN': PrayerMethod.karachi,
      'BD': PrayerMethod.karachi,
      'IR': PrayerMethod.tehran,
      'US': PrayerMethod.northAmerica,
      'CA': PrayerMethod.northAmerica,
      'GB': PrayerMethod.muslimWorldLeague,
      'FR': PrayerMethod.muslimWorldLeague,
      'NG': PrayerMethod.muslimWorldLeague,
    };
    for (final MapEntry(key: country, value: method) in expected.entries) {
      expect(PrayerMethod.forCountry(country), method, reason: country);
    }
  });

  test('every method maps to its adhan preset', () {
    const presets = {
      PrayerMethod.ummAlQura: CalculationMethod.ummAlQura,
      PrayerMethod.egyptian: CalculationMethod.egyptian,
      PrayerMethod.dubai: CalculationMethod.dubai,
      PrayerMethod.qatar: CalculationMethod.qatar,
      PrayerMethod.kuwait: CalculationMethod.kuwait,
      PrayerMethod.turkiye: CalculationMethod.turkiye,
      PrayerMethod.singapore: CalculationMethod.singapore,
      PrayerMethod.karachi: CalculationMethod.karachi,
      PrayerMethod.tehran: CalculationMethod.tehran,
      PrayerMethod.northAmerica: CalculationMethod.northAmerica,
      PrayerMethod.muslimWorldLeague: CalculationMethod.muslimWorldLeague,
    };
    for (final method in PrayerMethod.values) {
      expect(method.parameters.method, presets[method], reason: method.name);
    }
  });

  test('asr is hanafi in pakistan, india and bangladesh, standard elsewhere (FR-011)', () {
    for (final country in ['PK', 'IN', 'BD']) {
      expect(AsrMethod.forCountry(country), AsrMethod.hanafi, reason: country);
    }
    for (final country in ['SA', 'EG', 'US']) {
      expect(AsrMethod.forCountry(country), AsrMethod.standard, reason: country);
    }
    expect(AsrMethod.hanafi.madhab, Madhab.hanafi);
    expect(AsrMethod.standard.madhab, Madhab.shafi);
  });
}
