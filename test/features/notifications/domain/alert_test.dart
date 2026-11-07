import 'package:better_muslim/core/azkar/azkar_window.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/notifications/domain/alert.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

  test('15 oct 2026 maghrib is 24793, as in the data model', () {
    expect(alertId(DateTime(2026, 10, 15), Prayer.maghrib, AlertKind.adhan), 24793);
  });

  test('ids round trip for every prayer and kind across a year', () {
    final ids = <int>{};
    for (var i = 0; i < 366; i++) {
      final day = DateTime(2026, 1, 1 + i);
      for (final prayer in Prayer.values) {
        for (final kind in [AlertKind.adhan, AlertKind.reminder]) {
          final id = alertId(day, prayer, kind);
          expect(alertFromId(id), (day: day, prayer: prayer, kind: kind));
          ids.add(id);
        }
      }
    }
    expect(ids, hasLength(366 * 10));
  });

  test('azkar ids start at 2,000,000, one per set and day, and alertFromId leaves them', () {
    final ids = <int>{};
    for (var i = 0; i < 366; i++) {
      for (final set in AzkarSet.values) {
        final id = azkarAlertId(DateTime(2026, 1, 1 + i), set);
        expect(id, greaterThanOrEqualTo(2000000));
        expect(alertFromId(id), isNull);
        ids.add(id);
      }
    }
    expect(ids, hasLength(366 * 2));

    final evening = Alert(
      day: DateTime(2026, 10, 15),
      prayer: Prayer.asr,
      kind: AlertKind.azkar,
      at: TZDateTime(getLocation('Asia/Riyadh'), 2026, 10, 15, 15, 47),
      sound: PrayerSound.silent,
    );
    expect(evening.id, azkarAlertId(DateTime(2026, 10, 15), AzkarSet.evening));
  });

  test('an azkar payload round trips with its kind', () {
    final alert = Alert(
      day: DateTime(2026, 10, 15),
      prayer: Prayer.asr,
      kind: AlertKind.azkar,
      at: TZDateTime(getLocation('Asia/Riyadh'), 2026, 10, 15, 15, 47),
      sound: PrayerSound.silent,
    );
    final payload = payloadOf(alert);

    expect(payload, '2026-10-15|asr|azkar|silent|${alert.at.millisecondsSinceEpoch}');
    expect(alertFromPayload(payload)!.kind, AlertKind.azkar);
  });

  test('the test id gives null', () {
    expect(alertFromId(testAlertId), isNull);
  });

  test('a payload round trips and never holds a place', () {
    final alert = Alert(
      day: DateTime(2026, 10, 15),
      prayer: Prayer.isha,
      kind: AlertKind.reminder,
      at: TZDateTime(getLocation('Asia/Riyadh'), 2026, 10, 15, 19, 16),
      sound: PrayerSound.tone,
    );

    final payload = payloadOf(alert);
    final back = alertFromPayload(payload)!;

    expect(payload, '2026-10-15|isha|reminder|tone|${alert.at.millisecondsSinceEpoch}');
    expect(payload, isNot(contains('Makkah')));
    expect(payload, isNot(contains('Riyadh')));
    expect(back.day, alert.day);
    expect(back.prayer, alert.prayer);
    expect(back.kind, alert.kind);
    expect(back.sound, alert.sound);
    expect(back.at.isAtSameMomentAs(alert.at), isTrue);
    expect(back.id, alert.id);
  });

  group('staleDelivered', () {
    final day = DateTime(2026, 10, 15);
    int id(Prayer prayer, AlertKind kind) => alertId(day, prayer, kind);

    test('a prayer gives way to the next one, its reminder or its adhan', () {
      final asr = id(Prayer.asr, AlertKind.adhan);
      final reminder = id(Prayer.maghrib, AlertKind.reminder);
      final maghrib = id(Prayer.maghrib, AlertKind.adhan);

      expect(staleDelivered([asr, reminder]), [asr]);
      expect(staleDelivered([reminder, maghrib, asr]), unorderedEquals([reminder, asr]));
    });

    test('evening replaces morning, and the prayers leave the nudges alone', () {
      final morning = azkarAlertId(day, AzkarSet.morning);
      final evening = azkarAlertId(day, AzkarSet.evening);
      final asr = id(Prayer.asr, AlertKind.adhan);

      expect(staleDelivered([morning, evening, asr]), [morning]);
      expect(staleDelivered([morning, asr]), isEmpty);
    });

    test('the test and the open the app ones stay', () {
      expect(staleDelivered([testAlertId, quietAlertId]), isEmpty);
    });
  });

  test('a broken payload gives null', () {
    expect(alertFromPayload('2026-10-15|maghrib'), isNull);
    expect(alertFromPayload('2026-10-15|noon|adhan|adhan|1'), isNull);
  });
}
