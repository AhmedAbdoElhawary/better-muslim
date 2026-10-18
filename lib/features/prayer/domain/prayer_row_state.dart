import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:timezone/timezone.dart';

enum PrayerRowState { unavailable, prayed, next, later, mark, madeUp, inQada, addToQada }

typedef RowState = ({PrayerRowState state, bool isOpen});

/// first match wins (R4). a future day needs no case of its own, its times are all ahead
RowState rowState({
  required Prayer prayer,
  required TZDateTime? time,
  required TZDateTime? end,
  required DateTime now,
  required bool logged,
  QadaEntry? qada,
  (Prayer, TZDateTime)? next,
}) {
  if (time == null) return (state: PrayerRowState.unavailable, isOpen: false);
  final started = !now.isBefore(time);
  final ended = end != null && !now.isBefore(end);
  final isOpen = started && !ended;
  if (logged) return (state: PrayerRowState.prayed, isOpen: isOpen);
  if (!started) {
    final isNext = next != null && next.$1 == prayer && next.$2.isAtSameMomentAs(time);
    return (state: isNext ? PrayerRowState.next : PrayerRowState.later, isOpen: false);
  }
  if (!ended) return (state: PrayerRowState.mark, isOpen: true);
  if (qada != null) {
    final state = qada.madeUpAt == null ? PrayerRowState.inQada : PrayerRowState.madeUp;
    return (state: state, isOpen: false);
  }
  return (state: PrayerRowState.addToQada, isOpen: false);
}
