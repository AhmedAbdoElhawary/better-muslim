import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// work a cold open can do later waits for this, so it takes no frames from Home's first second.
/// bootstrap gives the real wait, a test is settled at once
final launchSettledProvider = Provider<Future<void>>((ref) => Future.value());

Future<void> launchSettled() async {
  /// a phone asleep at launch draws nothing until it wakes, the schedule can't wait for that
  await Future.any([
    WidgetsBinding.instance.waitUntilFirstFrameRasterized,
    Future<void>.delayed(const Duration(seconds: 3)),
  ]);
  await Future<void>.delayed(const Duration(seconds: 1));
}
