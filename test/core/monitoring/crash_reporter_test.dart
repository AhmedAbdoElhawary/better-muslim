import 'package:better_muslim/core/monitoring/crash_reporter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  test('the cap drops an error type after three events, other types still pass', () {
    final cap = SentryEventCap();
    final results = [
      for (var i = 0; i < 4; i++) cap(SentryEvent(throwable: StateError('x')), Hint()),
    ];

    expect(results.map((event) => event != null), [true, true, true, false]);
    expect(cap(SentryEvent(throwable: ArgumentError('y')), Hint()), isNotNull);
  });
}
