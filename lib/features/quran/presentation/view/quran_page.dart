import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/quran/last_read.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/compact_app_bar.dart';
import 'package:better_muslim/core/widgets/title_glow.dart';
import 'package:better_muslim/features/quran/presentation/providers/recitation_providers.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/continue_card.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/quran_tile.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/surah_index.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// 4.18 without the khatmah card and memorize, which wait for 7b
class QuranPage extends StatelessWidget {
  const QuranPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: TitleGlow(
        child: LargeTitleScrollView(
          title: StringsManager.tabQuran,
          slivers: [
            SliverToBoxAdapter(child: _Header()),
            SliverToBoxAdapter(
              child: OnlyPadding(
                top: SpaceManager.quranCardGap,
                start: SpaceManager.s4,
                end: SpaceManager.s4,
                child: Column(
                  children: [
                    ContinueCard(),
                    RSizedBox.vertical(SpaceManager.quranCardGap),
                    _Tools(),
                  ],
                ),
              ),
            ),
            SurahIndex(),
            SliverToBoxAdapter(child: RSizedBox.vertical(SpaceManager.s4)),
          ],
        ),
      ),
    );
  }
}

/// the same button row over the title as prayer's, so the tabs' titles line up
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return SafeArea(
      bottom: false,
      child: TopPadding(
        padding: SpaceManager.s1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EndPadding(
              padding: SpaceManager.s2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _HeaderButton(
                    icon: BmIcon.ui(BmUiIcon.search, size: SizeManager.icon.r),
                    label: StringsManager.searchQuran,
                    onTap: () => context.push(Routes.quranSearch),
                  ),
                  _HeaderButton(
                    icon: BmIcon.ui(BmUiIcon.download, size: SizeManager.icon.r),
                    label: StringsManager.downloads,
                    onTap: () => context.push(Routes.downloads),
                  ),
                ],
              ),
            ),
            SymmetricPadding(
              horizontal: SpaceManager.s5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LargeTitle(
                    StringsManager.tabQuran,
                    fontSize: isArabic ? FontSizeManager.titleAr : FontSizeManager.largeTitle,
                    height: isArabic ? LineHeightManager.titleAr : LineHeightManager.largeTitle,
                  ),
                  const RSizedBox.vertical(SpaceManager.quranHeaderGap),
                  const LargeTitleSubtitle(
                    child: RegularText(StringsManager.mushafHafs, color: ThemeEnum.text2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.label, required this.onTap});
  final BmIcon icon;

  /// a StringsManager key for screen readers
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.tr(label),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: RSizedBox.square(
          dimension: SizeManager.hit,
          child: Center(
            child: IconTheme.merge(
              data: IconThemeData(color: context.getColor(ThemeEnum.text)),
              child: icon,
            ),
          ),
        ),
      ),
    );
  }
}

class _Tools extends ConsumerWidget {
  const _Tools();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: QuranTile(
            icon: BmIcon(BmIconName.listen),
            label: StringsManager.listen,
            onTap: () {
              final lastRead = ref.read(lastReadProvider);
              playFrom(context, ref, lastRead.ayah);
              context.push(Routes.quranPage(lastRead.page, recite: true));
            },
          ),
        ),
        const RSizedBox.horizontal(SpaceManager.quranToolGap),
        Expanded(
          child: QuranTile(
            icon: BmIcon(BmIconName.bookmark),
            label: StringsManager.bookmarks,
            onTap: () => context.push(Routes.quranSaved),
          ),
        ),
        const RSizedBox.horizontal(SpaceManager.quranToolGap),
        Expanded(
          child: QuranTile(
            icon: BmIcon.ui(BmUiIcon.note),
            label: StringsManager.notes,
            onTap: () => context.push(Routes.quranNotes),
          ),
        ),
      ],
    );
  }
}
