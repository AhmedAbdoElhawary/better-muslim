import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/features/quran/data/quran_store.dart';
import 'package:better_muslim/features/quran/presentation/view/reader_page.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/mushaf_page_view.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/page_chrome.dart';
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
              category: AppDatabase.defaultCategory,
              createdAt: DateTime.utc(2026, 10, 1, 8),
            ),
          );
      final study = await storeOf(tester).addCategory('Study', CategoryColor.rose);
      await db
          .into(db.quranBookmarks)
          .insert(
            QuranBookmarksCompanion.insert(
              surah: const Value(2),
              ayah: const Value(255),
              page: 42,
              name: const Value('Reflect'),
              category: study,
              createdAt: DateTime.utc(2026, 10, 13, 8),
            ),
          );
      await storeOf(tester).saveNote(const AyahKey(1, 5), 'Ask for help in everything, then act.');
      await storeOf(tester).addCategory('Empty', CategoryColor.teal);
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

  testWidgets('bookmarks: last read first marked auto, then mine under their categories', (
    tester,
  ) async {
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
    expect(find.text('Highlights'), findsOneWidget, reason: 'the third tab');
    expect(find.text('Study'), findsOneWidget);
    expect(find.text('Empty'), findsOneWidget, reason: 'its header shows with no bookmarks');

    /// "Bookmarks" is the tab and the default's header
    final header = tester.getTopLeft(find.text('Bookmarks').last).dy;
    expect(topOf(tester, 'Last read'), lessThan(header));
    expect(header, lessThan(topOf(tester, 'Morning wird')));
    expect(topOf(tester, 'Morning wird'), lessThan(topOf(tester, 'Study')));
    expect(topOf(tester, 'Study'), lessThan(topOf(tester, 'Reflect')));
    expect(topOf(tester, 'Reflect'), lessThan(topOf(tester, 'Empty')));
    expect(topOf(tester, 'Empty'), lessThan(topOf(tester, 'New category')));
    final ribbons = tester.widgetList<RibbonShape>(find.byType(RibbonShape));
    expect(ribbons.map((ribbon) => ribbon.color), [
      ThemeEnum.text2,
      ThemeEnum.primary,
      ThemeEnum.categoryRose,
    ]);
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

  testWidgets('long press renames and moves a bookmark here', (tester) async {
    await pumpApp(tester);
    await seed(tester);
    await open(tester, Routes.quranSaved);

    await tester.longPress(find.text('Reflect'));
    await tester.pumpAndSettle();
    for (final text in ['Rename', 'Move here']) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(find.text('Color'), findsNothing, reason: 'the color is the category\'s');

    await tester.enterText(find.byType(TextField), 'Kursi');
    await tapAndStore(tester, find.text('Move here'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();

    expect(find.text('Kursi'), findsOneWidget);
    expect(find.text('Al-Fatiha 1:3 · Page 1'), findsNWidgets(2), reason: 'moved to last read');
    await unmount(tester);
  });

  testWidgets('saved makes a category and its header renames, recolors and deletes it', (
    tester,
  ) async {
    await pumpApp(tester);
    await seed(tester);
    await open(tester, Routes.quranSaved);
    Finder inSheet(Finder finder) =>
        find.descendant(of: find.byType(BottomSheet), matching: finder);

    await tester.ensureVisible(find.text('New category'));
    await tapAndStore(tester, find.text('New category'));
    expect(inSheet(find.text('Delete category')), findsNothing);
    await tester.enterText(inSheet(find.byType(TextField)), 'Night');
    await tapAndStore(tester, inSheet(find.text('Violet')));
    await tapAndStore(tester, inSheet(find.text('Save')));
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Night'), findsOneWidget, reason: 'shows before its first bookmark');

    /// "Bookmarks" is filled in and can't be deleted
    await tapAndStore(tester, find.text('Bookmarks').last);
    expect(inSheet(find.text('Edit category')), findsOneWidget);
    expect(inSheet(find.text('Delete category')), findsNothing);
    await tester.enterText(inSheet(find.byType(TextField)), 'Wird');
    await tapAndStore(tester, inSheet(find.text('Blue')));
    await tapAndStore(tester, inSheet(find.text('Save')));
    expect(find.text('Wird'), findsOneWidget);

    await tapAndStore(tester, find.text('Study'));
    await tapAndStore(tester, inSheet(find.text('Delete category')));
    await tapAndStore(tester, find.text('Delete'));
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Study'), findsNothing);
    expect(find.text('Reflect'), findsNothing, reason: 'its bookmarks went with it');

    final categories = await tester.runAsync(() => storeOf(tester).watchCategories().first);
    expect(categories!.map((category) => (category.name, category.color)), [
      ('Wird', CategoryColor.blue),
      ('Empty', CategoryColor.teal),
      ('Night', CategoryColor.violet),
    ]);
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

  Future<void> selectAyah(WidgetTester tester, AyahKey ayah) async {
    final page = tester.allRenderObjects.whereType<RenderMushafPage>().firstWhere(
      (page) => page.washBounds(ayah) != null,
    );
    await tester.tapAt(page.localToGlobal(page.washBounds(ayah)!.center));
    await tester.pumpAndSettle();
  }

  /// a tap past the spine shows the bars
  Future<void> showChrome(WidgetTester tester) async {
    await tester.tapAt(const Offset(385, 400));
    await tester.pumpAndSettle();
  }

  /// the top bar's, the page itself
  final topBookmark = find.descendant(
    of: find.byType(PageChrome),
    matching: find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.label == 'Bookmark',
    ),
  );

  Finder inPicker(Finder finder) => find.descendant(of: find.byType(BottomSheet), matching: finder);

  testWidgets('bookmark picks a category and hangs the ribbon, remove has undo for 4 s', (
    tester,
  ) async {
    await pumpApp(tester);
    await open(tester, Routes.quranPage(1));
    Finder ribbon() =>
        find.descendant(of: find.byType(PageRibbon), matching: find.byType(RibbonShape));
    expect(ribbon(), findsNothing);

    await selectAyah(tester, const AyahKey(1, 3));
    await tapAndStore(tester, find.text('Bookmark'));
    expect(inPicker(find.text('Al-Fatiha 1:3 · Page 1')), findsOneWidget);
    expect(inPicker(find.text('New category')), findsOneWidget);
    expect(inPicker(find.text('Remove bookmark')), findsNothing);
    await tapAndStore(tester, inPicker(find.text('Bookmarks')));
    expect(find.byType(BottomSheet), findsNothing, reason: 'picking saves and closes');
    expect(ribbon(), findsWidgets);
    expect(tester.widget<RibbonShape>(ribbon().first).color, ThemeEnum.primary);

    await tapAndStore(tester, find.text('Bookmark'));
    final ticked = find.ancestor(
      of: inPicker(find.text('Bookmarks')),
      matching: find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.selected == true,
      ),
    );
    expect(ticked, findsOneWidget, reason: 'its category is ticked');
    await tapAndStore(tester, inPicker(find.text('Remove bookmark')));
    expect(find.text('Bookmark removed'), findsOneWidget);
    expect(ribbon(), findsNothing);
    await tester.pump(const Duration(milliseconds: 3800));
    expect(find.text('Undo'), findsOneWidget, reason: 'undo stays for 4 s');

    await tapAndStore(tester, find.text('Undo'));
    expect(ribbon(), findsWidgets);
    await unmount(tester);
  });

  testWidgets('a bookmarked ayah has its ribbon before its marker in its color, others have none', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.runAsync(() => storeOf(tester).addCategory('Study', CategoryColor.rose));
    await open(tester, Routes.quranPage(1));
    RenderMushafPage page() => tester.allRenderObjects.whereType<RenderMushafPage>().firstWhere(
      (page) => page.washBounds(const AyahKey(1, 3)) != null,
    );
    Future<void> bookmark(AyahKey ayah, String category) async {
      await selectAyah(tester, ayah);
      await tapAndStore(tester, find.text('Bookmark'));
      await tapAndStore(tester, inPicker(find.text(category)));
      await tester.tapAt(const Offset(200, 60));
      await tester.pumpAndSettle();
    }

    expect(page().ribbonRect(const AyahKey(1, 3)), isNull);
    await bookmark(const AyahKey(1, 3), 'Bookmarks');
    await bookmark(const AyahKey(1, 4), 'Study');

    final three = page().ribbonRect(const AyahKey(1, 3))!;
    final four = page().ribbonRect(const AyahKey(1, 4))!;
    expect(page().ribbonRect(const AyahKey(1, 5)), isNull);
    expect(three.overlaps(four), isFalse, reason: 'never on top of each other');
    for (final (key, rect) in [(const AyahKey(1, 3), three), (const AyahKey(1, 4), four)]) {
      final wash = page().washBounds(key)!;
      expect(wash.contains(rect.center), isTrue, reason: 'inside its own ayah, in the line');
      expect(
        page().washBounds(AyahKey(1, key.ayah + 1))!.contains(rect.center),
        isFalse,
        reason: 'before its marker, not past it into the next ayah',
      );
    }
    final context = tester.element(find.byType(MushafPageView).first);
    expect(page().ribbons, {
      const AyahKey(1, 3): context.getColor(ThemeEnum.primary),
      const AyahKey(1, 4): context.getColor(ThemeEnum.categoryRose),
    });

    await selectAyah(tester, const AyahKey(1, 4));
    await tapAndStore(tester, find.text('Bookmark'));
    await tapAndStore(tester, inPicker(find.text('Remove bookmark')));
    expect(page().ribbonRect(const AyahKey(1, 4)), isNull);
    expect(page().ribbonRect(const AyahKey(1, 3)), isNotNull);
    await unmount(tester);
  });

  testWidgets('a new category from the picker takes the bookmark in its color', (tester) async {
    await pumpApp(tester);
    await open(tester, Routes.quranPage(1));
    await selectAyah(tester, const AyahKey(1, 3));
    await tapAndStore(tester, find.text('Bookmark'));

    await tapAndStore(tester, inPicker(find.text('New category')));
    expect(inPicker(find.text('Green')), findsOneWidget);
    expect(inPicker(find.text('Slate')), findsOneWidget);
    await tester.enterText(inPicker(find.byType(TextField)), 'Study');
    await tapAndStore(tester, inPicker(find.text('Teal')));
    await tapAndStore(tester, inPicker(find.text('Save')));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    final ribbon = find.descendant(of: find.byType(PageRibbon), matching: find.byType(RibbonShape));
    expect(tester.widget<RibbonShape>(ribbon.first).color, ThemeEnum.categoryTeal);
    await unmount(tester);
  });

  testWidgets('the top bar bookmarks the page through the same picker', (tester) async {
    await pumpApp(tester);
    await open(tester, Routes.quranPage(5));
    await showChrome(tester);
    await tester.tap(topBookmark);
    await tester.pumpAndSettle();

    expect(inPicker(find.text('Al-Baqarah · Page 5')), findsOneWidget);
    await tapAndStore(tester, inPicker(find.text('Bookmarks')));
    final bookmarks = await tester.runAsync(() => storeOf(tester).watchBookmarks().first);
    expect(bookmarks!.map((bookmark) => (bookmark.ayah, bookmark.page)), [(null, 5)]);
    await unmount(tester);
  });

  testWidgets('a long press in the picker renames, recolors and deletes a category', (
    tester,
  ) async {
    await pumpApp(tester);
    await seed(tester);
    await open(tester, Routes.quranPage(42));
    await showChrome(tester);
    await tester.tap(topBookmark);
    await tester.pumpAndSettle();

    /// "Bookmarks" is filled in and can't be deleted
    await tester.longPress(inPicker(find.text('Bookmarks')));
    await tester.pumpAndSettle();
    expect(inPicker(find.text('Edit category')), findsOneWidget);
    expect(inPicker(find.text('Delete category')), findsNothing);
    await tester.enterText(inPicker(find.byType(TextField)), 'Wird');
    await tapAndStore(tester, inPicker(find.text('Blue')));
    await tapAndStore(tester, inPicker(find.text('Save')));
    expect(inPicker(find.text('Wird')), findsOneWidget, reason: 'back on the list');

    await tester.longPress(inPicker(find.text('Study')));
    await tester.pumpAndSettle();
    await tapAndStore(tester, inPicker(find.text('Delete category')));
    expect(find.text('Delete this category?'), findsOneWidget);
    await tapAndStore(tester, find.text('Delete'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    expect(inPicker(find.text('Study')), findsNothing);

    final (categories, bookmarks) = (await tester.runAsync(
      () async => (
        await storeOf(tester).watchCategories().first,
        await storeOf(tester).watchBookmarks().first,
      ),
    ))!;
    expect(categories.map((category) => (category.name, category.color)), [
      ('Wird', CategoryColor.blue),
      ('Empty', CategoryColor.teal),
    ]);
    expect(bookmarks.map((bookmark) => bookmark.name), ['Morning wird'], reason: 'Reflect went');
    await unmount(tester);
  });

  testWidgets('highlights lists each highlighted ayah, long press takes the highlight off', (
    tester,
  ) async {
    await pumpApp(tester);
    final db = dbOf(tester);
    await tester.runAsync(
      () => db.batch(
        (batch) => batch.insertAll(db.quranNotes, [
          for (final (ayah, note, highlight, hour) in [
            (5, 'patience', true, 8),
            (2, '', true, 9),
            (7, 'not highlighted', false, 10),
          ])
            QuranNotesCompanion.insert(
              surah: 1,
              ayah: ayah,
              note: note,
              highlight: Value(highlight),
              updatedAt: DateTime.utc(2026, 10, 14, hour),
            ),
        ]),
      ),
    );
    await open(tester, Routes.quranSaved);
    await tester.tap(find.text('Highlights'));
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();

    expect(find.text('1:2'), findsOneWidget);
    expect(find.text('1:5'), findsOneWidget);
    expect(find.text('1:7'), findsNothing);
    expect(find.text('patience'), findsOneWidget);
    expect(find.text('Highlighted in mushaf'), findsNothing, reason: 'the ayah shows instead');
    expect(find.textContaining('ٱلۡحَمۡدُ'), findsOneWidget, reason: 'the ayah itself');
    expect(topOf(tester, '1:2'), lessThan(topOf(tester, '1:5')), reason: 'newest first');

    await tester.longPress(find.text('patience'));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    expect(find.text('Highlight removed'), findsOneWidget);
    expect(find.text('1:5'), findsNothing);
    final note = await tester.runAsync(() => storeOf(tester).watchNotes().first);
    expect(
      note!.map((note) => (note.ayah, note.text, note.highlight, note.updatedAt.toUtc().hour)),
      contains((const AyahKey(1, 5), 'patience', false, 8)),
      reason: 'the note text stays, at its place in Notes',
    );

    await tester.tap(find.text('1:2'));
    await tester.pumpAndSettle();
    final reader = tester.widget<ReaderPage>(find.byType(ReaderPage));
    expect((reader.page, reader.ayah), (1, const AyahKey(1, 2)));
    await unmount(tester);
  });

  testWidgets('no highlights shows the empty state', (tester) async {
    await pumpApp(tester);
    await open(tester, Routes.quranSaved);
    await tester.tap(find.text('Highlights'));
    await tester.pumpAndSettle();

    expect(find.text('No highlights yet'), findsOneWidget);
    await unmount(tester);
  });
}
