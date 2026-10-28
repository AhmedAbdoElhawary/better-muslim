import 'dart:async';
import 'dart:math' as math;

import 'package:audio_session/audio_session.dart';
import 'package:better_muslim/core/audio/ui_sounds.dart';
import 'package:better_muslim/core/monitoring/crash_reporter.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/settings/adhan_recording.dart';
import 'package:better_muslim/features/notifications/data/adhan_channel.dart';
import 'package:better_muslim/features/notifications/data/alert_texts.dart';
import 'package:better_muslim/features/notifications/data/notification_scheduler.dart';
import 'package:better_muslim/features/notifications/domain/alert.dart';
import 'package:just_audio/just_audio.dart';

class Playback {
  const Playback({
    this.id,
    this.playing = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.ended = false,
  });

  /// the alert being played, null when idle
  final int? id;
  final bool playing;
  final Duration position;
  final Duration duration;
  final bool ended;
}

/// one type for the adhan screen and the tests, ios plays in the app, android in its service
abstract class AdhanPlayer {
  /// once per alert, the alarm and the app can both start the same adhan
  Future<void> play(
    Alert alert,
    AlertTexts texts,
    AdhanRecording recording, {
    Duration from = Duration.zero,
  });

  Future<void> pause();

  Future<void> resume();

  Future<void> stop();

  /// read from the file, so the real recordings can come without a code change
  Future<Duration> length(Prayer prayer, AdhanRecording recording);

  Stream<Playback> get playback;

  void dispose() {}
}

/// android: the app never plays audio itself, so the screen and the shade show the same adhan
class NativeAdhanPlayer extends AdhanPlayer {
  NativeAdhanPlayer(this._channel);

  final AdhanChannel _channel;
  int? _played;
  StreamSubscription<Playback>? _busy;

  @override
  Future<void> play(
    Alert alert,
    AlertTexts texts,
    AdhanRecording recording, {
    Duration from = Duration.zero,
  }) async {
    if (_played == alert.id) return;
    _played = alert.id;
    _busy ??= playback.listen((state) => BmSounds.busy = state.playing && !state.ended);
    await _channel.play(NotificationScheduler.entryOf(alert, texts, recording), from: from);
  }

  @override
  Future<void> pause() => _channel.pause();

  @override
  Future<void> resume() => _channel.resume();

  @override
  Future<void> stop() {
    _played = null;
    return _channel.stop();
  }

  @override
  Future<Duration> length(Prayer prayer, AdhanRecording recording) async =>
      await _channel.length(recording.fullAsset(prayer)) ?? Duration.zero;

  @override
  Stream<Playback> get playback => _channel.state.map(
    (state) => Playback(
      id: state['id'] as int?,
      playing: state['playing'] as bool? ?? false,
      position: Duration(milliseconds: state['positionMillis'] as int? ?? 0),
      duration: Duration(milliseconds: state['durationMillis'] as int? ?? 0),
      ended: state['ended'] as bool? ?? false,
    ),
  );

  @override
  void dispose() {
    _busy?.cancel();
    BmSounds.busy = false;
  }
}

/// ios: playback keeps going with the screen locked and the silent switch on (FR-022a)
class JustAudioAdhanPlayer extends AdhanPlayer {
  JustAudioAdhanPlayer({AudioPlayer? player, Future<AudioSession>? session})
    : _player = player ?? AudioPlayer(),
      _session = session ?? AudioSession.instance;

  final AudioPlayer _player;
  final Future<AudioSession> _session;
  final _lengths = <String, Duration>{};
  StreamSubscription<AudioInterruptionEvent>? _interruptions;
  StreamSubscription<PlayerState>? _busy;
  Timer? _fade;
  int? _id;

  static const fade = Duration(milliseconds: 1500);
  static const _fadeStep = Duration(milliseconds: 50);

  @override
  Future<void> play(
    Alert alert,
    AlertTexts texts,
    AdhanRecording recording, {
    Duration from = Duration.zero,
  }) async {
    if (_id == alert.id) return;
    _id = alert.id;
    final session = await _session;
    await session.configure(const AudioSessionConfiguration.music());

    /// a call stops the adhan, it never comes back on its own (FR-025)
    _interruptions ??= session.interruptionEventStream.listen((event) {
      if (event.begin) stop();
    });
    _busy ??= _player.playerStateStream.listen(
      (state) =>
          BmSounds.busy = state.playing && state.processingState != ProcessingState.completed,
    );
    try {
      await _player.setAsset(recording.fullAsset(alert.prayer));
    } on PlayerException catch (error, stack) {
      /// the adhan screen is already open, it stays open silent instead of crashing
      _id = null;
      await _report(error, stack, 'adhan play');
      return;
    }
    await _player.seek(from);
    await _player.setVolume(0);
    await session.setActive(true);
    unawaited(_player.play());
    _fade?.cancel();
    _fade = Timer.periodic(_fadeStep, (timer) {
      final volume = math.min(1.0, timer.tick * _fadeStep.inMilliseconds / fade.inMilliseconds);
      _player.setVolume(volume);
      if (volume >= 1) timer.cancel();
    });
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> resume() => _player.play();

  @override
  Future<void> stop() async {
    _fade?.cancel();
    _id = null;
    await _player.stop();
    await (await _session).setActive(false);
  }

  @override
  Future<Duration> length(Prayer prayer, AdhanRecording recording) async {
    final asset = recording.fullAsset(prayer);
    final known = _lengths[asset];
    if (known != null) return known;
    final reader = AudioPlayer();
    try {
      return _lengths[asset] = await reader.setAsset(asset) ?? Duration.zero;
    } on PlayerException catch (error, stack) {
      await _report(error, stack, 'adhan length');

      /// zero would send a fresh adhan tap to the prayer tab, the label is close enough
      final [minutes, seconds] = recording.lengthLabel.split(':').map(int.parse).toList();
      return Duration(minutes: minutes, seconds: seconds);
    } finally {
      await reader.dispose();
    }
  }

  /// ios cold starting from a tap can refuse the file (-11800)
  Future<void> _report(PlayerException error, StackTrace stack, String reason) =>
      CrashReporter.instance.recordError(error, stack, context: {'reason': reason});

  @override
  Stream<Playback> get playback {
    late final StreamController<Playback> controller;
    final subscriptions = <StreamSubscription<Object?>>[];
    void emit(Object? _) => controller.add(
      Playback(
        id: _id,
        playing: _player.playing,
        position: _player.position,
        duration: _player.duration ?? Duration.zero,
        ended: _player.processingState == ProcessingState.completed,
      ),
    );
    controller = StreamController(
      onListen: () => subscriptions
        ..add(_player.positionStream.listen(emit))
        ..add(_player.playerStateStream.listen(emit)),
      onCancel: () {
        for (final subscription in subscriptions) {
          subscription.cancel();
        }
      },
    );
    return controller.stream;
  }

  @override
  void dispose() {
    _fade?.cancel();
    _interruptions?.cancel();
    _busy?.cancel();
    BmSounds.busy = false;
    _player.dispose();
  }
}

/// the design scenario's 4.03 values, paused and silent (FR-042)
class FixedAdhanPlayer extends AdhanPlayer {
  FixedAdhanPlayer({required this.position, required this.duration});

  final Duration position;
  final Duration duration;

  @override
  Future<void> play(
    Alert alert,
    AlertTexts texts,
    AdhanRecording recording, {
    Duration from = Duration.zero,
  }) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<Duration> length(Prayer prayer, AdhanRecording recording) async => duration;

  @override
  Stream<Playback> get playback => Stream.value(Playback(position: position, duration: duration));
}
