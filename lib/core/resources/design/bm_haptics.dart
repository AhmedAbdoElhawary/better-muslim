import 'package:flutter/services.dart';

/// Haptics map (05 Motion › Haptics). Respect the in-app Haptics switch; the OS switch always wins.
abstract final class BmHaptics {
  static bool enabled = true;
  static Future<void> bead() => _run(HapticFeedback.lightImpact); // every tasbih count
  static Future<void> setComplete() async {
    if (!enabled) return;
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.mediumImpact();
  }

  static Future<void> markPrayed() => _run(HapticFeedback.lightImpact);
  static Future<void> dayComplete() => _run(HapticFeedback.mediumImpact);
  static Future<void> qiblaApproach() =>
      _run(HapticFeedback.selectionClick); // once when entering ±10°
  static Future<void> qiblaAligned() =>
      _run(HapticFeedback.mediumImpact); // once per alignment (±3° for 400 ms)
  static Future<void> selection() => _run(
    HapticFeedback.selectionClick,
  ); // toggles, segmented, sheet detents, page settle (off by default)
  static Future<void> _run(Future<void> Function() f) async {
    if (enabled) await f();
  }
}
// Never: Living Sky, countdown, sky change, adhan reveal, tab switch, sheet opening.
