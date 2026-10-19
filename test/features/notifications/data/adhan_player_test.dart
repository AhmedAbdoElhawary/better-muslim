import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:better_muslim/core/audio/ui_sounds.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/settings/adhan_recording.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/notifications/data/adhan_channel.dart';
import 'package:better_muslim/features/notifications/data/adhan_player.dart';
import 'package:better_muslim/features/notifications/data/alert_texts.dart';
import 'package:better_muslim/features/notifications/domain/alert.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' show TZDateTime, getLocation;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AlertTexts texts;
  late Alert maghrib;

  setUpAll(() async {
    tz.initializeTimeZones();
    final location = Location(
      latitude: 21.4225,
      longitude: 39.8262,
      placeName: 'Makkah',
      zone: getLocation('Asia/Riyadh'),
      mode: LocationMode.auto,
    );
    texts = await AlertTexts.load(
      locale: const Locale('en'),
      use24h: true,
      digits: Digits.eastern,
      location: location,
    );
    maghrib = Alert(
      day: DateTime(2026, 10, 15),
      prayer: Prayer.maghrib,
      kind: AlertKind.adhan,
      at: TZDateTime(location.zone, 2026, 10, 15, 17, 56),
      sound: PrayerSound.adhan,
    );
  });

  group('android', () {
    test('plays the same adhan once, the alarm may have started it already', () async {
      final channel = _FakeChannel();
      final player = NativeAdhanPlayer(channel);

      await player.play(maghrib, texts, AdhanRecording.makkah);
      await player.play(maghrib, texts, AdhanRecording.makkah);

      expect(channel.played, hasLength(1));
      expect(channel.played.single['asset'], 'assets/audio/adhan_makkah.m4a');
      expect(channel.played.single['mediaSubtitle'], 'Adhan of Makkah');
    });

    test('state events become playback', () async {
      final channel = _FakeChannel();
      final next = NativeAdhanPlayer(channel).playback.first;

      channel.events.add({
        'id': maghrib.id,
        'playing': true,
        'positionMillis': 42000,
        'durationMillis': 176000,
        'ended': false,
      });
      final playback = await next;

      expect(playback.id, maghrib.id);
      expect(playback.playing, isTrue);
      expect(playback.position, const Duration(seconds: 42));
      expect(playback.duration, const Duration(minutes: 2, seconds: 56));
    });

    test('no ui sound plays while the adhan does', () async {
      final channel = _FakeChannel();
      final player = NativeAdhanPlayer(channel);
      addTearDown(player.dispose);

      await player.play(maghrib, texts, AdhanRecording.makkah);
      channel.events.add({'id': maghrib.id, 'playing': true, 'ended': false});
      await pumpEventQueue();
      expect(BmSounds.busy, isTrue);
      channel.events.add({'id': maghrib.id, 'playing': false, 'ended': true});
      await pumpEventQueue();
      expect(BmSounds.busy, isFalse);
    });
  });

  group('ios', () {
    test('no ui sound plays while the adhan does', () async {
      final audio = _FakeAudioPlayer();
      final player = JustAudioAdhanPlayer(player: audio, session: Future.value(_FakeSession()));

      await player.play(maghrib, texts, AdhanRecording.makkah);
      audio.states.add(PlayerState(true, ProcessingState.ready));
      await pumpEventQueue();
      expect(BmSounds.busy, isTrue);
      audio.states.add(PlayerState(true, ProcessingState.completed));
      await pumpEventQueue();
      expect(BmSounds.busy, isFalse);
    });

    testWidgets('fades in to full volume over 1.5 s', (tester) async {
      final audio = _FakeAudioPlayer();
      final player = JustAudioAdhanPlayer(player: audio, session: Future.value(_FakeSession()));

      await player.play(maghrib, texts, AdhanRecording.makkah);
      await tester.pump(const Duration(milliseconds: 750));
      expect(audio.volumes.last, closeTo(.5, .05));
      await tester.pump(const Duration(milliseconds: 800));

      expect(audio.volumes.first, 0);
      expect(audio.volumes.last, 1);
      final steps = audio.volumes.length;
      await tester.pump(const Duration(seconds: 1));
      expect(audio.volumes, hasLength(steps));
    });

    testWidgets('a call stops it', (tester) async {
      final audio = _FakeAudioPlayer();
      final session = _FakeSession();
      final player = JustAudioAdhanPlayer(player: audio, session: Future.value(session));

      await player.play(maghrib, texts, AdhanRecording.makkah);
      session.interruptions.add(AudioInterruptionEvent(true, AudioInterruptionType.unknown));
      await tester.pump();

      expect(audio.stops, 1);
    });
  });
}

class _FakeChannel extends AdhanChannel {
  final played = <Map<String, Object?>>[];
  final events = StreamController<Map<Object?, Object?>>.broadcast();

  @override
  Future<bool> play(Map<String, Object?> entry, {Duration from = Duration.zero}) async {
    played.add(entry);
    return true;
  }

  @override
  Stream<Map<Object?, Object?>> get state => events.stream;
}

class _FakeAudioPlayer implements AudioPlayer {
  final volumes = <double>[];
  final states = StreamController<PlayerState>.broadcast();
  int stops = 0;

  @override
  Stream<PlayerState> get playerStateStream => states.stream;

  @override
  Future<Duration?> setAsset(
    String assetPath, {
    bool? preload,
    Duration? initialPosition,
    String? package,
    dynamic tag,
  }) async => const Duration(minutes: 2, seconds: 56);

  @override
  Future<void> seek(Duration? position, {int? index}) async {}

  @override
  Future<void> setVolume(double volume) async => volumes.add(volume);

  @override
  Future<void> play() async {}

  @override
  Future<void> stop() async => stops++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSession implements AudioSession {
  final interruptions = StreamController<AudioInterruptionEvent>.broadcast();

  @override
  Future<void> configure(AudioSessionConfiguration configuration) async {}

  @override
  Future<bool> setActive(
    bool active, {
    AVAudioSessionSetActiveOptions? avAudioSessionSetActiveOptions,
    AndroidAudioFocusGainType? androidAudioFocusGainType,
    AndroidAudioAttributes? androidAudioAttributes,
    bool? androidWillPauseWhenDucked,
    AudioSessionConfiguration fallbackConfiguration = const AudioSessionConfiguration.music(),
  }) async => true;

  @override
  Stream<AudioInterruptionEvent> get interruptionEventStream => interruptions.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
