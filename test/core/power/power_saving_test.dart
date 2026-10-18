import 'package:better_muslim/core/power/power_saving.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('better_muslim/power');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  Future<bool> read() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container.read(powerSavingProvider.future);
  }

  void answer(bool saving) => messenger.setMockMethodCallHandler(
    channel,
    (call) async => call.method == 'isPowerSaving' ? saving : null,
  );

  test('low power mode or battery saver on', () async {
    answer(true);

    expect(await read(), isTrue);
  });

  test('off', () async {
    answer(false);

    expect(await read(), isFalse);
  });

  test('a phone without the handler counts as off', () async {
    expect(await read(), isFalse);
  });
}
