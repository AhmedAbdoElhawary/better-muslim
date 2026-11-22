import 'package:better_muslim/core/monitoring/crash_reporter.dart';

class FakeCrashReporter implements CrashReporter {
  final errors = <Object>[];
  final breadcrumbs = <String>[];
  final feedback = <({String message, String? email})>[];

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
    Map<String, Object?>? context,
  }) async => errors.add(error);

  @override
  void addBreadcrumb(String message, {String? category}) => breadcrumbs.add(message);

  @override
  Future<void> sendFeedback(String message, {String? email}) async =>
      feedback.add((message: message, email: email));
}
