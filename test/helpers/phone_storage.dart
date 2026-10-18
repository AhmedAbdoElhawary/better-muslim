import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// a temp folder as Application Support and an in-memory keychain, so AppDatabase.open runs on
/// the host with the real encrypted sqlite
Directory usePhoneStorage() {
  final directory = Directory.systemTemp.createTempSync('better_muslim_');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (_) async => directory.path,
  );
  FlutterSecureStorage.setMockInitialValues({});
  addTearDown(() => directory.deleteSync(recursive: true));
  return directory;
}
