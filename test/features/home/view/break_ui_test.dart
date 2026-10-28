import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_method.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../../helpers/fonts.dart';
import '../../../helpers/home.dart';
import '../../../helpers/providers.dart';

/// the home arc at its worst: polar days, a three hour night, big text, arabic, a narrow phone
void main() {
  setUpAll(tz.initializeTimeZones);
  setUpAll(loadAppFonts);

  /// hours of the day in makkah's zone, null drops the time like adhan does above the polar circle
  DayTimes times(DateTime date, List<double?> hours) {
    final zone = tz.getLocation('Asia/Riyadh');
    tz.TZDateTime? at(double? hour) => hour == null
        ? null
        : tz.TZDateTime(
            zone,
            date.year,
            date.month,
            date.day,
          ).add(Duration(minutes: (hour * 60).round()));
    return DayTimes(
      date: date,
      fajr: at(hours[0]),
      sunrise: at(hours[1]),
      dhuhr: at(hours[2]),
      asr: at(hours[3]),
      maghrib: at(hours[4]),
      isha: at(hours[5]),
      method: PrayerMethod.ummAlQura,
      asrMethod: AsrMethod.standard,
    );
  }

  final shapes = <String, List<double?>>{
    'no isha': [4.9, 6.25, 12.1, 15.45, 17.9, null],
    'no fajr and no isha': [null, 6.25, 12.1, 15.45, 17.9, null],
    'no sunrise and no maghrib': [6.5, null, 12.1, null, null, 17.5],
    'a three hour night': [1.2, 2.0, 12.5, 17.8, 22.7, 23.8],
    'everything but dhuhr': [null, null, 12.1, null, null, null],
  };
  final moments = {
    '13:32': DateTime.utc(2026, 10, 15, 10, 32),
    '23:00': DateTime.utc(2026, 10, 15, 20),
    '00:30': DateTime.utc(2026, 10, 15, 21, 30),
    '05:00': DateTime.utc(2026, 10, 15, 2),
  };

  for (final MapEntry(key: shape, value: hours) in shapes.entries) {
    for (final MapEntry(key: moment, value: utc) in moments.entries) {
      for (final locale in const [Locale('en'), Locale('ar')]) {
        for (final scale in const [1.0, 2.0]) {
          for (final width in const [320.0, 393.0]) {
            testWidgets('$shape at $moment, ${locale.languageCode} $scale x $width', (
              tester,
            ) async {
              await pumpHome(
                tester,
                makkahAt(
                  tester,
                  utc,
                  extra: [dayTimesProvider.overrideWith((ref, date) => times(date, hours))],
                ),
                locale: locale,
                textScale: scale,
                size: Size(width, 852),
              );
              expect(tester.takeException(), isNull);

              final labels = skyLabels(tester);

              /// the 14 pt margin scales with the screen like every other size
              final margin = 14 * width / 393 - .01;
              for (final (i, label) in labels.indexed) {
                expect(label.rect.left, greaterThanOrEqualTo(margin), reason: label.text);
                expect(label.rect.right, lessThanOrEqualTo(width - margin), reason: label.text);
                expect(label.rect.top, greaterThanOrEqualTo(0), reason: label.text);
                for (final other in labels.skip(i + 1)) {
                  expect(
                    label.rect.overlaps(other.rect),
                    isFalse,
                    reason: '${label.text} and ${other.text}',
                  );
                }
              }
              await unmount(tester);
            });
          }
        }
      }
    }
  }
}
