import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/quran/data/quran_store.dart';
import 'package:better_muslim/features/quran/presentation/providers/selection.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/ayah_sheet.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/mushaf_page_view.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/page_chrome.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/page_turn.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/study_tabs.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/translation_view.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/gestures.dart';
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

  late List<MethodCall> haptics;
  setUp(() {
    mockSystemChannel();
    haptics = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') haptics.add(call);
        return null;
      },
    );
  });

  /// al-fatiha's shipped sahih international and al-muyassar lines
  final fatiha = jsonDecode(File('assets/quran/surahs/001.json').readAsStringSync()) as Map;
  String translation(int ayah) => (fatiha['tr'] as List)[ayah - 1] as String;
  String tafsir(int ayah) => (fatiha['tafsir'] as List)[ayah - 1] as String;

  Future<void> setLayout(WidgetTester tester, QuranLayout layout) async {
    await tester.runAsync(
      () =>
          containerOf(tester)
              .read(databaseProvider)
              .updateSettings(SettingsCompanion(quranLayout: Value(layout))),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpReader(
    WidgetTester tester, {
    QuranLayout layout = QuranLayout.translation,
    Locale locale = const Locale('en'),
    double textScale = 1,
  }) async {
    await pumpHome(
      tester,
      await designOverrides(),
      locale: locale,
      textScale: textScale,
      settle: false,
    );
    await tester.pump();
    await setLayout(tester, layout);
    containerOf(tester).read(routerProvider).push(Routes.quranPage(1));
    await tester.pumpAndSettle();
  }

  AppSettings settingsOf(WidgetTester tester) => containerOf(tester).read(settingsProvider).value!;

  /// the turner builds the next page beside it
  final view = find.byWidgetPredicate((widget) => widget is TranslationView && widget.page == 1);

  double offsetOf(WidgetTester tester, {int page = 1}) => tester
      .state<ScrollableState>(
        find.descendant(
          of: find.byWidgetPredicate((widget) => widget is TranslationView && widget.page == page),
          matching: find.byType(Scrollable),
        ),
      )
      .position
      .pixels;

  Finder cellText(String text) => find.descendant(of: view, matching: find.text(text));

  /// the list builds only what is near the screen
  Future<void> scrollTo(WidgetTester tester, String text) async {
    await tester.scrollUntilVisible(
      cellText(text),
      200,
      scrollable: find.descendant(of: view, matching: find.byType(Scrollable)),
    );
    await tester.pumpAndSettle();
  }

  /// the cell's text is on screen, under the status bar and above the bottom
  void expectOnScreen(WidgetTester tester, Finder finder) {
    final rect = tester.getRect(finder);
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.bottom, lessThanOrEqualTo(screen.height));
  }

  testWidgets('translation is the page then 4.07 cells with the surah header', (tester) async {
    await pumpReader(tester);

    expect(view, findsOneWidget);
    await scrollTo(tester, 'سورة الفاتحة');
    expect(cellText('سورة الفاتحة'), findsOneWidget);
    expect(cellText('Al-Fatiha · Meccan · 7 ayahs'), findsOneWidget);
    for (var ayah = 1; ayah <= 7; ayah++) {
      await scrollTo(tester, translation(ayah));
      expect(cellText(translation(ayah)), findsOneWidget, reason: '$ayah');

      /// the marker numbers are eastern, as the mushaf prints them
      if (ayah == 5) expect(cellText('٥'), findsOneWidget);
    }
    await unmount(tester);
  });

  testWidgets('the page takes the mushaf size and opens at its top, with no scroll', (
    tester,
  ) async {
    await pumpHome(tester, await designOverrides(), settle: false);
    await tester.pump();
    await tester.runAsync(
      () =>
          containerOf(tester)
              .read(databaseProvider)
              .updateSettings(const SettingsCompanion(mushafSize: Value(3))),
    );
    await setLayout(tester, QuranLayout.translation);
    containerOf(tester).read(routerProvider).push(Routes.quranPage(1));
    while (view.evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(offsetOf(tester), 0);
    await tester.pumpAndSettle();
    expect(offsetOf(tester), 0);

    final page = tester.getRect(find.descendant(of: view, matching: find.byType(MushafPageView)));
    expect(page.width, screen.width);
    expect(page.height, greaterThanOrEqualTo(screen.height));
    expect(page.top, moreOrLessEquals(0, epsilon: .5));
    final render = tester.allRenderObjects.whereType<RenderMushafPage>().firstWhere(
      (page) => page.washBounds(const AyahKey(1, 1)) != null,
    );
    expect(render.reflow, isTrue);
    await unmount(tester);
  });

  testWidgets('a long press on the page keeps the page, a cell keeps the cells', (tester) async {
    await pumpReader(tester);
    final mushaf = tester.allRenderObjects.whereType<RenderMushafPage>().firstWhere(
      (page) => page.washBounds(const AyahKey(1, 2)) != null,
    );
    await tester.longPressAt(mushaf.localToGlobal(mushaf.washBounds(const AyahKey(1, 2))!.center));
    await tester.pumpAndSettle();
    expect(containerOf(tester).read(selectionProvider).sheet, const AyahKey(1, 2));
    expect(offsetOf(tester), 0);
    await unmount(tester);
  });

  testWidgets('only the Translation button scrolls, off goes back up before the mushaf', (
    tester,
  ) async {
    await pumpReader(tester, layout: QuranLayout.mushaf);
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    await tester.tapAt(const Offset(200, 40));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Translation'));
    await tester.pump();
    await tester.pump();
    expect(offsetOf(tester), lessThan(screen.height / 2), reason: 'scrolling in');
    await tester.pumpAndSettle();
    expect(offsetOf(tester), screen.height / 2);

    await tester.tap(find.text('Translation'));
    await tester.pump();
    await tester.pump(BmMotion.emphasized ~/ 2);
    expect(settingsOf(tester).quranLayout, QuranLayout.translation, reason: 'still scrolling up');
    expect(offsetOf(tester), inExclusiveRange(0, screen.height / 2));
    await tester.pumpAndSettle();
    expect(settingsOf(tester).quranLayout, QuranLayout.mushaf);
    expect(view, findsNothing);

    /// a tap mid scroll turns it around and keeps the translation
    await tester.tap(find.text('Translation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Translation'));
    await tester.pump();
    await tester.pump(BmMotion.emphasized ~/ 2);
    await tester.tap(find.text('Translation'));
    await tester.pumpAndSettle();
    expect(settingsOf(tester).quranLayout, QuranLayout.translation);
    expect(offsetOf(tester), screen.height / 2);
    await unmount(tester);
  });

  testWidgets('the sides of the top half turn the page, the cells never do', (tester) async {
    await pumpReader(tester);
    int shown() => tester.widget<PageTurner>(find.byType(PageTurner)).page.value;
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    final strip = translationStrip(screen);

    await tester.tapAt(Offset(strip.width / 2, strip.height / 2));
    await tester.pumpAndSettle();
    expect(shown(), 2);

    /// a turn shows the whole page with no scroll
    expect(offsetOf(tester, page: 2), 0);
    await tester.tapAt(Offset(screen.width - strip.width / 2, strip.height / 2));
    await tester.pumpAndSettle();
    expect(shown(), 1);

    /// a tap on a cell's edge shows the controls once it is no double tap
    await tester.tapAt(Offset(SpaceManager.s4, screen.height * .7));
    await tester.pump(kDoubleTapTimeout);
    await tester.pumpAndSettle();
    expect(shown(), 1);
    expect(tester.widget<PageChrome>(find.byType(PageChrome)).shown, isTrue);
    await unmount(tester);
  });

  testWidgets('a long press on a cell opens its ayah, the wash fills the cell behind the text', (
    tester,
  ) async {
    await pumpReader(tester);

    await scrollTo(tester, translation(5));
    await tester.longPress(cellText(translation(5)));
    await tester.pumpAndSettle();
    expect(containerOf(tester).read(selectionProvider).sheet, const AyahKey(1, 5));

    /// the mushaf's lift over the sheet stays, so only the cell being on screen is checked
    final cell = tester.getRect(cellText(translation(5)));
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(cell.bottom, greaterThan(0));
    expect(cell.top, lessThan(screen.height));
    await unmount(tester);
  });

  testWidgets('a highlighted cell opens its note, its bookmarked number the ayah sheet', (
    tester,
  ) async {
    await pumpReader(tester);
    final store = containerOf(tester).read(quranStoreProvider);
    unawaited(store.saveNote(const AyahKey(1, 5), 'ask for help', highlight: true));
    unawaited(store.addAyah(const AyahKey(1, 3), 1));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();

    StudySheet study() => tester.widget<StudySheet>(find.byType(StudySheet));
    await scrollTo(tester, translation(5));
    await tester.tap(cellText(translation(5)));
    await tester.pump(kDoubleTapTimeout);
    await tester.pumpAndSettle();
    expect(containerOf(tester).read(selectionProvider).sheet, const AyahKey(1, 5));
    expect(study().tab, StudyTab.notes);
    expect(study().open.value, closeTo(1, .01));

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(containerOf(tester).read(selectionProvider).sheet, isNull);

    /// the marker draws at 32, its 44 pt reaches past it
    await scrollTo(tester, translation(3));
    final marker = cellText('٣');
    await tester.tapAt(tester.getCenter(marker) + Offset(tester.getSize(marker).width / 2 + 4, 0));
    await tester.pump(kDoubleTapTimeout);
    await tester.pumpAndSettle();
    expect(containerOf(tester).read(selectionProvider).sheet, const AyahKey(1, 3));
    expect(tester.widget<AyahSheet>(find.byType(AyahSheet)).open.value, closeTo(1, .01));
    expect(study().open.value, closeTo(0, .01));

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(cellText(translation(4)));
    await tester.pump(kDoubleTapTimeout);
    await tester.pumpAndSettle();
    expect(containerOf(tester).read(selectionProvider).sheet, isNull, reason: 'a plain cell');
    await unmount(tester);
  });

  testWidgets('switching layout keeps the selected ayah on screen', (tester) async {
    await pumpReader(tester, layout: QuranLayout.mushaf);
    final mushaf = tester.allRenderObjects.whereType<RenderMushafPage>().firstWhere(
      (page) => page.washBounds(const AyahKey(1, 5)) != null,
    );
    await tester.longPressAt(mushaf.localToGlobal(mushaf.washBounds(const AyahKey(1, 5))!.center));
    await tester.pumpAndSettle();

    await setLayout(tester, QuranLayout.translation);
    expect(containerOf(tester).read(selectionProvider).sheet, const AyahKey(1, 5));

    /// the mushaf's lift over the sheet stays, so only the cell being on screen is checked
    final cell = tester.getRect(cellText(translation(5)));
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(cell.bottom, greaterThan(0));
    expect(cell.top, lessThan(screen.height));
    await unmount(tester);
  });

  testWidgets('the dock switches mushaf and translation', (tester) async {
    await pumpReader(tester, layout: QuranLayout.mushaf);
    Future<void> tapTranslation() async {
      await tester.tapAt(const Offset(200, 40));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Translation'));
      await tester.pumpAndSettle();
    }

    await tapTranslation();
    expect(settingsOf(tester).quranLayout, QuranLayout.translation);
    expect(view, findsOneWidget);

    /// the controls still show, a tap off them hides them
    await tester.tap(find.text('Translation'));
    await tester.pumpAndSettle();
    expect(settingsOf(tester).quranLayout, QuranLayout.mushaf);
    await unmount(tester);
  });

  testWidgets('the sizes change the cells at once with the selection haptic', (tester) async {
    await pumpReader(tester);
    await scrollTo(tester, translation(7));
    await tester.longPress(cellText(translation(7)));
    await tester.pumpAndSettle();
    expectOnScreen(tester, cellText(translation(7)));
    await tester.tap(
      find.descendant(
        of: find.byType(AyahSheet),
        matching: find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'Close'),
      ),
    );
    await tester.pumpAndSettle();

    double fontOf(String text) => tester
        .widget<RichText>(find.descendant(of: cellText(text), matching: find.byType(RichText)))
        .text
        .style!
        .fontSize!;
    final before = fontOf(translation(7));

    /// the controls, then Display, then a larger translation. a tap on a cell waits out a double tap
    await tester.tapAt(const Offset(200, 40));
    await tester.pump(kDoubleTapTimeout);
    await tester.pumpAndSettle();
    expect(tester.widget<PageChrome>(find.byType(PageChrome)).shown, isTrue);
    await tester.tap(find.text('Display'));
    await tester.pumpAndSettle();
    haptics.clear();
    await tester.ensureVisible(find.bySemanticsLabel('Larger').last);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Larger').last);
    await tester.pumpAndSettle();

    expect(settingsOf(tester).quranTranslationSize, 1);
    expect(fontOf(translation(7)), greaterThan(before));
    expect(haptics, isNotEmpty);
    await unmount(tester);
  });

  testWidgets('in arabic the translation slot is al-muyassar', (tester) async {
    await pumpReader(tester, locale: const Locale('ar'));

    await scrollTo(tester, tafsir(5));
    expect(cellText(tafsir(5)), findsOneWidget);
    expect(cellText(translation(5)), findsNothing);
    await unmount(tester);
  });

  testWidgets('a picked translation fills the cells in either language', (tester) async {
    await pumpReader(tester, locale: const Locale('ar'));
    await tester.runAsync(
      () =>
          containerOf(tester)
              .read(databaseProvider)
              .updateSettings(const SettingsCompanion(translation: Value(Translation.pickthall))),
    );
    await tester.pumpAndSettle();

    final pickthall =
        (jsonDecode(File('assets/quran/translations/en.pickthall.json').readAsStringSync())
                as List)[0][4]
            as String;
    await scrollTo(tester, pickthall);
    expect(cellText(pickthall), findsOneWidget);
    expect(cellText(tafsir(5)), findsNothing);
    await unmount(tester);
  });

  testWidgets('cells survive text scale 2.0', (tester) async {
    await pumpReader(tester, textScale: 2);
    await scrollTo(tester, translation(7));
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  test('an unshipped page still lists its ayahs from the index', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final assets = await QuranAssets.load();
    expect(assets.pageAyahs(1), [for (var a = 1; a <= 7; a++) AyahKey(1, a)]);
    expect(assets.pageAyahs(2), [for (var a = 1; a <= 5; a++) AyahKey(2, a)]);
    expect(assets.pageAyahs(604).last, const AyahKey(114, 6));
  });
}
