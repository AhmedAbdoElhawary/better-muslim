import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/bm_button.dart';
import 'package:better_muslim/core/widgets/segmented.dart';
import 'package:better_muslim/core/widgets/step/step_dots.dart';
import 'package:better_muslim/features/notifications/data/notification_scheduler.dart';
import 'package:better_muslim/features/notifications/presentation/view/widgets/prayer_sound_row.dart';
import 'package:better_muslim/features/theme_picker/view/theme_page.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../helpers/fonts.dart';
import '../../../helpers/notifications.dart';
import '../../../helpers/onboarding.dart';
import '../../../helpers/prayer.dart';
import '../../../helpers/providers.dart';
import '../../../helpers/widgets.dart';

void main() {
  setUpAll(tz.initializeTimeZones);
  setUpAll(loadAppFonts);

  late FakeScheduler scheduler;
  setUp(() {
    scheduler = FakeScheduler(allowed: false);
    muteAdhanChannel();
  });

  Future<List<Override>> overrides() async => [
    ...await designOverrides(onboarded: false),
    notificationSchedulerProvider.overrideWithValue(scheduler),
  ];

  Future<void> open(
    WidgetTester tester, {
    List<Override>? with_,
    Locale locale = const Locale('en'),
    double textScale = 1,
    bool use24 = true,
  }) async => pumpStep(
    tester,
    Routes.onboardingNotifications,
    overrides: with_ ?? await overrides(),
    locale: locale,
    textScale: textScale,
    use24: use24,
  );

  AppSettings saved(WidgetTester tester) => containerOf(tester).read(settingsProvider).value!;

  Finder row(Prayer prayer) =>
      find.byWidgetPredicate((widget) => widget is PrayerSoundRow && widget.prayer == prayer);

  PrayerSound shown(WidgetTester tester, Prayer prayer) => tester
      .widget<Segmented<PrayerSound>>(
        find.descendant(of: row(prayer), matching: find.byType(Segmented<PrayerSound>)),
      )
      .selected;

  testWidgets("today's five times, the defaults, the reminder at 10 min", (tester) async {
    await open(tester);

    expect(find.text('How should each prayer reach you?'), findsOneWidget);
    expect(tester.widget<StepDots>(find.byType(StepDots)).step, 2);
    for (final (prayer, time, sound) in [
      (Prayer.fajr, '04:58', PrayerSound.adhan),
      (Prayer.dhuhr, '12:05', PrayerSound.tone),
      (Prayer.asr, '15:27', PrayerSound.tone),
      (Prayer.maghrib, '17:56', PrayerSound.adhan),
      (Prayer.isha, '19:26', PrayerSound.tone),
    ]) {
      expect(find.descendant(of: row(prayer), matching: find.text(time)), findsOneWidget);
      expect(shown(tester, prayer), sound);
    }
    expect(find.text('Reminder before each prayer'), findsOneWidget);
    expect(find.text('10 min'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a segment is kept at once with one tick, the reminder opens its sheet', (
    tester,
  ) async {
    final haptics = recordHaptics();
    await open(tester);

    await tester.tap(find.descendant(of: row(Prayer.dhuhr), matching: find.text('Silent')));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
    expect(saved(tester).dhuhrSound, PrayerSound.silent);
    expect(haptics, ['HapticFeedbackType.selectionClick']);

    await tester.tap(find.text('Reminder before each prayer'));
    await frames(tester, const Duration(milliseconds: 700));
    expect(find.byType(Slider), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('allow asks, then alarms, then remembers it asked, then the theme step', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Allow notifications'));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await frames(tester, const Duration(milliseconds: 1200));

    expect(scheduler.asks, 1);
    expect(scheduler.alarmAsks, 1);
    expect(saved(tester).notificationsAsked, isTrue);
    expect(find.byType(ThemePage), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('already allowed still asks, so android 12 gets its alarms page', (tester) async {
    scheduler = FakeScheduler();
    await open(tester);
    await tester.tap(find.text('Allow notifications'));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await frames(tester, const Duration(milliseconds: 1200));

    expect(scheduler.asks, 1);
    expect(scheduler.alarmAsks, 1);
    await unmount(tester);
  });

  testWidgets('refused still goes on, with no alarms page', (tester) async {
    scheduler = FakeScheduler(allowed: false, grants: false);
    await open(tester);
    await tester.tap(find.text('Allow notifications'));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await frames(tester, const Duration(milliseconds: 1200));

    expect(scheduler.alarmAsks, 0);
    expect(find.byType(ThemePage), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('not now asks nothing and goes on', (tester) async {
    await open(tester);
    await tester.tap(find.text('Not now'));
    await frames(tester, const Duration(milliseconds: 1200));

    expect(scheduler.asks, 0);
    expect(saved(tester).notificationsAsked, isFalse);
    expect(find.byType(ThemePage), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('what an earlier run chose shows picked', (tester) async {
    final with_ = await overrides();
    await open(tester, with_: with_);
    await containerOf(tester)
        .read(databaseProvider)
        .updateSettings(
          const SettingsCompanion(
            dhuhrSound: Value(PrayerSound.silent),
            reminderMinutes: Value(15),
          ),
        );
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();

    expect(shown(tester, Prayer.dhuhr), PrayerSound.silent);
    expect(find.text('15 min'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('arabic: eastern digits', (tester) async {
    await open(tester, locale: const Locale('ar'));
    expect(find.descendant(of: row(Prayer.maghrib), matching: find.text('١٧:٥٦')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  testWidgets('12 hour times fit', (tester) async {
    await open(tester, use24: false);
    final time = find.descendant(of: row(Prayer.maghrib), matching: find.textContaining('5:56'));
    expect(tester.widget<Text>(time).data, matches(RegExp(r'^5:56\sPM$', unicode: true)));
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  for (final locale in [const Locale('en'), const Locale('ar')]) {
    testWidgets('text scale 2.0 in ${locale.languageCode}: rows stack, buttons at the bottom', (
      tester,
    ) async {
      await open(tester, locale: locale, textScale: 2);
      expect(tester.takeException(), isNull);
      final name = tester.getRect(
        find.descendant(of: row(Prayer.fajr), matching: find.byType(Column)).first,
      );
      final segments = tester.getRect(
        find.descendant(of: row(Prayer.fajr), matching: find.byType(Segmented<PrayerSound>)),
      );
      expect(segments.top, greaterThanOrEqualTo(name.top));
      expect(tester.getRect(find.byType(BmButton).last).bottom, lessThan(852));
      await unmount(tester);
    });
  }
}
