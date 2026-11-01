import 'package:flutter_riverpod/flutter_riverpod.dart';

/// clip is a dua or an adhan preview
enum AudioUse { none, recitation, adhan, clip }

final audioUseProvider = NotifierProvider<AudioUseNotifier, AudioUse>(AudioUseNotifier.new);

/// one voice at a time: the latest claim wins and whoever held it pauses
class AudioUseNotifier extends Notifier<AudioUse> {
  @override
  AudioUse build() => AudioUse.none;

  void claim(AudioUse use) => state = use;

  /// only the holder lets go, a late release of the recitation never frees the adhan
  void release(AudioUse use) {
    if (ref.mounted && state == use) state = AudioUse.none;
  }
}
