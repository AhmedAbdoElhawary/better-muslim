import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/last_read.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/bm_switcher.dart';
import 'package:better_muslim/core/widgets/compact_app_bar.dart';
import 'package:better_muslim/core/widgets/empty_state.dart';
import 'package:better_muslim/core/widgets/segmented.dart';
import 'package:better_muslim/core/widgets/surface_card.dart';
import 'package:better_muslim/core/widgets/title_glow.dart';
import 'package:better_muslim/features/quran/domain/bookmark.dart';
import 'package:better_muslim/features/quran/presentation/providers/saved_providers.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/bookmark_menu.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/note_editor.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/ribbon.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/saved_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

enum _Tab {
  bookmarks(StringsManager.bookmarks),
  notes(StringsManager.notes);

  const _Tab(this.label);

  final String label;
}

/// 4.29, bookmarks and notes. highlights and search wait for 7b
class SavedPage extends StatefulWidget {
  const SavedPage({this.notes = false, super.key});

  /// 4.18's Notes tool opens it on its notes
  final bool notes;

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  late var _tab = widget.notes ? _Tab.notes : _Tab.bookmarks;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TitleGlow(
        child: Column(
          children: [
            const CompactAppBar(StringsManager.savedTitle),
            Expanded(
              child: SingleChildScrollView(
                child: SafeArea(
                  top: false,
                  child: SymmetricPadding(
                    horizontal: SpaceManager.s4,
                    vertical: SpaceManager.savedGap,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Segmented(
                          values: _Tab.values,
                          selected: _tab,
                          labelOf: (tab) => tab.label,
                          onChanged: (tab) => setState(() => _tab = tab),
                        ),
                        const RSizedBox.vertical(SpaceManager.s3),
                        BmSwitcher(
                          child: KeyedSubtree(
                            key: ValueKey(_tab),
                            child: switch (_tab) {
                              _Tab.bookmarks => const _Bookmarks(),
                              _Tab.notes => const _Notes(),
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// last read first, then mine newest first, then the recent note
class _Bookmarks extends ConsumerWidget {
  const _Bookmarks();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(bookmarksProvider).value ?? const [];
    final note = ref.watch(writtenNotesProvider.select((notes) => notes.firstOrNull));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _LastReadRow(),
        for (final bookmark in bookmarks) ...[
          const RSizedBox.vertical(SpaceManager.savedGap),
          _BookmarkRow(bookmark, key: ValueKey(bookmark.id)),
        ],
        if (bookmarks.isEmpty) ...[
          const RSizedBox.vertical(SpaceManager.savedGap),
          const EmptyState(title: StringsManager.noBookmarks, body: StringsManager.noBookmarksBody),
        ],
        if (note != null) ...[
          const RSizedBox.vertical(SpaceManager.recentNoteTop),
          const StartPadding(
            padding: SpaceManager.s1,
            child: RegularText(
              StringsManager.recentNote,
              fontSize: FontSizeManager.sectionLabel,
              letterSpacing: LetterSpacingManager.sectionLabel,
              color: ThemeEnum.text3,
            ),
          ),
          const RSizedBox.vertical(SpaceManager.sectionLabelGap),
          NoteCard(note, onTap: () => _open(context, ref, note.ayah)),
        ],
      ],
    );
  }
}

class _LastReadRow extends ConsumerWidget {
  const _LastReadRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastRead = ref.watch(lastReadProvider);
    final assets = ref.watch(quranAssetsProvider).value;
    if (assets == null) return const SizedBox.shrink();
    final at = lastRead.at;
    return _SavedRow(
      ribbon: ThemeEnum.text2,
      title: context.tr(StringsManager.lastRead),
      auto: true,
      reference: savedReference(context, ref, assets, ayah: lastRead.ayah, page: lastRead.page),
      when: at == null ? null : savedWhen(context, ref, at),
      onTap: () => context.push(Routes.quranPage(lastRead.page, ayah: lastRead.ayah)),
    );
  }
}

class _BookmarkRow extends ConsumerWidget {
  const _BookmarkRow(this.bookmark, {super.key});

  final Bookmark bookmark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(quranAssetsProvider).value;
    if (assets == null) return const SizedBox.shrink();
    final (ayah, page) = (bookmark.ayah, bookmark.page);
    return _SavedRow(
      ribbon: bookmark.color.theme,
      title: bookmark.name ?? savedSurahName(context, assets, ayah: ayah, page: page),
      reference: savedReference(context, ref, assets, ayah: ayah, page: page),
      when: savedWhen(context, ref, bookmark.createdAt),
      onTap: () => context.push(Routes.quranPage(page, ayah: ayah)),
      onLongPress: () => showBookmarkMenu(context, bookmark),
    );
  }
}

/// K.card's 68 pt row of 4.29: the ribbon, the name over its place, the date at the end
class _SavedRow extends StatelessWidget {
  const _SavedRow({
    required this.ribbon,
    required this.title,
    required this.reference,
    required this.when,
    required this.onTap,
    this.auto = false,
    this.onLongPress,
  });

  final ThemeEnum ribbon;

  /// already in the app's language, a name I gave or a surah's
  final String title;
  final String reference;
  final String? when;
  final bool auto;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final when = this.when;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: SurfaceCard(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: SizeManager.savedRow.r),
            child: OnlyPadding(
              start: SpaceManager.savedRowStart,
              end: SpaceManager.savedRowEnd,
              top: SpaceManager.s2,
              bottom: SpaceManager.s2,
              child: Row(
                children: [
                  RibbonShape(
                    color: ribbon,
                    width: SizeManager.savedRibbonW,
                    height: SizeManager.savedRibbonH,
                    notch: SizeManager.savedRibbonNotch,
                  ),
                  const RSizedBox.horizontal(SpaceManager.savedRibbonGap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: SpaceManager.s1.r,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            MediumText(
                              title,
                              translate: false,
                              fontSize: FontSizeManager.surahName,
                            ),
                            if (auto)
                              RegularText(
                                StringsManager.auto,
                                fontSize: FontSizeManager.quranTag,
                                letterSpacing: isArabic ? null : LetterSpacingManager.autoTag,
                                color: ThemeEnum.text3,
                              ),
                          ],
                        ),
                        const RSizedBox.vertical(SpaceManager.savedLineGap),
                        RegularText(
                          reference,
                          translate: false,
                          fontSize: FontSizeManager.rowSubtitle,
                          color: ThemeEnum.text2,
                        ),
                      ],
                    ),
                  ),
                  if (when != null) ...[
                    const RSizedBox.horizontal(SpaceManager.s3),
                    RegularText(
                      when,
                      translate: false,
                      fontSize: FontSizeManager.rowSubtitle,
                      color: ThemeEnum.text3,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Notes extends ConsumerWidget {
  const _Notes();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(writtenNotesProvider);
    if (notes.isEmpty) {
      return const EmptyState(title: StringsManager.noNotes, body: StringsManager.noNotesBody);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, note) in notes.indexed) ...[
          if (i > 0) const RSizedBox.vertical(SpaceManager.savedGap),
          NoteCard(note, key: ValueKey(note.ayah), onTap: () => _open(context, ref, note.ayah)),
        ],
      ],
    );
  }
}

/// a note opens its ayah washed on its page
void _open(BuildContext context, WidgetRef ref, AyahKey ayah) {
  final assets = ref.read(quranAssetsProvider).value;
  if (assets != null) context.push(Routes.quranPage(assets.pageOf(ayah), ayah: ayah));
}
