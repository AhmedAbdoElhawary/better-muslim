import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/features/quran/domain/bookmark.dart';
import 'package:better_muslim/features/quran/domain/note.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final quranStoreProvider = Provider<QuranStore>(
  (ref) => QuranStore(ref.watch(databaseProvider), ref.watch(clockProvider)),
);

/// the bookmarks and notes, kept only in the encrypted store (FR-048)
class QuranStore {
  const QuranStore(this._db, this._clock);

  final AppDatabase _db;
  final DateTime Function() _clock;

  $QuranBookmarksTable get _bookmarks => _db.quranBookmarks;
  $QuranNotesTable get _notes => _db.quranNotes;

  /// newest first
  Stream<List<Bookmark>> watchBookmarks() {
    final query = _db.select(_bookmarks)
      ..orderBy([(row) => OrderingTerm.desc(row.createdAt), (row) => OrderingTerm.desc(row.id)]);
    return query.watch().map((rows) => rows.map(_bookmark).toList());
  }

  /// an ayah or a page is bookmarked once, a second add changes nothing
  Future<void> addAyah(AyahKey ayah, int page) => _db
      .into(_bookmarks)
      .insert(
        QuranBookmarksCompanion.insert(
          surah: Value(ayah.surah),
          ayah: Value(ayah.ayah),
          page: page,
          color: RibbonColor.primary,
          createdAt: _clock(),
        ),
        mode: InsertMode.insertOrIgnore,
      );

  Future<void> addPage(int page) => _db
      .into(_bookmarks)
      .insert(
        QuranBookmarksCompanion.insert(page: page, color: RibbonColor.primary, createdAt: _clock()),
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
          color: bookmark.color,
          createdAt: bookmark.createdAt,
        ),
        mode: InsertMode.insertOrIgnore,
      );

  /// an empty name shows the reference again
  Future<void> rename(int id, String name) =>
      _update(id, QuranBookmarksCompanion(name: Value(name.trim().isEmpty ? null : name.trim())));

  Future<void> recolor(int id, RibbonColor color) =>
      _update(id, QuranBookmarksCompanion(color: Value(color)));

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

  /// newest first
  Stream<List<Note>> watchNotes() {
    final query = _db.select(_notes)..orderBy([(row) => OrderingTerm.desc(row.updatedAt)]);
    return query.watch().map((rows) => rows.map(_note).toList());
  }

  /// trimmed, the store refuses an empty one
  Future<void> saveNote(AyahKey ayah, String text) => _db
      .into(_notes)
      .insertOnConflictUpdate(
        QuranNotesCompanion.insert(
          surah: ayah.surah,
          ayah: ayah.ayah,
          note: text.trim(),
          updatedAt: _clock(),
        ),
      );

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
          updatedAt: note.updatedAt,
        ),
      );

  static Bookmark _bookmark(QuranBookmark row) => Bookmark(
    id: row.id,
    ayah: row.surah == null ? null : AyahKey(row.surah!, row.ayah!),
    page: row.page,
    name: row.name,
    color: row.color,
    createdAt: row.createdAt,
  );

  static Note _note(QuranNote row) =>
      Note(ayah: AyahKey(row.surah, row.ayah), text: row.note, updatedAt: row.updatedAt);
}
