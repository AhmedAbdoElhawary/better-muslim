import 'dart:async';

import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/flavor/flavor_config.dart';
import 'package:better_muslim/core/monitoring/crash_reporter.dart';
import 'package:better_muslim/core/resources/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Sentry runs only in release builds that have a DSN, so local runs never send anything
abstract final class Monitoring {
  static const bool isEnabled = kCustomReleaseMode;

  /// sentry waits for the crash reports switch in the store, follow starts it
  static Future<void> start({
    required FlavorConfig config,
    required Future<void> Function() appRunner,
  }) {
    if (_sentryEnabledFor(config)) CrashReporter.instance = PendingCrashReporter();
    final completer = Completer<void>();
    runZonedGuarded(() async {
      await appRunner();
      if (!completer.isCompleted) completer.complete();
    }, (error, stackTrace) => CrashReporter.instance.recordError(error, stackTrace, fatal: true));
    return completer.future;
  }

  /// the switch at boot with the saved row, then on every change. off drops what waited
  static Future<void> follow({required FlavorConfig config, required bool on}) async {
    if (!_sentryEnabledFor(config)) return;
    final pending = CrashReporter.instance;
    if (on && !Sentry.isEnabled) {
      await SentryFlutter.init((options) => _configure(options, config));
    } else if (!on && Sentry.isEnabled) {
      await Sentry.close();
    }

    /// after init, so ours replace sentry's handlers and an error isn't sent twice
    installErrorHandlers();
    CrashReporter.instance = on ? const SentryCrashReporter() : _FeedbackOnly(config);
    if (on && pending is PendingCrashReporter) await pending.flushTo(CrashReporter.instance);
  }

  /// a background engine has no app around it, so errors only, no sessions and no traces.
  /// sentry starts only for an error, and only with the switch on
  static Future<void> runInBackground(Future<void> Function() task) async {
    final config = FlavorConfig.fromEnvironment();
    final pending = PendingCrashReporter();
    if (_sentryEnabledFor(config) && !Sentry.isEnabled) CrashReporter.instance = pending;
    try {
      await task();
    } catch (error, stackTrace) {
      await CrashReporter.instance.recordError(error, stackTrace, fatal: true);
      rethrow;
    } finally {
      if (pending.errors.isNotEmpty && await _crashReportsOn()) {
        await Sentry.init((options) => _configureShared(options, config));
        await pending.flushTo(const SentryCrashReporter());
        await Sentry.close();
      }
    }
  }

  /// a store that can't be opened can't say the switch is on
  static Future<bool> _crashReportsOn() async {
    final db = await AppDatabase.openExisting();
    if (db == null) return false;
    try {
      return (await db.watchSettings().first).crashReports;
    } finally {
      await db.close();
    }
  }

  static void installErrorHandlers() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      CrashReporter.instance.recordError(
        details.exception,
        details.stack,
        fatal: true,
        context: {'library': details.library ?? 'unknown'},
      );
    };

    /// errors from platform channels and native code never reach FlutterError
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      CrashReporter.instance.recordError(error, stackTrace, fatal: true);
      return true;
    };
  }

  static bool _sentryEnabledFor(FlavorConfig config) => isEnabled && config.sentryDsn.isNotEmpty;

  static void _configure(SentryFlutterOptions options, FlavorConfig config) {
    _configureShared(options, config);
    options.enableAutoSessionTracking = true;
    options.tracesSampleRate = config.flavor.isProduction ? 0.1 : 1.0;
  }

  static void _configureShared(SentryOptions options, FlavorConfig config) {
    options.dsn = config.sentryDsn;
    options.environment = config.flavor.name;

    /// no emails, usernames or ip addresses, what someone prays stays private
    options.sendDefaultPii = false;
    options.enablePrintBreadcrumbs = false;
    final cap = SentryEventCap();
    options.beforeSend = (event, hint) => cap(scrubbed(event), hint);

    /// without it feedback goes through beforeSend, and the cap drops the fourth
    options.beforeSendFeedback = (event, hint) => event;
  }

  @visibleForTesting
  static void debugReset() {
    CrashReporter.instance = const DebugCrashReporter();
  }
}

/// the switch is about crash reports, a message someone writes on the feedback page still goes
class _FeedbackOnly implements CrashReporter {
  const _FeedbackOnly(this.config);

  final FlavorConfig config;

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
    Map<String, Object?>? context,
  }) async {}

  @override
  void addBreadcrumb(String message, {String? category}) {}

  @override
  Future<void> sendFeedback(String message, {String? email}) async {
    await Sentry.init((options) => Monitoring._configureShared(options, config));
    try {
      await const SentryCrashReporter().sendFeedback(message, email: email);
    } finally {
      await Sentry.close();
    }
  }
}
