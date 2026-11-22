import 'package:better_muslim/core/resources/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// app code reports through instance, never Sentry directly, so debug runs and tests send nothing
abstract class CrashReporter {
  static CrashReporter instance = const DebugCrashReporter();

  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
    Map<String, Object?>? context,
  });

  void addBreadcrumb(String message, {String? category});

  /// what someone writes on the feedback page, reaches my mail through sentry's user feedback
  Future<void> sendFeedback(String message, {String? email});
}

class SentryCrashReporter implements CrashReporter {
  const SentryCrashReporter();

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
    Map<String, Object?>? context,
  }) async {
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: context == null ? null : (scope) => scope.setContexts('error_context', context),
    );
  }

  @override
  void addBreadcrumb(String message, {String? category}) {
    Sentry.addBreadcrumb(Breadcrumb(message: message, category: category));
  }

  @override
  Future<void> sendFeedback(String message, {String? email}) async {
    await Sentry.captureFeedback(SentryFeedback(message: message, contactEmail: email));
  }
}

final _url = RegExp(r'https?://\S+');

/// sqlite prints the row it failed on, which can be a note, and a url says what someone was playing
SentryEvent scrubbed(SentryEvent event) {
  for (final exception in event.exceptions ?? const <SentryException>[]) {
    exception.value = exception.value?.split('Causing statement').first.replaceAll(_url, '<url>');
  }
  return event;
}

/// one error in a loop would eat the free monthly quota
class SentryEventCap {
  SentryEventCap({this.maxPerErrorType = 3});

  final int maxPerErrorType;
  final Map<String, int> _seen = {};

  SentryEvent? call(SentryEvent event, Hint hint) {
    final key =
        event.throwable?.runtimeType.toString() ?? event.exceptions?.firstOrNull?.type ?? 'unknown';
    final count = (_seen[key] ?? 0) + 1;
    _seen[key] = count;
    return count > maxPerErrorType ? null : event;
  }
}

/// errors before the crash reports switch is read wait here, then go to sentry or nowhere
class PendingCrashReporter implements CrashReporter {
  final errors = <({Object error, StackTrace? stackTrace, Map<String, Object?>? context})>[];

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
    Map<String, Object?>? context,
  }) async {
    errors.add((error: error, stackTrace: stackTrace, context: context));
  }

  @override
  void addBreadcrumb(String message, {String? category}) {}

  @override
  Future<void> sendFeedback(String message, {String? email}) async {}

  Future<void> flushTo(CrashReporter reporter) async {
    for (final entry in errors) {
      await reporter.recordError(entry.error, entry.stackTrace, context: entry.context);
    }
    errors.clear();
  }
}

class DebugCrashReporter implements CrashReporter {
  const DebugCrashReporter();

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
    Map<String, Object?>? context,
  }) async {
    if (!kCustomDebugMode) return;
    debugPrint('[Crash]${fatal ? '[FATAL]' : ''} $error');
    if (context != null && context.isNotEmpty) debugPrint('[Crash] context: $context');
    if (stackTrace != null) debugPrint('$stackTrace');
  }

  @override
  void addBreadcrumb(String message, {String? category}) {
    if (!kCustomDebugMode) return;
    debugPrint('[Crash][breadcrumb]${category != null ? '[$category]' : ''} $message');
  }

  @override
  Future<void> sendFeedback(String message, {String? email}) async {
    if (!kCustomDebugMode) return;
    debugPrint('[Feedback]${email != null ? '[$email]' : ''} $message');
  }
}
