import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// the store's key, made on the phone and kept only in the Keychain or Keystore
abstract final class DatabaseKey {
  static const _name = 'database_key';

  /// first_unlock so the background top-up can open the store while the phone is locked,
  /// this_device so the key never travels in a backup the store isn't in
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
    aOptions: AndroidOptions(),
  );

  static Future<String?> read() => _storage.read(key: _name);

  static Future<String> create() async {
    final random = Random.secure();
    final key = List.generate(
      32,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    await _storage.write(key: _name, value: key);
    return key;
  }
}
