import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/day_dots.dart';
import 'package:better_muslim/core/widgets/sheet/location_sheet.dart';
import 'package:better_muslim/features/hijri_calendar/model/hijri_events.dart';
import 'package:better_muslim/features/hijri_calendar/view/hijri_calendar_page.dart';
import 'package:better_muslim/features/hijri_calendar/view/widgets/day_cell.dart';
import 'package:drift/drift.dart' show Value;
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

  Future<void> open(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    double textScale = 1,
  }) async => pumpMore(
    tester,
    await designOverrides(),
    push: Routes.hijriCalendar,
    locale: locale,
    textScale: textScale,
  );

  Finder day(String big) =>
      find.byWidgetPredicate((widget) => widget is DayCell && widget.day == big);

  DayCell cell(WidgetTester tester, String big) => tester.widget<DayCell>(day(big));

  /// scrolls only when it's off screen, so the header stays in view for the checks after
  Future<void> tap(WidgetTester tester, Finder finder) async {
    if (finder.hitTestable().evaluate().isEmpty) {
      await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
      await tester.pumpAndSettle();
    }
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  group('the day under the grid', () {
    testWidgets('4.13 on the design scenario, today selected with its prayer times', (
      tester,
    ) async {
      await open(tester);

      expect(find.text('Jumada I 1448'), findsOneWidget);
      expect(find.text('October – November 2026'), findsOneWidget);
      expect(cell(tester, '4').look, DayLook.today);
      expect(cell(tester, '4').other, '15');
      expect(cell(tester, '1').other, '12 Oct');
      expect(cell(tester, '21').other, '1 Nov');
      for (final big in ['13', '14', '15']) {
        expect(cell(tester, big).look, DayLook.whiteDay, reason: big);
      }
      expect(cell(tester, '16').look, DayLook.plain);
      expect(find.text('4 Jumada I 1448'), findsOneWidget);
      expect(find.text('Thursday, October 15, 2026'), findsOneWidget);
      for (final prayer in ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']) {
        expect(find.text(prayer), findsOneWidget, reason: prayer);
      }
      expect(find.text('Date adjustment'), findsNothing);
      expect(cell(tester, '4').semantics, contains('4 Jumada I 1448'));
      expect(cell(tester, '4').semantics, contains('Today'));
      expect(cell(tester, '13').semantics, contains('Ayyam al-Bid'));
      await unmount(tester);
    });

    testWidgets('a full day is filled, a part day outlined, the details show the five dots', (
      tester,
    ) async {
      await open(tester);

      BoxDecoration box(String big) =>
          tester
                  .widget<DecoratedBox>(
                    find.descendant(of: day(big), matching: find.byType(DecoratedBox)).first,
                  )
                  .decoration
              as BoxDecoration;
      expect(cell(tester, '3').prayed, 5);
      expect(box('3').color, isNotNull);
      expect(box('3').border, isNull);
      expect(cell(tester, '2').prayed, 4);
      expect(box('2').color, isNull);
      expect(box('2').border, isNotNull);
      expect(cell(tester, '2').semantics, contains('4 of 5 prayed'));
      expect(box('16').color, isNull);
      expect(box('16').border, isNull);
      expect(tester.widget<DayDots>(find.byType(DayDots)).prayed, {Prayer.fajr, Prayer.dhuhr});

      await tap(tester, day('3'));
      expect(tester.widget<DayDots>(find.byType(DayDots)).prayed, Prayer.values.toSet());
      await tap(tester, day('16'));
      expect(find.byType(DayDots), findsNothing);
      await unmount(tester);
    });

    testWidgets('a day tap selects it in place, the open tab stays on another day', (tester) async {
      await open(tester);
      await tap(tester, day('13'));

      expect(cell(tester, '13').look, DayLook.selected);
      expect(cell(tester, '4').look, DayLook.today);
      expect(find.text('13 Jumada I 1448'), findsOneWidget);
      expect(find.text('Saturday, October 24, 2026'), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(HijriCalendarPage), findsOneWidget);

      await tap(tester, find.text('Events'));
      expect(find.text('Ayyam al-Bid'), findsOneWidget);
      expect(find.text('White days, fasting recommended'), findsOneWidget);

      await tap(tester, day('14'));
      expect(find.text('14 Jumada I 1448'), findsOneWidget);
      expect(find.text('Ayyam al-Bid'), findsOneWidget, reason: 'events stays open');

      await tap(tester, day('16'));
      expect(find.text('No events on this day'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('coming up lists the year, a row opens its month on events', (tester) async {
      await open(tester);
      await tap(tester, find.text('Coming up'));

      expect(find.text('This year (1448)'), findsOneWidget);
      expect(find.text('This month'), findsOneWidget);
      expect(find.text('in 9 days'), findsOneWidget);
      expect(find.text('Ayyam al-Bid'), findsWidgets);

      await tap(tester, day('1'));
      expect(find.text('in 9 days'), findsOneWidget, reason: 'counted from today');

      await tap(tester, find.text('Ramadan begins'));
      expect(find.text('Ramadan 1448'), findsOneWidget);
      expect(cell(tester, '1').look, DayLook.selected);
      expect(find.text('1 Ramadan 1448'), findsOneWidget);
      expect(find.text('Ramadan begins'), findsOneWidget, reason: 'events is open');
      expect(find.text('This year (1448)'), findsNothing);
      await unmount(tester);
    });

    testWidgets('coming up from a past day shows the passed events muted, in days ago', (
      tester,
    ) async {
      await open(tester);
      await tap(tester, find.bySemanticsLabel('Previous month'));
      await tap(tester, day('1'));
      await tap(tester, find.text('Coming up'));

      expect(find.textContaining(RegExp(r'^\d+ days ago$')), findsOneWidget);
      expect(find.text('in 9 days'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('the adjustment moves the grid and keeps the gregorian day selected', (
      tester,
    ) async {
      await open(tester);
      await tap(tester, day('13'));
      await writeSettings(tester, const SettingsCompanion(hijriAdjust: Value(1)));

      expect(cell(tester, '5').look, DayLook.today);
      expect(cell(tester, '14').look, DayLook.selected);
      expect(find.text('Saturday, October 24, 2026'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('no place: the no location line and its buttons open the location sheet', (
      tester,
    ) async {
      await pumpMore(tester, testOverrides(), push: Routes.hijriCalendar);
      expect(find.text('No location yet'), findsOneWidget);

      await tap(tester, find.text('Choose a city instead'));
      expect(find.byType(LocationSheet), findsOneWidget);
      await unmount(tester);
    });
  });

  group('modes and views', () {
    testWidgets('the title switches to gregorian and keeps the selected day', (tester) async {
      await open(tester);
      await tap(tester, day('13'));
      await tap(tester, find.bySemanticsLabel('Hijri calendar'));

      expect((await settingsOf(tester)).calendarMode, CalendarMode.gregorian);
      await tester.pumpAndSettle();
      expect(find.text('Gregorian calendar'), findsOneWidget);
      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('Rabi II – Jumada I 1448'), findsOneWidget);
      expect(cell(tester, '24').look, DayLook.selected);
      expect(cell(tester, '15').look, DayLook.today);
      expect(cell(tester, '1').other, contains('Rab II'));
      expect(cell(tester, '12').other, '1 Jum I');
      expect(cell(tester, '13').other, '2');

      await tap(tester, find.bySemanticsLabel('Gregorian calendar'));
      expect((await settingsOf(tester)).calendarMode, CalendarMode.hijri);
      await tester.pumpAndSettle();
      expect(cell(tester, '13').look, DayLook.selected);
      await unmount(tester);
    });

    testWidgets('the header zooms out to months and years, a pick zooms back in', (tester) async {
      await open(tester);
      await tap(tester, find.bySemanticsLabel(RegExp('^Show months')));
      expect(find.text('1448'), findsOneWidget);
      expect(find.text('Muharram'), findsOneWidget);

      await tap(tester, find.bySemanticsLabel(RegExp('^Show years')));
      expect(find.text('1440 – 1451'), findsOneWidget);

      await tap(tester, find.text('1450'));
      expect(find.text('Ramadan'), findsOneWidget);
      await tap(tester, find.text('Ramadan'));
      expect(find.text('Ramadan 1450'), findsOneWidget);
      expect(find.byType(DayCell), findsWidgets);
      await unmount(tester);
    });

    testWidgets('the arrows step a month, a year and 12 years and stop at the end', (tester) async {
      await open(tester);
      await tap(tester, find.bySemanticsLabel('Next month'));
      expect(find.text('Jumada II 1448'), findsOneWidget);

      await tap(tester, find.bySemanticsLabel(RegExp('^Show months')));
      await tap(tester, find.bySemanticsLabel('Next year'));
      expect(find.text('1449'), findsOneWidget);

      await tap(tester, find.bySemanticsLabel(RegExp('^Show years')));
      for (var i = 0; i < 5; i++) {
        await tap(tester, find.bySemanticsLabel('Next years'));
      }
      expect(find.text('1500 – 1511'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Next years')),
        isSemantics(isEnabled: false),
      );
      await unmount(tester);
    });

    testWidgets('a flick on the grid pages like the arrows, the other way in arabic', (
      tester,
    ) async {
      Future<void> flick(double dx) async {
        await tester.fling(day('13'), Offset(dx, 0), 1000);
        await tester.pumpAndSettle();
      }

      await open(tester);
      await flick(-300);
      expect(find.text('Jumada II 1448'), findsOneWidget);
      await flick(300);
      await flick(300);
      expect(find.text('Rabi II 1448'), findsOneWidget);
      await unmount(tester);

      await open(tester, locale: const Locale('ar'));
      await tester.fling(day('١٣'), const Offset(300, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('جمادى الآخرة ١٤٤٨'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('today is dimmed on today, enabled elsewhere, its tap goes back', (tester) async {
      await open(tester);
      final today = find.bySemanticsLabel('Today');
      expect(tester.getSemantics(today), isSemantics(isEnabled: false));

      await tap(tester, find.bySemanticsLabel('Next month'));
      expect(tester.getSemantics(today), isSemantics(isEnabled: true));
      await tap(tester, today);
      expect(find.text('Jumada I 1448'), findsOneWidget);
      expect(tester.getSemantics(today), isSemantics(isEnabled: false));

      await tap(tester, day('13'));
      expect(tester.getSemantics(today), isSemantics(isEnabled: true));
      await tap(tester, today);
      expect(cell(tester, '13').look, DayLook.whiteDay);
      await unmount(tester);
    });

    testWidgets('past midnight the month and selection stay, today moves on', (tester) async {
      final start = DateTime(2026, 10, 15, 23, 59);
      final origin = tester.binding.clock.now();
      await pumpMore(tester, [
        ...testOverrides(),
        clockProvider.overrideWithValue(
          () => start.add(tester.binding.clock.now().difference(origin)),
        ),
      ], push: Routes.hijriCalendar);
      final today = find.bySemanticsLabel('Today');
      expect(cell(tester, '4').look, DayLook.today);

      await tester.pump(const Duration(minutes: 2));
      await tester.pumpAndSettle();
      expect(cell(tester, '5').look, DayLook.today);
      expect(cell(tester, '4').look, DayLook.selected);
      expect(find.text('Jumada I 1448'), findsOneWidget);
      expect(tester.getSemantics(today), isSemantics(isEnabled: true));
      await unmount(tester);
    });
  });

  testWidgets('arabic: sunday on the right, the arrows mirrored, eastern digits', (tester) async {
    await open(tester, locale: const Locale('ar'));
    expect(find.text('جمادى الأولى ١٤٤٨'), findsOneWidget);
    expect(cell(tester, '٤').look, DayLook.today);
    final page = tester.getRect(find.byType(HijriCalendarPage));
    expect(tester.getCenter(find.text('ح')).dx, greaterThan(page.center.dx));
    final arrows = find.descendant(
      of: find.bySemanticsLabel('الشهر السابق'),
      matching: find.byType(Transform),
    );
    expect(tester.widget<Transform>(arrows.first).transform.storage.first, -1);
    for (final tab in ['القادم', 'المناسبات']) {
      await tap(tester, find.text(tab));
      expect(tester.takeException(), isNull, reason: tab);
    }

    await writeSettings(tester, const SettingsCompanion(digits: Value(Digits.western)));
    expect(cell(tester, '4').look, DayLook.today);
    await unmount(tester);
  });

  testWidgets('text scale 2.0 scrolls with nothing cut, every day at least 44', (tester) async {
    await open(tester, textScale: 2);
    expect(tester.takeException(), isNull);
    for (final element in find.byType(DayCell).evaluate()) {
      expect(element.size!.height, greaterThanOrEqualTo(44));
      expect(element.size!.width, greaterThanOrEqualTo(44));
    }
    for (final tab in ['Coming up', 'Events']) {
      await tap(tester, find.text(tab));
      expect(tester.takeException(), isNull, reason: tab);
    }
    await unmount(tester);
  });
}
