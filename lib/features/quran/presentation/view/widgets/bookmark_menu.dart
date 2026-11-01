import 'package:better_muslim/core/quran/last_read.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/bm_button.dart';
import 'package:better_muslim/core/widgets/sheet/bm_sheet.dart';
import 'package:better_muslim/core/widgets/sheet/sheet_title.dart';
import 'package:better_muslim/core/widgets/text_field.dart';
import 'package:better_muslim/features/quran/data/quran_store.dart';
import 'package:better_muslim/features/quran/domain/bookmark.dart';
import 'package:better_muslim/features/quran/presentation/providers/saved_providers.dart';
import 'package:better_muslim/features/quran/presentation/view/bookmark_actions.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/saved_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the long press on a bookmark: rename it or move it to where I am (FR-039)
Future<void> showBookmarkMenu(BuildContext context, Bookmark bookmark) =>
    showBmSheet(context, builder: (_) => _BookmarkMenu(bookmark.id));

class _BookmarkMenu extends ConsumerStatefulWidget {
  const _BookmarkMenu(this.id);

  final int id;

  @override
  ConsumerState<_BookmarkMenu> createState() => _BookmarkMenuState();
}

class _BookmarkMenuState extends ConsumerState<_BookmarkMenu> {
  /// read here, dispose can't reach ref
  late final QuranStore _store;
  late final String _name;
  late String _typed;

  @override
  void initState() {
    super.initState();
    _store = ref.read(quranStoreProvider);
    _name = ref.read(bookmarkProvider(widget.id))?.name ?? '';
    _typed = _name;
  }

  /// the name is kept when the sheet closes, however it closes
  @override
  void dispose() {
    if (_typed.trim() != _name) _store.rename(widget.id, _typed);
    super.dispose();
  }

  Future<void> _moveHere() async {
    final ayah = ref.read(lastReadProvider).ayah;
    final page = (await ref.read(quranAssetsProvider.future)).pageOf(ayah);
    await _store.move(widget.id, ayah, page);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _remove(Bookmark bookmark) async {
    await removeBookmark(context, ref, bookmark);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bookmark = ref.watch(bookmarkProvider(widget.id));
    final assets = ref.watch(quranAssetsProvider).value;
    if (bookmark == null || assets == null) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: BottomPadding(
          padding: SpaceManager.s6,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetTitle(
                savedReference(context, ref, assets, ayah: bookmark.ayah, page: bookmark.page),
                translate: false,
              ),
              HorizontalPadding(
                padding: SpaceManager.s5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BmTextField(
                      label: StringsManager.rename,
                      hint: StringsManager.bookmarkName,
                      initial: bookmark.name,
                      textInputAction: TextInputAction.done,
                      onChanged: (name) => _typed = name,
                    ),
                    const RSizedBox.vertical(SpaceManager.s6),
                    BmButton.secondary(StringsManager.moveHere, onPressed: _moveHere),
                    const RSizedBox.vertical(SpaceManager.s2),
                    BmButton.text(
                      StringsManager.removeBookmark,
                      color: ThemeEnum.error,
                      onPressed: () => _remove(bookmark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
