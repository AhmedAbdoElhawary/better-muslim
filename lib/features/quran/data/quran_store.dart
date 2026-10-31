import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/features/quran/domain/bookmark.dart';
import 'package:better_muslim/features/quran/domain/category.dart';
import 'package:better_muslim/features/quran/domain/note.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final quranStoreProvider = Provider<QuranStore>(
  (ref) => QuranStore(ref.watch(databaseProvider), ref.watch(clockProvider)),
);

/// the bookmarks, their categories and the notes, kept only in the encrypted store (FR-048)
class QuranStore {
  const QuranStore(this._db, this._clock);

  final AppDatabase _db;
  final DateTime Function() _clock;

  $QuranBookmarksTable get _bookmarks => _db.quranBookmarks;
  $QuranCategoriesTable get _categories => _db.quranCategories;
  $QuranNotesTable get _notes => _db.quranNotes;
  $QuranSearchesTable get _searches => _db.quranSearches;

  static const _searchesKept = 10;

  /// newest first, each with its category's color
  Stream<List<Bookmark>> watchBookmarks() {
    final query = _db.select(_bookmarks).join([
      innerJoin(_categories, _categories.id.equalsExp(_bookmarks.category)),
    ])..orderBy([OrderingTerm.desc(_bookmarks.createdAt), OrderingTerm.desc(_bookmarks.id)]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          _bookmark(row.readTable(_bookmarks), row.readTable(_categories).color),
      ],
    );
  }

  /// an ayah or a page is bookmarked once, a second add changes nothing
  Future<void> addAyah(AyahKey ayah, int page, {int category = AppDatabase.defaultCategory}) => _db
      .into(_bookmarks)
      .insert(
        QuranBookmarksCompanion.insert(
          surah: Value(ayah.surah),
          ayah: Value(ayah.ayah),
          page: page,
          category: category,
          createdAt: _clock(),
        ),
        mode: InsertMode.insertOrIgnore,
      );

  Future<void> addPage(int page, {int category = AppDatabase.defaultCategory}) => _db
      .into(_bookmarks)
      .insert(
        QuranBookmarksCompanion.insert(page: page, category: category, createdAt: _clock()),
        mode: InsertMode.insertOrIgnore,
      );

  Future<void> remove(int id) => (_db.delete(_bookmarks)..where((row) => row.id.equals(id))).go();

  /// the toast's undo, the same row with its id back
  Future<void> restore(Bookmark bookmark) => _db
      .into(_bookmarks)
      .insert(
        QuranBookmarksCompanion.insert(
          id: Value(bookmark.id),
          surah: Value(bookmark.ayah?.surah),
          ayah: Value(bookmark.ayah?.ayah),
          page: bookmark.page,
          name: Value(bookmark.name),
          category: bookmark.category,
          createdAt: bookmark.createdAt,
        ),
        mode: InsertMode.insertOrIgnore,
      );

  /// an empty name shows the reference again
  Future<void> rename(int id, String name) =>
      _update(id, QuranBookmarksCompanion(name: Value(name.trim().isEmpty ? null : name.trim())));

  Future<void> setCategory(int id, int category) =>
      _update(id, QuranBookmarksCompanion(category: Value(category)));

  /// a bookmark already on that ayah gives way, an ayah is bookmarked once
  Future<void> move(int id, AyahKey ayah, int page) => _db.transaction(() async {
    await (_db.delete(_bookmarks)..where(
          (row) =>
              row.surah.equals(ayah.surah) & row.ayah.equals(ayah.ayah) & row.id.equals(id).not(),
        ))
        .go();
    await _update(
      id,
      QuranBookmarksCompanion(surah: Value(ayah.surah), ayah: Value(ayah.ayah), page: Value(page)),
    );
  });

  Future<void> _update(int id, QuranBookmarksCompanion changes) =>
      (_db.update(_bookmarks)..where((row) => row.id.equals(id))).write(changes);

  /// in the order they were made, "Bookmarks" first
  Stream<List<Category>> watchCategories() {
    final query = _db.select(_categories)
      ..orderBy([(row) => OrderingTerm.asc(row.position), (row) => OrderingTerm.asc(row.id)]);
    return query.watch().map(
      (rows) => [for (final row in rows) Category(id: row.id, name: row.name, color: row.color)],
    );
  }

  /// after the last one, the new id back so a bookmark can go in it
  Future<int> addCategory(String name, CategoryColor color) => _db.transaction(() async {
    final last = await (_db.selectOnly(_categories)..addColumns([_categories.position.max()]))
        .map((row) => row.read(_categories.position.max()))
        .getSingle();
    return _db
        .into(_categories)
        .insert(
          QuranCategoriesCompanion.insert(
            name: Value(name.trim()),
            color: color,
            position: (last ?? 0) + 1,
          ),
        );
  });

  /// null names the default "Bookmarks" again
  Future<void> updateCategory(int id, String? name, CategoryColor color) =>
      (_db.update(_categories)..where((row) => row.id.equals(id))).write(
        QuranCategoriesCompanion(name: Value(name?.trim()), color: Value(color)),
      );

  Future<void> deleteCategory(int id) => _db.transaction(() async {
    await (_db.delete(_bookmarks)..where((row) => row.category.equals(id))).go();
    await (_db.delete(_categories)..where((row) => row.id.equals(id))).go();
  });

  /// newest first
  Stream<List<Note>> watchNotes() {
    final query = _db.select(_notes)..orderBy([(row) => OrderingTerm.desc(row.updatedAt)]);
    return query.watch().map((rows) => rows.map(_note).toList());
  }

  /// trimmed, no text and no highlight leaves nothing to keep
  Future<void> saveNote(AyahKey ayah, String text, {bool highlight = false}) {
    if (text.trim().isEmpty && !highlight) return deleteNote(ayah);
    return _db
        .into(_notes)
        .insertOnConflictUpdate(
          QuranNotesCompanion.insert(
            surah: ayah.surah,
            ayah: ayah.ayah,
            note: text.trim(),
            highlight: Value(highlight),
            updatedAt: _clock(),
          ),
        );
  }

  Future<void> deleteNote(AyahKey ayah) => (_db.delete(
    _notes,
  )..where((row) => row.surah.equals(ayah.surah) & row.ayah.equals(ayah.ayah))).go();

  /// the toast's undo, with the time it had
  Future<void> restoreNote(Note note) => _db
      .into(_notes)
      .insertOnConflictUpdate(
        QuranNotesCompanion.insert(
          surah: note.ayah.surah,
          ayah: note.ayah.ayah,
          note: note.text,
          highlight: Value(note.highlight),
          updatedAt: note.updatedAt,
        ),
      );

  /// newest first
  Stream<List<String>> watchSearches() {
    final query = _db.select(_searches)
      ..orderBy([(row) => OrderingTerm.desc(row.searchedAt)])
      ..limit(_searchesKept);
    return query.watch().map((rows) => [for (final row in rows) row.query]);
  }

  /// a search made again moves to the top, the oldest past ten goes
  Future<void> saveSearch(String query) => _db.transaction(() async {
    await _db
        .into(_searches)
        .insertOnConflictUpdate(QuranSearchesCompanion.insert(query: query, searchedAt: _clock()));
    final kept = _db.selectOnly(_searches)
      ..addColumns([_searches.query])
      ..orderBy([OrderingTerm.desc(_searches.searchedAt)])
      ..limit(_searchesKept);
    await (_db.delete(_searches)..where((row) => row.query.isNotInQuery(kept))).go();
  });

  Future<void> removeSearch(String query) =>
      (_db.delete(_searches)..where((row) => row.query.equals(query))).go();

  Future<void> clearSearches() => _db.delete(_searches).go();

  static Bookmark _bookmark(QuranBookmark row, CategoryColor color) => Bookmark(
    id: row.id,
    ayah: row.surah == null ? null : AyahKey(row.surah!, row.ayah!),
    page: row.page,
    name: row.name,
    category: row.category,
    color: color,
    createdAt: row.createdAt,
  );

  static Note _note(QuranNote row) => Note(
    ayah: AyahKey(row.surah, row.ayah),
    text: row.note,
    highlight: row.highlight,
    updatedAt: row.updatedAt,
  );
}
