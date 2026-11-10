import 'package:better_muslim/core/azkar/azkar_window.dart';
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
import 'package:flutter/foundation.dart';
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

  /// the countdown posts on its prayer's channel now, so the reminder sounds like the prayer
  static const _oldReminderChannels = ['reminders', 'prayer_countdown', 'prayer_reminders'];

  /// system surfaces use the dark qiyam emerald, whatever the app's theme
  static final _accent = ThemeEnum.primary.resolve(bmThemes[BmThemeId.qiyamEmerald]!.dark);

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  IOSFlutterLocalNotificationsPlugin? get _ios =>
      _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

  /// asking is its own step, after the location (FR-004). ios keeps the actions' titles from here,
  /// so this runs again when the language changes
  Future<void> init({
    required String markPrayed,
    required String addToQada,
    DidReceiveNotificationResponseCallback? onTap,
  }) => _plugin.initialize(
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
            actions: [
              DarwinNotificationAction.plain(markPrayedAction, markPrayed),
              DarwinNotificationAction.plain(addToQadaAction, addToQada),
            ],
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

  /// null off android
  Future<bool?> canExactAlarms() async => _android?.canScheduleExactNotifications();

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

  /// android replaces its own at each prayer, ios only here
  bool get keepsOldOnes => defaultTargetPlatform == TargetPlatform.iOS;

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
  static Map<String, Object?> entryOf(
    Alert alert,
    AlertTexts texts,
    AdhanRecording recording, {
    PrayerTone tone = PrayerTone.phone,
    bool full = true,
  }) => {
    'id': alert.id,
    'atMillis': alert.at.millisecondsSinceEpoch,
    'full': full,

    /// an adhan that can't play comes quiet, the channel's sound is the reminder's takbir
    'adhan': alert.sound == PrayerSound.adhan,
    'payload': payloadOf(alert),

    /// its tap after the adhan, a sound of silent opens the prayer instead of the adhan again
    'quietPayload': payloadOf(
      Alert(
        day: alert.day,
        prayer: alert.prayer,
        kind: alert.kind,
        at: alert.at,
        sound: PrayerSound.silent,
      ),
    ),
    'asset': recording.fullAsset(alert.prayer),
    'channel': channelId(alert.prayer, alert.sound, recording, tone: tone),
    'title': texts.titleOf(alert),
    'body': texts.bodyOf(alert),
    'mediaTitle': texts.titleOf(alert),
    'mediaSubtitle': texts.tr(recording.subtitleOf(alert.prayer)),

    /// android draws the app name before it, "Better Muslim · Adhan"
    'subText': texts.tr(StringsManager.soundAdhan),
    'actions': {
      'markPrayed': texts.tr(StringsManager.markPrayed),
      'addToQada': texts.tr(StringsManager.addToQada),
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
    required Map<Prayer, PrayerTone> tones,
    required AlertTexts texts,
    bool azkarVoice = true,
  }) async {
    try {
      await _plugin.cancelAllPendingNotifications();
      await _channel.cancelAll();
      await _ensureChannels(sounds, recordings, tones, azkarVoice, texts);
      final exact = await _android?.canScheduleExactNotifications() ?? false;
      final native = <Map<String, Object?>>[];
      for (final alert in alerts) {
        /// the countdown is android's reminder
        if (_android != null && alert.kind == AlertKind.reminder) continue;

        /// every prayer time needs code on android: it removes the last prayer's notification and
        /// posts one that stays. without exact alarms the full adhan can't start, it comes quiet
        /// (FR-023)
        final recording = recordings[alert.prayer] ?? AdhanRecording.alafasy;
        final tone = tones[alert.prayer] ?? PrayerTone.phone;
        if (_android != null && alert.kind == AlertKind.adhan) {
          final full = exact && alert.sound == PrayerSound.adhan;
          native.add(entryOf(alert, texts, recording, tone: tone, full: full));
          continue;
        }
        await _plugin.zonedSchedule(
          id: alert.id,
          scheduledDate: alert.at,
          notificationDetails: alert.kind == AlertKind.azkar
              ? _azkarDetails(alert, texts, voice: azkarVoice)
              : _details(alert, texts, recording, tone),
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
  Future<void> testIn1Minute(
    Alert next,
    AlertTexts texts,
    AdhanRecording recording,
    PrayerTone tone, {
    Duration after = const Duration(minutes: 1),
  }) async {
    final at = TZDateTime.now(next.at.location).add(after);
    final alert = Alert(
      day: next.day,
      prayer: next.prayer,
      kind: AlertKind.adhan,
      at: at,
      sound: next.sound,
    );
    final exact = await _android?.canScheduleExactNotifications() ?? false;
    if (_android != null) {
      final full = exact && alert.sound == PrayerSound.adhan;
      await _channel.schedule([
        ..._native,
        {...entryOf(alert, texts, recording, tone: tone, full: full), 'id': testAlertId},
      ]);
      return;
    }
    await _plugin.zonedSchedule(
      id: testAlertId,
      scheduledDate: at,
      notificationDetails: _details(alert, texts, recording, tone),
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      title: texts.titleOf(alert),
      body: texts.bodyOf(alert),
      payload: payloadOf(alert),
    );
  }

  /// the dev page's check of one set's nudge and its voice, a minute from now
  Future<void> testAzkarIn1Minute(
    AzkarSet set,
    DateTime day,
    AlertTexts texts, {
    required bool voice,
  }) async {
    final alert = Alert(
      day: day,
      prayer: set.nudgePrayer,
      kind: AlertKind.azkar,
      at: TZDateTime.now(texts.location.zone).add(const Duration(minutes: 1)),
      sound: PrayerSound.silent,
    );
    await _plugin.zonedSchedule(
      id: testAlertId,
      scheduledDate: alert.at,
      notificationDetails: _azkarDetails(alert, texts, voice: voice),
      androidScheduleMode: await _android?.canScheduleExactNotifications() ?? false
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
    Map<Prayer, PrayerTone> tones,
    bool azkarVoice,
    AlertTexts texts,
  ) async {
    final android = _android;
    if (android == null) return;
    for (final old in _oldReminderChannels) {
      await android.deleteNotificationChannel(channelId: old);
    }
    final azkar = azkarVoice
        ? [for (final set in AzkarSet.values) _azkar(texts, set)]
        : [_azkar(texts)];
    for (final channel in azkar) {
      await android.createNotificationChannel(channel);
    }
    for (final id in _azkarChannelIds.where((id) => azkar.every((channel) => channel.id != id))) {
      await android.deleteNotificationChannel(channelId: id);
    }
    await android.createNotificationChannelGroup(
      AndroidNotificationChannelGroup(_group, texts.tr(StringsManager.soundAdhan)),
    );
    for (final MapEntry(key: prayer, value: sound) in sounds.entries) {
      final recording = recordings[prayer] ?? AdhanRecording.alafasy;
      final tone = tones[prayer] ?? PrayerTone.phone;
      final kept = channelId(prayer, sound, recording, tone: tone);
      await android.createNotificationChannel(_channelOf(prayer, sound, recording, tone, texts));
      for (final other in channelIdsOf(prayer).where((id) => id != kept)) {
        await android.deleteNotificationChannel(channelId: other);
      }
    }
  }

  /// android fixes a channel's sound when it is made, so each recording and tone needs its own id.
  /// the phone's tone keeps the old id, a sound changed in the phone's settings stays
  static String channelId(
    Prayer prayer,
    PrayerSound sound,
    AdhanRecording recording, {
    PrayerTone tone = PrayerTone.phone,
  }) => switch (sound) {
    PrayerSound.adhan => 'adhan_${prayer.name}_adhan_${recording.name}',
    PrayerSound.tone when tone != PrayerTone.phone => 'adhan_${prayer.name}_tone_${tone.name}',
    _ => 'adhan_${prayer.name}_${sound.name}',
  };

  /// every id the prayer has ever had, so an apply can leave exactly one
  static List<String> channelIdsOf(Prayer prayer) => [
    'adhan_${prayer.name}_adhan',
    for (final sound in PrayerSound.values)
      if (sound != PrayerSound.adhan) channelId(prayer, sound, AdhanRecording.alafasy),
    for (final recording in AdhanRecording.values) channelId(prayer, PrayerSound.adhan, recording),
    for (final tone in PrayerTone.values)
      if (tone != PrayerTone.phone)
        channelId(prayer, PrayerSound.tone, AdhanRecording.alafasy, tone: tone),
    for (final name in _removedRecordings) 'adhan_${prayer.name}_adhan_$name',
  ];

  /// taken out of the app, a phone that picked one still has its channel
  static const _removedRecordings = ['aaqibAzeez', 'andrewler', 'synagda', 'madinah'];

  AndroidNotificationChannel _channelOf(
    Prayer prayer,
    PrayerSound sound,
    AdhanRecording recording,
    PrayerTone tone,
    AlertTexts texts,
  ) => AndroidNotificationChannel(
    channelId(prayer, sound, recording, tone: tone),
    texts.tr(prayer.nameKey),
    groupId: _group,
    importance: Importance.high,
    playSound: sound != PrayerSound.silent,
    sound: switch (sound) {
      PrayerSound.adhan => RawResourceAndroidNotificationSound(recording.androidClipOf(prayer)),
      PrayerSound.tone when tone.file != null => RawResourceAndroidNotificationSound(tone.file),
      _ => null,
    },
    enableVibration: sound != PrayerSound.silent,
  );

  static final _azkarChannelIds = ['azkar', for (final set in AzkarSet.values) 'azkar_${set.name}'];

  /// the nudges never buzz. with the voice each set needs its own channel, android fixes its sound
  static AndroidNotificationChannel _azkar(AlertTexts texts, [AzkarSet? voice]) => voice == null
      ? AndroidNotificationChannel(
          'azkar',
          texts.tr(StringsManager.tabAzkar),
          playSound: false,
          enableVibration: false,
        )
      : AndroidNotificationChannel(
          'azkar_${voice.name}',
          texts.tr(voice.titleKey),
          sound: RawResourceAndroidNotificationSound('azkar_${voice.name}'),
          enableVibration: false,
        );

  NotificationDetails _azkarDetails(Alert alert, AlertTexts texts, {required bool voice}) {
    final set = azkarSetOf(alert.prayer);
    final channel = _azkar(texts, voice ? set : null);
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        playSound: channel.playSound,
        sound: channel.sound,
        enableVibration: false,
        color: _accent,
        category: AndroidNotificationCategory.reminder,
        timeoutAfter: alert.lasts?.inMilliseconds,
      ),

      /// passive can't make a sound, the voice needs active
      iOS: DarwinNotificationDetails(
        sound: voice ? 'azkar_${set.name}.caf' : null,
        presentSound: voice,
        presentBanner: true,
        presentList: true,
        interruptionLevel: voice ? InterruptionLevel.active : InterruptionLevel.passive,
      ),
    );
  }

  NotificationDetails _details(
    Alert alert,
    AlertTexts texts,
    AdhanRecording recording,
    PrayerTone tone,
  ) {
    final sound = alert.sound;
    final tonePath = tone.file == null ? null : '${tone.file}.caf';

    /// the takbir is the reminder's, never the prayer time's
    if (alert.kind == AlertKind.reminder) {
      return NotificationDetails(
        iOS: DarwinNotificationDetails(
          sound: switch (sound) {
            PrayerSound.adhan => '${recording.clipOf(alert.prayer)}.caf',
            PrayerSound.tone => tonePath,
            PrayerSound.silent => null,
          },
          presentSound: sound != PrayerSound.silent,
          presentBanner: true,
          presentList: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
          threadIdentifier: _group,
        ),
      );
    }
    final adhan = sound == PrayerSound.adhan;
    return NotificationDetails(
      /// ios can't play the full adhan closed, the phone's sound comes instead. in front the adhan
      /// screen plays it, the phone's sound rings there too since ios ties both (FR-021)
      iOS: DarwinNotificationDetails(
        sound: sound == PrayerSound.tone ? tonePath : null,
        presentSound: sound != PrayerSound.silent,
        presentBanner: !adhan,
        presentList: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
        categoryIdentifier: _group,
        threadIdentifier: _group,
      ),
    );
  }
}
