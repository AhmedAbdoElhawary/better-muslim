import 'dart:convert';
import 'dart:io';

import 'package:better_muslim/core/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/phone_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late File file;

  setUp(() async {
    file = File('${usePhoneStorage().path}/better_muslim.sqlite');
    final db = await AppDatabase.open();
    await db.updateSettings(const SettingsCompanion(placeName: Value('Makkah')));
    await db.close();
  });

  test('the file holds no plaintext (SC-007)', () {
    final text = latin1.decode(file.readAsBytesSync());

    expect(text, isNot(contains('Makkah')));
    expect(text, isNot(contains('SQLite format 3')));
  });

  test('without the key it is not a database', () async {
    final plain = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(plain.close);

    await expectLater(
      plain.customSelect('select count(*) from sqlite_master').get(),
      throwsA(isA<SqliteException>().having((error) => error.resultCode, 'resultCode', 26)),
    );
  });

  test('with the key it reads back', () async {
    final key = await const FlutterSecureStorage().read(key: 'database_key');
    final keyed = AppDatabase.forTesting(
      NativeDatabase(file, setup: (db) => db.execute("pragma key = '$key'")),
    );
    addTearDown(keyed.close);

    expect((await keyed.watchSettings().first).placeName, 'Makkah');
  });
}
