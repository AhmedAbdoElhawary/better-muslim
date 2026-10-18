import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/features/prayer/data/qada_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late QadaRepository qada;
  final now = DateTime.utc(2026, 10, 15, 13, 32);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    qada = QadaRepository(db, () => now);
  });

  DateTime october(int day) => DateTime(2026, 10, day);
  Future<List<QadaEntry>> entries() => db.select(db.qadaEntries).get();

  group('a passed prayer (US2)', () {
    test('add makes an open dated entry, a second add changes nothing', () async {
      await qada.add(october(13), Prayer.isha);
      await qada.add(october(13), Prayer.isha);

      final [entry] = await entries();
      expect((entry.missedOn, entry.prayer, entry.madeUpAt), (october(13), Prayer.isha, null));
    });

    test('remove deletes only the open dated entry of that day and prayer', () async {
      await qada.add(october(13), Prayer.isha);
      await qada.add(october(13), Prayer.fajr);
      await qada.add(october(14), Prayer.isha);
      await qada.addOlder(Prayer.isha, 1);
      await qada.remove(october(13), Prayer.isha);

      expect((await entries()).map((entry) => (entry.missedOn, entry.prayer)), [
        (october(13), Prayer.fajr),
        (october(14), Prayer.isha),
        (null, Prayer.isha),
      ]);
    });

    test('a made up entry is never removed', () async {
      await qada.add(october(13), Prayer.isha);
      await qada.makeUpOldest(Prayer.isha);
      await qada.remove(october(13), Prayer.isha);

      expect(await entries(), hasLength(1));
    });

    test('watchWeek gives the dated entries of the 7 days by day and prayer', () async {
      await qada.add(october(10), Prayer.fajr);
      await qada.add(october(11), Prayer.fajr);
      await qada.add(october(17), Prayer.isha);
      await qada.add(october(18), Prayer.isha);
      await qada.addOlder(Prayer.fajr, 2);

      final week = await qada.watchWeek(october(11)).first;
      expect(week.keys, {(october(11), Prayer.fajr), (october(17), Prayer.isha)});
    });
  });

  group('the qada list (US3)', () {
    test(
      'made one up takes a dateless entry first, then the oldest date, then the lowest id',
      () async {
        await qada.add(october(8), Prayer.fajr);
        await qada.add(october(6), Prayer.fajr);
        final [older] = await qada.addOlder(Prayer.fajr, 1);

        expect(await qada.makeUpOldest(Prayer.fajr), older);
        final second = await qada.makeUpOldest(Prayer.fajr);
        final third = await qada.makeUpOldest(Prayer.fajr);

        final byId = {for (final entry in await entries()) entry.id: entry};
        expect(byId[second]!.missedOn, october(6));
        expect(byId[third]!.missedOn, october(8));
        expect(byId[older]!.madeUpAt!.isAtSameMomentAs(now), isTrue);
        expect(await qada.makeUpOldest(Prayer.fajr), isNull);
      },
    );

    test('two dateless entries go by id', () async {
      final ids = await qada.addOlder(Prayer.dhuhr, 2);

      expect(await qada.makeUpOldest(Prayer.dhuhr), ids.first);
    });

    test('undo of made one up opens the same entry again', () async {
      await qada.add(october(13), Prayer.isha);
      final id = await qada.makeUpOldest(Prayer.isha);
      await qada.undoMadeUp(id!);

      final [entry] = await entries();
      expect((entry.id, entry.madeUpAt), (id, null));
    });

    test(
      'addOlder adds dateless entries and returns their ids, removeIds takes exactly those',
      () async {
        await qada.add(october(13), Prayer.fajr);
        final ids = await qada.addOlder(Prayer.fajr, 3);

        expect(ids, hasLength(3));
        expect((await entries()).where((entry) => entry.missedOn == null), hasLength(3));

        await qada.removeIds(ids);
        final [left] = await entries();
        expect(left.missedOn, october(13));
      },
    );

    test('open counts per prayer, made up entries never count', () async {
      await qada.add(october(6), Prayer.fajr);
      await qada.add(october(8), Prayer.fajr);
      await qada.add(october(13), Prayer.isha);
      await qada.addOlder(Prayer.dhuhr, 2);
      await qada.makeUpOldest(Prayer.isha);

      expect(await qada.watchOpenCounts().first, {Prayer.fajr: 2, Prayer.dhuhr: 2});
    });

    test('the month count is open dated entries of that gregorian month only', () async {
      await qada.add(DateTime(2026, 9, 30), Prayer.fajr);
      await qada.add(october(1), Prayer.fajr);
      await qada.add(october(31), Prayer.isha);
      await qada.add(DateTime(2026, 11, 1), Prayer.isha);
      await qada.add(october(13), Prayer.isha);
      await qada.addOlder(Prayer.fajr, 5);
      await qada.makeUpOldest(Prayer.isha);

      expect(await qada.watchMonthCount(october(15)).first, 2);
    });
  });
}
