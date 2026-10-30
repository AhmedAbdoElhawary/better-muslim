import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/prayer_log/prayer_row_state.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_method.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  tz.initializeTimeZones();

  const minute = Duration(minutes: 1);

  DayTimes compute(
    DateTime date, {
    double latitude = 21.4225,
    double longitude = 39.8262,
    String zone = 'Asia/Riyadh',
    PrayerMethod method = PrayerMethod.ummAlQura,
    bool isRamadan = false,
  }) => DayTimes.compute(
    latitude: latitude,
    longitude: longitude,
    date: date,
    zone: tz.getLocation(zone),
    method: method,
    asrMethod: AsrMethod.standard,
    isRamadan: isRamadan,
  );

  RowState at(
    DayTimes day,
    DayTimes tomorrow,
    Prayer prayer,
    DateTime now, {
    bool logged = false,
    QadaEntry? qada,
  }) => rowState(
    prayer: prayer,
    time: day.timeOf(prayer),
    end: day.endOf(prayer, tomorrow),
    now: now,
    logged: logged,
    qada: qada,
    next: day.next(now, tomorrow),
  );

  final days = {
    'the scenario day in makkah': (DateTime(2026, 10, 15), compute),
    'a ramadan day with umm al-qura': (
      DateTime(2027, 2, 20),
      (DateTime date) => compute(date, isRamadan: true),
    ),
    'london on the dst end': (
      DateTime(2026, 10, 25),
      (DateTime date) => compute(
        date,
        latitude: 51.5074,
        longitude: -0.1278,
        zone: 'Europe/London',
        method: PrayerMethod.muslimWorldLeague,
      ),
    ),
    'after the zone moves from riyadh to istanbul': (
      DateTime(2026, 10, 15),
      (DateTime date) => compute(
        date,
        latitude: 41.0082,
        longitude: 28.9784,
        zone: 'Europe/Istanbul',
        method: PrayerMethod.turkiye,
      ),
    ),
  };

  for (final MapEntry(key: name, value: (date, times)) in days.entries) {
    group(name, () {
      final day = times(date);
      final tomorrow = times(DateTime(date.year, date.month, date.day + 1));

      for (final prayer in Prayer.values) {
        test('${prayer.name} a minute either side of its time and its end (SC-004)', () {
          final time = day.timeOf(prayer)!;
          final end = day.endOf(prayer, tomorrow)!;

          expect(at(day, tomorrow, prayer, time.subtract(minute)), (
            state: PrayerRowState.next,
            isOpen: false,
          ));
          expect(at(day, tomorrow, prayer, time.add(minute)), (
            state: PrayerRowState.mark,
            isOpen: true,
          ));
          expect(at(day, tomorrow, prayer, end.subtract(minute)), (
            state: PrayerRowState.mark,
            isOpen: true,
          ));
          expect(at(day, tomorrow, prayer, end.add(minute)), (
            state: PrayerRowState.addToQada,
            isOpen: false,
          ));
        });
      }

      test('before fajr every later prayer is later', () {
        final now = day.fajr!.subtract(minute);
        for (final prayer in Prayer.values.skip(1)) {
          expect(at(day, tomorrow, prayer, now).state, PrayerRowState.later, reason: prayer.name);
        }
      });
    });
  }

  final day = compute(DateTime(2026, 10, 15));
  final tomorrow = compute(DateTime(2026, 10, 16));
  QadaEntry qada({DateTime? madeUpAt}) =>
      QadaEntry(id: 1, prayer: Prayer.dhuhr, missedOn: DateTime(2026, 10, 15), madeUpAt: madeUpAt);

  test('logged beats every other state, and the open row stays open', () {
    final asr = day.asr!.add(minute);

    expect(at(day, tomorrow, Prayer.asr, asr, logged: true), (
      state: PrayerRowState.prayed,
      isOpen: true,
    ));
    expect(at(day, tomorrow, Prayer.dhuhr, asr, logged: true, qada: qada()), (
      state: PrayerRowState.prayed,
      isOpen: false,
    ));
  });

  test('a passed prayer in qada is in qada, and made up once its entry is', () {
    final now = day.asr!.add(minute);

    expect(at(day, tomorrow, Prayer.dhuhr, now, qada: qada()).state, PrayerRowState.inQada);
    expect(
      at(day, tomorrow, Prayer.dhuhr, now, qada: qada(madeUpAt: DateTime(2026, 10, 16))).state,
      PrayerRowState.madeUp,
    );
  });

  test('isha at 23:59 and 00:01 is still open to mark', () {
    final riyadh = tz.getLocation('Asia/Riyadh');

    for (final now in [
      tz.TZDateTime(riyadh, 2026, 10, 15, 23, 59),
      tz.TZDateTime(riyadh, 2026, 10, 16, 0, 1),
    ]) {
      expect(at(day, tomorrow, Prayer.isha, now), (state: PrayerRowState.mark, isOpen: true));
    }
  });

  test('a future day only gives next or later', () {
    final now = day.asr!.add(minute);
    final states = {
      for (final prayer in Prayer.values)
        rowState(
          prayer: prayer,
          time: tomorrow.timeOf(prayer),
          end: tomorrow.endOf(prayer, null),
          now: now,
          logged: false,
          next: day.next(now, tomorrow),
        ).state,
    };

    expect(states, {PrayerRowState.later});
  });

  test('next only for the exact instant of the next prayer', () {
    final now = day.asr!.add(minute);
    final maghrib = day.maghrib!;
    RowState maghribWith((Prayer, tz.TZDateTime) next) => rowState(
      prayer: Prayer.maghrib,
      time: maghrib,
      end: day.isha,
      now: now,
      logged: false,
      next: next,
    );

    expect(maghribWith((Prayer.maghrib, maghrib)).state, PrayerRowState.next);
    expect(maghribWith((Prayer.maghrib, maghrib.add(minute))).state, PrayerRowState.later);
    expect(maghribWith((Prayer.isha, maghrib)).state, PrayerRowState.later);
  });

  test('a prayer with no time that day is unavailable', () {
    expect(rowState(prayer: Prayer.isha, time: null, end: null, now: day.asr!, logged: true), (
      state: PrayerRowState.unavailable,
      isOpen: false,
    ));
  });
}
