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

  final recordings = {for (final prayer in Prayer.values) prayer: AdhanRecording.madinah};

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

      await NotificationScheduler(channel)
          .apply(alerts: alerts, sounds: sounds, recordings: recordings, texts: texts);

      expect(android.calls.first, 'cancelAllPending');
      expect(android.calls.where((call) => call == 'schedule'), isNotEmpty);
    });

    test(
      'uses adhan_<prayer>_<sound>, the adhan with its recording, and deletes the rest',
      () async {
        final android = useAndroid(exact: false);

        await NotificationScheduler(channel)
            .apply(alerts: alerts, sounds: sounds, recordings: recordings, texts: texts);

        final adhan = android.channels.where((channel) => channel.id.startsWith('adhan_')).toList();
        expect(adhan.map((channel) => channel.id), [
          'adhan_fajr_adhan_madinah',
          'adhan_dhuhr_tone',
          'adhan_asr_tone',
          'adhan_maghrib_adhan_madinah',
          'adhan_isha_silent',
        ]);

        /// milestone 5's id and the removed recordings go too, so the phone lists one per prayer
        expect(
          android.deleted,
          containsAll([
            'adhan_maghrib_tone',
            'adhan_maghrib_silent',
            'adhan_maghrib_adhan',
            'adhan_maghrib_adhan_aaqibAzeez',
          ]),
        );
        expect(android.deleted, isNot(contains('adhan_maghrib_adhan_madinah')));
        final isha = adhan.last;
        expect([isha.playSound, isha.enableVibration], [false, false]);
        final maghrib = adhan[3];
        expect((maghrib.sound! as RawResourceAndroidNotificationSound).sound, 'adhan_madinah_clip');
        final fajr = adhan.first;
        expect((fajr.sound! as RawResourceAndroidNotificationSound).sound, 'adhan_fajr_clip');
        expect(android.scheduled.map((call) => call.details!.channelId), [
          'adhan_asr_tone',
          'adhan_maghrib_adhan_madinah',
          'adhan_isha_silent',
        ]);
      },
    );

    test('exact while idle when exact alarms are allowed, inexact otherwise', () async {
      final exact = useAndroid();
      await NotificationScheduler(channel)
          .apply(alerts: [alerts.first], sounds: sounds, recordings: recordings, texts: texts);
      expect(exact.scheduled.single.mode, AndroidScheduleMode.exactAllowWhileIdle);

      final inexact = useAndroid(exact: false);
      await NotificationScheduler(channel)
          .apply(alerts: alerts, sounds: sounds, recordings: recordings, texts: texts);
      expect(inexact.scheduled.map((call) => call.mode).toSet(), {
        AndroidScheduleMode.inexactAllowWhileIdle,
      });
    });

    test('with exact alarms, adhan prayers go to kotlin and not the plugin', () async {
      final android = useAndroid();

      await NotificationScheduler(channel)
          .apply(alerts: alerts, sounds: sounds, recordings: recordings, texts: texts);

      expect(channel.calls, ['cancelAll', 'schedule']);
      final [entry] = channel.entries;
      expect(entry['id'], alerts[1].id);
      expect(entry['atMillis'], alerts[1].at.millisecondsSinceEpoch);
      expect(entry['payload'], payloadOf(alerts[1]));
      expect(entry['asset'], 'assets/audio/adhan_madinah.m4a');
      expect(entry['channel'], 'adhan_maghrib_adhan_madinah');
      expect(entry['title'], 'Maghrib · 17:56');
      expect(entry['mediaSubtitle'], 'Adhan of Madinah');
      expect(entry['subText'], 'Adhan');
      expect(entry['actions'], {
        'markPrayed': 'Mark prayed',
        'stop': 'Stop',
        'pause': 'Pause',
        'play': 'Play',
      });
      expect(android.scheduled.map((call) => call.id), [alerts[0].id, alerts[2].id]);
    });

    test('without exact alarms the adhan stays with the plugin and its clip', () async {
      final android = useAndroid(exact: false);

      await NotificationScheduler(channel)
          .apply(alerts: alerts, sounds: sounds, recordings: recordings, texts: texts);

      expect(channel.calls, ['cancelAll']);
      expect(android.scheduled, hasLength(3));
    });

    test('reminders go to the reminders channel at default importance', () async {
      final android = useAndroid();

      await NotificationScheduler(channel).apply(
        alerts: [reminderOf(Prayer.maghrib)],
        sounds: sounds,
        recordings: recordings,
        texts: texts,
      );

      final reminders = android.channels.firstWhere((channel) => channel.id == 'reminders');
      expect(reminders.importance, Importance.defaultImportance);
      expect(reminders.name, 'Reminders');
      final details = android.scheduled.single.details!;
      expect(details.channelId, 'reminders');
      expect(details.actions, isNull);
      expect(android.scheduled.single.title, 'Maghrib in 10 minutes');
      expect(android.scheduled.single.body, '17:56 · Makkah');
      expect(channel.entries, isEmpty);
    });

    test('a plugin call that throws reports only the step', () async {
      useAndroid().throwOnSchedule = true;
      final reporter = _RecordingReporter();
      CrashReporter.instance = reporter;
      addTearDown(() => CrashReporter.instance = const DebugCrashReporter());

      await NotificationScheduler(channel)
          .apply(alerts: alerts, sounds: sounds, recordings: recordings, texts: texts);

      expect(reporter.contexts, [
        {'step': 'schedule'},
      ]);
    });
  });

  group('ios', () {
    test('reminders are passive and silent', () async {
      final ios = useIos();

      await NotificationScheduler(channel).apply(
        alerts: [reminderOf(Prayer.maghrib)],
        sounds: sounds,
        recordings: recordings,
        texts: texts,
      );

      final details = ios.scheduled.first.details!;
      expect(details.interruptionLevel, InterruptionLevel.passive);
      expect(
        [details.presentSound, details.sound, details.categoryIdentifier],
        [false, null, null],
      );
    });

    test('adhan, tone and silent follow research R2', () async {
      final ios = useIos();

      await NotificationScheduler(channel)
          .apply(alerts: alerts, sounds: sounds, recordings: recordings, texts: texts);

      expect(ios.calls.first, 'cancelAllPending');
      final [asr, maghrib, isha, _] = ios.scheduled.map((call) => call.details!).toList();
      expect(maghrib.sound, '${AdhanRecording.madinah.clipOf(Prayer.maghrib)}.caf');
      expect(
        [maghrib.presentSound, maghrib.presentBanner, maghrib.presentList],
        [false, false, true],
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

    test('titles, bodies and payloads, no place in the payload', () async {
      final ios = useIos();

      await NotificationScheduler(channel)
          .apply(alerts: alerts, sounds: sounds, recordings: recordings, texts: texts);

      final maghrib = ios.scheduled[1];
      expect(maghrib.id, alerts[1].id);
      expect(maghrib.title, 'Maghrib · 17:56');
      expect(maghrib.body, 'It is time for Maghrib in Makkah. Tap to mark it prayed.');
      expect(maghrib.payload, payloadOf(alerts[1]));
      expect(maghrib.payload, isNot(contains('Makkah')));
    });

    test('half an hour after the last alert one asks to open the app', () async {
      final ios = useIos();

      await NotificationScheduler(channel)
          .apply(alerts: alerts, sounds: sounds, recordings: recordings, texts: texts);

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
  bool throwOnSchedule = false;
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
    if (throwOnSchedule) throw PlatformException(code: 'boom', message: 'Makkah 17:56');
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

  @override
  Future<void> cancelAll() async => calls.add('cancelAll');

  @override
  Future<void> schedule(List<Map<String, Object?>> entries) async {
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
