import 'package:better_muslim/core/audio/clip_player.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/adhan_recording.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/notifications/data/notification_scheduler.dart';
import 'package:better_muslim/features/notifications/presentation/view/widgets/prayer_sound_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../../helpers/azkar.dart';
import '../../../../helpers/fonts.dart';
import '../../../../helpers/more.dart';
import '../../../../helpers/notifications.dart';
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
    Locale locale = const Locale('en'),
    double textScale = 1,
  }) async => pumpMore(
    tester,
    <Override>[
      ...await designOverrides(),
      notificationSchedulerProvider.overrideWithValue(FakeScheduler(allowed: allowed)),
      clipPlayerProvider.overrideWithValue(clips),
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
    expect(find.text('Makkah · full adhan'), findsNWidgets(2));
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

  testWidgets('the adhan sound sheet: six recordings, a tap plays, save keeps and stops', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(recordingOf(Prayer.fajr));
    await tester.pumpAndSettle();

    expect(find.text('Adhan sound'), findsWidgets);
    expect(find.text('For Fajr'), findsOneWidget);
    for (final line in [
      'Full adhan · 3:52',
      'Full adhan · 4:10',
      'Full adhan · 3:31',
      'Full adhan · 3:44',
      'Full adhan · 4:02',
      'Short · 0:12',
    ]) {
      expect(find.text(line), findsOneWidget, reason: line);
    }

    await tester.tap(find.text('Madinah'));
    await tester.pumpAndSettle();
    expect(clips.played, [AdhanRecording.madinah.fullAsset(Prayer.fajr)]);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect((await settingsOf(tester)).fajrRecording, AdhanRecording.madinah);
    expect(clips.stops, greaterThanOrEqualTo(1));
    expect(find.text('Madinah · full adhan'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('closing the sheet without save keeps the recording and stops the sound', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(recordingOf(Prayer.maghrib));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cairo'));
    await tester.pumpAndSettle();
    final stops = clips.stops;
    Navigator.of(tester.element(find.text('Cairo'))).pop();
    await tester.pumpAndSettle();
    expect((await settingsOf(tester)).maghribRecording, AdhanRecording.makkah);
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

  testWidgets('notifications off: the line shows and opens the phone\'s settings', (tester) async {
    await open(tester, allowed: false);
    expect(find.text('Notifications are off for this app.'), findsOneWidget);
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    expect(system.map((call) => call.method), contains('openNotificationSettings'));
    await unmount(tester);
  });

  for (final (name, locale) in [('english', const Locale('en')), ('arabic', const Locale('ar'))]) {
    testWidgets('$name at text scale 2.0, nothing cut', (tester) async {
      await open(tester, locale: locale, textScale: 2, allowed: false);
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });
  }
}
