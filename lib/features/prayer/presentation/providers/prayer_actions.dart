import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final prayerActionsProvider = Provider<PrayerActions>(PrayerActions.new);

class PrayerActions {
  const PrayerActions(this._ref);

  final Ref _ref;

  /// true only when this mark made the day's fifth, so a day already complete never plays Day
  /// complete again (R11). one transaction, so a double tap can't play it twice
  Future<bool> mark(DateTime day, Prayer prayer) {
    final db = _ref.read(databaseProvider);
    return db.transaction(() async {
      final logged = await (db.select(
        db.prayerLog,
      )..where((row) => row.date.equalsValue(day))).map((row) => row.prayer).get();
      if (logged.contains(prayer)) return false;
      await db.markPrayed(day, prayer);
      return logged.length == Prayer.values.length - 1;
    });
  }

  Future<void> unmark(DateTime day, Prayer prayer) =>
      _ref.read(databaseProvider).unmarkPrayed(day, prayer);
}
