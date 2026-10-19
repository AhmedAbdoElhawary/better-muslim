import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/settings.dart';
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

  DayCell cell(WidgetTester tester, String hijriDay) => tester.widget<DayCell>(
    find.byWidgetPredicate((widget) => widget is DayCell && widget.hijriDay == hijriDay),
  );

  testWidgets('4.13 on the design scenario', (tester) async {
    await open(tester);

    expect(find.text('Jumada I 1448'), findsOneWidget);
    expect(find.text('October – November 2026'), findsOneWidget);
    expect(cell(tester, '4').look, DayLook.today);
    expect(cell(tester, '4').gregorian, '15');
    expect(cell(tester, '1').gregorian, '12 Oct');
    expect(cell(tester, '21').gregorian, '1 Nov');
    for (final day in ['13', '14', '15']) {
      expect(cell(tester, day).look, DayLook.whiteDay, reason: day);
    }
    expect(cell(tester, '16').look, DayLook.plain);
    for (final text in [
      'COMING UP',
      'Ayyam al-Bid',
      'White days, fasting recommended · 24–26 Oct',
      'Jumada II begins',
      'Estimated 11 Nov · confirmed by moon sighting',
      'Rajab begins',
      'Estimated 10 Dec',
      'Date adjustment',
      '0 days',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(cell(tester, '4').semantics, contains('4 Jumada I 1448'));
    expect(cell(tester, '4').semantics, contains('Today'));
    expect(cell(tester, '13').semantics, contains('Ayyam al-Bid'));
    await unmount(tester);
  });

  testWidgets('forward four times is ramadan with 1 ramadan marked, the icon comes back', (
    tester,
  ) async {
    await open(tester);
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.bySemanticsLabel('Next month'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Ramadan 1448'), findsOneWidget);
    expect(cell(tester, '1').look, DayLook.event);
    expect(cell(tester, '21').look, DayLook.event);
    expect(find.text('Ayyam al-Bid'), findsOneWidget, reason: 'coming up stays on today');

    await tester.tap(find.bySemanticsLabel('Today'));
    await tester.pumpAndSettle();
    expect(find.text('Jumada I 1448'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('the adjustment moves today and the marks at once', (tester) async {
    await open(tester);
    await writeSettings(tester, const SettingsCompanion(hijriAdjust: Value(1)));
    expect(cell(tester, '5').look, DayLook.today);
    expect(find.text('+1 day'), findsOneWidget);
    await unmount(tester);
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
    await unmount(tester);
  });
}
