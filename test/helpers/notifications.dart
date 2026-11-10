import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/settings/adhan_recording.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/notifications/data/adhan_channel.dart';
import 'package:better_muslim/features/notifications/data/adhan_player.dart';
import 'package:better_muslim/features/notifications/data/alert_texts.dart';
import 'package:better_muslim/features/notifications/data/notification_scheduler.dart';
import 'package:better_muslim/features/notifications/domain/alert.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

/// widget tests run as android, so the kotlin channel gets an answer that does nothing
List<MethodCall> muteAdhanChannel() {
  final calls = <MethodCall>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('better_muslim/adhan'),
    (call) async {
      calls.add(call);
      return null;
    },
  );
  for (final name in ['better_muslim/adhan/state', 'better_muslim/adhan/opened']) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockStreamHandler(
      EventChannel(name),
      MockStreamHandler.inline(onListen: (_, _) {}),
    );
  }

  /// a resume reads the phone's zone again
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('flutter_timezone'),
    (_) async => 'Asia/Riyadh',
  );
  return calls;
}

/// records what the app asks of the plugin, nothing reaches the phone
class FakeScheduler extends NotificationScheduler {
  FakeScheduler({this.allowed = true, this.grants = true}) : super(AdhanChannel());

  bool allowed;
  bool grants;
  int asks = 0;
  int alarmAsks = 0;
  int cancels = 0;
  final applied = <List<Alert>>[];
  final appliedRecordings = <Map<Prayer, AdhanRecording>>[];
  final appliedVoices = <bool>[];

  int inits = 0;
  String? markPrayedLabel;

  @override
  Future<void> init({
    required String markPrayed,
    required String addToQada,
    DidReceiveNotificationResponseCallback? onTap,
  }) async {
    inits++;
    markPrayedLabel = markPrayed;
  }

  @override
  Future<bool> askPermission() async {
    asks++;
    allowed = grants;
    return grants;
  }

  @override
  Future<bool> askExactAlarms() async {
    alarmAsks++;
    return true;
  }

  @override
  Future<bool> isAllowed() async => allowed;

  /// each topUp ends in one of these two
  int get runs => applied.length + cancels;

  @override
  Future<void> cancelAll() async => cancels++;

  /// delivered notifications, as the os lists them
  final active = <int>[];
  final cancelled = <int>[];
  String? launch;

  @override
  Future<String?> launchPayload() async => launch;

  @override
  Future<List<int>> activeIds() async => [...active];

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    active.remove(id);
  }

  @override
  Future<void> apply({
    required List<Alert> alerts,
    required Map<Prayer, PrayerSound> sounds,
    required Map<Prayer, AdhanRecording> recordings,
    required Map<Prayer, PrayerTone> tones,
    required AlertTexts texts,
    bool azkarVoice = true,
  }) async {
    applied.add(alerts);
    appliedRecordings.add(recordings);
    appliedVoices.add(azkarVoice);
  }
}

class FakePlayer extends AdhanPlayer {
  FakePlayer({
    this.position = const Duration(seconds: 42),
    this.duration = const Duration(minutes: 2, seconds: 56),
  });

  final Duration position;
  final Duration duration;
  final played = <Alert>[];
  final recordings = <AdhanRecording>[];
  int stops = 0;

  @override
  Future<void> play(
    Alert alert,
    AlertTexts texts,
    AdhanRecording recording, {
    Duration from = Duration.zero,
  }) async {
    played.add(alert);
    recordings.add(recording);
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async => stops++;

  @override
  Future<Duration> length(Prayer prayer, AdhanRecording recording) async => duration;

  @override
  Stream<Playback> get playback =>
      Stream.value(Playback(id: 1, playing: true, position: position, duration: duration));
}
