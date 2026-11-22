import 'package:better_muslim/core/audio/audio_use.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the adhan takes over and a late recitation release leaves it', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final use = container.read(audioUseProvider.notifier);

    use.claim(AudioUse.recitation);
    use.claim(AudioUse.adhan);
    use.release(AudioUse.recitation);
    expect(container.read(audioUseProvider), AudioUse.adhan);

    use.release(AudioUse.adhan);
    expect(container.read(audioUseProvider), AudioUse.none);
  });
}
