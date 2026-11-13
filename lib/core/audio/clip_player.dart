import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:better_muslim/core/audio/ui_sounds.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

/// a downloaded adhan or recitation is a path on the phone, a streamed surah an https address,
/// everything else a flutter asset
UriAudioSource sourceOf(String asset) => asset.startsWith('/')
    ? AudioSource.file(asset)
    : asset.startsWith('https:')
    ? AudioSource.uri(Uri.parse(asset))
    : AudioSource.asset(asset);

/// start and end cut an ayah out of a surah file
IndexedAudioSource clipOf(String asset, {Duration? start, Duration? end}) =>
    start == null && end == null
    ? sourceOf(asset)
    : ClippingAudioSource(child: sourceOf(asset), start: start, end: end);

/// the one thing the tests replace, so no test reaches the phone's audio
abstract class ClipPlayer {
  /// end stops it early, the takbir preview is the full adhan's start
  Future<void> play(String asset, {Duration? start, Duration? end});
  Future<void> stop();

  /// a clip played to its end
  Stream<void> get ended;
  void dispose();
}

class JustAudioClipPlayer implements ClipPlayer {
  final _player = AudioPlayer();
  StreamSubscription<PlayerState>? _busy;

  @override
  Future<void> play(String asset, {Duration? start, Duration? end}) async {
    /// music like the adhan, so a preview is heard with the silent switch on
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    _busy ??= _player.playerStateStream.listen(
      (state) =>
          BmSounds.busy = state.playing && state.processingState != ProcessingState.completed,
    );
    await _player.setAudioSource(clipOf(asset, start: start, end: end));
    unawaited(_player.play());
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Stream<void> get ended => _player.processingStateStream
      .where((state) => state == ProcessingState.completed)
      .map((_) {});

  @override
  void dispose() {
    _busy?.cancel();
    BmSounds.busy = false;
    _player.dispose();
  }
}

/// made on the first clip, so a page without one never opens an audio player
final clipPlayerProvider = Provider<ClipPlayer>((ref) {
  final player = JustAudioClipPlayer();
  ref.onDispose(player.dispose);
  return player;
});
