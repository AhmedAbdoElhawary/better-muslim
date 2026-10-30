import 'dart:convert';
import 'dart:io';

import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/widgets/sheet/bm_sheet.dart';
import 'package:better_muslim/features/quran/presentation/providers/selection.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/ayah_sheet.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/mushaf_page_view.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/page_turn.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/study_tabs.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../helpers/fonts.dart';
import '../../../helpers/home.dart';
import '../../../helpers/more.dart';
import '../../../helpers/prayer.dart';
import '../../../helpers/providers.dart';

void main() {
  setUpAll(tz.initializeTimeZones);
  setUpAll(loadAppFonts);
  setUp(mockSystemChannel);

  /// al-fatiha's shipped sahih international and al-muyassar lines
  final fatiha = jsonDecode(File('assets/quran/surahs/001.json').readAsStringSync()) as Map;
  String translation(int ayah) => (fatiha['tr'] as List)[ayah - 1] as String;
  String tafsir(int ayah) => (fatiha['tafsir'] as List)[ayah - 1] as String;

  Future<void> pumpReader(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    double textScale = 1,
    bool reduceMotion = false,
  }) async {
    await pumpHome(
      tester,
      await designOverrides(),
      locale: locale,
      textScale: textScale,
      reduceMotion: reduceMotion,
      settle: false,
    );
    await tester.pump();
    containerOf(tester).read(routerProvider).push(Routes.quranPage(1));
    await tester.pumpAndSettle();
  }

  Future<void> select(WidgetTester tester, int ayah) async {
    final page = tester.allRenderObjects.whereType<RenderMushafPage>().firstWhere(
      (page) => page.washBounds(AyahKey(1, ayah)) != null,
    );
    await tester.tapAt(page.localToGlobal(page.washBounds(AyahKey(1, ayah))!.center));
    await tester.pumpAndSettle();
  }

  Finder inSheet(Type sheet, Finder matching) =>
      find.descendant(of: find.byType(sheet), matching: matching);

  Finder labelled(Type sheet, String label) =>
      inSheet(sheet, find.byWidgetPredicate((w) => w is Semantics && w.properties.label == label));

  Future<void> tapIn(WidgetTester tester, Type sheet, Finder finder) async {
    await tester.tap(inSheet(sheet, finder));
    await tester.pumpAndSettle();
  }

  AyahKey? selected(WidgetTester tester) => containerOf(tester).read(selectionProvider).sheet;

  /// how much of the study sheet is on screen, from its grabber down
  double shown(WidgetTester tester) =>
      tester.view.physicalSize.height / 3 -
      tester.getTopLeft(inSheet(StudySheet, find.byType(Grabber))).dy +
      SpaceManager.s2;

  ScrollPosition studyScroll(WidgetTester tester) => tester
      .state<ScrollableState>(
        find.descendant(of: find.byType(StudyTabs), matching: find.byType(Scrollable)).first,
      )
      .position;

  Future<void> drag(WidgetTester tester, Finder finder, double dy) async {
    await tester.drag(finder, Offset(0, dy));
    await tester.pumpAndSettle();
  }

  testWidgets('the medium detent shows the ayah, its translation and six actions', (tester) async {
    await pumpReader(tester);
    await select(tester, 5);

    for (final text in [
      'Al-Fatiha · Ayah 5',
      'Juz 1 · Page 1 · Meccan',
      translation(5),
      'Sahih International',
      'Play from here',
      'Tafsir',
      'Bookmark',
      'Note',
      'Share',
      'Copy',
    ]) {
      expect(inSheet(AyahSheet, find.text(text)), findsOneWidget, reason: text);
    }
    expect(translation(5), 'It is You we worship and You we ask for help.');
    expect(find.text('Word by word'), findsNothing);
    expect(find.text('Memorize'), findsNothing);
    await unmount(tester);
  });

  testWidgets('tafsir opens the large detent, the arrows move the ayah and its wash', (
    tester,
  ) async {
    await pumpReader(tester);
    await select(tester, 5);
    await tapIn(tester, AyahSheet, find.text('Tafsir'));

    expect(tester.widget<PageTurner>(find.byType(PageTurner)).recede.value, closeTo(1, .01));
    for (final text in ['Tafsir', 'Translation', 'Notes', 'Al-Muyassar', tafsir(5)]) {
      expect(inSheet(StudySheet, find.text(text)), findsWidgets, reason: text);
    }
    expect(inSheet(StudySheet, find.text('Words')), findsNothing);
    expect(inSheet(StudySheet, find.text('Al-Fatiha · Ayah 5')), findsOneWidget);

    await tester.tap(labelled(StudySheet, 'Next ayah'));
    await tester.pumpAndSettle();
    expect(selected(tester), const AyahKey(1, 6));
    expect(inSheet(StudySheet, find.text('Al-Fatiha · Ayah 6')), findsOneWidget);
    expect(inSheet(StudySheet, find.text(tafsir(6))), findsOneWidget);

    await tester.tap(labelled(StudySheet, 'Previous ayah'));
    await tester.pumpAndSettle();
    expect(selected(tester), const AyahKey(1, 5));

    /// ibn kathir downloads on its first pick, the test phone is offline
    await tapIn(tester, StudySheet, find.text('Ibn Kathir'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    expect(find.text('Needs internet once'), findsOneWidget);
    expect(inSheet(StudySheet, find.text(tafsir(5))), findsOneWidget);

    await tapIn(tester, StudySheet, find.text('Translation'));
    for (final text in ['Sahih International', translation(5), 'Arabic · Al-Muyassar summary']) {
      expect(inSheet(StudySheet, find.text(text)), findsWidgets, reason: text);
    }

    await tester.tap(labelled(StudySheet, 'Close'));
    await tester.pumpAndSettle();
    expect(selected(tester), isNull);
    expect(tester.widget<PageTurner>(find.byType(PageTurner)).recede.value, closeTo(0, .01));
    await unmount(tester);
  });

  group('the study sheet', () {
    Finder head() => inSheet(StudySheet, find.text('Al-Fatiha · Ayah 5'));

    testWidgets('opens at 400, its head grows it to 720 and steps back to 400 and closed', (
      tester,
    ) async {
      await pumpReader(tester);
      await select(tester, 5);
      await tapIn(tester, AyahSheet, find.text('Tafsir'));
      expect(shown(tester), closeTo(400, 1));

      await drag(tester, head(), -200);
      expect(shown(tester), closeTo(720, 1));

      await drag(tester, head(), 200);
      expect(shown(tester), closeTo(400, 1));
      expect(selected(tester), isNotNull);

      await drag(tester, head(), 200);
      expect(selected(tester), isNull);
      await unmount(tester);
    });

    testWidgets('a pull on its text grows it to 720 before the text scrolls, and back', (
      tester,
    ) async {
      await pumpReader(tester, textScale: 2);
      await select(tester, 5);
      await tapIn(tester, AyahSheet, find.text('Tafsir'));

      /// 200 under the grabber is the ayah's text at any height, the tafsir is still under the screen
      Future<void> pull(double dy) async {
        final grabber = tester.getTopLeft(inSheet(StudySheet, find.byType(Grabber)));
        await tester.dragFrom(Offset(196, grabber.dy + 200), Offset(0, dy));
        await tester.pumpAndSettle();
      }

      await pull(-200);
      expect(shown(tester), closeTo(720, 1));
      expect(studyScroll(tester).pixels, 0);

      await pull(-100);
      expect(shown(tester), closeTo(720, 1));
      expect(studyScroll(tester).pixels, greaterThan(0));

      /// the text goes back to its top first, then the sheet follows the rest of the drag
      await pull(100 + 250);
      expect(studyScroll(tester).pixels, 0);
      expect(shown(tester), closeTo(400, 1));

      await pull(-320);
      await pull(-100);
      await tester.tap(labelled(StudySheet, 'Close'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      final open = tester.widget<PageTurner>(find.byType(PageTurner)).recede.value;
      expect(open, lessThan(.9));
      expect(shown(tester), closeTo(720 * open, 1), reason: 'the whole sheet slides down');
      await tester.pumpAndSettle();
      expect(selected(tester), isNull);

      await select(tester, 5);
      await tapIn(tester, AyahSheet, find.text('Tafsir'));
      expect(shown(tester), closeTo(400, 1));
      expect(studyScroll(tester).pixels, 0);
      await unmount(tester);
    });

    testWidgets('720 is capped to what fits under the status bar', (tester) async {
      tester.view.padding = const FakeViewPadding(top: 200 * 3);
      await pumpReader(tester);
      await select(tester, 5);
      await tapIn(tester, AyahSheet, find.text('Tafsir'));
      await drag(tester, head(), -300);
      expect(shown(tester), closeTo(852 - 200, 1));
      await unmount(tester);
    });

    testWidgets('with reduce motion it opens at 400 in place and still grows', (tester) async {
      await pumpReader(tester, reduceMotion: true);
      await select(tester, 5);
      await tapIn(tester, AyahSheet, find.text('Tafsir'));
      expect(shown(tester), closeTo(400, 1));

      await drag(tester, head(), -200);
      expect(shown(tester), closeTo(720, 1));
      await unmount(tester);
    });
  });

  testWidgets('in arabic the translation slot is al-muyassar', (tester) async {
    await pumpReader(tester, locale: const Locale('ar'));
    await select(tester, 5);

    expect(inSheet(AyahSheet, find.text(tafsir(5))), findsOneWidget);
    expect(inSheet(AyahSheet, find.text('الميسّر')), findsOneWidget);
    expect(inSheet(AyahSheet, find.text(translation(5))), findsNothing);
    await unmount(tester);
  });

  testWidgets('both sheets hold at text scale 2.0 in arabic', (tester) async {
    await pumpReader(tester, locale: const Locale('ar'), textScale: 2);
    await select(tester, 5);
    await tapIn(tester, AyahSheet, find.text('التفسير'));
    await drag(tester, inSheet(StudySheet, find.byType(Grabber)), -320);
    await tapIn(tester, StudySheet, find.text('الترجمة'));
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  testWidgets('copy puts the arabic, the translation and the reference on the clipboard', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
      call,
    ) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
      return null;
    });
    await pumpReader(tester);
    await select(tester, 5);
    await tapIn(tester, AyahSheet, find.text('Copy'));

    final parts = copied!.split('\n\n');
    expect(parts, hasLength(3));
    expect(parts[0], startsWith('إِيَّاكَ'));
    expect(parts[1], translation(5));
    expect(parts[2], 'Al-Fatiha 1:5');
    expect(find.text('Copied'), findsOneWidget);
    await unmount(tester);
  });
}
