import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:better_muslim/core/backup/restore.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/database/civil_date.dart';
import 'package:better_muslim/core/monitoring/crash_reporter.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/isolate.dart' show DriftRemoteException;
import 'package:drift/native.dart' show SqliteException;
import 'package:path_provider/path_provider.dart';

/// why a file can't be restored, each with its own line in the restore sheet (FR-031, FR-034)
enum BackupError {
  notABackup(StringsManager.notABackup),
  damaged(StringsManager.damagedBackup),
  newer(StringsManager.newerBackup),
  wrongPassword(StringsManager.wrongPassword);

  const BackupError(this.key);

  /// a StringsManager key
  final String key;
}

/// the 19 byte header in front of the store (contracts/backup-file.md)
const _magic = 'BMBACKUP';
const _format = 1;
const _headerLength = 19;

/// sqlite's "file is not a database", what a wrong key gives
const _notADatabase = 26;

const _payloadName = 'backup.payload';
const _restoreName = 'restore.payload';

/// the store copied into a new file locked with the password, the phone's own columns left out.
/// the caller shares it and deletes it
Future<File> writeBackup(AppDatabase from, String password, {required DateTime now}) async {
  final temp = await getTemporaryDirectory();
  final payload = File('${temp.path}/$_payloadName');
  _delete(payload);
  try {
    final store = AppDatabase.backup(payload, password);
    try {
      await copyTables(from, store);
      await store.updateSettings(
        const SettingsCompanion(
          onboarded: Value(false),
          notificationsAsked: Value(false),
          storeResetPending: Value(false),
        ),
      );
    } finally {
      await store.close();
    }
    final bytes = await payload.readAsBytes();
    final header = ByteData(_headerLength)
      ..setUint8(8, _format)
      ..setUint16(9, from.schemaVersion)
      ..setUint64(11, bytes.length);
    final head = header.buffer.asUint8List()..setAll(0, ascii.encode(_magic));
    final file = File('${temp.path}/better-muslim-${const CivilDate().toSql(now)}.bmbackup');
    await file.writeAsBytes([...head, ...bytes], flush: true);
    return file;
  } finally {
    _delete(payload);
  }
}

/// what the header alone says, before any password. null = it looks like a backup this app reads
BackupError? checkBackup(Uint8List bytes, {required int schemaVersion}) {
  if (bytes.length < _magic.length ||
      ascii.decode(bytes.sublist(0, _magic.length), allowInvalid: true) != _magic) {
    return BackupError.notABackup;
  }
  if (bytes.length < _headerLength) return BackupError.damaged;
  final header = ByteData.sublistView(bytes, 0, _headerLength);

  /// a later format is another cipher setup, only a newer app reads it
  if (header.getUint8(8) > _format || header.getUint16(9) > schemaVersion) {
    return BackupError.newer;
  }
  if (bytes.length < _headerLength + header.getUint64(11)) return BackupError.damaged;
  return null;
}

/// the backup's store, opened with the password and upgraded to this app's schema. the caller
/// restores from it, then closes it with closeBackup
Future<(AppDatabase?, BackupError?)> readBackup(
  File file,
  String password, {
  required int schemaVersion,
}) async {
  final temp = await getTemporaryDirectory();
  final payload = File('${temp.path}/$_restoreName');
  AppDatabase? store;
  try {
    final bytes = await file.readAsBytes();
    final error = checkBackup(bytes, schemaVersion: schemaVersion);
    if (error != null) return (null, error);
    final length = ByteData.sublistView(bytes, 0, _headerLength).getUint64(11);
    _delete(payload);
    await payload.writeAsBytes(bytes.sublist(_headerLength, _headerLength + length), flush: true);
    store = AppDatabase.backup(payload, password);

    /// the first read opens the store, a wrong key fails here before any migration
    try {
      await store.customSelect('select count(*) from sqlite_master').get();
    } catch (error) {
      await _discard(store, payload);
      return (
        null,
        _code(error) == _notADatabase ? BackupError.wrongPassword : BackupError.damaged,
      );
    }
    try {
      final check = await store.customSelect('pragma quick_check').getSingle();
      if (check.data.values.first != 'ok') throw StateError('quick check');
    } catch (_) {
      await _discard(store, payload);
      return (null, BackupError.damaged);
    }
    return (store, null);
  } catch (error, stack) {
    if (store != null) await _discard(store, payload);
    await CrashReporter.instance.recordError(error, stack, context: {'reason': 'read backup'});
    return (null, BackupError.damaged);
  }
}

/// the restore is over, done or not
Future<void> closeBackup(AppDatabase store) async {
  final temp = await getTemporaryDirectory();
  await _discard(store, File('${temp.path}/$_restoreName'));
}

/// the store runs in its own isolate, its errors come back wrapped
int? _code(Object error) => switch (error) {
  SqliteException(:final resultCode) => resultCode,
  DriftRemoteException(remoteCause: SqliteException(:final resultCode)) => resultCode,
  _ => null,
};

Future<void> _discard(AppDatabase store, File payload) async {
  await store.close();
  _delete(payload);
}

void _delete(File file) {
  for (final suffix in ['', '-wal', '-shm', '-journal']) {
    final leftover = File('${file.path}$suffix');
    if (leftover.existsSync()) leftover.deleteSync();
  }
}
