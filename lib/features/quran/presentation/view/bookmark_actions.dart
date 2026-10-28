import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/widgets/toast/toast.dart';
import 'package:better_muslim/features/quran/data/quran_store.dart';
import 'package:better_muslim/features/quran/domain/bookmark.dart';
import 'package:better_muslim/features/quran/presentation/providers/saved_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// the ayah sheet's Bookmark: saves the ayah, or removes it with undo (FR-037)
Future<void> toggleAyahBookmark(BuildContext context, WidgetRef ref, AyahKey ayah) async {
  if (ref.read(ayahBookmarkProvider(ayah)) case final bookmark?) {
    return removeBookmark(context, ref, bookmark);
  }
  final page = (await ref.read(quranAssetsProvider.future)).pageOf(ayah);
  BmHaptics.selection();
  await ref.read(quranStoreProvider).addAyah(ayah, page);
}

/// the top bar's bookmark, the page and not one of its ayahs
Future<void> togglePageBookmark(BuildContext context, WidgetRef ref, int page) async {
  if (ref.read(pageBookmarkProvider(page)) case final bookmark?) {
    return removeBookmark(context, ref, bookmark);
  }
  BmHaptics.selection();
  await ref.read(quranStoreProvider).addPage(page);
}

Future<void> removeBookmark(BuildContext context, WidgetRef ref, Bookmark bookmark) async {
  final store = ref.read(quranStoreProvider);
  await store.remove(bookmark.id);
  if (!context.mounted) return;
  showToast(
    context,
    StringsManager.bookmarkRemoved,
    icon: BmIconName.bookmark,
    onUndo: () => store.restore(bookmark),
  );
}
