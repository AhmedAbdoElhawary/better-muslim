import 'package:better_muslim/core/azkar/azkar_window.dart';
import 'package:better_muslim/core/monitoring/crash_reporter.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
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

/// every pending notification is replaced on each apply that changes one, so none is left from before
class NotificationScheduler {
  NotificationScheduler(this._channel);

  final AdhanChannel _channel;
  final _plugin = FlutterLocalNotificationsPlugin();

  /// what kotlin was last given, the dev test adds to it instead of replacing it
  var _native = <Map<String, Object?>>[];

  /// what the last apply scheduled, null at start so a cold open always applies
  Map<String, DateTime>? _applied;
  DateTime _appliedAt = DateTime.now();

  static const _group = 'adhan';

  /// the countdown posts on its prayer's channel now, so the reminder sounds like the prayer
  static const _oldReminderChannels = ['reminders', 'prayer_countdown', 'prayer_reminders'];

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
    _applied = null;
    await _plugin.cancelAllPendingNotifications();
    await _channel.cancelAll();
  }

  /// what kotlin needs to fire and play an adhan, a reminder's sound or a nudge on its own
  /// (data-model.md, alarm entry)
  static Map<String, Object?> entryOf(
    Alert alert,
    AlertTexts texts,
    AdhanRecording recording, {
    PrayerTone tone = PrayerTone.phone,
    bool full = true,
    bool voice = true,
  }) => {
    'id': alert.id,
    'atMillis': alert.at.millisecondsSinceEpoch,
    'kind': alert.kind.name,
    'full': full,
    'clip': ?_clipOf(alert, recording, tone, voice: voice),
    'lasts': ?alert.lasts?.inMilliseconds,

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
    'channel': alert.kind == AlertKind.azkar
        ? _azkarChannelOf(voice: voice)
        : channelId(alert.prayer, alert.sound),
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

  /// do not disturb a minute after the prayer, kotlin waits for its adhan to end
  static Map<String, Object?> silenceEntryOf(Alert alert, int minutes) => {
    'id': silenceId(alert.id),
    'atMillis': alert.at.add(const Duration(minutes: 1)).millisecondsSinceEpoch,
    'kind': 'silence',
    'untilMillis': alert.at
        .add(Duration(minutes: silentMinutesOf(alert, minutes)))
        .millisecondsSinceEpoch,
  };

  /// errors carry only the step, never a payload, a place or a time (FR-040)
  Future<void> apply({
    required List<Alert> alerts,
    required Map<Prayer, PrayerSound> sounds,
    required Map<Prayer, AdhanRecording> recordings,
    required Map<Prayer, PrayerTone> tones,
    required AlertTexts texts,
    bool azkarVoice = true,
    bool flipStops = true,
    bool buttonsStop = true,

    /// 0 is off
    int silentMinutes = 0,
  }) async {
    try {
      await _channel.stops(flip: flipStops, buttons: buttonsStop);
      final exact = await _android?.canScheduleExactNotifications() ?? false;
      final keys = {
        for (final alert in alerts)
          [
            alert.id,
            alert.at.millisecondsSinceEpoch,
            alert.kind,
            alert.sound,
            alert.before,
            alert.lasts,
            recordings[alert.prayer],
            tones[alert.prayer],
            texts.titleOf(alert),
            texts.bodyOf(alert),
            exact,
            azkarVoice,
            silentMinutes,
          ].join('|'): alert.at,
      };

      /// the plugin rewrites its whole saved list for each alert on the thread that draws, so a
      /// resume with nothing new skips it. one that went off is gone from the phone already
      final now = DateTime.now();
      final applied = _applied;

      /// a clock moved back by hand brings the ones that went off back, they are set again
      if (applied != null &&
          !now.isBefore(_appliedAt) &&
          keys.keys.every(applied.containsKey) &&
          applied.entries.every(
            (entry) => keys.containsKey(entry.key) || !entry.value.isAfter(now),
          )) {
        return;
      }
      _applied = null;
      await _plugin.cancelAllPendingNotifications();
      await _channel.cancelAll();
      await _ensureChannels(sounds, azkarVoice, texts);
      final native = <Map<String, Object?>>[];
      for (final alert in alerts) {
        final recording = recordings[alert.prayer] ?? AdhanRecording.alafasy;
        final tone = tones[alert.prayer] ?? PrayerTone.phone;

        /// everything is kotlin's on android: a prayer time removes the last prayer's notification
        /// and posts one that stays, and it plays every sound itself (ADR 0006). without exact
        /// alarms the full adhan can't start, it comes quiet (FR-023)
        if (_android != null) {
          /// the countdown is android's reminder, a silent one leaves kotlin nothing to play
          if (alert.kind == AlertKind.reminder && alert.sound == PrayerSound.silent) continue;
          final full = exact && alert.kind == AlertKind.adhan && alert.sound == PrayerSound.adhan;
          native.add(entryOf(alert, texts, recording, tone: tone, full: full, voice: azkarVoice));
          if (silentMinutes > 0 && alert.kind == AlertKind.adhan) {
            native.add(silenceEntryOf(alert, silentMinutes));
          }
          continue;
        }
        await _plugin.zonedSchedule(
          id: alert.id,
          scheduledDate: alert.at,
          notificationDetails: alert.kind == AlertKind.azkar
              ? _azkarDetails(alert, voice: azkarVoice)
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
      _applied = keys;
      _appliedAt = now;
    } catch (error, stack) {
      await CrashReporter.instance.recordError(error, stack, context: const {'step': 'schedule'});
    }
  }

  /// the dev page's check: the next prayer's notification with its sound, a minute from now. the
  /// rehearsal adds its reminder's sound with the countdown
  Future<void> testIn1Minute(
    Alert next,
    AlertTexts texts,
    AdhanRecording recording,
    PrayerTone tone, {
    Duration after = const Duration(minutes: 1),
    Duration? reminder,
  }) async {
    final now = TZDateTime.now(next.at.location);
    final at = now.add(after);
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
        if (reminder != null)
          {
            ...entryOf(
              Alert(
                day: next.day,
                prayer: next.prayer,
                kind: AlertKind.reminder,
                at: now.add(reminder),
                sound: next.sound,
              ),
              texts,
              recording,
              tone: tone,
              full: false,
            ),
            'id': testReminderId,
          },
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
    if (_android != null) {
      return _channel.schedule([
        ..._native,
        {
          ...entryOf(alert, texts, AdhanRecording.alafasy, full: false, voice: voice),
          'id': testAlertId,
        },
      ]);
    }
    await _plugin.zonedSchedule(
      id: testAlertId,
      scheduledDate: alert.at,
      notificationDetails: _azkarDetails(alert, voice: voice),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: texts.titleOf(alert),
      body: texts.bodyOf(alert),
      payload: payloadOf(alert),
    );
  }

  /// one entry per prayer in the phone's settings: every other channel of the prayer is deleted,
  /// milestone 5's adhan_{prayer}_adhan too
  Future<void> _ensureChannels(
    Map<Prayer, PrayerSound> sounds,
    bool azkarVoice,
    AlertTexts texts,
  ) async {
    final android = _android;
    if (android == null) return;
    for (final old in _oldReminderChannels) {
      await android.deleteNotificationChannel(channelId: old);
    }
    final azkar = _azkar(texts, voice: azkarVoice);
    await android.createNotificationChannel(azkar);
    for (final id in _azkarChannelIds.where((id) => id != azkar.id)) {
      await android.deleteNotificationChannel(channelId: id);
    }
    await android.createNotificationChannelGroup(
      AndroidNotificationChannelGroup(_group, texts.tr(StringsManager.soundAdhan)),
    );
    for (final MapEntry(key: prayer, value: sound) in sounds.entries) {
      final kept = channelId(prayer, sound);
      await android.createNotificationChannel(_channelOf(prayer, sound, texts));
      for (final other in channelIdsOf(prayer).where((id) => id != kept)) {
        await android.deleteNotificationChannel(channelId: other);
      }
    }
  }

  /// the channels make no sound, kotlin plays it (ADR 0006). they still buzz, a silent prayer
  /// doesn't
  static String channelId(Prayer prayer, PrayerSound sound) =>
      'adhan_${prayer.name}_${sound == PrayerSound.silent ? 'silent' : 'alert'}';

  /// every id the prayer has ever had, so an apply can leave exactly one
  static List<String> channelIdsOf(Prayer prayer) {
    final id = 'adhan_${prayer.name}';
    return [
      '${id}_alert',
      '${id}_silent',
      '${id}_adhan',
      '${id}_tone',
      for (final tone in PrayerTone.values)
        if (tone != PrayerTone.phone) '${id}_tone_${tone.name}',
      for (final recording in AdhanRecording.values) '${id}_adhan_${recording.name}',
      for (final name in _removedRecordings) '${id}_adhan_$name',
    ];
  }

  /// taken out of the app, a phone that picked one still has its channel
  static const _removedRecordings = ['aaqibAzeez', 'andrewler', 'synagda', 'madinah'];

  static AndroidNotificationChannel _channelOf(
    Prayer prayer,
    PrayerSound sound,
    AlertTexts texts,
  ) => AndroidNotificationChannel(
    channelId(prayer, sound),
    texts.tr(prayer.nameKey),
    groupId: _group,
    importance: Importance.high,
    playSound: false,
    enableVibration: sound != PrayerSound.silent,
  );

  /// the raw clip kotlin plays with the alert. the takbir is the reminder's, the prayer time's
  /// adhan is the full one
  static String? _clipOf(
    Alert alert,
    AdhanRecording recording,
    PrayerTone tone, {
    required bool voice,
  }) => switch ((alert.kind, alert.sound)) {
    (AlertKind.azkar, _) => voice ? 'azkar_${azkarSetOf(alert.prayer).name}' : null,
    (AlertKind.reminder, PrayerSound.adhan) => recording.androidClipOf(alert.prayer),
    (_, PrayerSound.tone) => tone.file ?? _phoneClip,
    _ => null,
  };

  /// kotlin's ClipPlayer.PHONE
  static const _phoneClip = 'phone';

  /// the earlier per set ids carried the voice as the channel's sound
  static final _azkarChannelIds = [
    'azkar',
    'azkar_voice',
    for (final set in AzkarSet.values) ...['azkar_${set.name}', 'azkar_${set.name}_2'],
  ];

  static String _azkarChannelOf({required bool voice}) => voice ? 'azkar_voice' : 'azkar';

  /// the nudges never buzz. with the voice the banner drops down while kotlin says the set's name
  static AndroidNotificationChannel _azkar(AlertTexts texts, {required bool voice}) =>
      AndroidNotificationChannel(
        _azkarChannelOf(voice: voice),
        texts.tr(StringsManager.tabAzkar),
        importance: voice ? Importance.high : Importance.defaultImportance,
        playSound: false,
        enableVibration: false,
      );

  /// ios only, android's nudge is kotlin's
  static NotificationDetails _azkarDetails(Alert alert, {required bool voice}) {
    final set = azkarSetOf(alert.prayer);
    return NotificationDetails(
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
