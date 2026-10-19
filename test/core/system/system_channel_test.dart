import 'package:better_muslim/core/system/system_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('better_muslim/system'),
      (call) async {
        calls.add(call);
        return switch (call.method) {
          'openUrl' => true,
          'version' => '1.0.0 (12)',
          _ => null,
        };
      },
    );
  });

  test('opens the notification settings', () async {
    await SystemChannel.openNotificationSettings();
    expect(calls.single.method, 'openNotificationSettings');
  });

  test('passes an https link', () async {
    expect(await SystemChannel.openUrl('https://www.geonames.org'), isTrue);
    expect(calls.single.arguments, {'url': 'https://www.geonames.org'});
  });

  test('refuses anything not https before it reaches the phone', () async {
    expect(await SystemChannel.openUrl('http://www.geonames.org'), isFalse);
    expect(await SystemChannel.openUrl('mailto:me@example.com'), isFalse);
    expect(calls, isEmpty);
  });

  test('reads the version and build', () async {
    expect(await SystemChannel.version(), '1.0.0 (12)');
  });
}
