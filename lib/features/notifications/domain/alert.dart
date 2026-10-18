import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:timezone/timezone.dart';

enum AlertKind { adhan, reminder }

/// one notification to schedule
class Alert {
  const Alert({
    required this.day,
    required this.prayer,
    required this.kind,
    required this.at,
    required this.sound,
  });

  /// the prayer day it belongs to, so isha after midnight stays on the day it started
  final DateTime day;
  final Prayer prayer;
  final AlertKind kind;
  final TZDateTime at;

  /// reminders ignore it
  final PrayerSound sound;

  int get id => alertId(day, prayer, kind);
}

/// the dev page's test notification, far from any real day
const testAlertId = 1000000;

final _firstDay = DateTime.utc(2020);

/// an id gives back its day and prayer, so cleaning up a delivered one needs no payload
int alertId(DateTime day, Prayer prayer, AlertKind kind) {
  final days = DateTime.utc(day.year, day.month, day.day).difference(_firstDay).inDays;
  final slot = prayer.index + (kind == AlertKind.reminder ? Prayer.values.length : 0);
  return days * 10 + slot;
}

({DateTime day, Prayer prayer, AlertKind kind})? alertFromId(int id) {
  if (id < 0 || id >= testAlertId) return null;
  final date = _firstDay.add(Duration(days: id ~/ 10));
  final slot = id % 10;
  return (
    day: DateTime(date.year, date.month, date.day),
    prayer: Prayer.values[slot % Prayer.values.length],
    kind: slot < Prayer.values.length ? AlertKind.adhan : AlertKind.reminder,
  );
}

/// pipe separated so kotlin reads it with one split. no place, it can sit in the os for days
String payloadOf(Alert alert) {
  final day = alert.day;
  final date =
      '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
  return [
    date,
    alert.prayer.name,
    alert.kind.name,
    alert.sound.name,
    alert.at.millisecondsSinceEpoch,
  ].join('|');
}

Alert? alertFromPayload(String payload) {
  final parts = payload.split('|');
  if (parts.length != 5) return null;
  final date = DateTime.tryParse(parts[0]);
  final prayer = Prayer.values.asNameMap()[parts[1]];
  final kind = AlertKind.values.asNameMap()[parts[2]];
  final sound = PrayerSound.values.asNameMap()[parts[3]];
  final millis = int.tryParse(parts[4]);
  if (date == null || prayer == null || kind == null || sound == null || millis == null) {
    return null;
  }
  return Alert(
    day: DateTime(date.year, date.month, date.day),
    prayer: prayer,
    kind: kind,
    at: TZDateTime.fromMillisecondsSinceEpoch(UTC, millis),
    sound: sound,
  );
}
