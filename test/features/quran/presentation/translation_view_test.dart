import 'dart:convert';
import 'dart:io';

import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/quran/presentation/providers/selection.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/ayah_sheet.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/mushaf_page_view.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/page_chrome.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/translation_view.dart';
import 'package:drift/drift.dart' show Value;
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

  testWidgets('translation is the page as 4.07 cells with the surah header', (tester) async {
    await pumpReader(tester);

    expect(view, findsOneWidget);
    expect(find.byType(MushafPageView), findsNothing);
    expect(cellText('سورة الفاتحة'), findsOneWidget);
    expect(cellText('Al-Fatiha · Meccan · 7 ayahs'), findsOneWidget);
    for (var ayah = 1; ayah <= 7; ayah++) {
      await scrollTo(tester, translation(ayah));
      expect(cellText(translation(ayah)), findsOneWidget, reason: '$ayah');
    }

    /// the marker numbers are eastern, as the mushaf prints them
    expect(cellText('٥'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('both is the mushaf page with its cells under it', (tester) async {
    await pumpReader(tester, layout: QuranLayout.both);

    final page = find.descendant(of: view, matching: find.byType(MushafPageView));
    expect(page, findsOneWidget);
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(tester.getSize(page).height, screen.height);

    /// the first cell waits under the page until it scrolls up
    final first = cellText(translation(1));
    expect(first.evaluate().isEmpty || tester.getRect(first).top >= screen.height, isTrue);
    await scrollTo(tester, translation(1));
    expect(tester.getRect(first).top, lessThan(screen.height));
    await unmount(tester);
  });

  testWidgets('a cell tap selects its ayah, the wash fills the cell behind the text', (
    tester,
  ) async {
    await pumpReader(tester);

    await scrollTo(tester, translation(5));
    await tester.tap(cellText(translation(5)));
    await tester.pumpAndSettle();
    expect(containerOf(tester).read(selectionProvider), const AyahKey(1, 5));
    expectOnScreen(tester, cellText(translation(5)));
    await unmount(tester);
  });

  testWidgets('switching layout keeps the selected ayah on screen', (tester) async {
    await pumpReader(tester, layout: QuranLayout.mushaf);
    final mushaf = tester.allRenderObjects.whereType<RenderMushafPage>().firstWhere(
      (page) => page.washBounds(const AyahKey(1, 5)) != null,
    );
    await tester.tapAt(mushaf.localToGlobal(mushaf.washBounds(const AyahKey(1, 5))!.center));
    await tester.pumpAndSettle();

    await setLayout(tester, QuranLayout.translation);
    expect(containerOf(tester).read(selectionProvider), const AyahKey(1, 5));
    expectOnScreen(tester, cellText(translation(5)));

    /// in Both the page itself is on screen with the ayah washed on it
    await setLayout(tester, QuranLayout.both);
    expect(containerOf(tester).read(selectionProvider), const AyahKey(1, 5));
    final page = tester.allRenderObjects.whereType<RenderMushafPage>().firstWhere(
      (page) => page.washBounds(const AyahKey(1, 5)) != null,
    );
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    final wash = page.localToGlobal(page.washBounds(const AyahKey(1, 5))!.center);
    expect(wash.dy, inInclusiveRange(0, screen.height));
    await unmount(tester);
  });

  testWidgets('the dock switches mushaf and translation, both goes back to the mushaf', (
    tester,
  ) async {
    await pumpReader(tester, layout: QuranLayout.mushaf);
    Future<void> tapTranslation() async {
      await tester.tapAt(const Offset(385, 400));
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

    await setLayout(tester, QuranLayout.both);
    await tester.tap(find.text('Translation'));
    await tester.pumpAndSettle();
    expect(settingsOf(tester).quranLayout, QuranLayout.mushaf);
    await unmount(tester);
  });

  testWidgets('the sizes change the cells at once with the selection haptic', (tester) async {
    await pumpReader(tester);
    await scrollTo(tester, translation(7));
    await tester.tap(cellText(translation(7)));
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

    /// the controls, then Display, then a larger translation
    await tester.tapAt(const Offset(385, 400));
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
