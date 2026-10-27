import 'package:better_muslim/core/monitoring/crash_reporter.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/adhan_recording.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/notifications/data/adhan_channel.dart';
import 'package:better_muslim/features/notifications/data/alert_texts.dart';
import 'package:better_muslim/features/notifications/data/background.dart';
import 'package:better_muslim/features/notifications/domain/alert.dart';
import 'package:better_muslim/features/notifications/domain/schedule.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' show TZDateTime;

final notificationSchedulerProvider = Provider<NotificationScheduler>(
  (ref) => NotificationScheduler(ref.watch(adhanChannelProvider)),
);

/// every pending notification is replaced on each apply, so none is ever left from before
class NotificationScheduler {
  NotificationScheduler(this._channel);

  final AdhanChannel _channel;
  final _plugin = FlutterLocalNotificationsPlugin();

  /// what kotlin was last given, the dev test adds to it instead of replacing it
  var _native = <Map<String, Object?>>[];

  static const _group = 'adhan';

  /// system surfaces use the dark qiyam emerald, whatever the app's theme
  static final _accent = ThemeEnum.primary.resolve(bmThemes[BmThemeId.qiyamEmerald]!.dark);

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  IOSFlutterLocalNotificationsPlugin? get _ios =>
      _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

  /// asking is its own step, after the location (FR-004). ios keeps the action's title from here,
  /// so this runs again when the language changes
  Future<void> init({required String markPrayed, DidReceiveNotificationResponseCallback? onTap}) =>
      _plugin.initialize(
        settings: InitializationSettings(
          android: const AndroidInitializationSettings('ic_notification'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
            notificationCategories: [
              /// no foreground and no unlock, the log is written from the lock screen (research R5)
              DarwinNotificationCategory(
                _group,
                actions: [DarwinNotificationAction.plain(markPrayedAction, markPrayed)],
              ),
            ],
          ),
        ),
        onDidReceiveNotificationResponse: onTap,
        onDidReceiveBackgroundNotificationResponse: onNotificationActionInBackground,
      );

  Future<bool> askPermission() async =>
      await (_ios?.requestPermissions(alert: true, sound: true) ??
          _android?.requestNotificationsPermission()) ??
      false;

  /// android 12+ opens "alarms & reminders" once. refused, adhans come late and with the clip
  Future<bool> askExactAlarms() async {
    final android = _android;
    if (android == null || await android.canScheduleExactNotifications() == true) return true;
    return await android.requestExactAlarmsPermission() ?? false;
  }

  /// a permission granted later in the phone's settings is picked up here (FR-006)
  Future<bool> isAllowed() async {
    final ios = _ios;
    if (ios != null) return (await ios.checkPermissions())?.isEnabled ?? false;
    return await _android?.areNotificationsEnabled() ?? false;
  }

  /// the payload of the notification that started the app, a tap on its action doesn't count
  Future<String?> launchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    final response = details?.notificationResponse;
    if (details?.didNotificationLaunchApp != true || response?.actionId != null) return null;
    return response?.payload;
  }

  Future<List<int>> activeIds() async => [
    for (final notification in await _plugin.getActiveNotifications()) ?notification.id,
  ];

  /// also removes kotlin's plain adhan notification, they share the id
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  /// no location, nothing can be right
  Future<void> cancelAll() async {
    await _plugin.cancelAllPendingNotifications();
    await _channel.cancelAll();
  }

  /// what kotlin needs to fire and play an adhan on its own (data-model.md, alarm entry)
  static Map<String, Object?> entryOf(Alert alert, AlertTexts texts, AdhanRecording recording) => {
    'id': alert.id,
    'atMillis': alert.at.millisecondsSinceEpoch,
    'payload': payloadOf(alert),
    'asset': recording.fullAsset(alert.prayer),
    'channel': channelId(alert.prayer, PrayerSound.adhan, recording),
    'title': texts.titleOf(alert),
    'body': texts.bodyOf(alert),
    'mediaTitle': texts.titleOf(alert),
    'mediaSubtitle': texts.tr(recording.subtitleKey),

    /// android draws the app name before it, "Better Muslim · Adhan"
    'subText': texts.tr(StringsManager.soundAdhan),
    'actions': {
      'markPrayed': texts.tr(StringsManager.markPrayed),
      'stop': texts.tr(StringsManager.stop),
      'pause': texts.tr(StringsManager.pause),
      'play': texts.tr(StringsManager.play),
    },
  };

  /// errors carry only the step, never a payload, a place or a time (FR-040)
  Future<void> apply({
    required List<Alert> alerts,
    required Map<Prayer, PrayerSound> sounds,
    required Map<Prayer, AdhanRecording> recordings,
    required AlertTexts texts,
  }) async {
    try {
      await _plugin.cancelAllPendingNotifications();
      await _channel.cancelAll();
      await _ensureChannels(sounds, recordings, texts);
      final exact = await _android?.canScheduleExactNotifications() ?? false;
      final native = <Map<String, Object?>>[];
      for (final alert in alerts) {
        /// the full adhan needs code at prayer time with the app closed, the plugin can't run it.
        /// without exact alarms it stays with the plugin and its clip (FR-023)
        final recording = recordings[alert.prayer] ?? AdhanRecording.makkah;
        if (exact && alert.kind == AlertKind.adhan && alert.sound == PrayerSound.adhan) {
          native.add(entryOf(alert, texts, recording));
          continue;
        }
        await _plugin.zonedSchedule(
          id: alert.id,
          scheduledDate: alert.at,
          notificationDetails: _details(alert, texts, recording),
          androidScheduleMode: exact
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexactAllowWhileIdle,
          title: texts.titleOf(alert),
          body: texts.bodyOf(alert),
          payload: payloadOf(alert),
        );
      }
      if (_ios != null) {
        if (quietNoticeAt(alerts) case final at?) {
          await _plugin.zonedSchedule(
            id: quietAlertId,
            scheduledDate: at,
            notificationDetails: const NotificationDetails(
              iOS: DarwinNotificationDetails(presentSound: false),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            title: texts.tr(StringsManager.notifQuietTitle),
            body: texts.tr(StringsManager.notifQuietBody),
          );
        }
      }
      _native = native;
      if (native.isNotEmpty) await _channel.schedule(native);
    } catch (error, stack) {
      await CrashReporter.instance.recordError(error, stack, context: const {'step': 'schedule'});
    }
  }

  /// the dev page's check: the next prayer's notification with its sound, a minute from now
  Future<void> testIn1Minute(Alert next, AlertTexts texts, AdhanRecording recording) async {
    final at = TZDateTime.now(next.at.location).add(const Duration(minutes: 1));
    final alert = Alert(
      day: next.day,
      prayer: next.prayer,
      kind: AlertKind.adhan,
      at: at,
      sound: next.sound,
    );
    final exact = await _android?.canScheduleExactNotifications() ?? false;
    if (exact && alert.sound == PrayerSound.adhan) {
      await _channel.schedule([
        ..._native,
        {...entryOf(alert, texts, recording), 'id': testAlertId},
      ]);
      return;
    }
    await _plugin.zonedSchedule(
      id: testAlertId,
      scheduledDate: at,
      notificationDetails: _details(alert, texts, recording),
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      title: texts.titleOf(alert),
      body: texts.bodyOf(alert),
      payload: payloadOf(alert),
    );
  }

  /// one entry per prayer in the phone's settings: every other channel of the prayer is deleted,
  /// milestone 5's adhan_{prayer}_adhan too
  Future<void> _ensureChannels(
    Map<Prayer, PrayerSound> sounds,
    Map<Prayer, AdhanRecording> recordings,
    AlertTexts texts,
  ) async {
    final android = _android;
    if (android == null) return;
    await android.createNotificationChannel(_reminders(texts));
    await android.createNotificationChannel(_azkar(texts));
    await android.createNotificationChannelGroup(
      AndroidNotificationChannelGroup(_group, texts.tr(StringsManager.soundAdhan)),
    );
    for (final MapEntry(key: prayer, value: sound) in sounds.entries) {
      final recording = recordings[prayer] ?? AdhanRecording.makkah;
      final kept = channelId(prayer, sound, recording);
      await android.createNotificationChannel(_channelOf(prayer, sound, recording, texts));
      for (final other in channelIdsOf(prayer).where((id) => id != kept)) {
        await android.deleteNotificationChannel(channelId: other);
      }
    }
  }

  /// android fixes a channel's sound when it is made, so each recording needs its own id
  static String channelId(Prayer prayer, PrayerSound sound, AdhanRecording recording) =>
      sound == PrayerSound.adhan
      ? 'adhan_${prayer.name}_adhan_${recording.name}'
      : 'adhan_${prayer.name}_${sound.name}';

  /// every id the prayer has ever had, so an apply can leave exactly one
  static List<String> channelIdsOf(Prayer prayer) => [
    'adhan_${prayer.name}_adhan',
    for (final sound in PrayerSound.values)
      if (sound != PrayerSound.adhan) channelId(prayer, sound, AdhanRecording.makkah),
    for (final recording in AdhanRecording.values) channelId(prayer, PrayerSound.adhan, recording),
  ];

  AndroidNotificationChannel _channelOf(
    Prayer prayer,
    PrayerSound sound,
    AdhanRecording recording,
    AlertTexts texts,
  ) => AndroidNotificationChannel(
    channelId(prayer, sound, recording),
    texts.tr(prayer.nameKey),
    groupId: _group,
    importance: Importance.high,
    playSound: sound != PrayerSound.silent,
    sound: sound == PrayerSound.adhan
        ? RawResourceAndroidNotificationSound(recording.clipOf(prayer))
        : null,
    enableVibration: sound != PrayerSound.silent,
  );

  /// one category for all five, default importance and the phone's own sound (FR-017)
  static AndroidNotificationChannel _reminders(AlertTexts texts) =>
      AndroidNotificationChannel('reminders', texts.tr(StringsManager.reminders));

  /// the nudges never make a sound or buzz (FR-037)
  static AndroidNotificationChannel _azkar(AlertTexts texts) => AndroidNotificationChannel(
    'azkar',
    texts.tr(StringsManager.tabAzkar),
    playSound: false,
    enableVibration: false,
  );

  NotificationDetails _details(Alert alert, AlertTexts texts, AdhanRecording recording) {
    if (alert.kind == AlertKind.azkar) {
      final channel = _azkar(texts);
      return NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          playSound: false,
          enableVibration: false,
          color: _accent,
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: const DarwinNotificationDetails(
          presentSound: false,
          presentBanner: true,
          presentList: true,
          interruptionLevel: InterruptionLevel.passive,
        ),
      );
    }
    if (alert.kind == AlertKind.reminder) {
      final channel = _reminders(texts);
      return NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          color: _accent,
          category: AndroidNotificationCategory.reminder,
        ),

        /// into the list, no sound and no lit screen (FR-035)
        iOS: const DarwinNotificationDetails(
          presentSound: false,
          presentBanner: true,
          presentList: true,
          interruptionLevel: InterruptionLevel.passive,
        ),
      );
    }
    final channel = _channelOf(alert.prayer, alert.sound, recording, texts);
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
        actions: [
          AndroidNotificationAction(
            markPrayedAction,
            texts.tr(StringsManager.markPrayed),
            showsUserInterface: false,
            cancelNotification: true,
          ),
        ],
      ),

      /// ios plays the clip with the app closed. in front the adhan screen plays the full adhan
      /// instead, so the adhan notification itself stays out of the way (FR-021)
      iOS: DarwinNotificationDetails(
        sound: sound == PrayerSound.adhan ? '${recording.clipOf(alert.prayer)}.caf' : null,
        presentSound: sound == PrayerSound.tone,
        presentBanner: sound != PrayerSound.adhan,
        presentList: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
        categoryIdentifier: _group,
      ),
    );
  }
}
