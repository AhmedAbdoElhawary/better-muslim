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
}
