import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/features/quran/data/quran_store.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late QuranStore store;
  var now = DateTime.utc(2026, 10, 15, 11, 10);

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    now = DateTime.utc(2026, 10, 15, 11, 10);
    store = QuranStore(db, () => now);
  });

  const ayah = AyahKey(1, 3);

  group('bookmarks (US5)', () {
    test('an ayah is bookmarked once and a page once', () async {
      await store.addAyah(ayah, 1);
      await store.addAyah(ayah, 1);
      await store.addPage(1);
      await store.addPage(1);

      final bookmarks = await store.watchBookmarks().first;
      expect(bookmarks.map((bookmark) => (bookmark.ayah, bookmark.page)), [(null, 1), (ayah, 1)]);
      expect(
        bookmarks.map((bookmark) => (bookmark.category, bookmark.color)),
        everyElement((AppDatabase.defaultCategory, CategoryColor.primary)),
      );
    });

    test('newest first', () async {
      await store.addAyah(ayah, 1);
      now = now.add(const Duration(hours: 1));
      await store.addPage(42);

      final bookmarks = await store.watchBookmarks().first;
      expect(bookmarks.map((bookmark) => bookmark.page), [42, 1]);
    });

    test('rename, move and a new category keep the id', () async {
      await store.addAyah(ayah, 1);
      final [before] = await store.watchBookmarks().first;
      final rose = await store.addCategory(' Reflect ', CategoryColor.rose);

      await store.rename(before.id, '  Kursi ');
      await store.setCategory(before.id, rose);
      await store.move(before.id, const AyahKey(2, 255), 42);

      final [after] = await store.watchBookmarks().first;
      expect(
        (after.id, after.name, after.category, after.color, after.ayah, after.page),
        (before.id, 'Kursi', rose, CategoryColor.rose, const AyahKey(2, 255), 42),
      );
    });

    test('an empty name shows the reference again', () async {
      await store.addAyah(ayah, 1);
      final [bookmark] = await store.watchBookmarks().first;
      await store.rename(bookmark.id, 'Reflect');
      await store.rename(bookmark.id, ' ');

      expect((await store.watchBookmarks().first).single.name, isNull);
    });

    test('moving onto a bookmarked ayah replaces that one', () async {
      await store.addAyah(ayah, 1);
      await store.addAyah(const AyahKey(1, 5), 1);
      final [five, three] = await store.watchBookmarks().first;

      await store.move(three.id, const AyahKey(1, 5), 1);

      final [moved] = await store.watchBookmarks().first;
      expect((moved.id, moved.ayah), (three.id, five.ayah));
    });

    test('delete and undo put the same row back', () async {
      await store.addAyah(ayah, 1);
      final [bookmark] = await store.watchBookmarks().first;
      await store.rename(bookmark.id, 'Reflect');
      final [named] = await store.watchBookmarks().first;

      await store.remove(named.id);
      expect(await store.watchBookmarks().first, isEmpty);
      await store.restore(named);

      expect(await store.watchBookmarks().first, [named]);
    });
  });

  group('categories', () {
    test('"Bookmarks" first, a new one after it, trimmed', () async {
      final id = await store.addCategory(' Reflect ', CategoryColor.teal);
      await store.addCategory('Wird', CategoryColor.amber);

      final categories = await store.watchCategories().first;
      expect(categories.map((category) => (category.name, category.color)), [
        (null, CategoryColor.primary),
        ('Reflect', CategoryColor.teal),
        ('Wird', CategoryColor.amber),
      ]);
      expect(categories[1].id, id);
    });

    test('a new category can hold a bookmark straight away', () async {
      final id = await store.addCategory('Reflect', CategoryColor.teal);
      await store.addAyah(ayah, 1, category: id);
      await store.addPage(5, category: id);

      final bookmarks = await store.watchBookmarks().first;
      expect(bookmarks.map((bookmark) => bookmark.category), [id, id]);
    });

    test('rename and recolor, "Bookmarks" too', () async {
      await store.addAyah(ayah, 1);
      await store.updateCategory(AppDatabase.defaultCategory, ' Mine ', CategoryColor.violet);

      final [category] = await store.watchCategories().first;
      expect((category.name, category.color), ('Mine', CategoryColor.violet));
      expect((await store.watchBookmarks().first).single.color, CategoryColor.violet);
    });

    test('deleting a category takes its bookmarks with it', () async {
      final id = await store.addCategory('Reflect', CategoryColor.teal);
      await store.addAyah(ayah, 1, category: id);
      await store.addPage(5);

      await store.deleteCategory(id);

      expect((await store.watchCategories().first).map((category) => category.id), [
        AppDatabase.defaultCategory,
      ]);
      expect((await store.watchBookmarks().first).single.page, 5);
    });
  });

  group('notes (US5)', () {
    test('one note per ayah, trimmed, the last one kept', () async {
      await store.saveNote(ayah, ' first ');
      now = now.add(const Duration(minutes: 5));
      await store.saveNote(ayah, 'Ask for help in everything, then act.');

      final [note] = await store.watchNotes().first;
      expect((note.ayah, note.text), (ayah, 'Ask for help in everything, then act.'));
      expect(note.updatedAt.isAtSameMomentAs(now), isTrue);
    });

    test('a highlight is kept with or without text, and goes when unchecked', () async {
      await store.saveNote(ayah, '  ', highlight: true);
      final [note] = await store.watchNotes().first;
      expect((note.text, note.highlight), ('', true));

      await store.saveNote(ayah, 'patience', highlight: true);
      expect((await store.watchNotes().first).single.text, 'patience');
      await store.saveNote(ayah, 'patience');
      expect((await store.watchNotes().first).single.highlight, isFalse);
    });

    test('no text and no highlight deletes the note', () async {
      await store.saveNote(ayah, 'remember', highlight: true);
      await store.saveNote(ayah, '   ');
      expect(await store.watchNotes().first, isEmpty);
    });

    test('newest first', () async {
      await store.saveNote(ayah, 'one');
      now = now.add(const Duration(minutes: 5));
      await store.saveNote(const AyahKey(2, 255), 'two');

      final notes = await store.watchNotes().first;
      expect(notes.map((note) => note.text), ['two', 'one']);
    });

    test('delete and undo put the same note back', () async {
      await store.saveNote(ayah, 'remember', highlight: true);
      final [note] = await store.watchNotes().first;

      await store.deleteNote(ayah);
      expect(await store.watchNotes().first, isEmpty);
      await store.restoreNote(note);

      expect(await store.watchNotes().first, [note]);
    });
  });

  test('recent searches are newest first, a repeat moves up, only ten stay', () async {
    for (var i = 1; i <= 11; i++) {
      now = now.add(const Duration(minutes: 1));
      await store.saveSearch('q$i');
    }
    now = now.add(const Duration(minutes: 1));
    await store.saveSearch('q5');

    expect(await store.watchSearches().first, [
      'q5',
      'q11',
      'q10',
      'q9',
      'q8',
      'q7',
      'q6',
      'q4',
      'q3',
      'q2',
    ]);
    expect(await db.select(db.quranSearches).get(), hasLength(10));

    await store.removeSearch('q11');
    expect((await store.watchSearches().first).take(2), ['q5', 'q10']);
    await store.clearSearches();
    expect(await store.watchSearches().first, isEmpty);
  });
}
