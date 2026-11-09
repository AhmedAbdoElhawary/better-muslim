import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/widgets/toast/toast.dart';
import 'package:better_muslim/features/quran/data/quran_store.dart';
import 'package:better_muslim/features/quran/domain/bookmark.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// the toast's undo puts the same bookmark back (FR-037)
Future<void> removeBookmark(BuildContext context, WidgetRef ref, Bookmark bookmark) async {
  final store = ref.read(quranStoreProvider);
  final stored = bookmark.storedIn(await ref.read(quranAssetsProvider.future));
  await store.remove(bookmark.id);
  if (!context.mounted) return;
  showToast(
    context,
    StringsManager.bookmarkRemoved,
    icon: BmIconName.bookmark,
    onUndo: () => store.restore(stored),
  );
}
