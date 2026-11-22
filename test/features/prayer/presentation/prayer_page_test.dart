import 'dart:ui' show CheckedState;

import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/day_dots.dart';
import 'package:better_muslim/features/notifications/data/notification_scheduler.dart';
import 'package:better_muslim/features/notifications/presentation/view/adhan_settings_page.dart';
import 'package:better_muslim/features/prayer/presentation/view/widgets/mark_button.dart';
import 'package:better_muslim/features/prayer/presentation/view/widgets/prayer_header.dart';
import 'package:better_muslim/features/prayer/presentation/view/widgets/progress_ring.dart';
import 'package:better_muslim/features/prayer/presentation/view/widgets/summary_card.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../helpers/fonts.dart';
import '../../../helpers/notifications.dart';
import '../../../helpers/prayer.dart';
import '../../../helpers/providers.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

  /// the real fonts, the square test font is far wider and would overflow where the app doesn't
  setUpAll(loadAppFonts);

  final thursday = DateTime(2026, 10, 15);
  Finder mark() => inRow(Prayer.asr, find.text('Mark'));
  Finder prayedIn(Prayer prayer) => inRow(prayer, find.text('Prayed'));
  Finder icon(String asset) =>
      find.byWidgetPredicate((widget) => widget is BmIcon && widget.asset.endsWith(asset));

  /// the compact bar holds a hidden copy of the title until the page scrolls
  Finder header(String text) =>
      find.descendant(of: find.byType(PrayerHeader), matching: find.text(text));

  testWidgets('the scenario day as in 4.04 (SC-001)', (tester) async {
    await pumpPrayer(tester, await designOverrides());

    expect(header('Prayer times'), findsOneWidget);
    expect(find.text('Makkah · Umm al-Qura'), findsOneWidget);
    for (final time in ['04:58', '06:15', '12:05', '15:27', '17:56', '19:26']) {
      expect(find.text(time), findsOneWidget, reason: time);
    }
    expect(prayedIn(Prayer.fajr), findsOneWidget);
    expect(prayedIn(Prayer.dhuhr), findsOneWidget);

    /// an hour past asr's now window, still on time to mark
    expect(find.text('NOW'), findsNothing);
    expect(mark(), findsOneWidget);
    expect(inRow(Prayer.maghrib, find.text('in 1:24')), findsOneWidget);
    expect(inRow(Prayer.isha, icon('ui/sound.svg')), findsOneWidget);
    expect(find.text('2 of 5 prayed today'), findsOneWidget);
    expect(find.text('3 missed this month to make up'), findsOneWidget);
    expect(dotsOf(tester, DateTime(2026, 10, 13)), hasLength(4));
    expect(dotsOf(tester, thursday), {Prayer.fajr, Prayer.dhuhr});
    await unmount(tester);
  });

  testWidgets('mark asr, unmark it and undo (US1)', (tester) async {
    await pumpPrayer(tester, await designOverrides());

    await tester.tap(mark());
    await tester.pumpAndSettle();
    expect(find.text('3 of 5 prayed today'), findsOneWidget);
    expect(dotsOf(tester, thursday), {Prayer.fajr, Prayer.dhuhr, Prayer.asr});
    expect(prayedIn(Prayer.asr), findsOneWidget);

    await tester.tap(prayedIn(Prayer.asr));
    await tester.pumpAndSettle();
    expect(find.text('2 of 5 prayed today'), findsOneWidget);
    expect(find.text('Asr unmarked'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('3 of 5 prayed today'), findsOneWidget);
    expect(find.text('Asr unmarked'), findsNothing);

    await tester.tap(prayedIn(Prayer.asr));
    await tester.pumpAndSettle();
    expect(find.text('Asr unmarked'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('Asr unmarked'), findsNothing);
    expect(find.text('2 of 5 prayed today'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('the adhan button opens adhan and reminders', (tester) async {
    await pumpPrayer(tester, [
      ...await designOverrides(),
      notificationSchedulerProvider.overrideWithValue(FakeScheduler()),
    ]);

    await tester.tap(find.bySemanticsLabel('Adhan and reminders'));
    await tester.pumpAndSettle();
    expect(find.byType(AdhanSettingsPage), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('the bell moves isha from tone to silent to adhan', (tester) async {
    await pumpPrayer(tester, await designOverrides());
    final db = dbOf(tester);
    Future<PrayerSound> isha() async =>
        (await tester.runAsync(() => db.select(db.settings).getSingle()))!.ishaSound;

    await tester.tap(inRow(Prayer.isha, icon('ui/sound.svg')));
    await tester.pumpAndSettle();
    expect(await isha(), PrayerSound.silent);
    expect(find.text('Isha: Silent'), findsOneWidget);
    expect(inRow(Prayer.isha, icon('ui/bell_off.svg')), findsOneWidget);

    await tester.tap(inRow(Prayer.isha, icon('ui/bell_off.svg')));
    await tester.pumpAndSettle();
    expect(await isha(), PrayerSound.adhan);
    expect(inRow(Prayer.isha, icon('outline/adhan.svg')), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a double tap on mark logs once', (tester) async {
    await pumpPrayer(tester, await designOverrides());
    final db = dbOf(tester);

    await tester.tap(mark());
    await tester.tap(mark());
    await tester.pumpAndSettle();

    final rows = await db.select(db.prayerLog).get();
    expect(rows.where((row) => row.date == thursday && row.prayer == Prayer.asr), hasLength(1));
    expect(find.text('3 of 5 prayed today'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('arabic: eastern digits, sunday on the right, ring and dots never mirror', (
    tester,
  ) async {
    await pumpPrayer(tester, await designOverrides(), locale: const Locale('ar'));

    expect(header('مواقيت الصلاة'), findsOneWidget);
    expect(find.text('مكة المكرمة · أم القرى'), findsOneWidget);
    expect(find.text('١٥:٢٧'), findsOneWidget);
    expect(find.text('٢ من ٥ صلوات اليوم'), findsOneWidget);
    expect(find.text('٣ صلوات فائتة هذا الشهر للقضاء'), findsOneWidget);
    expect(find.text('ح'), findsOneWidget);
    expect(
      tester.getCenter(cellOf(DateTime(2026, 10, 11))).dx,
      greaterThan(tester.getCenter(cellOf(DateTime(2026, 10, 17))).dx),
    );
    for (final finder in [find.byType(DayDots).first, find.byType(ProgressRing)]) {
      final direction = tester.widget<Directionality>(
        find.descendant(of: finder, matching: find.byType(Directionality)).first,
      );
      expect(direction.textDirection, TextDirection.ltr);
    }
    await unmount(tester);
  });

  testWidgets('at text scale 2 nothing overflows and the rows stack', (tester) async {
    await pumpPrayer(tester, await designOverrides(), textScale: 2);

    expect(tester.takeException(), isNull);
    final name = inRow(Prayer.asr, find.text('Asr'));
    final time = inRow(Prayer.asr, find.text('15:27'));
    expect(tester.getTopLeft(time).dy, greaterThanOrEqualTo(tester.getBottomLeft(name).dy));
    await unmount(tester);
  });

  testWidgets('a 12 hour phone reads 5:56 PM and it fits the row', (tester) async {
    await pumpPrayer(tester, await designOverrides(), use24: false);

    /// intl puts a narrow no-break space before PM
    final maghrib = find.text('5:56\u202fPM');
    expect(maghrib, findsOneWidget);
    expect(tester.renderObject<RenderParagraph>(maghrib).didExceedMaxLines, isFalse);
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  testWidgets('every action is at least 44 x 44 (FR-030)', (tester) async {
    await pumpPrayer(tester, await designOverrides());

    Finder inside(Finder widget) =>
        find.descendant(of: widget, matching: find.byType(GestureDetector)).first;
    Finder around(Finder child) =>
        find.ancestor(of: child, matching: find.byType(GestureDetector)).first;
    for (final action in [
      inside(find.byType(MarkButton).first),
      around(mark()),
      inside(cellOf(thursday)),
      inside(find.byType(SummaryCard)),
      around(icon('outline/location.svg')),
      around(icon('outline/settings.svg').first),
    ]) {
      final size = tester.getSize(action);
      expect(size.width, greaterThanOrEqualTo(44), reason: '$action');
      expect(size.height, greaterThanOrEqualTo(44), reason: '$action');
    }
    await unmount(tester);
  });

  testWidgets('a screen reader hears each row as prayer, time and state (R13)', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpPrayer(tester, await designOverrides());

    final asr = tester.getSemantics(rowOf(Prayer.asr));
    expect(asr.label, allOf(contains('Asr'), contains('15:27'), contains('Mark')));
    expect(asr.flagsCollection.isButton, isTrue);

    final fajr = tester.getSemantics(rowOf(Prayer.fajr));
    expect(fajr.label, allOf(contains('Fajr'), contains('04:58'), contains('Prayed')));
    expect(fajr.flagsCollection.isChecked, CheckedState.isTrue);
    await unmount(tester);
    semantics.dispose();
  });
}
