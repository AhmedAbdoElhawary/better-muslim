import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:better_muslim/core/audio/clip_player.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/recitation_files.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/features/quran/domain/recitation.dart';
import 'package:just_audio/just_audio.dart';

/// the recitation on its own player, in the background and on the lock screen (research R10, R11).
/// the playlist grows as the files come in, so repeats and ayah changes stay gapless
class AudioServiceRecitation implements Recitation {
  AudioServiceRecitation(this._files) {
    _handler = _Handler(this);
    _listen();
  }

  /// once, from the app's own run, never a background engine. after the cold open's first frame,
  /// the handler keeps what was published before and hands it over
  Future<void> start({required String channel}) => AudioService.init(
    builder: () => _handler,
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.elhawary.bettermuslim.recitation',
      androidNotificationChannelName: channel,
      androidNotificationIcon: 'drawable/ic_notification',
    ),
  );

  final RecitationFiles _files;
  final _player = AudioPlayer();

  /// reads an ayah's length for ±10 s when it hasn't played yet, it never plays
  final _probe = AudioPlayer();
  final _lengths = <(Reciter, AyahKey), Duration>{};
  late final _Handler _handler;
  final _states = StreamController<RecitationState>.broadcast();
  RecitationState _state = const RecitationState();
  MediaText? _media;

  var _queue = <AyahKey>[];

  /// how much of the queue is in the player's playlist
  var _added = 0;

  /// the item the shown time belongs to, a late tick of the one before showed it jump back
  var _timed = 0;
  var _timedAt = Duration.zero;

  /// bumped by every play and stop, so a late download never lands in a newer queue
  var _session = 0;

  /// the player reached the end of the playlist before the next file came in
  var _waiting = false;

  /// next and previous never wait the pause between ayahs
  var _jumped = false;

  /// the last play failed, so play starts it again instead of resuming
  var _failed = false;

  /// why the feed stopped before the queue's end, the player fails there
  RecitationFailure? _cut;
  Timer? _gap;
  Timer? _sleep;
  Timer? _fade;
  Timer? _stall;

  static const _fadeTime = Duration(seconds: 3);
  static const _fadeStep = Duration(milliseconds: 100);
  static const _stallTime = Duration(seconds: 15);

  @override
  RecitationState get current => _state;

  @override
  Stream<RecitationState> get state => _states.stream;

  void _emit(RecitationState state) {
    _state = state;
    _states.add(state);
    _handler.publish(state, _media);
  }

  void _listen() {
    _player.currentIndexStream.listen(_moved);
    _player.playerStateStream.listen(_changed);
    _player.playbackEventStream.listen((_) {}, onError: (_) => _fail(RecitationFailure.failed));

    /// a stream still coming in is not stuck
    _player.bufferedPositionStream.listen((_) {
      if (_stall?.isActive ?? false) _watchStall();
    });
    _player.positionStream.listen((position) {
      /// the index and length from the same event as the position, so the pair always matches
      final event = _player.playbackEvent;
      final duration = event.duration;
      if (!_state.active || event.currentIndex != _timed || duration == null) return;
      if (_timed < _queue.length) _lengths[(_state.reciter, _queue[_timed])] = duration;

      /// the player guesses between its real updates, the real one can land a little behind
      final back = _timedAt - position;
      if (back > Duration.zero && back < const Duration(seconds: 1)) return;
      _timedAt = position;
      _emit(_state.copyWith(position: position, duration: duration));
    });
  }

  void _watchStall() {
    _stall?.cancel();
    _stall = Timer(_stallTime, () => _fail(RecitationFailure.offline));
  }

  /// stays up paused with the failure, so a tap on play tries again from this ayah
  Future<void> _fail(RecitationFailure failure, {AyahKey? at}) async {
    if (!_state.active) return;
    _session++;
    _cancelTimers();
    _waiting = false;
    _failed = true;
    _emit(_state.copyWith(status: RecitationStatus.paused, ayah: at, failure: failure));
    await _player.stop();
  }

  void _moved(int? index) {
    if (index == null || index >= _queue.length || !_state.active) return;
    if (index > 0 && sleepsAfter(_queue, index - 1, _state.sleep)) {
      stop();
      return;
    }

    /// the time keeps the last ayah's until the new one's first tick brings its length
    _timed = index;
    _timedAt = Duration.zero;
    _emit(_state.copyWith(ayah: _queue[index]));
    if (!_jumped && _state.pause > Duration.zero && pausesBefore(_queue, index)) {
      _player.pause();
      _gap = Timer(_state.pause, _player.play);
    }
    _jumped = false;
  }

  void _changed(PlayerState player) {
    if (!_state.active || _failed) return;
    if (player.processingState == ProcessingState.completed) {
      _stall?.cancel();
      if (_cut case final cut? when _added < _queue.length) {
        _fail(cut, at: _queue[_added]);
      } else if (_added < _queue.length) {
        _waiting = true;
        _emit(_state.copyWith(status: RecitationStatus.loading));
      } else {
        _ended();
      }
      return;
    }
    if (_waiting) return;
    final processing = player.processingState;
    final loading =
        processing == ProcessingState.loading ||
        (processing == ProcessingState.buffering && player.playing);
    if (!loading) {
      _stall?.cancel();
    } else if (!(_stall?.isActive ?? false)) {
      _watchStall();
    }
    final status = loading
        ? RecitationStatus.loading
        : player.playing || (_gap?.isActive ?? false)
        ? RecitationStatus.playing
        : RecitationStatus.paused;
    if (status != _state.status) _emit(_state.copyWith(status: status));
  }

  @override
  Future<void> play(AyahKey from, {required AyahKey to, MediaText? media}) =>
      _play(from, to: to, media: media);

  /// paused loads the first file and waits there, for a new reciter picked while paused
  Future<void> _play(
    AyahKey from, {
    required AyahKey to,
    MediaText? media,
    bool paused = false,
  }) async {
    final session = ++_session;
    _cancelTimers();
    _waiting = false;
    _failed = false;
    _cut = null;
    _media = media ?? _media;
    _queue = recitationQueue(from, to, repeat: _state.repeat);
    _added = 0;
    _timed = 0;
    _timedAt = Duration.zero;
    _emit(
      _state.copyWith(
        status: RecitationStatus.loading,
        ayah: _queue.first,
        from: from,
        to: to,
        position: Duration.zero,
        duration: Duration.zero,
        surahReady: false,
      ),
    );
    await _player.stop();
    await _player.clearAudioSources();
    await _configure();

    final AyahAudio first;
    try {
      first = await _files.audio(_state.reciter, _queue.first);
    } on RecitationException catch (error) {
      if (session == _session) await _fail(error.failure);
      return;
    }
    if (session != _session) return;
    try {
      await _player.setAudioSources([_source(first)]);
    } on PlayerException {
      _forget(first);
      if (session == _session) await _fail(RecitationFailure.failed);
      return;
    }
    _added = 1;
    _files.ahead(_state.reciter, _queue.skip(1));
    unawaited(_feed(session));
    await _player.setSpeed(_state.speed);
    await _player.setVolume(1);
    if (paused) {
      _emit(_state.copyWith(status: RecitationStatus.paused));
      return;
    }
    await (await AudioSession.instance).setActive(true);
    unawaited(_player.play());
  }

  /// the rest of the queue into the playlist as each file is checked
  Future<void> _feed(int session) async {
    while (_added < _queue.length) {
      final AyahAudio audio;
      try {
        audio = await _files.audio(_state.reciter, _queue[_added]);
      } on RecitationException catch (error) {
        /// what is in the playlist still plays, it stops where the files end
        if (session != _session) return;
        _cut = error.failure;
        if (_waiting) await _fail(error.failure, at: _queue[_added]);
        return;
      }
      if (session != _session) return;
      try {
        await _player.addAudioSource(_source(audio));
      } on PlayerException {
        _forget(audio);
        _cut = RecitationFailure.failed;
        if (_waiting) await _fail(RecitationFailure.failed, at: _queue[_added]);
        return;
      }
      _added++;
      if (_waiting) {
        _waiting = false;
        await _player.seek(Duration.zero, index: _added - 1);
        unawaited(_player.play());
      }
    }
    final ready = await _files.isSurahReady(_state.reciter, [
      if (_queue.first.ayah == 0) const AyahKey(1, 1),
      for (var ayah = 1; ayah <= _queue.last.ayah; ayah++) AyahKey(_queue.last.surah, ayah),
    ]);
    if (session == _session) _emit(_state.copyWith(surahReady: ready));
  }

  IndexedAudioSource _source(AyahAudio audio) =>
      clipOf(audio.path, start: audio.start, end: audio.end);

  /// the system can't open the file, so it is deleted and the next play downloads it again
  void _forget(AyahAudio audio) {
    final file = File(audio.path);
    if (audio.path.startsWith('/') && file.existsSync()) file.deleteSync();
  }

  /// music like the clip and adhan players, so the shared session never flips (research R12)
  StreamSubscription<Object?>? _interruptions;
  StreamSubscription<Object?>? _noisy;

  Future<void> _configure() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    /// a call or unplugged headphones pause it, it never comes back on its own (FR-028)
    _interruptions ??= session.interruptionEventStream.listen((event) {
      if (event.begin) pause();
    });
    _noisy ??= session.becomingNoisyEventStream.listen((_) => pause());
  }

  int? get _index => _player.currentIndex;

  @override
  Future<void> pause() async {
    _gap?.cancel();
    await _player.pause();
    if (_state.active) _emit(_state.copyWith(status: RecitationStatus.paused));
  }

  @override
  Future<void> resume() async {
    if (!_state.active) return;
    if (_failed) return _replay();
    await (await AudioSession.instance).setActive(true);
    unawaited(_player.play());
  }

  @override
  Future<void> next() async {
    final index = _index;
    if (index == null) return;
    final next = nextAyahIndex(_queue, index);
    if (next == null) return _ended();
    if (next >= _added) return _replay(_queue[next]);
    _jump(next);
  }

  @override
  Future<void> previous() async {
    final index = _index;
    if (index == null) return;
    _jump(previousAyahIndex(_queue, index) ?? _queue.indexOf(_queue[index]));
  }

  @override
  Future<void> seekBy(Duration by) async {
    final index = _index;
    if (index == null || !_state.active) return;
    final ({int index, Duration position})? landed;
    try {
      landed = await seekAcross(_queue, index, _player.position, by, _length);
    } on Exception {
      /// an ayah ahead that can't be read or downloaded now, the tap does nothing
      return;
    }
    if (landed == null) return _ended();
    if (landed.index >= _added) return _replay(_queue[landed.index]);
    final waiting = _gap?.isActive ?? false;
    _gap?.cancel();
    if (landed.index != index) _jumped = true;
    await _player.seek(landed.position, index: landed.index);
    if (waiting) unawaited(_player.play());
  }

  /// surah loop starts the range again from its start, bismillah included
  Future<void> _ended() => startsAgain(_state.repeat, _state.sleep) && _state.from != null
      ? play(_state.from!, to: _state.to!)
      : stop();

  /// past what's in the playlist it stops the walk there, that file may not be on the phone yet
  Future<Duration> _length(int index) async {
    if (index >= _added) return const Duration(days: 1);
    final key = (_state.reciter, _queue[index]);
    if (_lengths[key] case final length?) return length;
    final audio = await _files.audio(key.$1, key.$2);
    if ((audio.start, audio.end) case (final start?, final end?)) {
      return _lengths[key] = end - start;
    }
    return _lengths[key] = await _probe.setFilePath(audio.path) ?? Duration.zero;
  }

  @override
  Future<void> seekToAyah(AyahKey ayah) async {
    final index = _queue.indexOf(ayah);

    /// after a replay the queue starts at the ayah that played then, the range still starts before
    if (index >= 0 && index < _added) return _jump(index);
    await _replay(ayah);
  }

  void _jump(int index) {
    _gap?.cancel();
    _jumped = true;
    _player.seek(Duration.zero, index: index);
    if (!_player.playing) unawaited(_player.play());
  }

  @override
  Future<void> setSpeed(double speed) async {
    _emit(_state.copyWith(speed: speed));
    await _player.setSpeed(speed);
  }

  /// a new repeat rebuilds the queue from the playing ayah
  @override
  Future<void> setRepeat(int times) async {
    _emit(_state.copyWith(repeat: times));
    if (_state.status == RecitationStatus.playing) await _replay();
  }

  @override
  Future<void> setReciter(Reciter reciter) async {
    if (reciter == _state.reciter) return;
    final paused = _state.status == RecitationStatus.paused;
    _emit(_state.copyWith(reciter: reciter));
    if (!_state.active) return;
    await _replay(null, paused);
  }

  /// the queue again from the playing ayah or the one given, the range keeps its start
  Future<void> _replay([AyahKey? start, bool paused = false]) async {
    final (ayah, from, to) = (start ?? _state.ayah, _state.from, _state.to);
    if (ayah == null || to == null) return;
    await _play(ayah, to: to, paused: paused);
    _emit(_state.copyWith(from: from));
  }

  @override
  Future<void> setPause(Duration gap) async => _emit(_state.copyWith(pause: gap));

  @override
  Future<void> setSleep(SleepTimer timer) async {
    _sleep?.cancel();
    _emit(_state.copyWith(sleep: timer));
    if (timer.after case final after?) _sleep = Timer(after, _fadeOut);
  }

  /// the volume to 0 over 3 s, then stop
  void _fadeOut() {
    final steps = _fadeTime.inMilliseconds ~/ _fadeStep.inMilliseconds;
    _fade = Timer.periodic(_fadeStep, (timer) {
      _player.setVolume(math.max(0, 1 - timer.tick / steps));
      if (timer.tick >= steps) {
        _emit(_state.copyWith(sleep: const SleepTimer.off()));
        stop();
      }
    });
  }

  void _cancelTimers() {
    _gap?.cancel();
    _fade?.cancel();
    _stall?.cancel();
  }

  @override
  Future<void> stop() async {
    _session++;
    _cancelTimers();
    _sleep?.cancel();
    _waiting = false;
    _failed = false;
    _emit(_state.copyWith(status: RecitationStatus.idle));
    await _player.stop();
    await (await AudioSession.instance).setActive(false);
  }
}

/// the lock screen and the notification: previous, play or pause, next
class _Handler extends BaseAudioHandler {
  _Handler(this._recitation);

  final AudioServiceRecitation _recitation;

  void publish(RecitationState state, MediaText? media) {
    final ayah = state.ayah;
    final id = '${state.reciter.name}/$ayah';
    if (media != null && ayah != null && mediaItem.value?.id != id) {
      mediaItem.add(
        MediaItem(id: id, title: media.title(readAyah(ayah)), artist: media.artist(state.reciter)),
      );
    }
    final playing = state.status == RecitationStatus.playing;
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        androidCompactActionIndices: const [0, 1, 2],
        processingState: switch (state.status) {
          RecitationStatus.idle => AudioProcessingState.idle,
          RecitationStatus.loading => AudioProcessingState.loading,
          _ => AudioProcessingState.ready,
        },
        playing: playing,
        updatePosition: state.position,
        speed: state.speed,
      ),
    );
  }

  @override
  Future<void> play() => _recitation.resume();

  @override
  Future<void> pause() => _recitation.pause();

  @override
  Future<void> skipToNext() => _recitation.next();

  @override
  Future<void> skipToPrevious() => _recitation.previous();

  @override
  Future<void> stop() => _recitation.stop();
}
