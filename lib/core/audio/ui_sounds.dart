import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// the brand board's ui sounds, next to their haptics. App copies the setting into [enabled]
abstract final class BmSounds {
  static bool enabled = false;

  /// set while the adhan or a clip plays, a tap sound never plays over them
  static bool busy = false;

  @visibleForTesting
  static SoundOutput output = JustAudioSoundOutput();

  // TODO(ahmed): these are placeholder tones, put the brand board's Bead (40 ms), Complete (600 ms) and Aligned (300 ms) at -24 LUFS under the same names.
  static const _bead = 'assets/audio/ui_bead.m4a';
  static const _complete = 'assets/audio/ui_complete.m4a';
  static const _aligned = 'assets/audio/ui_aligned.m4a';

  static Future<void> bead() => _play(_bead);
  static Future<void> complete() => _play(_complete);
  static Future<void> aligned() => _play(_aligned);

  static Future<void> _play(String asset) async {
    if (!enabled || busy) return;
    if (!await output.canPlay()) return;
    await output.play(asset);
  }
}

/// the one thing the tests replace, so no test reaches the phone's audio
abstract class SoundOutput {
  /// false with the phone on silent or vibrate
  Future<bool> canPlay();
  Future<void> play(String asset);
}

class JustAudioSoundOutput implements SoundOutput {
  final _players = <String, AudioPlayer>{};

  @override
  Future<bool> canPlay() async {
    if (Platform.isAndroid) {
      return await AndroidAudioManager().getRingerMode() == AndroidRingerMode.normal;
    }

    /// ambient follows the silent switch and mixes with other apps, the adhan sets music again
    final session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.ambient,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
      ),
    );
    return true;
  }

  @override
  Future<void> play(String asset) async {
    var player = _players[asset];
    if (player == null) {
      /// a tap sound never takes audio focus from the user's music
      player = _players[asset] = AudioPlayer(handleAudioSessionActivation: false);
      await player.setAsset(asset);
    }
    await player.seek(Duration.zero);
    unawaited(player.play());
  }
}
