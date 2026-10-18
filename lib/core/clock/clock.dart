import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// every "now" in the app comes from here, so tests and the design scenario can freeze it
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// fires on each whole second of the wall clock, so the countdown changes with the phone's clock
final tickerProvider = StreamProvider<DateTime>((ref) {
  final clock = ref.watch(clockProvider);
  final controller = StreamController<DateTime>();
  Timer? timer;
  void tick() {
    final now = clock();
    controller.add(now);

    /// re-armed every tick from the clock, a periodic timer drifts away from the second
    timer = Timer(Duration(milliseconds: 1000 - now.millisecond), tick);
  }

  tick();
  ref.onDispose(() {
    timer?.cancel();
    controller.close();
  });
  return controller.stream;
});
