import 'dart:ui' show Tristate;

import 'package:better_muslim/core/audio/clip_player.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/network/download.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/adhan_recording.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/grouped_section.dart';
import 'package:better_muslim/core/widgets/toggle_row.dart';
import 'package:better_muslim/features/notifications/data/notification_scheduler.dart';
import 'package:better_muslim/features/notifications/presentation/providers/adhan_providers.dart';
import 'package:better_muslim/features/notifications/presentation/view/widgets/prayer_sound_row.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../../helpers/azkar.dart';
import '../../../../helpers/fonts.dart';
import '../../../../helpers/more.dart';
import '../../../../helpers/notifications.dart';
import '../../../../helpers/prayer.dart';
import '../../../../helpers/providers.dart';

void main() {
  setUpAll(() async {
    tz.initializeTimeZones();
    await loadAppFonts();
  });

  late List<MethodCall> system;
  late FakeClipPlayer clips;
  setUp(() {
    system = mockSystemChannel();
    clips = FakeClipPlayer();
  });

  Future<void> open(
    WidgetTester tester, {
    bool allowed = true,
    FakeScheduler? scheduler,
    Locale locale = const Locale('en'),
    double textScale = 1,
    AdhanDownloadNotifier Function(AdhanRecording recording)? downloads,
  }) async => pumpMore(
    tester,
    <Override>[
      ...await designOverrides(),
      notificationSchedulerProvider.overrideWithValue(scheduler ?? FakeScheduler(allowed: allowed)),
      clipPlayerProvider.overrideWithValue(clips),
      if (downloads != null)
        for (final recording in AdhanRecording.values)
          adhanDownloadProvider(recording).overrideWith(() => downloads(recording)),
    ],
    push: Routes.adhanSettings,
    locale: locale,
    textScale: textScale,
  );

  Finder inRow(Prayer prayer, String text) => find.descendant(
    of: find.byWidgetPredicate((widget) => widget is PrayerSoundRow && widget.prayer == prayer),
    matching: find.text(text),
  );

  Finder recordingOf(Prayer prayer) =>
      find.byWidgetPredicate((widget) => widget is RecordingRow && widget.prayer == prayer);

  testWidgets('the five prayers with their times and sounds, a recording under each adhan', (
    tester,
  ) async {
    await open(tester);
    for (final time in ['04:58', '12:05', '15:27', '17:56', '19:26']) {
      expect(find.text(time), findsOneWidget, reason: time);
    }
    expect(find.byType(RecordingRow), findsNWidgets(2));
    expect(recordingOf(Prayer.fajr), findsOneWidget);
    expect(recordingOf(Prayer.maghrib), findsOneWidget);
    expect(find.text('Mishary Alafasy · full adhan'), findsNWidgets(2));
    expect(find.text('10 min'), findsOneWidget);
    expect(find.text('Notifications are off for this app.'), findsNothing);
    await unmount(tester);
  });

  testWidgets('a sound change is kept at once', (tester) async {
    await open(tester);
    await tester.tap(inRow(Prayer.dhuhr, 'Silent'));
    await tester.tap(inRow(Prayer.asr, 'Adhan'));
    await tester.pumpAndSettle();
    final settings = await settingsOf(tester);
    expect(settings.soundOf(Prayer.dhuhr), PrayerSound.silent);
    expect(settings.soundOf(Prayer.asr), PrayerSound.adhan);
    expect(find.byType(RecordingRow), findsNWidgets(3));
    await unmount(tester);
  });

  testWidgets('the fajr sheet plays alafasy fajr, save keeps and stops', (tester) async {
    await open(tester);
    await tester.tap(recordingOf(Prayer.fajr));
    await tester.pumpAndSettle();

    expect(find.text('Adhan sound'), findsWidgets);
    expect(find.text('For Fajr'), findsOneWidget);
    expect(find.text('Full adhan · 3:41'), findsOneWidget);

    await tester.tap(find.text('Mishary Alafasy'));
    await tester.pumpAndSettle();
    expect(clips.played, [AdhanRecording.alafasy.fullAsset(Prayer.fajr)]);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect((await settingsOf(tester)).fajrRecording, AdhanRecording.alafasy);
    expect(clips.stops, greaterThanOrEqualTo(1));
    expect(find.text('Mishary Alafasy · full adhan'), findsNWidgets(2));
    await unmount(tester);
  });

  testWidgets('the maghrib sheet: alafasy only, it plays and save keeps it', (tester) async {
    await open(tester, downloads: (recording) => _FakeDownload(recording, ready: true));
    await tester.tap(recordingOf(Prayer.maghrib));
    await tester.pumpAndSettle();

    expect(find.text('Full adhan · 2:34'), findsOneWidget);
    expect(find.textContaining('Full adhan · '), findsOneWidget);

    await tester.tap(find.text('Mishary Alafasy'));
    await tester.pumpAndSettle();
    expect(clips.played, [AdhanRecording.alafasy.fullAsset(Prayer.maghrib)]);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect((await settingsOf(tester)).maghribRecording, AdhanRecording.alafasy);
    await unmount(tester);
  });

  testWidgets('closing the sheet without save keeps the recording and stops the sound', (
    tester,
  ) async {
    await open(tester, downloads: (recording) => _FakeDownload(recording, ready: true));
    await tester.tap(recordingOf(Prayer.maghrib));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mishary Alafasy'));
    await tester.pumpAndSettle();
    final stops = clips.stops;
    Navigator.of(tester.element(find.text('Mishary Alafasy'))).pop();
    await tester.pumpAndSettle();
    expect((await settingsOf(tester)).maghribRecording, AdhanRecording.alafasy);
    expect(clips.stops, greaterThan(stops));
    await unmount(tester);
  });

  testWidgets('the reminder slider gives 0 to 30 in 5s, saved when the sheet closes', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Reminder before each prayer'));
    await tester.pumpAndSettle();

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect((slider.min, slider.max, slider.divisions), (0, 30, 6));
    slider.onChanged!(25);
    await tester.pumpAndSettle();
    expect(find.text('25 min'), findsWidgets);
    expect((await settingsOf(tester)).reminderMinutes, 10);

    Navigator.of(tester.element(find.byType(Slider))).pop();
    await tester.pumpAndSettle();
    expect((await settingsOf(tester)).reminderMinutes, 25);
    expect(find.text('25 min'), findsOneWidget);

    await tester.tap(find.text('Reminder before each prayer'));
    await tester.pumpAndSettle();
    tester.widget<Slider>(find.byType(Slider)).onChanged!(0);
    await tester.pumpAndSettle();
    expect(find.text('Off'), findsWidgets);
    await unmount(tester);
  });

  /// ios has no switch for an app that never asked (milestone 10 FR-026)
  testWidgets('notifications off, never asked: the line asks first and remembers it', (
    tester,
  ) async {
    final scheduler = FakeScheduler(allowed: false);
    await open(tester, scheduler: scheduler);
    expect(find.text('Notifications are off for this app.'), findsOneWidget);
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();

    expect(scheduler.asks, 1);
    expect(scheduler.alarmAsks, 1);
    expect((await settingsOf(tester)).notificationsAsked, isTrue);
    expect(system.map((call) => call.method), isNot(contains('openNotificationSettings')));
    expect(find.text('Notifications are off for this app.'), findsNothing);
    await unmount(tester);
  });

  testWidgets('notifications off, asked before: the line opens the phone\'s settings', (
    tester,
  ) async {
    final scheduler = FakeScheduler(allowed: false);
    await open(tester, scheduler: scheduler);
    await containerOf(tester)
        .read(databaseProvider)
        .updateSettings(const SettingsCompanion(notificationsAsked: Value(true)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();

    expect(scheduler.asks, 0);
    expect(system.map((call) => call.method), contains('openNotificationSettings'));
    await unmount(tester);
  });

  testWidgets('the countdown switch is on, each flip writes it with the selection haptic', (
    tester,
  ) async {
    await open(tester);
    final phone = recordPhone();
    await tester.scrollUntilVisible(find.text('Countdown before each prayer'), 100);
    expect(find.text('Starts 2 hours before, ends at the adhan'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('Countdown before each prayer'),
        matching: find.byType(GroupedSection),
      ),
      findsOneWidget,
    );
    expect(tester.getSemantics(find.byType(ToggleRow)).flagsCollection.isToggled, Tristate.isTrue);

    await tester.tap(find.text('Countdown before each prayer'));
    await tester.pumpAndSettle();
    expect((await settingsOf(tester)).prayerCountdown, isFalse);
    expect(phone.haptics, [selection]);

    await tester.tap(find.text('Countdown before each prayer'));
    await tester.pumpAndSettle();
    expect((await settingsOf(tester)).prayerCountdown, isTrue);
    await unmount(tester);
  });

  for (final (name, locale) in [('english', const Locale('en')), ('arabic', const Locale('ar'))]) {
    testWidgets('$name at text scale 2.0, nothing cut', (tester) async {
      await open(tester, locale: locale, textScale: 2, allowed: false);
      await tester.scrollUntilVisible(
        find.text(name == 'english' ? 'Countdown before each prayer' : 'العد التنازلي قبل كل صلاة'),
        100,
      );
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });
  }
}

/// no files in a test, ready says whether the recording is already on the phone
class _FakeDownload extends AdhanDownloadNotifier {
  _FakeDownload(super.recording, {required this.ready});

  final bool ready;

  @override
  AdhanDownload build() => (ready: ready, downloading: false, progress: null);

  @override
  Future<void> download() async => throw const DownloadException(DownloadFailure.offline);
}
