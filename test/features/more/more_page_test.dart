import 'dart:ui' show Tristate;

import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/resources/design/bm_tokens.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/system/share.dart';
import 'package:better_muslim/core/widgets/compact_app_bar.dart';
import 'package:better_muslim/core/widgets/nav_row.dart';
import 'package:better_muslim/core/widgets/sheet/location_sheet.dart';
import 'package:better_muslim/core/widgets/title_glow.dart';
import 'package:better_muslim/features/duas/view/duas_page.dart';
import 'package:better_muslim/features/hijri_calendar/view/hijri_calendar_page.dart';
import 'package:better_muslim/features/more/model/contact.dart';
import 'package:better_muslim/features/more/view/more_page.dart';
import 'package:better_muslim/features/more/view/widgets/contact_section.dart';
import 'package:better_muslim/features/qibla/view/qibla_page.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../helpers/fonts.dart';
import '../../helpers/more.dart';
import '../../helpers/prayer.dart';
import '../../helpers/providers.dart';
import '../../helpers/widgets.dart';

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
    for (final tile in ['Qibla', 'Calendar', 'Duas']) {
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
      ('Calendar', HijriCalendarPage),
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

  testWidgets('top glow: on by default, off fades every glow out and the bar goes plain', (
    tester,
  ) async {
    await pumpMore(tester, await designOverrides(), push: Routes.hijriCalendar);
    double glow() => tester
        .widget<AnimatedOpacity>(
          find.descendant(of: find.byType(TitleGlow), matching: find.byType(AnimatedOpacity)).first,
        )
        .opacity;
    Color bar() =>
        (tester
                    .widget<DecoratedBox>(
                      find
                          .descendant(
                            of: find.byType(CompactAppBar),
                            matching: find.byType(DecoratedBox),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration)
            .color!;
    expect(glow(), 1);
    expect(bar().a, closeTo(BmGlass.surfaceOpacity, .01));

    containerOf(tester).read(routerProvider).pop();
    await tester.pumpAndSettle();
    expect(await toggledOf(tester, 'Top glow'), isTrue);
    await tapText(tester, 'Top glow');
    expect((await settingsOf(tester)).topGlow, isFalse);
    await tester.pumpAndSettle();
    expect(await toggledOf(tester, 'Top glow'), isFalse);
    expect(glow(), 0);

    containerOf(tester).read(routerProvider).push(Routes.hijriCalendar);
    await tester.pumpAndSettle();
    expect(glow(), 0);
    expect(bar().a, closeTo(.8, .01));
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

  testWidgets('the hijri date adjustment sits right after adhan and reminders', (tester) async {
    await pumpMore(tester, await designOverrides());
    final adhan = tester.getRect(row('Adhan and reminders'));
    final adjustment = tester.getRect(row('Hijri date adjustment'));
    expect(adjustment.top, closeTo(adhan.bottom, 2));
    expect(find.text('0 days'), findsOneWidget);
    await unmount(tester);
  });

  group('contact', () {
    const contact = Contact(
      email: 'me@example.com',
      developerName: 'Ahmed',
      website: 'https://example.com',
      appStoreUrl: 'https://apps.apple.com/app/id1',
      playStoreUrl: 'https://play.google.com/store/apps/details?id=x',
    );
    final shared = <ShareParams>[];

    Future<List<MethodCall>> pumpContact(
      WidgetTester tester,
      Contact contact, {
      bool mailed = true,
    }) async {
      final calls = mockSystemChannel(mailed: mailed);
      shared.clear();
      await pumpCoreWidget(
        tester,
        ProviderScope(
          overrides: [shareProvider.overrideWithValue((params) async => shared.add(params))],
          child: ContactSection(contact: contact),
        ),
      );
      return calls;
    }
    //
    // testWidgets('each row shows only once its value is set', (tester) async {
    //   await pumpContact(tester, const Contact(email: 'me@example.com'));
    //   expect(find.text('CONTACT'), findsOneWidget);
    //   expect(find.text('Send feedback'), findsOneWidget);
    //   for (final title in ['Rate Better Muslim', 'Share Better Muslim', 'Developer']) {
    //     expect(find.text(title), findsNothing, reason: title);
    //   }
    //
    //   await pumpContact(tester, contact);
    //   for (final title in [
    //     'Send feedback',
    //     'Rate Better Muslim',
    //     'Share Better Muslim',
    //     'Developer',
    //     'Ahmed',
    //   ]) {
    //     expect(find.text(title), findsOneWidget, reason: title);
    //   }
    //
    //   await pumpContact(tester, Contact.mine);
    //   expect(find.text('CONTACT'), findsNothing);
    // });

    testWidgets('send feedback opens a draft with the version and the phone', (tester) async {
      final calls = await pumpContact(tester, contact);
      await tester.tap(find.text('Send feedback'));
      await tester.pumpAndSettle();
      final mail = calls.singleWhere((call) => call.method == 'mail');
      expect(mail.arguments, {
        'to': 'me@example.com',
        'subject': 'Better Muslim feedback',
        'body': 'Version 1.0.0 (12) · Google Pixel 8 · Android 16',
      });
      expect(find.text('No mail app. Write to me@example.com'), findsNothing);
    });

    testWidgets('no mail app shows the address in a toast', (tester) async {
      await pumpContact(tester, contact, mailed: false);
      await tester.tap(find.text('Send feedback'));
      await tester.pumpAndSettle();
      expect(find.text('No mail app. Write to me@example.com'), findsOneWidget);
    });

    testWidgets('rate and developer open their links, share the line with the link', (
      tester,
    ) async {
      final calls = await pumpContact(tester, contact);
      await tester.tap(find.text('Rate Better Muslim'));
      await tester.tap(find.text('Developer'));
      await tester.tap(find.text('Share Better Muslim'));
      await tester.pumpAndSettle();
      expect(calls.where((call) => call.method == 'openUrl').map((call) => call.arguments), [
        {'url': contact.playStoreUrl},
        {'url': contact.website},
      ]);
      expect(shared.single.text, contains(contact.playStoreUrl));
    });
  });
}
