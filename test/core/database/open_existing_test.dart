import 'dart:io';

import 'package:better_muslim/core/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull;
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

  test('opens the store the app made', () async {
    final db = (await AppDatabase.openExisting())!;
    addTearDown(db.close);

    expect((await db.watchSettings().first).placeName, 'Makkah');
  });

  test('a missing key gives null and leaves the file in place', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final before = file.readAsBytesSync();

    expect(await AppDatabase.openExisting(), isNull);
    expect(file.readAsBytesSync(), before);
  });

  test('an unreadable file gives null and leaves the file in place', () async {
    FlutterSecureStorage.setMockInitialValues({'database_key': 'not the key'});
    final before = file.readAsBytesSync();

    expect(await AppDatabase.openExisting(), isNull);
    expect(file.readAsBytesSync(), before);
  });

  test('no file gives null', () async {
    file.deleteSync();

    expect(await AppDatabase.openExisting(), isNull);
    expect(file.existsSync(), isFalse);
  });
}
