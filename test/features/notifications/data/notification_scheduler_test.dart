import 'package:better_muslim/core/app/app_localizations.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/monitoring/crash_reporter.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/settings/adhan_recording.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/notifications/data/adhan_channel.dart';
import 'package:better_muslim/features/notifications/data/alert_texts.dart';
import 'package:better_muslim/features/notifications/data/notification_scheduler.dart';
import 'package:better_muslim/features/notifications/domain/alert.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' show TZDateTime, getLocation;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AlertTexts texts;
  late _FakeChannel channel;

  setUpAll(() async {
    tz.initializeTimeZones();
    await initializeDateFormatting();
    texts = AlertTexts(
      l10n: await AppLocalizations.load(const Locale('en')),
      language: 'en',
      use24h: true,
      digits: Digits.eastern,
      location: Location(
        latitude: 21.4225,
        longitude: 39.8262,
        placeName: 'Makkah',
        zone: getLocation('Asia/Riyadh'),
        mode: LocationMode.auto,
      ),
    );
  });

  setUp(() => channel = _FakeChannel());
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  const sounds = {
    Prayer.fajr: PrayerSound.adhan,
    Prayer.dhuhr: PrayerSound.tone,
    Prayer.asr: PrayerSound.tone,
    Prayer.maghrib: PrayerSound.adhan,
    Prayer.isha: PrayerSound.silent,
  };

  final recordings = {for (final prayer in Prayer.values) prayer: AdhanRecording.alafasy};
  final tones = {for (final prayer in Prayer.values) prayer: PrayerTone.phone};
  final glass = {...tones, Prayer.asr: PrayerTone.glass};

  Alert alertOf(Prayer prayer, int hour, int minute) => Alert(
    day: DateTime(2026, 10, 15),
    prayer: prayer,
    kind: AlertKind.adhan,
    at: TZDateTime(getLocation('Asia/Riyadh'), 2026, 10, 15, hour, minute),
    sound: sounds[prayer]!,
  );

  Alert reminderOf(Prayer prayer) => Alert(
    day: DateTime(2026, 10, 15),
    prayer: prayer,
    kind: AlertKind.reminder,
    at: TZDateTime(getLocation('Asia/Riyadh'), 2026, 10, 15, 17, 46),
    sound: sounds[prayer]!,
    before: const Duration(minutes: 10),
  );

  Alert nudgeOf({Duration? lasts}) => Alert(
    day: DateTime(2026, 10, 15),
    prayer: Prayer.asr,
    kind: AlertKind.azkar,
    at: TZDateTime(getLocation('Asia/Riyadh'), 2026, 10, 15, 15, 47),
    sound: PrayerSound.silent,
    lasts: lasts,
  );

  late final alerts = [
    alertOf(Prayer.asr, 15, 27),
    alertOf(Prayer.maghrib, 17, 56),
    alertOf(Prayer.isha, 19, 26),
  ];

  _FakeAndroid useAndroid({bool exact = true}) {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final fake = _FakeAndroid(exact: exact);
    FlutterLocalNotificationsPlatform.instance = fake;
    return fake;
  }

  _FakeIos useIos() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final fake = _FakeIos();
    FlutterLocalNotificationsPlatform.instance = fake;
    return fake;
  }

  group('android', () {
    test('cancels every pending one before anything else', () async {
      final android = useAndroid();

      await NotificationScheduler(
        channel,
      ).apply(alerts: alerts, sounds: sounds, recordings: recordings, tones: tones, texts: texts);

      expect(android.calls.first, 'cancelAllPending');
      expect(channel.calls, ['cancelAll', 'schedule']);
    });

    test('the same alerts again schedule nothing, one that went off is no change', () async {
      final android = useAndroid();
      final scheduler = NotificationScheduler(channel);
      final now = TZDateTime.now(getLocation('Asia/Riyadh'));
      Alert at(Prayer prayer, Duration from) => Alert(
        day: DateTime(now.year, now.month, now.day),
        prayer: prayer,
        kind: AlertKind.adhan,
        at: now.add(from),
        sound: sounds[prayer]!,
      );
      final past = at(Prayer.asr, const Duration(hours: -1));
      final next = at(Prayer.maghrib, const Duration(hours: 1));
      Future<void> apply(List<Alert> alerts) => scheduler.apply(
        alerts: alerts,
        sounds: sounds,
        recordings: recordings,
        tones: tones,
        texts: texts,
      );

      await apply([past, next]);
      await apply([past, next]);
      await apply([next]);
      expect(android.calls.where((call) => call == 'cancelAllPending'), hasLength(1));
      expect(channel.calls, ['cancelAll', 'schedule']);

      await apply([next, at(Prayer.isha, const Duration(hours: 2))]);
      expect(channel.calls, ['cancelAll', 'schedule', 'cancelAll', 'schedule']);

      await scheduler.cancelAll();
      await apply([next, at(Prayer.isha, const Duration(hours: 2))]);
      expect(channel.calls.where((call) => call == 'schedule'), hasLength(3));
    });

    test('one silent channel per prayer that still buzzes, every older id is deleted', () async {
      final android = useAndroid(exact: false);

      await NotificationScheduler(
        channel,
      ).apply(alerts: alerts, sounds: sounds, recordings: recordings, tones: tones, texts: texts);

      final adhan = android.channels.where((channel) => channel.id.startsWith('adhan_')).toList();
      expect(adhan.map((channel) => channel.id), [
        'adhan_fajr_alert',
        'adhan_dhuhr_alert',
        'adhan_asr_alert',
        'adhan_maghrib_alert',
        'adhan_isha_silent',
      ]);
      expect(adhan.map((channel) => channel.playSound), everyElement(isFalse));
      expect(adhan.map((channel) => channel.enableVibration), [true, true, true, true, false]);
      expect(adhan.map((channel) => channel.importance), everyElement(Importance.high));

      /// the ids that carried a sound go, so the phone lists one per prayer
      expect(
        android.deleted,
        containsAll([
          'adhan_maghrib_tone',
          'adhan_maghrib_silent',
          'adhan_maghrib_adhan',
          'adhan_maghrib_adhan_alafasy',
          'adhan_maghrib_adhan_aaqibAzeez',
          'adhan_maghrib_adhan_madinah',
          'adhan_asr_tone_glass',
        ]),
      );
      expect(android.deleted, isNot(contains('adhan_maghrib_alert')));
      expect(channel.entries.map((entry) => entry['channel']), [
        'adhan_asr_alert',
        'adhan_maghrib_alert',
        'adhan_isha_silent',
      ]);
    });

    test(
      'a nudge goes to kotlin, it says its set\'s name and goes when the next one comes',
      () async {
        final android = useAndroid();

        await NotificationScheduler(channel).apply(
          alerts: [nudgeOf(lasts: const Duration(hours: 12))],
          sounds: sounds,
          recordings: recordings,
          tones: tones,
          texts: texts,
        );

        expect(android.scheduled, isEmpty);
        final entry = channel.entries.single;
        expect(entry['id'], nudgeOf().id);
        expect(entry['kind'], 'azkar');
        expect(entry['full'], isFalse);
        expect(entry['clip'], 'azkar_evening');
        expect(entry['channel'], 'azkar_voice');
        expect(entry['lasts'], 43200000);
        expect(entry['payload'], payloadOf(nudgeOf()));
        expect(entry['title'], texts.titleOf(nudgeOf()));
      },
    );

    test('the voice channel only drops the banner, without the voice the nudge is quiet', () async {
      final voice = useAndroid();
      await NotificationScheduler(channel).apply(
        alerts: [nudgeOf()],
        sounds: sounds,
        recordings: recordings,
        tones: tones,
        texts: texts,
      );
      final azkar = voice.channels.firstWhere((channel) => channel.id == 'azkar_voice');
      expect([azkar.playSound, azkar.enableVibration], [false, false]);
      expect(azkar.importance, Importance.high);
      expect(
        voice.deleted,
        containsAll([
          'azkar',
          'azkar_morning',
          'azkar_evening',
          'azkar_morning_2',
          'azkar_evening_2',
        ]),
      );

      final quiet = useAndroid();
      await NotificationScheduler(channel).apply(
        alerts: [nudgeOf()],
        sounds: sounds,
        recordings: recordings,
        tones: tones,
        texts: texts,
        azkarVoice: false,
      );
      expect(quiet.channels.firstWhere((channel) => channel.id == 'azkar').playSound, isFalse);
      expect(quiet.deleted, contains('azkar_voice'));
      expect(channel.entries.single['channel'], 'azkar');
      expect(channel.entries.single.containsKey('clip'), isFalse);
    });

    test('with exact alarms every prayer goes to kotlin, only the adhan plays in full', () async {
      final android = useAndroid();

      await NotificationScheduler(
        channel,
      ).apply(alerts: alerts, sounds: sounds, recordings: recordings, tones: tones, texts: texts);

      expect(channel.calls, ['cancelAll', 'schedule']);
      expect(android.scheduled, isEmpty);
      expect(channel.entries.map((entry) => entry['id']), alerts.map((alert) => alert.id));
      expect(channel.entries.map((entry) => entry['full']), [false, true, false]);
      expect(channel.entries.map((entry) => entry['adhan']), [false, true, false]);
      expect(channel.entries.map((entry) => entry['kind']), everyElement('adhan'));

      /// the full adhan is the service's, only the tone is a clip, the phone's own here
      expect(channel.entries.map((entry) => entry['clip']), ['phone', null, null]);
      final entry = channel.entries[1];
      expect(entry['atMillis'], alerts[1].at.millisecondsSinceEpoch);
      expect(entry['payload'], payloadOf(alerts[1]));
      expect(alertFromPayload(entry['quietPayload']! as String)?.sound, PrayerSound.silent);
      expect(entry['asset'], 'assets/audio/adhan_alafasy.m4a');
      expect(entry['channel'], 'adhan_maghrib_alert');
      expect(entry['title'], 'Maghrib time in Makkah');
      expect(entry['mediaSubtitle'], 'Mishary Alafasy');
      expect(entry['subText'], 'Adhan');
      expect(entry['actions'], {
        'markPrayed': 'Mark prayed',
        'addToQada': 'Add to qada',
        'stop': 'Stop',
        'pause': 'Pause',
        'play': 'Play',
      });
    });

    test('without exact alarms no adhan plays in full, kotlin posts it quiet', () async {
      final android = useAndroid(exact: false);

      await NotificationScheduler(
        channel,
      ).apply(alerts: alerts, sounds: sounds, recordings: recordings, tones: tones, texts: texts);

      expect(android.scheduled, isEmpty);
      expect(channel.entries.map((entry) => entry['full']), [false, false, false]);
      expect(channel.entries.map((entry) => entry['adhan']), [false, true, false]);
    });

    test('a tone from the app is its clip', () async {
      useAndroid();

      await NotificationScheduler(
        channel,
      ).apply(alerts: alerts, sounds: sounds, recordings: recordings, tones: glass, texts: texts);

      expect(channel.entries.first['clip'], 'tone_glass');
    });

    test('the countdown is the reminder, kotlin plays its takbir or tone', () async {
      final android = useAndroid();

      await NotificationScheduler(channel).apply(
        alerts: [reminderOf(Prayer.maghrib), reminderOf(Prayer.asr), reminderOf(Prayer.isha)],
        sounds: sounds,
        recordings: recordings,
        tones: glass,
        texts: texts,
      );

      expect(android.channels.map((channel) => channel.id), isNot(contains('prayer_reminders')));
      expect(android.deleted, containsAll(['reminders', 'prayer_countdown', 'prayer_reminders']));
      expect(android.scheduled, isEmpty);

      /// isha is silent, nothing to play
      expect(channel.entries.map((entry) => entry['id']), [
        reminderOf(Prayer.maghrib).id,
        reminderOf(Prayer.asr).id,
      ]);
      expect(channel.entries.map((entry) => entry['kind']), everyElement('reminder'));
      expect(channel.entries.map((entry) => entry['full']), everyElement(isFalse));
      expect(channel.entries.map((entry) => entry['clip']), [
        AdhanRecording.alafasy.androidClipOf(Prayer.maghrib),
        'tone_glass',
      ]);
      expect(channel.entries.first['channel'], 'adhan_maghrib_alert');
    });

    test('a plugin call that throws reports only the step', () async {
      useAndroid();
      channel.throwOnSchedule = true;
      final reporter = _RecordingReporter();
      CrashReporter.instance = reporter;
      addTearDown(() => CrashReporter.instance = const DebugCrashReporter());

      await NotificationScheduler(channel).apply(
        alerts: [nudgeOf()],
        sounds: sounds,
        recordings: recordings,
        tones: tones,
        texts: texts,
      );

      expect(reporter.contexts, [
        {'step': 'schedule'},
      ]);
    });
  });

  group('ios', () {
    test('a nudge says its set\'s name, without the voice it is passive and quiet', () async {
      final ios = useIos();

      for (final voice in [true, false]) {
        await NotificationScheduler(channel).apply(
          alerts: [nudgeOf()],
          sounds: sounds,
          recordings: recordings,
          tones: tones,
          texts: texts,
          azkarVoice: voice,
        );
      }

      final [voice, quiet] = [
        for (final scheduled in ios.scheduled)
          if (scheduled.id == nudgeOf().id) scheduled.details!,
      ];
      expect(voice.sound, 'azkar_evening.caf');
      expect(voice.presentSound, isTrue);
      expect(voice.interruptionLevel, InterruptionLevel.active);
      expect(quiet.sound, isNull);
      expect(quiet.presentSound, isFalse);
      expect(quiet.interruptionLevel, InterruptionLevel.passive);
    });

    test('a reminder sounds like its prayer: the takbir, the tone or nothing', () async {
      final ios = useIos();

      await NotificationScheduler(channel).apply(
        alerts: [reminderOf(Prayer.maghrib), reminderOf(Prayer.asr), reminderOf(Prayer.isha)],
        sounds: sounds,
        recordings: recordings,
        tones: glass,
        texts: texts,
      );

      final [maghrib, asr, isha, _] = ios.scheduled.map((call) => call.details!).toList();
      expect(maghrib.sound, '${AdhanRecording.alafasy.clipOf(Prayer.maghrib)}.caf');
      expect(asr.sound, 'tone_glass.caf');
      expect(isha.sound, isNull);
      expect([maghrib.presentSound, asr.presentSound, isha.presentSound], [true, true, false]);
      for (final details in [maghrib, asr, isha]) {
        expect(details.interruptionLevel, InterruptionLevel.timeSensitive);
        expect([details.presentBanner, details.categoryIdentifier], [true, null]);
      }
    });

    test('adhan, tone and silent follow research R2', () async {
      final ios = useIos();

      await NotificationScheduler(
        channel,
      ).apply(alerts: alerts, sounds: sounds, recordings: recordings, tones: tones, texts: texts);

      expect(ios.calls.first, 'cancelAllPending');
      final [asr, maghrib, isha, _] = ios.scheduled.map((call) => call.details!).toList();

      /// the phone's own sound, the takbir is the reminder's
      expect(maghrib.sound, isNull);
      expect(
        [maghrib.presentSound, maghrib.presentBanner, maghrib.presentList],
        [true, false, true],
      );
      expect(asr.sound, isNull);
      expect([asr.presentSound, asr.presentBanner, asr.presentList], [true, true, true]);
      expect(isha.sound, isNull);
      expect([isha.presentSound, isha.presentBanner, isha.presentList], [false, true, true]);
      for (final details in [asr, maghrib, isha]) {
        expect(details.interruptionLevel, InterruptionLevel.timeSensitive);
        expect(details.categoryIdentifier, 'adhan');
      }
    });

    test('a tone from the app plays its caf at the prayer time', () async {
      final ios = useIos();

      await NotificationScheduler(
        channel,
      ).apply(alerts: alerts, sounds: sounds, recordings: recordings, tones: glass, texts: texts);

      expect(ios.scheduled.first.details!.sound, 'tone_glass.caf');
    });

    test('titles, bodies and payloads, no place in the payload', () async {
      final ios = useIos();

      await NotificationScheduler(
        channel,
      ).apply(alerts: alerts, sounds: sounds, recordings: recordings, tones: tones, texts: texts);

      final maghrib = ios.scheduled[1];
      expect(maghrib.id, alerts[1].id);
      expect(maghrib.title, 'Maghrib time in Makkah');
      expect(maghrib.body, '17:56');
      expect(maghrib.payload, payloadOf(alerts[1]));
      expect(maghrib.payload, isNot(contains('Makkah')));
    });

    test('half an hour after the last alert one asks to open the app', () async {
      final ios = useIos();

      await NotificationScheduler(
        channel,
      ).apply(alerts: alerts, sounds: sounds, recordings: recordings, tones: tones, texts: texts);

      final quiet = ios.scheduled.last;
      expect(quiet.id, quietAlertId);
      expect(quiet.title, 'Keep the adhan coming');
      expect(quiet.payload, isNull);
      expect(ios.scheduled, hasLength(alerts.length + 1));
    });
  });
}

typedef _Scheduled<T> = ({
  int id,
  String? title,
  String? body,
  String? payload,
  T? details,
  AndroidScheduleMode? mode,
});

class _FakeAndroid extends AndroidFlutterLocalNotificationsPlugin {
  _FakeAndroid({required this.exact});

  final bool exact;
  final calls = <String>[];
  final scheduled = <_Scheduled<AndroidNotificationDetails>>[];
  final channels = <AndroidNotificationChannel>[];
  final deleted = <String>[];

  @override
  Future<void> cancelAllPendingNotifications() async => calls.add('cancelAllPending');

  @override
  Future<bool?> canScheduleExactNotifications() async => exact;

  @override
  Future<void> createNotificationChannelGroup(AndroidNotificationChannelGroup group) async {}

  @override
  Future<void> createNotificationChannel(AndroidNotificationChannel channel) async =>
      channels.add(channel);

  @override
  Future<void> deleteNotificationChannel({required String channelId}) async =>
      deleted.add(channelId);

  @override
  Future<void> zonedSchedule({
    required int id,
    String? title,
    String? body,
    required TZDateTime scheduledDate,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
    AndroidNotificationDetails? notificationDetails,
    AndroidScheduleMode scheduleMode = AndroidScheduleMode.exact,
  }) async {
    calls.add('schedule');
    scheduled.add((
      id: id,
      title: title,
      body: body,
      payload: payload,
      details: notificationDetails,
      mode: scheduleMode,
    ));
  }
}

class _FakeIos extends IOSFlutterLocalNotificationsPlugin {
  final calls = <String>[];
  final scheduled = <_Scheduled<DarwinNotificationDetails>>[];

  @override
  Future<void> cancelAllPendingNotifications() async => calls.add('cancelAllPending');

  @override
  Future<void> zonedSchedule({
    required int id,
    String? title,
    String? body,
    required TZDateTime scheduledDate,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
    DarwinNotificationDetails? notificationDetails,
  }) async {
    calls.add('schedule');
    scheduled.add((
      id: id,
      title: title,
      body: body,
      payload: payload,
      details: notificationDetails,
      mode: null,
    ));
  }
}

class _FakeChannel extends AdhanChannel {
  final calls = <String>[];
  List<Map<String, Object?>> entries = [];
  bool throwOnSchedule = false;

  @override
  Future<void> cancelAll() async => calls.add('cancelAll');

  @override
  Future<void> schedule(List<Map<String, Object?>> entries) async {
    if (throwOnSchedule) throw PlatformException(code: 'boom', message: 'Makkah 17:56');
    calls.add('schedule');
    this.entries = entries;
  }
}

class _RecordingReporter implements CrashReporter {
  final contexts = <Map<String, Object?>?>[];

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
    Map<String, Object?>? context,
  }) async => contexts.add(context);

  @override
  void addBreadcrumb(String message, {String? category}) {}
}
