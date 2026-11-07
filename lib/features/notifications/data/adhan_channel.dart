import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adhanChannelProvider = Provider<AdhanChannel>((ref) => AdhanChannel());

/// the kotlin side that plays the full adhan on android (contracts/adhan-channel.md).
/// every call does nothing off android
class AdhanChannel {
  static const _methods = MethodChannel('better_muslim/adhan');
  static const _state = EventChannel('better_muslim/adhan/state');
  static const _opened = EventChannel('better_muslim/adhan/opened');

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  Future<void> schedule(List<Map<String, Object?>> entries) => _call('schedule', entries);

  Future<void> cancelAll() => _call('cancelAll');

  /// false when the phone is on silent, vibrate or do not disturb and nothing plays
  Future<bool> play(Map<String, Object?> entry, {Duration from = Duration.zero}) async {
    if (!_isAndroid) return false;
    return await _methods.invokeMethod<bool>('play', {
          'entry': entry,
          'fromMillis': from.inMilliseconds,
        }) ??
        false;
  }

  Future<void> pause() => _call('pause');

  Future<void> resume() => _call('resume');

  Future<void> stop() => _call('stop');

  Future<void> markPrayedAction(int id) => _call('markPrayedAction', id);

  Future<Duration?> length(String asset) async {
    if (!_isAndroid) return null;
    final millis = await _methods.invokeMethod<int>('length', asset);
    return millis == null ? null : Duration(milliseconds: millis);
  }

  /// the dev page's check, null off android
  Future<bool?> canSound() async {
    if (!_isAndroid) return null;
    return _methods.invokeMethod<bool>('canSound');
  }

  Future<void> dismiss(int id) => _call('dismiss', id);

  /// the payload of the notification that started the app, given once
  Future<String?> launchPayload() async {
    if (!_isAndroid) return null;
    return _methods.invokeMethod<String>('launchPayload');
  }

  /// one stream, flutter sends an event channel only to the newest one made from it
  late final Stream<Map<Object?, Object?>> state = _isAndroid
      ? _state.receiveBroadcastStream().cast<Map<Object?, Object?>>()
      : const Stream.empty();

  /// payloads of adhan notifications tapped while the app runs
  Stream<String> get opened =>
      _isAndroid ? _opened.receiveBroadcastStream().cast<String>() : const Stream.empty();

  Future<void> _call(String method, [Object? arguments]) async {
    if (!_isAndroid) return;
    await _methods.invokeMethod<void>(method, arguments);
  }
}
