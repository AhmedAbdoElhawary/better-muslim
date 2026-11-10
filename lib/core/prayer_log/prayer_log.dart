import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/database/civil_date.dart';
import 'package:better_muslim/core/prayer_log/prayer_row_state.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// the sunday on or before the day, the week starts on sunday in both languages
DateTime weekStart(DateTime day) => DateTime(day.year, day.month, day.day - day.weekday % 7);

/// the 7 days from a sunday in one query, so a year of logs stays cheap (SC-006)
final weekLogProvider = StreamProvider.autoDispose.family<Map<DateTime, Set<Prayer>>, DateTime>((
  ref,
  start,
) {
  final db = ref.watch(databaseProvider);
  const date = CivilDate();
  final end = DateTime(start.year, start.month, start.day + 6);
  final query = db.select(db.prayerLog)
    ..where((row) => row.date.isBetweenValues(date.toSql(start), date.toSql(end)));
  return query.watch().map((rows) {
    final log = <DateTime, Set<Prayer>>{};
    for (final row in rows) {
      (log[row.date] ??= {}).add(row.prayer);
    }
    return log;
  });
});

final prayedProvider = Provider.autoDispose.family<Set<Prayer>, DateTime>(
  (ref, day) => ref.watch(
    weekLogProvider(weekStart(day)).select((log) => log.value?[day] ?? const <Prayer>{}),
  ),
);

/// the dated qada entries of the 7 days from a sunday, one query per visible week
final qadaWeekProvider = StreamProvider.autoDispose
    .family<Map<(DateTime, Prayer), QadaEntry>, DateTime>((ref, start) {
      final db = ref.watch(databaseProvider);
      const date = CivilDate();
      final end = DateTime(start.year, start.month, start.day + 6);
      final query = db.select(db.qadaEntries)
        ..where((row) => row.missedOn.isBetweenValues(date.toSql(start), date.toSql(end)));
      return query.watch().map(
        (rows) => {for (final row in rows) (row.missedOn!, row.prayer): row},
      );
    });

/// a row only rebuilds when its state changes
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
    now: ref.watch(boundaryProvider),
    logged: ref.watch(prayedProvider(day).select((prayed) => prayed.contains(prayer))),
    qada: qada,
    next: ref.watch(nextPrayerProvider),
    highlighted: ref.watch(highlightedPrayerProvider),
  );
});
