import 'package:flutter/services.dart';

/// the phone's notification settings, links and the version, without three packages (R10)
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
}
