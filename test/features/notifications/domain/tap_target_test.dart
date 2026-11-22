import 'package:better_muslim/core/azkar/azkar_window.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/notifications/domain/alert.dart';
import 'package:better_muslim/features/notifications/domain/tap_target.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

  const length = Duration(minutes: 3, seconds: 52);

  String payload(
    Prayer prayer,
    PrayerSound sound, {
    AlertKind kind = AlertKind.adhan,
    int day = 15,
  }) => payloadOf(
    Alert(
      day: DateTime(2026, 10, day),
      prayer: prayer,
      kind: kind,
      at: TZDateTime(getLocation('Asia/Riyadh'), 2026, 10, 15, 17, 56),
      sound: sound,
    ),
  );

  DateTime after(Duration elapsed) =>
      TZDateTime(getLocation('Asia/Riyadh'), 2026, 10, 15, 17, 56).add(elapsed);

  test('an adhan tapped while it would still play opens the adhan screen at that point', () {
    final atStart = tapTarget(
      payload(Prayer.maghrib, PrayerSound.adhan),
      after(Duration.zero),
      length,
    );
    final nearEnd = tapTarget(
      payload(Prayer.maghrib, PrayerSound.adhan),
      after(length - const Duration(seconds: 1)),
      length,
    );

    expect(atStart, isA<AdhanTarget>().having((target) => target.from, 'from', Duration.zero));
    expect(
      nearEnd,
      isA<AdhanTarget>()
          .having((target) => target.from, 'from', length - const Duration(seconds: 1))
          .having((target) => target.prayer, 'prayer', Prayer.maghrib)
          .having((target) => target.day, 'day', DateTime(2026, 10, 15)),
    );
  });

  test('later than the adhan\'s length opens the prayer tab', () {
    final target = tapTarget(
      payload(Prayer.maghrib, PrayerSound.adhan),
      after(length + const Duration(seconds: 1)),
      length,
    );

    expect(
      target,
      isA<PrayerTarget>()
          .having((target) => target.day, 'day', DateTime(2026, 10, 15))
          .having((target) => target.prayer, 'prayer', Prayer.maghrib),
    );
  });

  test('tone and silent open the prayer tab', () {
    for (final sound in [PrayerSound.tone, PrayerSound.silent]) {
      expect(
        tapTarget(payload(Prayer.asr, sound), after(Duration.zero), length),
        isA<PrayerTarget>(),
      );
    }
  });

  test('a reminder only opens the app', () {
    expect(
      tapTarget(
        payload(Prayer.asr, PrayerSound.tone, kind: AlertKind.reminder),
        after(Duration.zero),
        length,
      ),
      isA<NoTarget>(),
    );
  });

  test('isha after midnight keeps the day it started', () {
    final target = tapTarget(
      payload(Prayer.isha, PrayerSound.tone, day: 14),
      after(const Duration(hours: 7)),
      length,
    );

    expect(
      target,
      isA<PrayerTarget>().having((target) => target.day, 'day', DateTime(2026, 10, 14)),
    );
  });

  test('an azkar nudge opens its set', () {
    final target = tapTarget(
      payload(Prayer.asr, PrayerSound.silent, kind: AlertKind.azkar),
      after(const Duration(minutes: 20)),
      length,
    );

    expect(target, isA<AzkarTarget>().having((target) => target.set, 'set', AzkarSet.evening));
    expect(
      tapTarget(
        payload(Prayer.fajr, PrayerSound.silent, kind: AlertKind.azkar),
        after(Duration.zero),
        length,
      ),
      isA<AzkarTarget>().having((target) => target.set, 'set', AzkarSet.morning),
    );
  });
}
