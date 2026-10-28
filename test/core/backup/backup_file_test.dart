import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:better_muslim/core/backup/backup_file.dart';
import 'package:better_muslim/core/backup/restore.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../drift/app_database/generated/schema_v10.dart' as v10;
import '../../drift/app_database/generated/schema_v7.dart' as v7;
import '../../helpers/backup.dart';
import '../../helpers/phone_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory phone;
  late AppDatabase from;
  setUp(() async {
    phone = usePhoneStorage();
    from = await seededStore();
  });
  tearDown(() => from.close());

  Future<File> write([String password = 'test1234']) =>
      writeBackup(from, password, now: DateTime(2026, 10, 20));

  Future<BackupError?> errorOf(File file, [String password = 'test1234']) async {
    final (store, error) = await readBackup(file, password, schemaVersion: from.schemaVersion);
    if (store != null) await closeBackup(store);
    return error;
  }

  File withBytes(Uint8List bytes) => File('${phone.path}/other.bmbackup')..writeAsBytesSync(bytes);

  test('the header: magic, format 1, the schema, the payload length', () async {
    final file = await write();
    final bytes = file.readAsBytesSync();
    expect(file.uri.pathSegments.last, 'better-muslim-2026-10-20.bmbackup');
    expect(ascii.decode(bytes.sublist(0, 8)), 'BMBACKUP');
    final header = ByteData.sublistView(bytes, 0, 19);
    expect(header.getUint8(8), 1);
    expect(header.getUint16(9), 11);
    expect(header.getUint64(11), bytes.length - 19);
  });

  test('a round trip opens with the password, the phone columns left out', () async {
    final (store, error) = await readBackup(
      await write(),
      'test1234',
      schemaVersion: from.schemaVersion,
    );
    expect(error, isNull);
    final settings = await store!.select(store.settings).getSingle();
    expect(settings.placeName, 'Makkah');
    expect(settings.subhanallahCount, 21);
    expect(
      (settings.onboarded, settings.notificationsAsked, settings.storeResetPending),
      (false, false, false),
    );
    expect(await store.select(store.prayerLog).get(), hasLength(2));
    expect(await store.select(store.qadaEntries).get(), hasLength(2));
    expect(await store.select(store.azkarCounts).get(), hasLength(1));
    expect(await store.select(store.savedDuas).get(), hasLength(1));
    await closeBackup(store);
  });

  test('no place, date or sqlite header can be read without the password (SC-006)', () async {
    final text = latin1.decode((await write()).readAsBytesSync());
    expect(text, isNot(contains('Makkah')));
    expect(text, isNot(contains('2026-10-15')));
    expect(text, isNot(contains('travel-1')));
    expect(text, isNot(contains('SQLite format 3')));
  });

  test('a wrong password says so', () async {
    expect(await errorOf(await write(), 'test12345'), BackupError.wrongPassword);
  });

  test('a file that is no backup', () async {
    final bytes = (await write()).readAsBytesSync()..setAll(0, ascii.encode('NOTABACK'));
    expect(await errorOf(withBytes(bytes)), BackupError.notABackup);
    expect(
      await errorOf(withBytes(Uint8List.fromList(utf8.encode('hello')))),
      BackupError.notABackup,
    );
  });

  test('a file cut short is damaged', () async {
    final bytes = (await write()).readAsBytesSync();
    expect(await errorOf(withBytes(bytes.sublist(0, bytes.length - 100))), BackupError.damaged);
    expect(await errorOf(withBytes(bytes.sublist(0, 12))), BackupError.damaged);
  });

  test('a backup from a newer schema says to update', () async {
    final bytes = (await write()).readAsBytesSync();
    ByteData.sublistView(bytes).setUint16(9, 99);
    expect(await errorOf(withBytes(bytes)), BackupError.newer);
  });

  test('a flipped byte deep in the payload is damaged', () async {
    final bytes = (await write()).readAsBytesSync();
    final at = bytes.length - 2000;
    bytes[at] = bytes[at] ^ 0xFF;
    expect(await errorOf(withBytes(bytes)), BackupError.damaged);
  });

  test("sqlite3mc's default iterations can't open it (R12)", () async {
    final bytes = (await write()).readAsBytesSync();
    final payload = File('${phone.path}/probe.db')..writeAsBytesSync(bytes.sublist(19));
    final key = utf8.encode('test1234').map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final store = AppDatabase.forTesting(
      NativeDatabase(
        payload,
        setup: (db) => db
          ..execute("pragma cipher = 'chacha20'")
          ..execute("pragma hexkey = '$key'"),
      ),
    );
    await expectLater(
      store.customSelect('select count(*) from sqlite_master').get(),
      throwsA(anything),
    );
    await store.close();
  });

  /// the old store locked like a backup, ready to write at its own schema
  (File, NativeDatabase) olderStore(int version) {
    final payload = File('${phone.path}/v$version.db');
    final key = utf8.encode('test1234').map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return (
      payload,
      NativeDatabase(
        payload,
        setup: (db) => db
          ..execute("pragma cipher = 'chacha20'")
          ..execute('pragma kdf_iter = 600000')
          ..execute("pragma hexkey = '$key'"),
      ),
    );
  }

  /// the old store behind a header, restored into the phone's store
  Future<void> restoreOlder(int version, File payload) async {
    final bytes = payload.readAsBytesSync();
    final header = ByteData(19)
      ..setUint8(8, 1)
      ..setUint16(9, version)
      ..setUint64(11, bytes.length);
    final head = header.buffer.asUint8List()..setAll(0, ascii.encode('BMBACKUP'));

    final (store, error) = await readBackup(
      withBytes(Uint8List.fromList([...head, ...bytes])),
      'test1234',
      schemaVersion: from.schemaVersion,
    );
    expect(error, isNull);
    await restore(from, store!);
    await closeBackup(store);
  }

  test('a v7 backup moves its count to the shown dhikr (R4)', () async {
    final (payload, executor) = olderStore(7);
    final old = v7.DatabaseAtV7(executor);
    await old
        .into(old.settings)
        .insert(const v7.SettingsCompanion(tasbihDhikr: Value(0), tasbihCount: Value(20)));
    await old.close();
    await restoreOlder(7, payload);
    final settings = await from.select(from.settings).getSingle();
    expect(
      (settings.subhanallahCount, settings.alhamdulillahCount, settings.allahuAkbarCount),
      (20, 0, 0),
    );
  });

  test('a v10 backup restores with amiri and its page color', () async {
    final (payload, executor) = olderStore(10);
    final old = v10.DatabaseAtV10(executor);
    await old.into(old.settings).insert(const v10.SettingsCompanion(pageColor: Value('night')));
    await old.close();
    await restoreOlder(10, payload);
    final settings = await from.select(from.settings).getSingle();
    expect((settings.quranFont, settings.pageColor), (QuranFont.amiri, PageColor.night));
  });

  test('the temp files are gone after every call', () async {
    final file = await write();
    await errorOf(file, 'wrong');
    await errorOf(file);
    final left = phone.listSync().map((entry) => entry.uri.pathSegments.last).toList();
    expect(left, ['better-muslim-2026-10-20.bmbackup']);
  });
}
