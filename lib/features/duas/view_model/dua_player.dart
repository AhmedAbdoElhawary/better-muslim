import 'dart:async';

import 'package:better_muslim/core/audio/clip_player.dart';
import 'package:better_muslim/features/duas/model/dua.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  Future<bool> toggle(Dua dua) async {
    final audio = dua.audio;
    if (audio == null) return false;

    if (state == dua.id) {
      stop();
      return true;
    }
    final ClipPlayer player = _player ?? ref.read(clipPlayerProvider);
    _player = player;
    _ended ??= player.ended.listen((_) => state = null);
    if (state != null) await player.stop();
    state = dua.id;
    await player.play(audio);
    return true;
  }

  Future<void> stop() async {
    /// the guard's microtask can land after the duas pages closed, dispose already stopped it
    if (!ref.mounted || state == null) return;
    state = null;
    await _player?.stop();
  }
}
