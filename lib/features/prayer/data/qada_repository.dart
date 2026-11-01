import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/features/prayer/domain/week.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final qadaRepositoryProvider = Provider<QadaRepository>(
  (ref) => QadaRepository(ref.watch(databaseProvider), ref.watch(clockProvider)),
);

/// one row per prayer to make up. a dated entry is a missed prayer day, a dateless one was
/// missed before using the app (R5)
class QadaRepository {
  const QadaRepository(this._db, this._clock);

  final AppDatabase _db;
  final DateTime Function() _clock;

  $QadaEntriesTable get _qada => _db.qadaEntries;

  /// a prayer day is in qada once, a second add changes nothing
  Future<void> add(DateTime day, Prayer prayer) => _db
      .into(_qada)
      .insert(
        QadaEntriesCompanion.insert(prayer: prayer, missedOn: Value(day)),
        mode: InsertMode.insertOrIgnore,
      );

  /// only the open one, a made up entry stays as it is
  Future<void> remove(DateTime day, Prayer prayer) =>
      (_db.delete(_qada)..where(
            (row) =>
                row.missedOn.equalsValue(day) &
                row.prayer.equalsValue(prayer) &
                row.madeUpAt.isNull(),
          ))
          .go();

  /// dateless entries were missed before any dated one, so they go first. null = nothing open
  Future<int?> makeUpOldest(Prayer prayer) => _db.transaction(() async {
    final oldest =
        await (_db.select(_qada)
              ..where((row) => row.prayer.equalsValue(prayer) & row.madeUpAt.isNull())
              ..orderBy([
                (row) => OrderingTerm(expression: row.missedOn, nulls: NullsOrder.first),
                (row) => OrderingTerm(expression: row.id),
              ])
              ..limit(1))
            .getSingleOrNull();
    if (oldest == null) return null;
    await (_db.update(_qada)..where((row) => row.id.equals(oldest.id))).write(
      QadaEntriesCompanion(madeUpAt: Value(_clock())),
    );
    return oldest.id;
  });

  Future<void> undoMadeUp(int id) => (_db.update(
    _qada,
  )..where((row) => row.id.equals(id))).write(const QadaEntriesCompanion(madeUpAt: Value(null)));

  /// the ids, so the toast's undo removes exactly this batch
  Future<List<int>> addOlder(Prayer prayer, int count) {
    assert(count >= 1 && count <= 999, 'the + sheet keeps the count between 1 and 999');
    return _db.transaction(
      () async => [
        for (var i = 0; i < count; i++)
          await _db.into(_qada).insert(QadaEntriesCompanion.insert(prayer: prayer)),
      ],
    );
  }

  Future<void> removeIds(List<int> ids) =>
      (_db.delete(_qada)..where((row) => row.id.isIn(ids))).go();

  /// open entries per prayer from one grouped count, a prayer with none is missing from the map
  Stream<Map<Prayer, int>> watchOpenCounts() {
    final count = _qada.id.count();
    final query = _db.selectOnly(_qada)
      ..addColumns([_qada.prayer, count])
      ..where(_qada.madeUpAt.isNull())
      ..groupBy([_qada.prayer]);
    return query.watch().map(
      (rows) => {
        for (final row in rows) Prayer.values.byName(row.read(_qada.prayer)!): row.read(count)!,
      },
    );
  }

  /// open dated entries missed in the gregorian month of the day, dateless ones never count
  Stream<int> watchMonthCount(DateTime day) {
    final range = monthRange(day);
    final count = _qada.id.count();
    final query = _db.selectOnly(_qada)
      ..addColumns([count])
      ..where(_qada.madeUpAt.isNull() & _qada.missedOn.isBetweenValues(range.from, range.to));
    return query.map((row) => row.read(count)!).watchSingle();
  }
}
