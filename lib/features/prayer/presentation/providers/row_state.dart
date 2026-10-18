import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/prayer_log/prayer_log.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/features/prayer/domain/prayer_row_state.dart';
import 'package:better_muslim/features/prayer/presentation/providers/qada.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// follows the ticker, but a row only rebuilds when its state changes
final rowStateProvider = Provider.autoDispose.family<RowState, (DateTime, Prayer)>((ref, key) {
  final (day, prayer) = key;
  final times = ref.watch(dayTimesProvider(day));
  final tomorrow = ref.watch(dayTimesProvider(DateTime(day.year, day.month, day.day + 1)));
  final qada = ref.watch(
    qadaWeekProvider(weekStart(day)).select((week) => week.value?[(day, prayer)]),
  );
  return rowState(
    prayer: prayer,
    time: times?.timeOf(prayer),
    end: times?.endOf(prayer, tomorrow),
    now: ref.watch(tickerProvider).value ?? ref.watch(clockProvider)(),
    logged: ref.watch(prayedProvider(day).select((prayed) => prayed.contains(prayer))),
    qada: qada,
    next: ref.watch(nextPrayerProvider),
  );
});
