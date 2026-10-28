import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:better_muslim/core/backup/backup_file.dart';
import 'package:better_muslim/core/backup/restore.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../drift/app_database/generated/schema_v5.dart' as v5;
import '../../helpers/backup.dart';
import '../../helpers/phone_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory phone;
  setUp(() => phone = usePhoneStorage());

  /// a phone that has its own data and its own columns
  Future<AppDatabase> otherPhone() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.updateSettings(
      const SettingsCompanion(
        placeName: Value('Cairo'),
        onboarded: Value(false),
        notificationsAsked: Value(true),
        storeResetPending: Value(true),
      ),
    );
    await db.markPrayed(DateTime(2026, 10, 1), Prayer.dhuhr);
    await db.saveDua('sleep-1');
    addTearDown(db.close);
    return db;
  }

  Future<List<Map<String, Object?>>> rows(AppDatabase db, String table) async => [
    for (final row in await db.customSelect('select * from $table order by 1, 2').get()) row.data,
  ];

  test('every row of every table comes back, this phone keeps its own columns (SC-004)', () async {
    final from = await seededStore();
    addTearDown(from.close);
    final file = await writeBackup(from, 'test1234', now: DateTime(2026, 10, 20));
    final (backup, _) = await readBackup(file, 'test1234', schemaVersion: from.schemaVersion);
    final into = await otherPhone();

    await restore(into, backup!);
    await closeBackup(backup);

    for (final table in backupTables.skip(1)) {
      expect(await rows(into, table), await rows(from, table), reason: table);
    }
    final mine = await into.select(into.settings).getSingle();
    final theirs = await from.select(from.settings).getSingle();
    expect(mine.copyWith(onboarded: true, storeResetPending: true).toJson(), theirs.toJson());
    expect((mine.onboarded, mine.notificationsAsked, mine.storeResetPending), (false, true, true));
  });

  test('a failure in the middle leaves this phone as it was', () async {
    final from = await seededStore();
    addTearDown(from.close);

    /// a value the store's check refuses, slipped past it in the backup
    await from.customStatement('pragma ignore_check_constraints = on');
    await from.customStatement('update settings set reminder_minutes = 7');
    final into = await otherPhone();
    final before = {for (final table in backupTables) table: await rows(into, table)};

    await expectLater(restore(into, from), throwsA(anything));
    for (final table in backupTables) {
      expect(await rows(into, table), before[table], reason: table);
    }
  });

  test('the copy names every table of the store', () {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    expect(backupTables.toSet(), db.allTables.map((table) => table.actualTableName).toSet());
  });

  test('a backup from schema 5 is upgraded and restored', () async {
    final payload = File('${phone.path}/old.db');
    final key = utf8.encode('test1234').map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final old = v5.DatabaseAtV5(
      NativeDatabase(
        payload,
        setup: (db) => db
          ..execute("pragma cipher = 'chacha20'")
          ..execute('pragma kdf_iter = 600000')
          ..execute("pragma hexkey = '$key'")
          ..execute('pragma user_version = 5'),
      ),
    );
    await old.createMigrator().createAll();
    await old.customStatement(
      "insert into settings (id, place_name, reminder_minutes) values (1, 'Makkah', 20)",
    );
    await old.customStatement("insert into prayer_log values ('2026-10-15', 'asr')");
    await old.close();

    final bytes = payload.readAsBytesSync();
    final header = ByteData(19)
      ..setUint8(8, 1)
      ..setUint16(9, 5)
      ..setUint64(11, bytes.length);
    final head = header.buffer.asUint8List()..setAll(0, ascii.encode('BMBACKUP'));
    final file = File('${phone.path}/old.bmbackup')..writeAsBytesSync([...head, ...bytes]);

    final into = await otherPhone();
    final (backup, error) = await readBackup(file, 'test1234', schemaVersion: into.schemaVersion);
    expect(error, isNull);
    await restore(into, backup!);
    await closeBackup(backup);

    final settings = await into.select(into.settings).getSingle();
    expect((settings.placeName, settings.reminderMinutes), ('Makkah', 20));
    expect(await rows(into, 'prayer_log'), [
      {'date': '2026-10-15', 'prayer': 'asr'},
    ]);
  });
}
