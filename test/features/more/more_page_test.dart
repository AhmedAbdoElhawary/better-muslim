import 'dart:ui' show Tristate;

import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/nav_row.dart';
import 'package:better_muslim/core/widgets/sheet/location_sheet.dart';
import 'package:better_muslim/features/duas/view/duas_page.dart';
import 'package:better_muslim/features/hijri_calendar/view/hijri_calendar_page.dart';
import 'package:better_muslim/features/more/view/more_page.dart';
import 'package:better_muslim/features/qibla/view/qibla_page.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../helpers/fonts.dart';
import '../../helpers/more.dart';
import '../../helpers/prayer.dart';
import '../../helpers/providers.dart';

void main() {
  setUpAll(() async {
    tz.initializeTimeZones();
    await loadAppFonts();
  });
  setUp(mockSystemChannel);

  Finder row(String title) =>
      find.ancestor(of: find.text(title), matching: find.byType(NavRow)).first;

  Future<bool> toggledOf(WidgetTester tester, String title) async {
    await scrollTo(tester, title);
    return tester.getSemantics(row(title)).flagsCollection.isToggled == Tristate.isTrue;
  }

  testWidgets('4.09 on the design scenario: every row shows its value', (tester) async {
    await pumpMore(tester, await designOverrides());

    expect(find.text('More'), findsWidgets);
    expect(find.text('Stored on this device · no account needed'), findsOneWidget);
    for (final tile in ['Qibla', 'Hijri calendar', 'Duas']) {
      expect(find.text(tile), findsOneWidget);
    }
    for (final value in ['Umm al-Qura', '10 min before', 'Makkah · auto', 'Qiyam Emerald']) {
      expect(find.text(value), findsOneWidget, reason: value);
    }
    expect(find.text('Follow sky'), findsOneWidget);
    expect(await toggledOf(tester, 'Reduce motion'), isFalse);
    expect(await toggledOf(tester, 'Haptics'), isTrue);
    expect(await toggledOf(tester, 'UI sounds'), isFalse);
    expect(find.text('Eastern Arabic digits ١٢٣'), findsNothing);
    await unmount(tester);
  });

  testWidgets('the tiles push qibla, the hijri calendar and duas', (tester) async {
    await pumpMore(tester, await designOverrides());
    for (final (tile, page) in [
      ('Qibla', QiblaPage),
      ('Hijri calendar', HijriCalendarPage),
      ('Duas', DuasPage),
    ]) {
      await tester.tap(find.text(tile));
      await tester.pumpAndSettle();
      expect(find.byType(page), findsOneWidget, reason: tile);
      containerOf(tester).read(routerProvider).pop();
      await tester.pumpAndSettle();
    }
    await unmount(tester);
  });

  testWidgets('each toggle writes the store and stays', (tester) async {
    await pumpMore(tester, await designOverrides());
    for (final title in ['Reduce motion', 'Haptics', 'UI sounds']) {
      await tapText(tester, title);
    }
    final settings = await settingsOf(tester);
    expect(settings.reduceMotion, isTrue);
    expect(settings.haptics, isFalse);
    expect(settings.uiSounds, isTrue);
    expect(await toggledOf(tester, 'Haptics'), isFalse);
    await unmount(tester);
  });

  testWidgets('the method and location rows open their sheets', (tester) async {
    await pumpMore(tester, await designOverrides());
    await tapText(tester, 'Calculation method');
    expect(find.text('By country'), findsWidgets);
    Navigator.of(tester.element(find.text('By country').first)).pop();
    await tester.pumpAndSettle();

    await tapText(tester, 'Location');
    expect(find.byType(LocationSheet), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a reminder of 0 reads off', (tester) async {
    await pumpMore(tester, await designOverrides());
    await writeSettings(tester, const SettingsCompanion(reminderMinutes: Value(0)));
    expect(find.text('Off'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('arabic: the digits toggle shows and writes digits', (tester) async {
    await pumpMore(tester, await designOverrides(), locale: const Locale('ar'));
    expect(find.text('المزيد'), findsWidgets);
    expect(find.text('قبل ١٠ دقائق'), findsOneWidget);
    expect(await toggledOf(tester, 'الأرقام المشرقية ١٢٣'), isTrue);

    await tapText(tester, 'الأرقام المشرقية ١٢٣');
    expect((await settingsOf(tester)).digits, Digits.western);
    expect(find.text('قبل 10 دقائق'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('the dev row shows only in dev', (tester) async {
    await pumpMore(tester, await designOverrides());
    await scrollTo(tester, 'Notifications (dev)');
    expect(find.text('Notifications (dev)'), findsOneWidget);
    await unmount(tester);
  });

  for (final (name, locale, brightness, scale) in [
    ('light', const Locale('en'), Brightness.light, 1.0),
    ('text scale 2.0', const Locale('en'), Brightness.dark, 2.0),
    ('arabic at 2.0', const Locale('ar'), Brightness.dark, 2.0),
  ]) {
    testWidgets('$name: nothing overflows, every row and tile is at least 44', (tester) async {
      await pumpMore(
        tester,
        await designOverrides(),
        locale: locale,
        brightness: brightness,
        textScale: scale,
      );
      final scrollable = find
          .descendant(of: find.byType(MorePage), matching: find.byType(Scrollable))
          .first;
      for (var i = 0; i < 12; i++) {
        final error = tester.takeException();
        expect(error, isNull, reason: error is FlutterError ? error.toStringDeep() : null);
        for (final element in find.byType(NavRow).evaluate()) {
          expect(element.size!.height, greaterThanOrEqualTo(44));
        }
        await tester.drag(scrollable, const Offset(0, -300));
        await tester.pumpAndSettle();
      }
      expect(find.byType(MorePage), findsOneWidget);
      await unmount(tester);
    });
  }
}
