import 'package:better_muslim/core/backup/backup_file.dart';
import 'package:better_muslim/core/backup/restore.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/features/quran/data/quran_store.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/backup.dart';
import '../../../helpers/phone_storage.dart';

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
      expect(bookmarks.map((bookmark) => bookmark.color), everyElement(RibbonColor.primary));
    });

    test('newest first', () async {
      await store.addAyah(ayah, 1);
      now = now.add(const Duration(hours: 1));
      await store.addPage(42);

      final bookmarks = await store.watchBookmarks().first;
      expect(bookmarks.map((bookmark) => bookmark.page), [42, 1]);
    });

    test('rename, recolor and move keep the id', () async {
      await store.addAyah(ayah, 1);
      final [before] = await store.watchBookmarks().first;

      await store.rename(before.id, '  Reflect ');
      await store.recolor(before.id, RibbonColor.accent);
      await store.move(before.id, const AyahKey(2, 255), 42);

      final [after] = await store.watchBookmarks().first;
      expect(
        (after.id, after.name, after.color, after.ayah, after.page),
        (before.id, 'Reflect', RibbonColor.accent, const AyahKey(2, 255), 42),
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

  test('a backup and restore carries both tables (SC-006)', () async {
    usePhoneStorage();
    final from = await seededStore();
    addTearDown(from.close);
    final file = await writeBackup(from, 'test1234', now: DateTime(2026, 10, 20));
    final (backup, _) = await readBackup(file, 'test1234', schemaVersion: from.schemaVersion);

    await restore(db, backup!);
    await closeBackup(backup);

    final [bookmark] = await store.watchBookmarks().first;
    expect(
      (bookmark.ayah, bookmark.page, bookmark.color),
      (const AyahKey(2, 255), 42, RibbonColor.accent),
    );
    final [note] = await store.watchNotes().first;
    expect(
      (note.ayah, note.text, note.highlight),
      (const AyahKey(1, 5), 'remember this one', true),
    );
  });
}
