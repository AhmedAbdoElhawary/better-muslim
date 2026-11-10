import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:timezone/timezone.dart';

enum PrayerRowState {
  unavailable,
  prayed,
  next,
  later,
  mark,
  madeUp,
  inQada,
  addToQada;

  /// a made up prayer counts as prayed for the day
  bool get done => this == prayed || this == madeUp;
}

typedef RowState = ({PrayerRowState state, bool isHighlighted, bool isNow});

/// first match wins (R4). a future day needs no case of its own, its times are all ahead
RowState rowState({
  required Prayer prayer,
  required TZDateTime? time,
  required TZDateTime? end,
  required DateTime now,
  required bool logged,
  QadaEntry? qada,
  (Prayer, TZDateTime)? next,
  (Prayer, TZDateTime)? highlighted,
}) {
  if (time == null) return (state: PrayerRowState.unavailable, isHighlighted: false, isNow: false);
  bool isAt((Prayer, TZDateTime)? pick) =>
      pick != null && pick.$1 == prayer && pick.$2.isAtSameMomentAs(time);
  final started = !now.isBefore(time);
  final ended = end != null && !now.isBefore(end);
  final state = switch ((logged, started, ended, qada)) {
    (true, _, _, _) => PrayerRowState.prayed,
    (_, false, _, _) => isAt(next) ? PrayerRowState.next : PrayerRowState.later,

    /// still on time after its now window, only the highlight moves on
    (_, _, false, _) => PrayerRowState.mark,
    (_, _, _, final qada?) => qada.madeUpAt == null ? PrayerRowState.inQada : PrayerRowState.madeUp,
    _ => PrayerRowState.addToQada,
  };
  final isHighlighted = isAt(highlighted);
  return (state: state, isHighlighted: isHighlighted, isNow: isHighlighted && started);
}
