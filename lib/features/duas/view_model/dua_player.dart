import 'dart:async';

import 'package:better_muslim/features/duas/model/dua.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

/// the one thing the tests replace, so no test reaches the phone's audio
abstract class ClipPlayer {
  Future<void> play(String asset);
  Future<void> stop();

  /// a clip played to its end
  Stream<void> get ended;
  void dispose();
}

class JustAudioClipPlayer implements ClipPlayer {
  final _player = AudioPlayer();

  @override
  Future<void> play(String asset) async {
    await _player.setAsset(asset);
    unawaited(_player.play());
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Stream<void> get ended => _player.processingStateStream
      .where((state) => state == ProcessingState.completed)
      .map((_) {});

  @override
  void dispose() => _player.dispose();
}

/// made on the first clip, so a dua page without one never opens an audio player
final clipPlayerProvider = Provider<ClipPlayer>((ref) {
  final player = JustAudioClipPlayer();
  ref.onDispose(player.dispose);
  return player;
});

final duaPlayerProvider = NotifierProvider.autoDispose<DuaPlayer, String?>(DuaPlayer.new);

/// the id of the dua playing, one at a time
class DuaPlayer extends Notifier<String?> {
  ClipPlayer? _player;
  StreamSubscription<void>? _ended;

  @override
  String? build() {
    /// leaving the duas pages stops the clip with them
    ref.onDispose(() {
      _ended?.cancel();
      _player?.stop();
    });
    return null;
  }

  /// a dua without a clip does nothing until the clips are in the app
  Future<void> toggle(Dua dua) async {
    final audio = dua.audio;
    if (audio == null) return;
    if (state == dua.id) return stop();
    final ClipPlayer player = _player ?? ref.read(clipPlayerProvider);
    _player = player;
    _ended ??= player.ended.listen((_) => state = null);
    if (state != null) await player.stop();
    state = dua.id;
    await player.play(audio);
  }

  Future<void> stop() async {
    if (state == null) return;
    state = null;
    await _player?.stop();
  }
}
