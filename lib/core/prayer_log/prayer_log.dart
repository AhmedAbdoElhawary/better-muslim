import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/database/civil_date.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
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
