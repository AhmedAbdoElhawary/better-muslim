import 'package:better_muslim/core/monitoring/crash_reporter.dart';
import 'package:flutter/services.dart';

/// iOS backs Application Support up to iCloud, the store must stay on this phone (FR-023).
/// android turns backups off in its manifest instead
abstract final class BackupExclusion {
  static const _channel = MethodChannel('better_muslim/backup');

  /// a failure is reported, not thrown, so the app still starts
  static Future<void> exclude(String path) async {
    try {
      await _channel.invokeMethod('exclude', path);
    } on PlatformException catch (error, stack) {
      await CrashReporter.instance.recordError(
        error,
        stack,
        context: {'reason': 'backup exclusion'},
      );
    }
  }
}
