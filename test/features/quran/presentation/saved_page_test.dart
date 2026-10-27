import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/features/quran/data/quran_store.dart';
import 'package:better_muslim/features/quran/presentation/view/reader_page.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/mushaf_page_view.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/ribbon.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
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

  Future<void> pumpApp(WidgetTester tester) async {
    await pumpHome(tester, await designOverrides(), settle: false);
    await tester.pump();
  }

  Future<void> open(WidgetTester tester, String route) async {
    containerOf(tester).read(routerProvider).push(route);
    await tester.pumpAndSettle();
  }

  QuranStore storeOf(WidgetTester tester) => containerOf(tester).read(quranStoreProvider);

  /// the scenario's "today" is thu 15 oct, so these show as a weekday and a date
  Future<void> seed(WidgetTester tester) async {
    final db = dbOf(tester);
    await tester.runAsync(() async {
      await db
          .into(db.quranBookmarks)
          .insert(
            QuranBookmarksCompanion.insert(
              page: 582,
              name: const Value('Morning wird'),
              color: RibbonColor.primary,
              createdAt: DateTime.utc(2026, 10, 1, 8),
            ),
          );
      await db
          .into(db.quranBookmarks)
          .insert(
            QuranBookmarksCompanion.insert(
              surah: const Value(2),
              ayah: const Value(255),
              page: 42,
              name: const Value('Reflect'),
              color: RibbonColor.accent,
              createdAt: DateTime.utc(2026, 10, 13, 8),
            ),
          );
      await storeOf(tester).saveNote(const AyahKey(1, 5), 'Ask for help in everything, then act.');
    });
    await tester.pumpAndSettle();
  }

  /// the store writes on a real clock, the test's fake one never lets them finish
  Future<void> tapAndStore(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
  }

  double topOf(WidgetTester tester, String text) => tester.getTopLeft(find.text(text).first).dy;

  testWidgets('bookmarks: last read first marked auto, then mine newest first', (tester) async {
    await pumpApp(tester);
    await seed(tester);
    await open(tester, Routes.quranSaved);

    for (final text in [
      'Saved',
      'Last read',
      'AUTO',
      'Al-Fatiha 1:3 · Page 1',
      'Today 14:10',
      'Reflect',
      'Al-Baqarah 2:255 · Page 42',
      'Tue',
      'Morning wird',
      "An-Naba' · Page 582",
      '1 Oct',
      'RECENT NOTE',
      'Ask for help in everything, then act.',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(topOf(tester, 'Last read'), lessThan(topOf(tester, 'Reflect')));
    expect(topOf(tester, 'Reflect'), lessThan(topOf(tester, 'Morning wird')));
    expect(find.text('Highlights'), findsNothing);
    await unmount(tester);
  });

  testWidgets('notes lists my notes and opens the ayah washed', (tester) async {
    await pumpApp(tester);
    await seed(tester);
    await open(tester, Routes.quranNotes);

    expect(find.text('1:5'), findsOneWidget);
    expect(find.text('Ask for help in everything, then act.'), findsOneWidget);

    await tester.tap(find.text('Ask for help in everything, then act.'));
    await tester.pumpAndSettle();
    final reader = tester.widget<ReaderPage>(find.byType(ReaderPage));
    expect((reader.page, reader.ayah), (1, const AyahKey(1, 5)));
    await unmount(tester);
  });

  testWidgets('a bookmark row opens its page with the ayah washed', (tester) async {
    await pumpApp(tester);
    await seed(tester);
    await open(tester, Routes.quranSaved);

    await tester.tap(find.text('Reflect'));
    await tester.pumpAndSettle();
    final reader = tester.widget<ReaderPage>(find.byType(ReaderPage));
    expect((reader.page, reader.ayah), (42, const AyahKey(2, 255)));
    await unmount(tester);
  });

  testWidgets('long press renames, recolors and moves a bookmark here', (tester) async {
    await pumpApp(tester);
    await seed(tester);
    await open(tester, Routes.quranSaved);

    await tester.longPress(find.text('Reflect'));
    await tester.pumpAndSettle();
    for (final text in ['Rename', 'Color', 'Main', 'Accent', 'Neutral', 'Move here']) {
      expect(find.text(text), findsOneWidget, reason: text);
    }

    await tester.enterText(find.byType(TextField), 'Kursi');
    await tapAndStore(tester, find.text('Neutral'));
    await tapAndStore(tester, find.text('Move here'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();

    expect(find.text('Kursi'), findsOneWidget);
    expect(find.text('Al-Fatiha 1:3 · Page 1'), findsNWidgets(2), reason: 'moved to last read');
    final ribbons = tester.widgetList<RibbonShape>(find.byType(RibbonShape));
    expect(ribbons.map((ribbon) => ribbon.color), contains(ThemeEnum.text2));
    await unmount(tester);
  });

  testWidgets('nothing saved shows the empty state under last read', (tester) async {
    await pumpApp(tester);
    await open(tester, Routes.quranSaved);

    expect(find.text('Last read'), findsOneWidget);
    expect(find.text('No bookmarks yet'), findsOneWidget);
    expect(find.text('Tap Bookmark on any ayah to keep your place.'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('bookmark hangs the ribbon, again removes it with undo for 4 s', (tester) async {
    await pumpApp(tester);
    await open(tester, Routes.quranPage(1));
    Finder ribbon() =>
        find.descendant(of: find.byType(PageRibbon), matching: find.byType(RibbonShape));
    expect(ribbon(), findsNothing);

    final page = tester.allRenderObjects.whereType<RenderMushafPage>().firstWhere(
      (page) => page.washBounds(const AyahKey(1, 3)) != null,
    );
    await tester.tapAt(page.localToGlobal(page.washBounds(const AyahKey(1, 3))!.center));
    await tester.pumpAndSettle();
    await tapAndStore(tester, find.text('Bookmark'));
    expect(ribbon(), findsWidgets);
    expect(tester.widget<RibbonShape>(ribbon().first).color, ThemeEnum.primary);

    await tapAndStore(tester, find.text('Bookmark'));
    expect(find.text('Bookmark removed'), findsOneWidget);
    expect(ribbon(), findsNothing);
    await tester.pump(const Duration(milliseconds: 3800));
    expect(find.text('Undo'), findsOneWidget, reason: 'undo stays for 4 s');

    await tapAndStore(tester, find.text('Undo'));
    expect(ribbon(), findsWidgets);
    await unmount(tester);
  });
}
