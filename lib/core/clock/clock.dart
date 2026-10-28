import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 24 hours in 5 minutes from when it is turned on, from the dev page. off each launch
final fastDayProvider = NotifierProvider<FastDay, bool>(FastDay.new);

class FastDay extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool on) => state = on;
}

/// every "now" in the app comes from here, so tests, the design scenario and the fast day move it
final clockProvider = Provider<DateTime Function()>((ref) {
  if (!ref.watch(fastDayProvider)) return DateTime.now;
  final start = DateTime.now();
  final watch = Stopwatch()..start();
  return () => start.add(watch.elapsed * 288);
});

/// fires on each whole second of the wall clock, so the countdown changes with the phone's clock
final tickerProvider = StreamProvider<DateTime>((ref) {
  final clock = ref.watch(clockProvider);
  final fast = ref.watch(fastDayProvider);
  final controller = StreamController<DateTime>();
  Timer? timer;
  void tick() {
    final now = clock();
    controller.add(now);

    /// re-armed every tick from the clock, a periodic timer drifts away from the second. a fast
    /// day has no whole second, 10 a second keeps the sun smooth
    timer = Timer(
      fast ? const Duration(milliseconds: 100) : Duration(milliseconds: 1000 - now.millisecond),
      tick,
    );
  }

  tick();
  ref.onDispose(() {
    timer?.cancel();
    controller.close();
  });
  return controller.stream;
});
