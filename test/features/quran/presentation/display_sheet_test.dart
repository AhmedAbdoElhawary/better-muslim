import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/grouped_section.dart';
import 'package:better_muslim/core/widgets/nav_row.dart';
import 'package:better_muslim/core/widgets/segmented.dart';
import 'package:better_muslim/core/widgets/sheet/picker_row.dart';
import 'package:better_muslim/features/quran/presentation/providers/page_providers.dart';
import 'package:better_muslim/features/quran/presentation/providers/selection.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/mushaf_page_view.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/page_turn.dart';
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

  late List<MethodCall> calls;
  setUp(() => calls = mockSystemChannel());

  Future<void> pumpReader(WidgetTester tester, {double textScale = 1, int page = 1}) async {
    await pumpHome(tester, await designOverrides(), textScale: textScale, settle: false);
    await tester.pump();
    containerOf(tester).read(routerProvider).push(Routes.quranPage(page));
    await tester.pumpAndSettle();
  }

  /// a tap on the page's header shows the controls, then the dock's Display
  Future<void> openDisplay(WidgetTester tester) async {
    await tester.tapAt(const Offset(200, 40));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Display'));
    await tester.pumpAndSettle();
  }

  AppSettings settingsOf(WidgetTester tester) => containerOf(tester).read(settingsProvider).value!;

  Finder segment<T>(String label) =>
      find.descendant(of: find.byType(Segmented<T>), matching: find.text(label));

  Future<void> tapInSheet(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('holds page, layout, page turn, keep screen on and the mushaf', (tester) async {
    await pumpReader(tester);
    await openDisplay(tester);

    for (final text in [
      'Display',
      'Applies to every page',
      'PAGE',
      'White',
      'Paper',
      'Cream',
      'Sepia',
      'Green',
      'Night',
      'Navy',
      'Match app',
      'FONT',
      'Amiri Quran',
      'KFGQPC Hafs',
      'Scheherazade',
      'Layout',
      'Page turn',
      'Book',
      'Slide',
      'Keep screen on',
      'Text',
      'Sahih International',
    ]) {
      expect(find.text(text), findsWidgets, reason: text);
    }
    for (final label in ['Mushaf', 'Translation']) {
      expect(segment<QuranLayout>(label), findsOneWidget, reason: label);
    }

    /// tajweed colors wait for 7b, the sizes only matter in the translation layouts
    expect(find.text('Tajweed colors'), findsNothing);
    expect(find.text('Arabic size'), findsNothing);
    await unmount(tester);
  });

  testWidgets('each choice is kept in settings and the page takes it at once', (tester) async {
    await pumpReader(tester);
    await openDisplay(tester);

    await tapInSheet(tester, find.text('Night'));
    expect(settingsOf(tester).pageColor, PageColor.night);
    expect(containerOf(tester).read(pageColorProvider), PageColor.night);

    await tapInSheet(tester, segment<PageTurn>('Slide'));
    expect(settingsOf(tester).pageTurn, PageTurn.slide);
    expect(tester.widget<PageTurner>(find.byType(PageTurner)).book, isFalse);

    await tapInSheet(tester, segment<QuranLayout>('Translation'));
    expect(settingsOf(tester).quranLayout, QuranLayout.translation);

    /// the sheet reopens on what was picked
    await tester.tapAt(const Offset(200, 40));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Display'));
    await tester.pumpAndSettle();
    final picked = tester.widget<Segmented<QuranLayout>>(find.byType(Segmented<QuranLayout>));
    expect(picked.selected, QuranLayout.translation);
    await unmount(tester);
  });

  testWidgets('a font and the palettes past the edge are kept in settings', (tester) async {
    await pumpReader(tester);
    await openDisplay(tester);

    /// one sample per font, each drawn in its own
    expect(find.text('بِسْمِ ٱللَّهِ'), findsNWidgets(QuranFont.values.length));

    await tapInSheet(tester, find.text('Scheherazade'));
    expect(settingsOf(tester).quranFont, QuranFont.scheherazade);

    await tapInSheet(tester, find.text('Navy'));
    expect(settingsOf(tester).pageColor, PageColor.navy);
    await tapInSheet(tester, find.text('Sepia'));
    expect(containerOf(tester).read(pageColorProvider), PageColor.sepia);
    await unmount(tester);
  });

  testWidgets('the font tiles show only with the text style', (tester) async {
    await pumpReader(tester);
    await containerOf(tester)
        .read(databaseProvider)
        .updateSettings(const SettingsCompanion(mushafStyle: Value(MushafStyle.qcfV2)));
    await openDisplay(tester);
    expect(find.text('FONT'), findsNothing);
    expect(find.text('KFGQPC Hafs'), findsNothing);

    await containerOf(tester)
        .read(databaseProvider)
        .updateSettings(const SettingsCompanion(mushafStyle: Value(MushafStyle.text)));
    await tester.pumpAndSettle();
    expect(find.text('FONT'), findsOneWidget);
    expect(find.text('KFGQPC Hafs'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('the sizes step within -2 to 3 and show their point size', (tester) async {
    await pumpReader(tester);
    await openDisplay(tester);
    await tapInSheet(tester, segment<QuranLayout>('Translation'));

    expect(find.text('Arabic size'), findsOneWidget);
    expect(find.text('Translation size'), findsOneWidget);
    expect(find.text('26'), findsOneWidget);
    expect(find.text('14'), findsOneWidget);

    final larger = find.bySemanticsLabel('Larger');
    final smaller = find.bySemanticsLabel('Smaller');
    await tapInSheet(tester, larger.at(1));
    expect(settingsOf(tester).quranArabicSize, 1);
    expect(find.text('28'), findsOneWidget);

    for (var i = 0; i < 5; i++) {
      await tapInSheet(tester, smaller.last);
    }
    expect(settingsOf(tester).quranTranslationSize, -2);
    expect(find.text('12'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('mushaf size steps from 80% to 150%, above 100% the page rewraps and scrolls', (
    tester,
  ) async {
    await pumpReader(tester, page: 3);
    await openDisplay(tester);
    expect(find.text('Mushaf size'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);

    final larger = find.bySemanticsLabel('Larger').first;
    final smaller = find.bySemanticsLabel('Smaller').first;
    for (var i = 0; i < 3; i++) {
      await tapInSheet(tester, smaller);
    }
    expect(settingsOf(tester).mushafSize, -2);
    expect(find.text('80%'), findsOneWidget);
    for (var i = 0; i < 8; i++) {
      await tapInSheet(tester, larger);
    }
    expect(settingsOf(tester).mushafSize, 5);
    expect(find.text('150%'), findsOneWidget);

    await tester.tapAt(const Offset(200, 40));
    await tester.pumpAndSettle();

    /// the dock lies over the page now, so it goes before the press at the bottom
    await tester.tapAt(const Offset(200, 400));
    await tester.pump(kDoubleTapTimeout);
    await tester.pumpAndSettle();
    final page = tester.allRenderObjects.whereType<RenderMushafPage>().firstWhere(
      (page) => page.washBounds(const AyahKey(2, 16)) != null,
    );
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(page.size.height, greaterThan(screen.height));
    expect(page.reflow, isTrue);

    /// the last ayah is under the fold, the page scrolls to it and a tap still finds it
    final last = page.washBounds(const AyahKey(2, 16))!;
    page.showOnScreen(rect: last);
    await tester.pumpAndSettle();
    await tester.longPressAt(page.localToGlobal(last.center));
    await tester.pumpAndSettle();
    expect(containerOf(tester).read(selectionProvider).sheet, const AyahKey(2, 16));
    await unmount(tester);
  });

  testWidgets('keep screen on holds the screen in the reader and lets go on leaving', (
    tester,
  ) async {
    await pumpReader(tester);
    await openDisplay(tester);
    calls.clear();

    await tapInSheet(tester, find.text('Keep screen on'));
    expect(settingsOf(tester).keepScreenOn, isTrue);
    expect(calls.where((call) => call.method == 'keepScreenOn').last.arguments, {'on': true});

    await tester.tapAt(const Offset(200, 40));
    await tester.pumpAndSettle();
    containerOf(tester).read(routerProvider).pop();
    await tester.pumpAndSettle();
    expect(calls.where((call) => call.method == 'keepScreenOn').last.arguments, {'on': false});
    await unmount(tester);
  });

  testWidgets('in arabic the translation row names al-muyassar', (tester) async {
    await pumpHome(tester, await designOverrides(), locale: const Locale('ar'), settle: false);
    await tester.pump();
    containerOf(tester).read(routerProvider).push(Routes.quranPage(1));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(200, 40));
    await tester.pumpAndSettle();
    await tester.tap(find.text('العرض'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: find.byType(GroupedSection), matching: find.text('الميسّر')),
      findsOneWidget,
    );
    expect(find.widgetWithText(NavRow, 'نص'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('the translation row opens every translation in place of display', (tester) async {
    await pumpReader(tester);
    await openDisplay(tester);
    expect(settingsOf(tester).translation, isNull);

    await tapInSheet(tester, find.widgetWithText(NavRow, 'Translation'));
    expect(find.text('Applies to every page'), findsNothing);
    for (final text in [
      'Sahih International',
      'Pickthall',
      'Yusuf Ali',
      'Hilali & Khan',
      'Al-Muyassar',
      'Al-Jalalayn',
    ]) {
      expect(find.text(text), findsWidgets, reason: text);
    }
    await tapInSheet(tester, find.text('Al-Jalalayn'));
    expect(settingsOf(tester).translation, Translation.jalalayn);
    expect(tester.widget<PickerRow>(find.widgetWithText(PickerRow, 'Al-Jalalayn')).selected, true);
    expect(find.text('Applies to every page'), findsNothing);
    await unmount(tester);
  });

  testWidgets('the mushaf row opens the styles in place of display, a pick keeps them', (
    tester,
  ) async {
    await pumpReader(tester);
    await openDisplay(tester);

    await tapInSheet(tester, find.widgetWithText(NavRow, 'Mushaf'));
    expect(find.text('Applies to every page'), findsNothing);
    expect(find.text('Madinah · Hafs'), findsOneWidget);

    await tapInSheet(tester, find.text('Text'));
    expect(settingsOf(tester).mushafStyle, MushafStyle.text);
    expect(find.text('Madinah · Hafs'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('survives text scale 2.0', (tester) async {
    await pumpReader(tester, textScale: 2);
    await openDisplay(tester);
    await tapInSheet(tester, segment<QuranLayout>('Translation'));
    await tester.ensureVisible(find.text('Sahih International'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });
}
