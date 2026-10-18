import 'package:better_muslim/core/monitoring/crash_reporter.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/notifications/data/adhan_channel.dart';
import 'package:better_muslim/features/notifications/data/adhan_recording.dart';
import 'package:better_muslim/features/notifications/data/alert_texts.dart';
import 'package:better_muslim/features/notifications/domain/alert.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationSchedulerProvider = Provider<NotificationScheduler>(
  (ref) => NotificationScheduler(ref.watch(adhanChannelProvider)),
);

/// every pending notification is replaced on each apply, so none is ever left from before
class NotificationScheduler {
  NotificationScheduler(this._channel);

  final AdhanChannel _channel;
  final _plugin = FlutterLocalNotificationsPlugin();

  static const _recording = AdhanRecording.makkah;
  static const _group = 'adhan';

  /// system surfaces use the dark qiyam emerald, whatever the app's theme
  static final _accent = ThemeEnum.primary.resolve(bmThemes[BmThemeId.qiyamEmerald]!.dark);

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  IOSFlutterLocalNotificationsPlugin? get _ios =>
      _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

  /// asking is its own step, after the location (FR-004)
  Future<void> init() => _plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ),
  );

  Future<bool> askPermission() async =>
      await (_ios?.requestPermissions(alert: true, sound: true) ??
          _android?.requestNotificationsPermission()) ??
      false;

  /// no location, nothing can be right
  Future<void> cancelAll() => _plugin.cancelAllPendingNotifications();

  /// errors carry only the step, never a payload, a place or a time (FR-040)
  Future<void> apply({
    required List<Alert> alerts,
    required Map<Prayer, PrayerSound> sounds,
    required AlertTexts texts,
  }) async {
    try {
      await _plugin.cancelAllPendingNotifications();
      await _ensureChannels(sounds, texts);
      final exact = await _android?.canScheduleExactNotifications() ?? false;
      for (final alert in alerts) {
        await _plugin.zonedSchedule(
          id: alert.id,
          scheduledDate: alert.at,
          notificationDetails: _details(alert, texts),
          androidScheduleMode: exact
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexactAllowWhileIdle,
          title: texts.titleOf(alert),
          body: texts.bodyOf(alert),
          payload: payloadOf(alert),
        );
      }
    } catch (error, stack) {
      await CrashReporter.instance.recordError(error, stack, context: const {'step': 'schedule'});
    }
  }

  /// one entry per prayer in the phone's settings: the prayer's other two channels are deleted
  Future<void> _ensureChannels(Map<Prayer, PrayerSound> sounds, AlertTexts texts) async {
    final android = _android;
    if (android == null) return;
    await android.createNotificationChannelGroup(
      AndroidNotificationChannelGroup(_group, texts.tr(StringsManager.soundAdhan)),
    );
    for (final MapEntry(key: prayer, value: sound) in sounds.entries) {
      await android.createNotificationChannel(_channelOf(prayer, sound, texts));
      for (final other in PrayerSound.values.where((other) => other != sound)) {
        await android.deleteNotificationChannel(channelId: _channelId(prayer, other));
      }
    }
  }

  static String _channelId(Prayer prayer, PrayerSound sound) =>
      'adhan_${prayer.name}_${sound.name}';

  AndroidNotificationChannel _channelOf(Prayer prayer, PrayerSound sound, AlertTexts texts) =>
      AndroidNotificationChannel(
        _channelId(prayer, sound),
        texts.tr(prayer.nameKey),
        groupId: _group,
        importance: Importance.high,
        playSound: sound != PrayerSound.silent,
        sound: sound == PrayerSound.adhan
            ? RawResourceAndroidNotificationSound(_recording.clipOf(prayer))
            : null,
        enableVibration: sound != PrayerSound.silent,
      );

  NotificationDetails _details(Alert alert, AlertTexts texts) {
    final channel = _channelOf(alert.prayer, alert.sound, texts);
    final sound = alert.sound;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        groupKey: _group,
        importance: channel.importance,
        priority: Priority.high,
        playSound: channel.playSound,
        sound: channel.sound,
        enableVibration: channel.enableVibration,
        color: _accent,
        category: AndroidNotificationCategory.reminder,
      ),

      /// ios plays the clip with the app closed. in front the adhan screen plays the full adhan
      /// instead, so the adhan notification itself stays out of the way (FR-021)
      iOS: DarwinNotificationDetails(
        sound: sound == PrayerSound.adhan ? '${_recording.clipOf(alert.prayer)}.caf' : null,
        presentSound: sound == PrayerSound.tone,
        presentBanner: sound != PrayerSound.adhan,
        presentList: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
        categoryIdentifier: _group,
      ),
    );
  }
}
