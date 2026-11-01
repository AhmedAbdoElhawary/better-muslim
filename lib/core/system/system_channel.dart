import 'package:flutter/services.dart';

/// the phone's notification settings, links, mail, the version and the device, without five
/// packages (R10)
abstract final class SystemChannel {
  static const _channel = MethodChannel('better_muslim/system');

  static Future<void> openNotificationSettings() =>
      _channel.invokeMethod<void>('openNotificationSettings');

  /// https only, nothing else ever leaves the app (constitution VII)
  static Future<bool> openUrl(String url) async {
    if (Uri.tryParse(url)?.scheme != 'https') return false;
    return await _channel.invokeMethod<bool>('openUrl', {'url': url}) ?? false;
  }

  /// "1.0.0 (12)"
  static Future<String> version() async => await _channel.invokeMethod<String>('version') ?? '';

  /// a draft in the mail app, I send it or not. the only way to a mailto
  static Future<bool> mail({
    required String to,
    required String subject,
    required String body,
  }) async =>
      await _channel.invokeMethod<bool>('mail', {'to': to, 'subject': subject, 'body': body}) ??
      false;

  /// "iPhone15,2" and "iOS 26.1", for the feedback mail
  static Future<({String model, String os})> device() async {
    final info = await _channel.invokeMapMethod<String, String>('device');
    return (model: info?['model'] ?? '', os: info?['os'] ?? '');
  }

  /// the sound a tone notification makes: the channel's on android, ios' default on ios
  static Future<void> playTone(String channel) =>
      _channel.invokeMethod<void>('playTone', {'channel': channel});

  /// the reader's setting, cleared again when the reader closes
  static Future<void> keepScreenOn(bool on) =>
      _channel.invokeMethod<void>('keepScreenOn', {'on': on});
}
