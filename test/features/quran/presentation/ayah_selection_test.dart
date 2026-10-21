import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/features/quran/domain/mushaf_layout.dart';
import 'package:better_muslim/features/quran/domain/mushaf_page.dart';
import 'package:better_muslim/features/quran/presentation/providers/selection.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/ayah_sheet.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/mushaf_page_view.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/page_chrome.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../helpers/fonts.dart';
import '../../../helpers/home.dart';
import '../../../helpers/more.dart';
import '../../../helpers/prayer.dart';
import '../../../helpers/providers.dart';
import '../../../helpers/widgets.dart';

MushafWord _word(int ayah, {bool end = false}) =>
    MushafWord(key: AyahKey(1, ayah), text: '$ayah', end: end);

void main() {
  setUpAll(tz.initializeTimeZones);
  setUpAll(loadAppFonts);
  setUp(mockSystemChannel);

  group('the wash and the lift', () {
    /// two lines: ayah 1 and the start of 2, then the rest of 2
    final page = MushafPage(
      number: 3,
      lines: [
        MushafLine(type: MushafLineType.ayah, words: [_word(1), _word(1, end: true), _word(2)]),
        MushafLine(type: MushafLineType.ayah, words: [_word(2), _word(2, end: true)]),
      ],
    );
    final layout = layoutMushaf(
      page: page,
      widths: [
        [60, 20, 80],
        [100, 20],
      ],
      bands: [45, 45],
      area: const Rect.fromLTWH(20, 100, 300, 0),
      gap: 6,
    );

    test('one rect per line part, from its first to its last word', () {
      final rects = washRects(page, layout, const AyahKey(1, 2), height: 30, side: 2);
      expect(rects, hasLength(2));
      expect(rects[0].right, layout.words[0][2].right + 2);
      expect(rects[0].left, layout.words[0][2].left - 2);
      expect(rects[1].right, layout.words[1][0].right + 2);
      expect(rects[1].left, layout.words[1][1].left - 2);
      for (final (i, rect) in rects.indexed) {
        expect(rect.height, 30);
        expect(rect.center.dy, layout.lines[i].center.dy);
      }
      expect(washRects(page, layout, const AyahKey(1, 1), height: 30, side: 2), hasLength(1));
      expect(washRects(page, layout, const AyahKey(1, 3), height: 30, side: 2), isEmpty);
      expect(RadiusManager.ayahWash, 9);
    });

    test('the page goes up only as far as keeps the ayah 24 pt above the sheet', () {
      expect(ayahLift(bottom: 300, sheetTop: 452, gap: 24), 0);
      expect(ayahLift(bottom: 520, sheetTop: 452, gap: 24), 92);
      expect(ayahLift(bottom: 428, sheetTop: 452, gap: 24), 0);
    });

    test('an ayah split over two pages is one ayah on both', () {
      final next = MushafPage(
        number: 4,
        lines: [
          MushafLine(type: MushafLineType.ayah, words: [_word(2), _word(2, end: true), _word(3)]),
        ],
      );
      expect(page.has(const AyahKey(1, 2)), isTrue);
      expect(next.has(const AyahKey(1, 2)), isTrue);
      expect(ayahText([page, next], const AyahKey(1, 2)), '2 2 2');
    });
  });

  group('on the reader', () {
    Future<void> pumpReader(WidgetTester tester) async {
      await pumpHome(tester, await designOverrides(), settle: false);
      await tester.pump();
      containerOf(tester).read(routerProvider).push(Routes.quranPage(1));
      await tester.pumpAndSettle();
    }

    RenderMushafPage pageOne(WidgetTester tester) => tester.allRenderObjects
        .whereType<RenderMushafPage>()
        .firstWhere((page) => page.washBounds(const AyahKey(1, 1)) != null);

    Offset ayahAt(WidgetTester tester, int ayah) {
      final page = pageOne(tester);
      return page.localToGlobal(page.washBounds(AyahKey(1, ayah))!.center);
    }

    Finder labelled(Type sheet, String label) => find.descendant(
      of: find.byType(sheet),
      matching: find.byWidgetPredicate((w) => w is Semantics && w.properties.label == label),
    );

    Finder inSheet(String text) =>
        find.descendant(of: find.byType(AyahSheet), matching: find.text(text));

    AyahKey? selected(WidgetTester tester) => containerOf(tester).read(selectionProvider);

    testWidgets('a tap on a word selects its ayah with the light haptic', (tester) async {
      await pumpReader(tester);
      final haptics = recordHaptics();

      await tester.tapAt(ayahAt(tester, 5));
      await tester.pumpAndSettle();
      expect(selected(tester), const AyahKey(1, 5));
      expect(inSheet('Al-Fatiha · Ayah 5'), findsOneWidget);
      expect(haptics, ['HapticFeedbackType.lightImpact']);

      /// the sheet stays, the selection moves
      await tester.tapAt(ayahAt(tester, 2));
      await tester.pumpAndSettle();
      expect(selected(tester), const AyahKey(1, 2));
      expect(inSheet('Al-Fatiha · Ayah 2'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('a long press selects too', (tester) async {
      await pumpReader(tester);

      await tester.longPressAt(ayahAt(tester, 4));
      await tester.pumpAndSettle();
      expect(selected(tester), const AyahKey(1, 4));
      await unmount(tester);
    });

    testWidgets('a tap off the text toggles the controls, or closes the sheet', (tester) async {
      await pumpReader(tester);
      bool chrome() => tester.widget<PageChrome>(find.byType(PageChrome)).shown;

      /// the page's top margin, above the frame
      /// the right margin past the spine, the top bar covers the top one while it shows
      const margin = Offset(385, 400);
      await tester.tapAt(margin);
      await tester.pumpAndSettle();
      expect(chrome(), isTrue);
      expect(selected(tester), isNull);
      await tester.tapAt(margin);
      await tester.pumpAndSettle();
      expect(chrome(), isFalse);

      await tester.tapAt(ayahAt(tester, 5));
      await tester.pumpAndSettle();
      expect(selected(tester), isNotNull);
      await tester.tapAt(margin);
      await tester.pumpAndSettle();
      expect(selected(tester), isNull);
      expect(chrome(), isFalse);
      await unmount(tester);
    });

    testWidgets('the page lifts the ayah clear of the sheet and settles back', (tester) async {
      await pumpReader(tester);
      double bottom() {
        final page = pageOne(tester);
        return page.localToGlobal(page.washBounds(const AyahKey(1, 7))!.bottomCenter).dy;
      }

      final rest = bottom();
      await tester.tapAt(ayahAt(tester, 7));
      await tester.pumpAndSettle();
      final sheetTop = tester.getTopLeft(find.byType(AyahSheet)).dy;
      expect(rest, greaterThan(sheetTop - SpaceManager.ayahLift), reason: 'ayah 7 needs a lift');
      expect(bottom(), closeTo(sheetTop - SpaceManager.ayahLift, 1));

      await tester.tap(labelled(AyahSheet, 'Close'));
      await tester.pumpAndSettle();
      expect(selected(tester), isNull);
      expect(bottom(), closeTo(rest, .5));
      await unmount(tester);
    });
  });
}
