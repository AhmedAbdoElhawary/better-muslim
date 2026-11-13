import 'package:better_muslim/core/azkar/azkar_window.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:timezone/timezone.dart';

/// azkar is the quiet nudge after fajr and asr, its prayer says which set
enum AlertKind { adhan, reminder, azkar }

/// one notification to schedule
class Alert {
  const Alert({
    required this.day,
    required this.prayer,
    required this.kind,
    required this.at,
    required this.sound,
    this.before = Duration.zero,
    this.lasts,
  });

  /// the prayer day it belongs to, so isha after midnight stays on the day it started
  final DateTime day;
  final Prayer prayer;
  final AlertKind kind;
  final TZDateTime at;

  /// reminders ignore it
  final PrayerSound sound;

  /// how long before the prayer a reminder comes, zero for the adhan
  final Duration before;

  /// a nudge goes when the next one's time comes, whether that one shows or not
  final Duration? lasts;

  TZDateTime get prayerTime => at.add(before);

  int get id =>
      kind == AlertKind.azkar ? azkarAlertId(day, azkarSetOf(prayer)) : alertId(day, prayer, kind);
}

AzkarSet azkarSetOf(Prayer prayer) => prayer == Prayer.fajr ? AzkarSet.morning : AzkarSet.evening;

/// the dev page's test notification, far from any real day
const testAlertId = 1000000;

/// ios's "open the app" after the last alert
const quietAlertId = testAlertId + 1;

/// the dev page rehearsal's reminder sound on android
const testReminderId = testAlertId + 2;

final _firstDay = DateTime.utc(2020);

/// an id gives back its day and prayer, so cleaning up a delivered one needs no payload
int alertId(DateTime day, Prayer prayer, AlertKind kind) {
  final days = DateTime.utc(day.year, day.month, day.day).difference(_firstDay).inDays;
  final slot = prayer.index + (kind == AlertKind.reminder ? Prayer.values.length : 0);
  return days * 10 + slot;
}

/// past alertFromId's range, so the delivered cleanup leaves the nudges alone
int azkarAlertId(DateTime day, AzkarSet set) {
  final days = DateTime.utc(day.year, day.month, day.day).difference(_firstDay).inDays;
  return _firstAzkarId + days * AzkarSet.values.length + set.index;
}

const _firstAzkarId = 2000000;

/// ios can't take a delivered notification away at a prayer time, so this runs when it can: all
/// but the newest prayer one and the newest nudge
List<int> staleDelivered(List<int> ids) {
  /// a prayer's reminder comes before its adhan, their ids don't say so
  int rank(int id) {
    final slot = id % 10;
    final count = Prayer.values.length;
    return id - slot + slot % count * 2 + (slot < count ? 1 : 0);
  }

  final nudges = ids.where((id) => id >= _firstAzkarId).toList()..sort();
  final prayers = ids.where((id) => alertFromId(id) != null).toList()
    ..sort((a, b) => rank(a).compareTo(rank(b)));
  return [...nudges.reversed.skip(1), ...prayers.reversed.skip(1)];
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
