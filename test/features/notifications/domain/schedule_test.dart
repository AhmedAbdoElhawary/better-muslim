import 'package:better_muslim/core/azkar/azkar_window.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_method.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/notifications/domain/alert.dart';
import 'package:better_muslim/features/notifications/domain/schedule.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

  const sounds = {
    Prayer.fajr: PrayerSound.adhan,
    Prayer.dhuhr: PrayerSound.tone,
    Prayer.asr: PrayerSound.tone,
    Prayer.maghrib: PrayerSound.adhan,
    Prayer.isha: PrayerSound.silent,
  };

  List<DayTimes> daysFrom(
    DateTime first, {
    double latitude = 21.4225,
    double longitude = 39.8262,
    String zone = 'Asia/Riyadh',
  }) => [
    for (var i = 0; i < scheduleDays; i++)
      DayTimes.compute(
        latitude: latitude,
        longitude: longitude,
        date: DateTime(first.year, first.month, first.day + i),
        zone: getLocation(zone),
        method: PrayerMethod.ummAlQura,
        asrMethod: AsrMethod.standard,
        isRamadan: false,
      ),
  ];

  TZDateTime makkah(int day, int hour, int minute) =>
      TZDateTime(getLocation('Asia/Riyadh'), 2026, 10, day, hour, minute);

  test('6 days from 15 oct 10:00 give 29 adhans, today\'s fajr is past', () {
    final alerts = buildSchedule(
      now: makkah(15, 10, 0),
      days: daysFrom(DateTime(2026, 10, 15)),
      sounds: sounds,
      reminderMinutes: 0,
    );

    expect(alerts, hasLength(29));
    expect(alerts.first.prayer, Prayer.dhuhr);
    expect(alerts.every((alert) => alert.kind == AlertKind.adhan), isTrue);
    expect(
      alerts.where((alert) => alert.prayer == Prayer.isha).map((alert) => alert.sound).toSet(),
      {PrayerSound.silent},
    );
    expect(alerts.map((alert) => alert.id).toSet(), hasLength(29));
  });

  test('nothing in the past', () {
    final now = makkah(15, 16, 32);
    final alerts = buildSchedule(
      now: now,
      days: daysFrom(DateTime(2026, 10, 15)),
      sounds: sounds,
      reminderMinutes: 0,
    );

    expect(alerts.every((alert) => alert.at.isAfter(now)), isTrue);
  });

  test('nothing for a prayer with no time that day (tromsø, 21 jun)', () {
    final days = daysFrom(
      DateTime(2026, 6, 21),
      latitude: 69.6489,
      longitude: 18.9551,
      zone: 'Europe/Oslo',
    );
    final alerts = buildSchedule(
      now: TZDateTime(getLocation('Europe/Oslo'), 2026, 6, 21, 0, 1),
      days: days,
      sounds: sounds,
      reminderMinutes: 0,
    );

    final withTime = [
      for (final day in days)
        for (final prayer in Prayer.values) ?day.timeOf(prayer),
    ];
    expect(alerts, hasLength(withTime.length));
    expect(alerts.where((alert) => alert.prayer == Prayer.maghrib), isEmpty);
  });

  test('at 00:30 the first day is yesterday\'s prayer day, so the next fajr is today\'s', () {
    final alerts = buildSchedule(
      now: makkah(16, 0, 30),
      days: daysFrom(DateTime(2026, 10, 15)),
      sounds: sounds,
      reminderMinutes: 0,
    );

    expect(alerts.first.prayer, Prayer.fajr);
    expect(alerts.first.day, DateTime(2026, 10, 16));
    expect(alerts.where((alert) => alert.day == DateTime(2026, 10, 15)), isEmpty);
  });

  test('never more than 30 adhans, even as fajr gets earlier each day', () {
    final alerts = buildSchedule(
      now: makkah(15, 0, 1),
      days: daysFrom(DateTime(2026, 10, 15)),
      sounds: sounds,
      reminderMinutes: 0,
    );

    expect(alerts, hasLength(30));
  });

  group('reminders', () {
    test('25 minutes, the slider\'s new step, comes 25 minutes before', () {
      final alerts = buildSchedule(
        now: makkah(15, 0, 1),
        days: daysFrom(DateTime(2026, 10, 15)),
        sounds: sounds,
        reminderMinutes: 25,
      );
      final reminder = alerts.firstWhere((alert) => alert.kind == AlertKind.reminder);
      expect(reminder.prayerTime.difference(reminder.at), const Duration(minutes: 25));
    });

    test('come the minutes before each of the five, whatever its sound', () {
      final alerts = buildSchedule(
        now: makkah(15, 0, 1),
        days: daysFrom(DateTime(2026, 10, 15)),
        sounds: sounds,
        reminderMinutes: 10,
      );

      final reminders = alerts.where((alert) => alert.kind == AlertKind.reminder).toList();
      expect(reminders, hasLength(30));
      expect(alerts, hasLength(60));
      for (final reminder in reminders) {
        final adhan = alerts.singleWhere(
          (alert) =>
              alert.kind == AlertKind.adhan &&
              alert.day == reminder.day &&
              alert.prayer == reminder.prayer,
        );
        expect(adhan.at.difference(reminder.at), const Duration(minutes: 10));
        expect(reminder.prayerTime, adhan.at);
      }
      expect(alerts.map((alert) => alert.id).toSet(), hasLength(60));
    });

    test('none at 0', () {
      final alerts = buildSchedule(
        now: makkah(15, 0, 1),
        days: daysFrom(DateTime(2026, 10, 15)),
        sounds: sounds,
        reminderMinutes: 0,
      );

      expect(alerts.where((alert) => alert.kind == AlertKind.reminder), isEmpty);
    });

    test('a reminder already past is skipped while its adhan stays', () {
      final asr = daysFrom(DateTime(2026, 10, 15)).first.asr!;
      final alerts = buildSchedule(
        now: asr.subtract(const Duration(minutes: 5)),
        days: daysFrom(DateTime(2026, 10, 15)),
        sounds: sounds,
        reminderMinutes: 10,
      );

      final first = alerts.first;
      expect([first.prayer, first.kind], [Prayer.asr, AlertKind.adhan]);
    });
  });

  group('azkar nudges (US6)', () {
    test('at 16:32 the next 3: tomorrow\'s morning and evening, the day after\'s morning', () {
      final days = daysFrom(DateTime(2026, 10, 15));
      final nudges = buildNudges(now: makkah(15, 16, 32), days: days, done: const {});

      expect(
        [for (final nudge in nudges) (nudge.day.day, nudge.prayer)],
        [(16, Prayer.fajr), (16, Prayer.asr), (17, Prayer.fajr)],
      );
      expect(nudges.first.at, days[1].fajr!.add(const Duration(minutes: 20)));
      expect(nudges.every((nudge) => nudge.kind == AlertKind.azkar), isTrue);
      expect(nudges.every((nudge) => nudge.sound == PrayerSound.silent), isTrue);
    });

    test('before asr + 20 today\'s evening nudge comes first', () {
      final days = daysFrom(DateTime(2026, 10, 15));
      final nudges = buildNudges(now: makkah(15, 15, 30), days: days, done: const {});

      expect(nudges.first.day, DateTime(2026, 10, 15));
      expect(nudges.first.prayer, Prayer.asr);
    });

    test('a nudge lasts until the next one, whether that one shows or not', () {
      final days = daysFrom(DateTime(2026, 10, 15));
      final nudges = buildNudges(
        now: makkah(15, 15, 30),
        days: days,
        done: {(AzkarSet.morning, DateTime(2026, 10, 16))},
      );

      expect(nudges.first.lasts, days[1].fajr!.difference(days[0].asr!));
    });

    test('a done window gets no nudge', () {
      final nudges = buildNudges(
        now: makkah(15, 15, 30),
        days: daysFrom(DateTime(2026, 10, 15)),
        done: {(AzkarSet.evening, DateTime(2026, 10, 15))},
      );

      expect(nudges.first.day, DateTime(2026, 10, 16));
      expect(nudges.first.prayer, Prayer.fajr);
    });

    test('a day with no fajr or asr time has no nudge for it', () {
      final day = daysFrom(DateTime(2026, 10, 16)).first;
      final polar = DayTimes(
        date: day.date,
        fajr: null,
        sunrise: day.sunrise,
        dhuhr: day.dhuhr,
        asr: null,
        maghrib: day.maghrib,
        isha: day.isha,
        method: day.method,
        asrMethod: day.asrMethod,
      );

      expect(buildNudges(now: makkah(15, 16, 32), days: [polar], done: const {}), isEmpty);
    });

    test('with the 60 prayer alerts the total stays at 63, under ios\'s 64 (SC-008)', () {
      final days = daysFrom(DateTime(2026, 10, 15));
      final now = makkah(15, 4, 0);
      final total = [
        ...buildSchedule(now: now, days: days, sounds: sounds, reminderMinutes: 10),
        ...buildNudges(now: now, days: days, done: const {}),
      ];

      expect(total, hasLength(63));
      expect(total.map((alert) => alert.id).toSet(), hasLength(63));
    });
  });

  test('the quiet notice comes half an hour after the latest alert, none without alerts', () {
    final alerts = buildSchedule(
      now: makkah(15, 10, 0),
      days: daysFrom(DateTime(2026, 10, 15)),
      sounds: sounds,
      reminderMinutes: 10,
    );

    expect(quietNoticeAt(alerts), alerts.last.at.add(quietNoticeDelay));
    expect(quietNoticeAt(alerts)!.day, 20);
    expect(quietNoticeAt([]), isNull);
  });

  group('silent minutes', () {
    Alert dhuhrOn(DateTime day) => Alert(
      day: day,
      prayer: Prayer.dhuhr,
      kind: AlertKind.adhan,
      at: TZDateTime(getLocation('Asia/Riyadh'), day.year, day.month, day.day, 12),
      sound: PrayerSound.adhan,
    );

    test('friday dhuhr gets at least an hour for the khutbah', () {
      final friday = DateTime(2026, 10, 16);
      expect(silentMinutesOf(dhuhrOn(friday), 20), fridaySilentMinutes);
      expect(silentMinutesOf(dhuhrOn(DateTime(2026, 10, 15)), 20), 20);
    });
  });
}
