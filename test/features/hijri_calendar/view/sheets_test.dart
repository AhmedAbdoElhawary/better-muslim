import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/features/hijri_calendar/model/hijri_events.dart';
import 'package:better_muslim/features/hijri_calendar/view/widgets/day_cell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../helpers/fonts.dart';
import '../../../helpers/more.dart';
import '../../../helpers/providers.dart';

void main() {
  setUpAll(() async {
    tz.initializeTimeZones();
    await loadAppFonts();
  });
  setUp(mockSystemChannel);

  Future<void> open(WidgetTester tester, {Locale locale = const Locale('en')}) async =>
      pumpMore(tester, await designOverrides(), push: Routes.hijriCalendar, locale: locale);

  Finder day(String hijriDay) =>
      find.byWidgetPredicate((widget) => widget is DayCell && widget.hijriDay == hijriDay);

  group('the day sheet', () {
    testWidgets('13 jumada i: 24 oct, six times, ayyam al-bid, selected until it closes', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(day('13'));
      await tester.pumpAndSettle();

      expect(find.text('13 Jumada I 1448'), findsOneWidget);
      expect(find.text('Saturday, October 24, 2026'), findsOneWidget);
      for (final prayer in ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']) {
        expect(find.text(prayer), findsOneWidget, reason: prayer);
      }
      expect(find.text('EVENTS'), findsOneWidget);
      expect(find.text('White days, fasting recommended'), findsOneWidget);
      expect(tester.widget<DayCell>(day('13')).look, DayLook.selected);

      Navigator.of(tester.element(find.text('EVENTS'))).pop();
      await tester.pumpAndSettle();
      expect(tester.widget<DayCell>(day('13')).look, DayLook.whiteDay);
      await unmount(tester);
    });

    testWidgets('a plain day has no events section', (tester) async {
      await open(tester);
      await tester.tap(day('16'));
      await tester.pumpAndSettle();
      expect(find.text('EVENTS'), findsNothing);
      await unmount(tester);
    });

    testWidgets('arabic: eastern digits', (tester) async {
      await open(tester, locale: const Locale('ar'));
      await tester.tap(day('١٣'));
      await tester.pumpAndSettle();
      expect(find.text('١٣ جمادى الأولى ١٤٤٨'), findsOneWidget);
      expect(find.text('المناسبات'), findsOneWidget);
      await unmount(tester);
    });
  });

  group('the date adjustment sheet', () {
    Future<void> openSheet(WidgetTester tester) async {
      await tapText(tester, 'Date adjustment');
      expect(
        find.text('Move the Hijri date to match the moon sighting where you live.'),
        findsOneWidget,
      );
    }

    Finder plus() => find.bySemanticsLabel('+');
    Finder minus() => find.bySemanticsLabel('−');

    testWidgets('steps stop at −2 and +2 and show today for each step', (tester) async {
      await open(tester);
      await openSheet(tester);
      expect(find.text('4 Jumada I 1448'), findsOneWidget);

      for (var i = 0; i < 3; i++) {
        await tester.tap(plus());
        await tester.pumpAndSettle();
      }
      expect(find.text('+2 days'), findsOneWidget);
      expect(find.text('6 Jumada I 1448'), findsOneWidget);

      for (var i = 0; i < 5; i++) {
        await tester.tap(minus());
        await tester.pumpAndSettle();
      }
      expect(find.text('−2 days'), findsOneWidget);
      expect(find.text('2 Jumada I 1448'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('save keeps it, closing without save changes nothing', (tester) async {
      await open(tester);
      await openSheet(tester);
      await tester.tap(plus());
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.text('+1 day'))).pop();
      await tester.pumpAndSettle();
      expect((await settingsOf(tester)).hijriAdjust, 0);

      await openSheet(tester);
      await tester.tap(plus());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect((await settingsOf(tester)).hijriAdjust, 1);
      expect(find.text('+1 day'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('arabic', (tester) async {
      await open(tester, locale: const Locale('ar'));
      await tapText(tester, 'تعديل التاريخ');
      await tester.tap(plus());
      await tester.pumpAndSettle();
      expect(find.text('+١ يوم'), findsOneWidget);
      await unmount(tester);
    });
  });
}
