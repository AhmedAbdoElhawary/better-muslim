import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/features/quran/data/quran_store.dart';
import 'package:better_muslim/features/quran/domain/bookmark.dart';
import 'package:better_muslim/features/quran/domain/category.dart';
import 'package:better_muslim/features/quran/domain/note.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// newest first, on their pages in the print shown
final bookmarksProvider = StreamProvider<List<Bookmark>>((ref) {
  final v1 = ref.watch(
    quranAssetsProvider.select(
      (assets) => switch (assets.value) {
        final assets? when assets != assets.stored => assets,
        _ => null,
      },
    ),
  );
  final bookmarks = ref.watch(quranStoreProvider).watchBookmarks();
  return v1 == null
      ? bookmarks
      : bookmarks.map((bookmarks) => [for (final bookmark in bookmarks) bookmark.shownIn(v1)]);
});

/// "Bookmarks" first, then in the order I made them
final categoriesProvider = StreamProvider<List<Category>>(
  (ref) => ref.watch(quranStoreProvider).watchCategories(),
);

/// most bookmarks first, a tie keeps the order they were made in. Saved and the picker
final categoriesByCountProvider = Provider<List<Category>>((ref) {
  final categories = ref.watch(categoriesProvider).value ?? const <Category>[];
  final bookmarks = ref.watch(bookmarksProvider).value ?? const <Bookmark>[];
  final counts = <int, int>{};
  for (final bookmark in bookmarks) {
    counts.update(bookmark.category, (count) => count + 1, ifAbsent: () => 1);
  }
  final order = {for (final (i, category) in categories.indexed) category.id: i};
  return [...categories]..sort((a, b) {
    final more = (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0);
    return more != 0 ? more : order[a.id]!.compareTo(order[b.id]!);
  });
});

/// one category's bookmarks, newest first
final categoryBookmarksProvider = Provider.family<List<Bookmark>, int>(
  (ref, category) => [
    for (final bookmark in ref.watch(bookmarksProvider).value ?? const <Bookmark>[])
      if (bookmark.category == category) bookmark,
  ],
);

/// newest first
final notesProvider = StreamProvider<List<Note>>(
  (ref) => ref.watch(quranStoreProvider).watchNotes(),
);

/// newest first, the search page's recent list
final searchesProvider = StreamProvider<List<String>>(
  (ref) => ref.watch(quranStoreProvider).watchSearches(),
);

/// a highlight with no text isn't a note to list
final writtenNotesProvider = Provider<List<Note>>(
  (ref) => [...?ref.watch(notesProvider).value?.where((note) => note.text.isNotEmpty)],
);

/// newest first, like the notes
final highlightsProvider = Provider<List<Note>>(
  (ref) => [...?ref.watch(notesProvider).value?.where((note) => note.highlight)],
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
