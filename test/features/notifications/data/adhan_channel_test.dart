import 'package:better_muslim/features/notifications/data/adhan_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a late listener takes no events from the first, kotlin is listened to once', () async {
    var listens = 0;
    late MockStreamHandlerEventSink sink;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockStreamHandler(
      const EventChannel('better_muslim/adhan/state'),
      MockStreamHandler.inline(
        onListen: (_, events) {
          listens++;
          sink = events;
        },
      ),
    );
    final channel = AdhanChannel();
    final first = <Map<Object?, Object?>>[];
    final late = <Map<Object?, Object?>>[];

    final page = channel.state.listen(first.add);
    await pumpEventQueue();
    final other = channel.state.listen(late.add);
    await pumpEventQueue();
    sink.success({'id': 1});
    await pumpEventQueue();

    expect(first, hasLength(1));
    expect(late, hasLength(1));
    expect(listens, 1);
    await page.cancel();
    await other.cancel();
  });
}
