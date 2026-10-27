import 'dart:convert';
import 'dart:io';

import 'package:better_muslim/core/hijri/hijri_date.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_method.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  tz.initializeTimeZones();
  final riyadh = tz.getLocation('Asia/Riyadh');

  DayTimes makkah(DateTime date, {bool isRamadan = false}) => DayTimes.compute(
    latitude: 21.4266,
    longitude: 39.8256,
    date: date,
    zone: riyadh,
    method: PrayerMethod.ummAlQura,
    asrMethod: AsrMethod.standard,
    isRamadan: isRamadan,
  );

  String hhmm(tz.TZDateTime? time) => time == null
      ? '--:--'
      : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  List<String> six(DayTimes times) => [
    times.fajr,
    times.sunrise,
    times.dhuhr,
    times.asr,
    times.maghrib,
    times.isha,
  ].map(hhmm).toList();

  test('makkah on the scenario day matches the real calculation (R10)', () {
    expect(six(makkah(DateTime(2026, 10, 15))), [
      '05:00',
      '06:16',
      '12:06',
      '15:27',
      '17:56',
      '19:26',
    ]);
  });

  test('the last third starts a third of maghrib to fajr before fajr (FR-032)', () {
    final today = makkah(DateTime(2026, 10, 15));
    final fajr = makkah(DateTime(2026, 10, 16)).fajr!;

    expect(today.lastThird(fajr), fajr.subtract(fajr.difference(today.maghrib!) ~/ 3));
    expect(hhmm(today.lastThird(fajr)), '01:18');
    expect(today.lastThird(null), isNull);
  });

  group('SC-002 fixtures are within 1 minute', () {
    final files = Directory('test/fixtures/prayer_times').listSync().whereType<File>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      final fixture = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      for (final day in (fixture['days'] as List).cast<Map<String, dynamic>>()) {
        final date = DateTime.parse(day['date'] as String);

        final gaps = (day['gaps'] as Map<String, dynamic>? ?? {}).cast<String, String>();
        final name = '${fixture['city']} ${day['date']} ${day['source']}';
        test(name, () {
          final times = DayTimes.compute(
            latitude: fixture['latitude'] as double,
            longitude: fixture['longitude'] as double,
            date: date,
            zone: tz.getLocation(fixture['timeZone'] as String),
            method: PrayerMethod.values.byName(fixture['method'] as String),
            asrMethod: AsrMethod.values.byName(fixture['asrMethod'] as String),
            isRamadan: HijriDate.of(date, 0).month == 9,
          );
          const names = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'];
          final actual = six(times);
          final off = [
            for (var i = 0; i < names.length; i++)
              if (!gaps.containsKey(names[i]) &&
                  (_minutes(actual[i]) - _minutes(day[names[i]] as String)).abs() > 1)
                '${names[i]} ${actual[i]} against ${day[names[i]]}',
          ];
          expect(off, isEmpty);
        });

        /// a gap the fixture explains shows up in every run as a skip with its reason
        for (final MapEntry(key: time, value: reason) in gaps.entries) {
          test('$name $time', () {}, skip: 'known gap: $reason');
        }
      }
    }
  });

  test('umm al-qura isha is maghrib + 120 in ramadan, + 90 outside it (FR-014)', () {
    final ramadanDay = DateTime(2027, 2, 20);
    expect(HijriDate.of(ramadanDay, 0).month, 9);
    final ramadan = makkah(ramadanDay, isRamadan: true);
    final normal = makkah(DateTime(2026, 10, 15));

    expect(ramadan.isha!.difference(ramadan.maghrib!).inMinutes, 120);
    expect(normal.isha!.difference(normal.maghrib!).inMinutes, 90);
  });

  test('above the polar circle, times adhan puts weeks away are not available', () {
    final date = DateTime(2026, 6, 21);
    final tromso = DayTimes.compute(
      latitude: 69.6489,
      longitude: 18.9551,
      date: date,
      zone: tz.getLocation('Europe/Oslo'),
      method: PrayerMethod.muslimWorldLeague,
      asrMethod: AsrMethod.standard,
      isRamadan: false,
    );

    expect(tromso.sunrise, isNull);
    expect(tromso.maghrib, isNull);
    for (final time in [tromso.fajr, tromso.dhuhr, tromso.asr, tromso.isha].nonNulls) {
      expect([time.year, time.month, time.day], [2026, 6, 21]);
    }
  });

  test('samoa, whose zone is a day off its longitude, still gets the asked day', () {
    final apia = DayTimes.compute(
      latitude: -13.8333,
      longitude: -171.7667,
      date: DateTime(2026, 10, 15),
      zone: tz.getLocation('Pacific/Apia'),
      method: PrayerMethod.muslimWorldLeague,
      asrMethod: AsrMethod.standard,
      isRamadan: false,
    );

    expect(six(apia), everyElement(isNot('--:--')));
    expect([apia.dhuhr!.day, apia.dhuhr!.hour], [15, 12]);
  });

  test('an isha after local midnight is still that day\'s isha', () {
    /// mountain view seen from a phone on riyadh time, asr to isha land after midnight there
    final times = DayTimes.compute(
      latitude: 37.422,
      longitude: -122.084,
      date: DateTime(2026, 10, 16),
      zone: riyadh,
      method: PrayerMethod.northAmerica,
      asrMethod: AsrMethod.standard,
      isRamadan: false,
    );

    expect(six(times), everyElement(isNot('--:--')));
    expect(times.isha!.day, 17);
  });

  test('london in june still has fajr and isha (FR-013)', () {
    final london = DayTimes.compute(
      latitude: 51.5085,
      longitude: -0.1257,
      date: DateTime(2026, 6, 21),
      zone: tz.getLocation('Europe/London'),
      method: PrayerMethod.muslimWorldLeague,
      asrMethod: AsrMethod.standard,
      isRamadan: false,
    );

    expect(london.fajr, isNotNull);
    expect(london.isha, isNotNull);
  });

  group('period and next', () {
    final today = makkah(DateTime(2026, 10, 15));
    final tomorrow = makkah(DateTime(2026, 10, 16));
    tz.TZDateTime at(int hour, int minute, [int day = 15]) =>
        tz.TZDateTime(riyadh, 2026, 10, day, hour, minute);

    test('fajr until sunrise, duha until dhuhr, isha before fajr (FR-015a)', () {
      expect(today.periodAt(at(4, 30)), Period.isha);
      expect(today.periodAt(at(5, 10)), Period.fajr);
      expect(today.periodAt(at(6, 30)), Period.duha);
      expect(today.periodAt(at(12, 10)), Period.dhuhr);
      expect(today.periodAt(at(16, 32)), Period.asr);
      expect(today.periodAt(at(18, 0)), Period.maghrib);
      expect(today.periodAt(at(23, 0)), Period.isha);
    });

    test('after fajr the next is dhuhr, after isha it is tomorrow\'s fajr (FR-015)', () {
      expect(today.next(at(5, 10), tomorrow), (Prayer.dhuhr, today.dhuhr));
      expect(today.next(at(16, 32), tomorrow), (Prayer.maghrib, today.maghrib));
      expect(today.next(at(23, 0), tomorrow), (Prayer.fajr, tomorrow.fajr));
    });
  });
}

int _minutes(String hhmm) {
  final [hours, minutes] = hhmm.split(':').map(int.parse).toList();
  return hours * 60 + minutes;
}
