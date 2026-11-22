import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
  });

  final day = DateTime(2026, 10, 15);

  test('marking twice leaves one row', () async {
    await db.markPrayed(day, Prayer.asr);
    await db.markPrayed(day, Prayer.asr);

    expect(await db.select(db.prayerLog).get(), hasLength(1));
  });

  test('unmark removes it', () async {
    await db.markPrayed(day, Prayer.asr);
    await db.markPrayed(day, Prayer.dhuhr);
    await db.unmarkPrayed(day, Prayer.asr);

    final [row] = await db.select(db.prayerLog).get();
    expect((row.date, row.prayer), (day, Prayer.dhuhr));
  });

  test('a prayer day goes in qada once, dateless entries never collide', () async {
    Future<int> add(DateTime? missedOn) => db
        .into(db.qadaEntries)
        .insert(QadaEntriesCompanion.insert(prayer: Prayer.isha, missedOn: Value(missedOn)));

    await add(day);
    await expectLater(add(day), throwsA(isA<SqliteException>()));
    await add(null);
    await add(null);

    expect(await db.select(db.qadaEntries).get(), hasLength(3));
  });

  test('first use is set once, from the clock passed in', () async {
    final first = await db.watchSettings(now: DateTime(2026, 10, 1, 9)).first;
    final second = await db.watchSettings(now: DateTime(2026, 10, 9, 9)).first;

    expect(first.firstUse, DateTime(2026, 10, 1));
    expect(second.firstUse, DateTime(2026, 10, 1));
  });
}
