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

  test('a failed write loses the statement and the note that was in it', () {
    final event = SentryEvent(
      exceptions: [
        SentryException(
          type: 'SqliteException',
          value:
              'SqliteException(1555): while executing, UNIQUE constraint failed\n'
              '  Causing statement: INSERT INTO notes (body) VALUES (?), parameters: my private note',
        ),
      ],
    );

    final value = scrubbed(event).exceptions!.single.value!;

    expect(value, contains('UNIQUE constraint failed'));
    expect(value, isNot(contains('INSERT')));
    expect(value, isNot(contains('my private note')));
  });

  test('a url in an error is taken out', () {
    final event = SentryEvent(
      exceptions: [
        SentryException(type: 'x', value: 'failed https://cdn.example.com/ayah/2/255.mp3 at 3'),
      ],
    );

    expect(scrubbed(event).exceptions!.single.value, 'failed <url> at 3');
  });

  test('an event with no text passes as it is', () {
    final event = SentryEvent(exceptions: [SentryException(type: 'x', value: null)]);

    expect(scrubbed(event).exceptions!.single.value, isNull);
    expect(scrubbed(SentryEvent()).exceptions, isNull);
  });
}
