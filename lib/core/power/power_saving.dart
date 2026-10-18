import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _channel = MethodChannel('better_muslim/power');

/// low power mode or battery saver, ambient motion pauses on it (MOTION tiers). read again on
/// every resume, the os sends no change event without more native code
final powerSavingProvider = FutureProvider<bool>((ref) async {
  final listener = AppLifecycleListener(onResume: ref.invalidateSelf);
  ref.onDispose(listener.dispose);
  try {
    return await _channel.invokeMethod<bool>('isPowerSaving') ?? false;
  } on MissingPluginException {
    return false;
  } on PlatformException {
    return false;
  }
});
