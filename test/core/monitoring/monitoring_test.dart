import 'package:better_muslim/core/monitoring/crash_reporter.dart';
import 'package:better_muslim/core/monitoring/monitoring.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/crash_reporter.dart';

void main() {
  late FakeCrashReporter reporter;

  setUp(() => CrashReporter.instance = reporter = FakeCrashReporter());
  tearDown(Monitoring.debugReset);

  test('a background task that fails is recorded and still fails', () async {
    final error = StateError('x');

    await expectLater(Monitoring.runInBackground(() async => throw error), throwsStateError);

    expect(reporter.errors, [error]);
  });

  test('a background task that works records nothing', () async {
    var ran = false;

    await Monitoring.runInBackground(() async => ran = true);

    expect(ran, isTrue);
    expect(reporter.errors, isEmpty);
  });
}
