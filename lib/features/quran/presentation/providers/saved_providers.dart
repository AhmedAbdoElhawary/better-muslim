import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/features/quran/data/quran_store.dart';
import 'package:better_muslim/features/quran/domain/bookmark.dart';
import 'package:better_muslim/features/quran/domain/note.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// newest first
final bookmarksProvider = StreamProvider<List<Bookmark>>(
  (ref) => ref.watch(quranStoreProvider).watchBookmarks(),
);

/// newest first
final notesProvider = StreamProvider<List<Note>>(
  (ref) => ref.watch(quranStoreProvider).watchNotes(),
);

/// a highlight with no text isn't a note to list
final writtenNotesProvider = Provider<List<Note>>(
  (ref) => [...?ref.watch(notesProvider).value?.where((note) => note.text.isNotEmpty)],
);

/// the bookmark menu's, it changes while the menu is open
final bookmarkProvider = Provider.family<Bookmark?, int>(
  (ref, id) => ref.watch(
    bookmarksProvider.select(
      (bookmarks) => bookmarks.value?.where((bookmark) => bookmark.id == id).firstOrNull,
    ),
  ),
);

/// the newest bookmark on the page hangs its ribbon
final pageRibbonProvider = Provider.family<Bookmark?, int>(
  (ref, page) => ref.watch(
    bookmarksProvider.select(
      (bookmarks) => bookmarks.value?.where((bookmark) => bookmark.page == page).firstOrNull,
    ),
  ),
);

final ayahBookmarkProvider = Provider.family<Bookmark?, AyahKey>(
  (ref, ayah) => ref.watch(
    bookmarksProvider.select(
      (bookmarks) => bookmarks.value?.where((bookmark) => bookmark.ayah == ayah).firstOrNull,
    ),
  ),
);

/// the top bar's, the page itself and not one of its ayahs
final pageBookmarkProvider = Provider.family<Bookmark?, int>(
  (ref, page) => ref.watch(
    bookmarksProvider.select(
      (bookmarks) => bookmarks.value
          ?.where((bookmark) => bookmark.ayah == null && bookmark.page == page)
          .firstOrNull,
    ),
  ),
);

final noteProvider = Provider.family<Note?, AyahKey>(
  (ref, ayah) => ref.watch(
    notesProvider.select((notes) => notes.value?.where((note) => note.ayah == ayah).firstOrNull),
  ),
);
