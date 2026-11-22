import 'package:better_muslim/core/clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// testWidgets for its fake time, the clock moves with it
  testWidgets('ticks on the wall clock second and never drifts (R5)', (tester) async {
    final start = DateTime(2026, 10, 15, 10, 0, 0, 700);
    final origin = tester.binding.clock.now();
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(
          () => start.add(tester.binding.clock.now().difference(origin)),
        ),
      ],
    );
    final ticks = <DateTime>[];
    container.listen(tickerProvider, (_, next) {
      if (next.value case final now?) ticks.add(now);
    });
    await tester.pump();

    expect(ticks, [start]);

    await tester.pump(const Duration(milliseconds: 299));
    expect(ticks, hasLength(1));
    await tester.pump(const Duration(milliseconds: 1));
    expect(ticks.last, DateTime(2026, 10, 15, 10, 0, 1));

    await tester.pump(const Duration(minutes: 5));
    expect(ticks, hasLength(2 + 300));
    expect(ticks.skip(1).every((tick) => tick.millisecond == 0 && tick.microsecond == 0), isTrue);
    expect(ticks.last, DateTime(2026, 10, 15, 10, 5, 1));

    container.dispose();
  });

  testWidgets('stops while nothing on screen shows it, ticks at once when back', (tester) async {
    final start = DateTime(2026, 10, 15, 10, 0, 0, 500);
    final origin = tester.binding.clock.now();
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(
          () => start.add(tester.binding.clock.now().difference(origin)),
        ),
      ],
    );
    final ticks = <DateTime>[];
    final sub = container.listen(tickerProvider, (_, next) {
      if (next.value case final now?) ticks.add(now);
    });
    await tester.pump();

    sub.pause();
    await tester.pump(const Duration(minutes: 1));
    expect(ticks, [start]);

    sub.resume();
    await tester.pump();
    expect(ticks.last, DateTime(2026, 10, 15, 10, 1, 0, 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(ticks.last, DateTime(2026, 10, 15, 10, 1, 1));

    container.dispose();
  });

  testWidgets('the minute ticker ticks on the wall clock minute', (tester) async {
    final start = DateTime(2026, 10, 15, 10, 0, 40);
    final origin = tester.binding.clock.now();
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(
          () => start.add(tester.binding.clock.now().difference(origin)),
        ),
      ],
    );
    final ticks = <DateTime>[];
    container.listen(minuteProvider, (_, next) {
      if (next.value case final now?) ticks.add(now);
    });
    await tester.pump();

    await tester.pump(const Duration(seconds: 20));
    await tester.pump(const Duration(minutes: 2));
    expect(ticks, [
      start,
      DateTime(2026, 10, 15, 10, 1),
      DateTime(2026, 10, 15, 10, 2),
      DateTime(2026, 10, 15, 10, 3),
    ]);

    container.dispose();
  });

  /// a provider rebuilding pauses what it watches, a ticker it is the only one on must not tick
  /// again on its resume, or the two keep each other going every frame
  testWidgets('a rebuild of its only watcher does not tick again', (tester) async {
    final start = DateTime(2026, 10, 15, 10, 0, 10);
    final origin = tester.binding.clock.now();
    var builds = 0;
    var reads = 0;
    final watcher = Provider<void>((ref) {
      builds++;

      /// stops watching, so a loop fails the test instead of hanging it
      if (builds < 10) ref.watch(minuteProvider);
    });
    final container = ProviderContainer(
      overrides: [
        /// fake time stands still inside a pump, a real clock has moved on by the next read
        clockProvider.overrideWithValue(
          () => start.add(
            tester.binding.clock.now().difference(origin) + Duration(microseconds: reads++),
          ),
        ),
      ],
    );
    container.listen(watcher, (_, _) {});
    for (var i = 0; i < 300; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    /// loading, then the first minute
    expect(builds, 2);

    await tester.pump(const Duration(seconds: 20));
    expect(builds, 3);

    container.dispose();
  });
}
