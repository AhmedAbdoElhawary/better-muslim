import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final surfacesChannelProvider = Provider<SurfacesChannel>((ref) => SurfacesChannel());

/// packages/prayer_surfaces, the widgets, the live activity and the android countdown
/// (contracts/surfaces-channel.md)
class SurfacesChannel {
  static const _methods = MethodChannel('better_muslim/surfaces');

  /// the plugin skips the file when it holds the same json, force writes it anyway
  Future<void> update(String json, {bool force = false}) =>
      _methods.invokeMethod<void>('update', {'json': json, 'force': force});

  /// the next prayer's countdown from now, whatever the 2 hours. false when the phone refused it
  Future<bool> startNow() async => await _methods.invokeMethod<bool>('startNow') ?? false;
}
