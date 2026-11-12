import 'dart:async';

import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/features/quran/data/quran_store.dart';
import 'package:better_muslim/features/quran/domain/mushaf_layout.dart';
import 'package:better_muslim/features/quran/domain/mushaf_page.dart';
import 'package:better_muslim/features/quran/presentation/providers/selection.dart';
import 'package:better_muslim/features/quran/presentation/view/reader_page.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/ayah_sheet.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/choosing_bar.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/mushaf_page_view.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/page_chrome.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/page_turn.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/study_tabs.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
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

    test('a shift moves every rect onto the ink, the same height', () {
      final rects = washRects(page, layout, const AyahKey(1, 2), height: 30, side: 2, shift: -3);
      for (final (i, rect) in rects.indexed) {
        expect(rect.height, 30);
        expect(rect.center.dy, layout.lines[i].center.dy - 3);
      }
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
    Future<void> pumpAt(WidgetTester tester, int page) async {
      await pumpHome(tester, await designOverrides(), settle: false);
      await tester.pump();
      containerOf(tester).read(routerProvider).push(Routes.quranPage(page));
      await tester.pumpAndSettle();
    }

    Future<void> pumpReader(WidgetTester tester) => pumpAt(tester, 1);

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

    AyahKey? selected(WidgetTester tester) => containerOf(tester).read(selectionProvider).sheet;

    Offset at(WidgetTester tester, AyahKey key) {
      final page = tester.allRenderObjects.whereType<RenderMushafPage>().firstWhere(
        (page) => page.washBounds(key) != null,
      );
      return page.localToGlobal(page.washBounds(key)!.center);
    }

    bool chrome(WidgetTester tester) => tester.widget<PageChrome>(find.byType(PageChrome)).shown;

    int shown(WidgetTester tester) => tester.widget<PageTurner>(find.byType(PageTurner)).page.value;

    Future<void> doubleTapAt(WidgetTester tester, Offset position) async {
      await tester.tapAt(position);
      await tester.pump(kDoubleTapMinTime * 2);
      await tester.tapAt(position);
      await tester.pumpAndSettle();
    }

    /// the page's header, off the words and the strips
    const header = Offset(200, 40);
    const left = Offset(20, 250);
    const right = Offset(373, 250);

    testWidgets('a long press or a double tap on a word opens its ayah with a medium impact', (
      tester,
    ) async {
      await pumpReader(tester);
      final haptics = recordHaptics();

      await tester.longPressAt(ayahAt(tester, 5));
      await tester.pumpAndSettle();
      expect(selected(tester), const AyahKey(1, 5));
      expect(inSheet('Al-Fatiha · Ayah 5'), findsOneWidget);
      expect(haptics, ['HapticFeedbackType.mediumImpact']);

      /// the sheet stays, the selection moves
      await doubleTapAt(tester, ayahAt(tester, 2));
      expect(selected(tester), const AyahKey(1, 2));
      expect(inSheet('Al-Fatiha · Ayah 2'), findsOneWidget);
      expect(haptics, hasLength(2));
      expect(chrome(tester), isFalse);
      await unmount(tester);
    });

    testWidgets('opening the reader at an ayah has no haptic', (tester) async {
      await pumpHome(tester, await designOverrides(), settle: false);
      await tester.pump();
      final haptics = recordHaptics();
      containerOf(tester).read(routerProvider).push(Routes.quranPage(1, ayah: const AyahKey(1, 5)));
      await tester.pumpAndSettle();
      expect(selected(tester), const AyahKey(1, 5));
      expect(haptics, isEmpty);
      await unmount(tester);
    });

    testWidgets('opening at an ayah washes it at once, its sheet rises 500 ms after the open', (
      tester,
    ) async {
      await pumpHome(tester, await designOverrides(), settle: false);
      await tester.pump();
      containerOf(tester).read(routerProvider).push(Routes.quranPage(1, ayah: const AyahKey(1, 5)));
      await tester.pumpAndSettle();
      double sheet() => tester.widget<AyahSheet>(find.byType(AyahSheet)).open.value;
      expect(selected(tester), const AyahKey(1, 5));
      expect(sheet(), 0);

      await tester.pump(BmMotion.ayahSheetWait);
      await tester.pumpAndSettle();
      expect(sheet(), closeTo(1, .01));
      await unmount(tester);
    });

    testWidgets('a tap before the sheet rises drops the wash and shows the controls', (
      tester,
    ) async {
      await pumpHome(tester, await designOverrides(), settle: false);
      await tester.pump();
      containerOf(tester).read(routerProvider).push(Routes.quranPage(1, ayah: const AyahKey(1, 5)));
      await tester.pumpAndSettle();
      await tester.tapAt(tester.getCenter(find.byType(PageTurner)));
      await tester.pump(kDoubleTapTimeout);
      await tester.pumpAndSettle();
      expect(selected(tester), isNull);
      expect(chrome(tester), isTrue);

      await tester.pump(BmMotion.ayahSheetWait);
      await tester.pumpAndSettle();
      expect(tester.widget<AyahSheet>(find.byType(AyahSheet)).open.value, 0);
      await unmount(tester);
    });

    testWidgets('a tap on the words toggles the controls once it is no double tap', (tester) async {
      await pumpReader(tester);
      await tester.tapAt(ayahAt(tester, 5));
      await tester.pump();
      expect(chrome(tester), isFalse, reason: 'it waits for a second tap');
      await tester.pump(kDoubleTapTimeout);
      await tester.pumpAndSettle();
      expect(chrome(tester), isTrue);
      expect(selected(tester), isNull);

      await tester.tapAt(ayahAt(tester, 5));
      await tester.pump(kDoubleTapTimeout);
      await tester.pumpAndSettle();
      expect(chrome(tester), isFalse);
      await unmount(tester);
    });

    testWidgets('a highlighted ayah opens its note, a bookmarked number its ayah sheet', (
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
      await tester.tapAt(ayahAt(tester, 5));
      await tester.pump(kDoubleTapTimeout);
      await tester.pumpAndSettle();
      expect(selected(tester), const AyahKey(1, 5));
      expect(study().tab, StudyTab.notes);
      expect(study().open.value, closeTo(1, .01));
      expect(chrome(tester), isFalse);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(selected(tester), isNull);

      /// beside the number, on the words next to it, still the number's 44 pt
      final page = pageOne(tester);
      final number = page.bookmarkedNumber(const AyahKey(1, 3))!.getBounds().center;
      await tester.tapAt(page.localToGlobal(number + const Offset(16, 0)));
      await tester.pump(kDoubleTapTimeout);
      await tester.pumpAndSettle();
      expect(selected(tester), const AyahKey(1, 3));
      expect(tester.widget<AyahSheet>(find.byType(AyahSheet)).open.value, closeTo(1, .01));
      expect(study().open.value, closeTo(0, .01));
      await unmount(tester);
    });

    testWidgets(
      'the left strip turns to the next page and the right one back, controls shown too',
      (tester) async {
        await pumpAt(tester, 5);
        await tester.tapAt(left);
        await tester.pumpAndSettle();
        expect(shown(tester), 6);
        await tester.tapAt(right);
        await tester.pumpAndSettle();
        expect(shown(tester), 5);

        await tester.tapAt(header);
        await tester.pumpAndSettle();
        expect(chrome(tester), isTrue);
        await tester.tapAt(left);
        await tester.pumpAndSettle();
        expect(shown(tester), 6);
        expect(chrome(tester), isTrue, reason: 'a turn leaves the controls as they are');
        await unmount(tester);
      },
    );

    testWidgets('with a sheet open a tap only closes it, on the strips too', (tester) async {
      await pumpAt(tester, 5);
      await tester.longPressAt(at(tester, const AyahKey(2, 26)));
      await tester.pumpAndSettle();
      expect(selected(tester), const AyahKey(2, 26));

      await tester.tapAt(left);
      await tester.pumpAndSettle();
      expect(selected(tester), isNull);
      expect(shown(tester), 5);

      /// the lifted page has its words under the header now, the tap waits out a double tap
      await tester.longPressAt(at(tester, const AyahKey(2, 26)));
      await tester.pumpAndSettle();
      await tester.tapAt(header);
      await tester.pump(kDoubleTapTimeout);
      await tester.pumpAndSettle();
      expect(selected(tester), isNull);
      expect(chrome(tester), isFalse);
      await unmount(tester);
    });

    group('select mode', () {
      /// Share on the ayah's sheet starts it with the ayah checked
      Future<void> startChoosing(WidgetTester tester, Offset ayah) async {
        await tester.longPressAt(ayah);
        await tester.pumpAndSettle();
        await tester.tap(inSheet('Share'));
        await tester.pumpAndSettle();
      }

      /// the fit check reads the ayah's page off the bundle
      Future<void> settle(WidgetTester tester) async {
        await tester.pump();
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
        await tester.pumpAndSettle();
      }

      /// the mushaf turns right to left, a drag to the right opens the next page
      Future<void> nextPage(WidgetTester tester) async {
        await tester.timedDrag(
          find.byType(PageTurner),
          const Offset(393 * .8, 0),
          const Duration(seconds: 2),
        );
        await tester.pumpAndSettle();
      }

      Set<AyahKey> chosen(WidgetTester tester) =>
          containerOf(tester).read(selectionProvider).chosen;

      testWidgets("the sheet's Share starts it, taps toggle at once, the bar counts", (
        tester,
      ) async {
        await pumpReader(tester);
        await startChoosing(tester, ayahAt(tester, 4));
        expect(chosen(tester), {const AyahKey(1, 4)});
        expect(selected(tester), isNull);
        expect(find.text('Share (1)'), findsOneWidget);

        await tester.tapAt(ayahAt(tester, 5));
        await settle(tester);
        expect(chosen(tester), {const AyahKey(1, 4), const AyahKey(1, 5)});
        expect(find.text('Share (2)'), findsOneWidget);
        expect(selected(tester), isNull);

        await tester.tapAt(ayahAt(tester, 4));
        await tester.pump();
        expect(chosen(tester), {const AyahKey(1, 5)}, reason: 'no wait for a double tap');
        await unmount(tester);
      });

      testWidgets('cancel and back both end it', (tester) async {
        await pumpReader(tester);
        await startChoosing(tester, ayahAt(tester, 4));
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(chosen(tester), isEmpty);
        expect(find.byType(ChoosingBar), findsNothing);

        await startChoosing(tester, ayahAt(tester, 4));
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(chosen(tester), isEmpty);
        expect(
          find.byType(ReaderPage),
          findsOneWidget,
          reason: 'back ended choosing, not the page',
        );
        await unmount(tester);
      });

      testWidgets('turning the page keeps the choices', (tester) async {
        await pumpReader(tester);
        await startChoosing(tester, ayahAt(tester, 4));
        await nextPage(tester);
        expect(chosen(tester), {const AyahKey(1, 4)});
        expect(find.text('Share (1)'), findsOneWidget);

        await tester.tapAt(right);
        await tester.pumpAndSettle();
        expect(shown(tester), 1, reason: 'the strips still turn');
        expect(chosen(tester), {const AyahKey(1, 4)});
        await unmount(tester);
      });

      testWidgets("2:282 alone always starts it, 2:283 doesn't fit beside it", (tester) async {
        await pumpAt(tester, 48);
        await startChoosing(tester, at(tester, const AyahKey(2, 282)));
        expect(chosen(tester), {const AyahKey(2, 282)});

        await nextPage(tester);
        await tester.tapAt(at(tester, const AyahKey(2, 283)));
        await settle(tester);
        expect(chosen(tester), {const AyahKey(2, 282)});
        expect(find.text("This ayah doesn't fit the image"), findsOneWidget);
        await tester.pump(const Duration(seconds: 5));
        await unmount(tester);
      });
    });

    testWidgets('a tap on the header toggles the controls', (tester) async {
      await pumpReader(tester);
      await tester.tapAt(header);
      await tester.pumpAndSettle();
      expect(chrome(tester), isTrue);
      expect(selected(tester), isNull);
      await unmount(tester);
    });

    testWidgets('the page lifts the ayah clear of the sheet and settles back', (tester) async {
      await pumpReader(tester);
      double bottom() {
        final page = pageOne(tester);
        return page.localToGlobal(page.washBounds(const AyahKey(1, 7))!.bottomCenter).dy;
      }

      final rest = bottom();
      await tester.longPressAt(ayahAt(tester, 7));
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
