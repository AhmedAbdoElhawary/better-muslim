import 'dart:async';

import 'package:better_muslim/core/flavor/flavor_config.dart';
import 'package:better_muslim/core/monitoring/crash_reporter.dart';
import 'package:better_muslim/core/resources/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Sentry runs only in release builds that have a DSN, so local runs never send anything
abstract final class Monitoring {
  static const bool isEnabled = kCustomReleaseMode;

  static Future<void> start({
    required FlavorConfig config,
    required Future<void> Function() appRunner,
  }) async {
    if (!_sentryEnabledFor(config)) {
      final completer = Completer<void>();
      runZonedGuarded(() async {
        await appRunner();
        if (!completer.isCompleted) completer.complete();
      }, (error, stackTrace) => CrashReporter.instance.recordError(error, stackTrace, fatal: true));
      return completer.future;
    }

    await SentryFlutter.init((options) => _configure(options, config), appRunner: appRunner);
  }

  /// a background engine has no app around it, so errors only, no sessions and no traces
  static Future<void> runInBackground(Future<void> Function() task) async {
    final config = FlavorConfig.fromEnvironment();
    if (_sentryEnabledFor(config) && !Sentry.isEnabled) {
      await Sentry.init((options) => _configureShared(options, config));
      CrashReporter.instance = const SentryCrashReporter();
    }
    try {
      await task();
    } catch (error, stackTrace) {
      await CrashReporter.instance.recordError(error, stackTrace, fatal: true);
      rethrow;
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

  static void activate({required FlavorConfig config}) {
    if (!_sentryEnabledFor(config)) return;
    CrashReporter.instance = const SentryCrashReporter();
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
  }

  @visibleForTesting
  static void debugReset() {
    CrashReporter.instance = const DebugCrashReporter();
  }
}
