import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AudioUse { none, recitation, adhan }

final audioUseProvider = NotifierProvider<AudioUseNotifier, AudioUse>(AudioUseNotifier.new);

/// one voice at a time: the latest claim wins and whoever held it pauses
class AudioUseNotifier extends Notifier<AudioUse> {
  @override
  AudioUse build() => AudioUse.none;

  void claim(AudioUse use) => state = use;

  /// only the holder lets go, a late release of the recitation never frees the adhan
  void release(AudioUse use) {
    if (state == use) state = AudioUse.none;
  }
}
