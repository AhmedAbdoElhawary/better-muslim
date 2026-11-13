import 'dart:async';

import 'package:better_muslim/core/audio/audio_use.dart';
import 'package:better_muslim/core/audio/clip_player.dart';
import 'package:better_muslim/core/network/download.dart';
import 'package:better_muslim/core/quran/recitation_files.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/duas/model/dua.dart';
import 'package:better_muslim/features/duas/model/dua_clips.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final duaPlayerProvider = NotifierProvider.autoDispose<DuaPlayer, String?>(DuaPlayer.new);

/// the id of the dua playing, one at a time
class DuaPlayer extends Notifier<String?> {
  ClipPlayer? _player;
  StreamSubscription<void>? _ended;

  /// a quranic dua's ayahs still to recite
  final _next = <AyahAudio>[];

  @override
  String? build() {
    final use = ref.read(audioUseProvider.notifier);

    /// held for the whole dua, so the quran never comes back between its ayahs
    listenSelf((_, id) => id == null ? use.release(AudioUse.clip) : use.claim(AudioUse.clip));
    ref.listen(audioUseProvider, (_, now) {
      if (now == AudioUse.recitation || now == AudioUse.adhan) stop();
    });

    /// leaving the duas pages stops the clip with them
    ref.onDispose(() {
      _ended?.cancel();
      _player?.stop();

      /// riverpod lets no provider change another while it is disposed
      Future(() => use.release(AudioUse.clip));
    });
    return null;
  }

  Future<bool> toggle(Dua dua) async {
    if (!dua.listenable) return false;

    if (state == dua.id) {
      stop();
      return true;
    }
    final ClipPlayer player = _player ?? ref.read(clipPlayerProvider);
    _player = player;
    _ended ??= player.ended.listen((_) {
      if (_next.isEmpty) {
        state = null;
      } else {
        _play(player, _next.removeAt(0));
      }
    });
    _next.clear();
    if (state != null) await player.stop();
    state = dua.id;
    final List<AyahAudio> clips;
    try {
      clips = await _clips(dua);
    } on Exception catch (error) {
      if (error is! RecitationException && error is! DownloadException) rethrow;
      if (ref.mounted && state == dua.id) state = null;
      return false;
    }

    /// stopped or another dua tapped while the ayahs downloaded
    if (!ref.mounted || state != dua.id) return true;
    _next.addAll(clips.skip(1));
    await _play(player, clips.first);
    return true;
  }

  Future<void> _play(ClipPlayer player, AyahAudio clip) =>
      player.play(clip.path, start: clip.start, end: clip.end);

  /// the dua's clip or the ayahs in the reciter picked for the quran, from the phone when already there
  Future<List<AyahAudio>> _clips(Dua dua) async {
    if (dua.audio != null) {
      return [(path: await ref.read(duaClipsProvider).path(dua), start: null, end: null)];
    }
    final files = ref.read(recitationFilesProvider);
    final reciter = ref.read(settingsProvider).value?.reciter ?? Reciter.alafasy;
    return [for (final key in dua.ayahs) await files.audio(reciter, key)];
  }

  Future<void> stop() async {
    /// the guard's microtask can land after the duas pages closed, dispose already stopped it
    if (!ref.mounted || state == null) return;
    state = null;
    _next.clear();
    await _player?.stop();
  }
}
