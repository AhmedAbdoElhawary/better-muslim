import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 24 hours in 5 minutes from when it is turned on, from the dev page. off each launch
final fastDayProvider = NotifierProvider<FastDay, bool>(FastDay.new);

class FastDay extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool on) => state = on;
}

/// how much faster a fast day's clock runs
const fastDaySpeed = 288;

/// every "now" in the app comes from here, so tests, the design scenario and the fast day move it
final clockProvider = Provider<DateTime Function()>((ref) {
  if (!ref.watch(fastDayProvider)) return DateTime.now;
  final start = DateTime.now();
  final watch = Stopwatch()..start();
  return () => start.add(watch.elapsed * fastDaySpeed);
});

/// fires on each whole second of the wall clock, so the countdown changes with the phone's clock.
/// only for a countdown with seconds, what changes at a boundary follows boundaryProvider
final tickerProvider = StreamProvider<DateTime>((ref) => _ticks(ref, const Duration(seconds: 1)));

/// fires on each whole minute, for what moves too slowly to need the second
final minuteProvider = StreamProvider<DateTime>((ref) => _ticks(ref, const Duration(minutes: 1)));

Stream<DateTime> _ticks(Ref ref, Duration every) {
  final clock = ref.watch(clockProvider);
  final fast = ref.watch(fastDayProvider);
  final controller = StreamController<DateTime>();
  Timer? timer;
  int? sent;
  void tick() {
    timer?.cancel();
    final now = clock();
    final step = now.millisecondsSinceEpoch ~/ every.inMilliseconds;

    /// a watcher's rebuild pauses and resumes this, sending the same step again rebuilds it again
    if (step != sent) {
      sent = step;
      controller.add(now);
    }

    /// re-armed every tick from the clock, a periodic timer drifts away from the second. a fast
    /// day has no whole second, 10 a second keeps the sun smooth
    final left = every.inMilliseconds - now.millisecondsSinceEpoch % every.inMilliseconds;
    timer = Timer(fast ? const Duration(milliseconds: 100) : Duration(milliseconds: left), tick);
  }

  tick();

  /// nothing on screen shows it, so it stops instead of waking the app every second
  ref.onCancel(() => timer?.cancel());
  ref.onResume(tick);
  ref.onDispose(() {
    timer?.cancel();
    controller.close();
  });
  return controller.stream;
}
