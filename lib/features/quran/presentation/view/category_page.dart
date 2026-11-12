import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/widgets/compact_app_bar.dart';
import 'package:better_muslim/core/widgets/title_glow.dart';
import 'package:better_muslim/features/quran/presentation/providers/saved_providers.dart';
import 'package:better_muslim/features/quran/presentation/view/saved_page.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/saved_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Saved's See all: every bookmark of one category, newest first
class CategoryPage extends ConsumerWidget {
  const CategoryPage(this.id, {super.key});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(
      categoriesProvider.select(
        (categories) => categories.value?.where((category) => category.id == id).firstOrNull,
      ),
    );
    final bookmarks = ref.watch(categoryBookmarksProvider(id));

    /// the last one removed or the category deleted, nothing is left to show
    ref.listen(categoryBookmarksProvider(id).select((bookmarks) => bookmarks.isEmpty), (_, empty) {
      if (empty && context.canPop()) context.pop();
    });
    return Scaffold(
      body: TitleGlow(
        child: Column(
          children: [
            CompactAppBar(
              category == null ? '' : categoryName(context, category),
              translate: false,
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverSafeArea(
                    top: false,
                    sliver: SliverPadding(
                      padding: REdgeInsets.symmetric(
                        horizontal: SpaceManager.s4,
                        vertical: SpaceManager.savedGap,
                      ),
                      sliver: SliverList.separated(
                        itemCount: bookmarks.length,
                        separatorBuilder: (_, _) => const RSizedBox.vertical(SpaceManager.savedGap),
                        itemBuilder: (context, i) =>
                            BookmarkRow(bookmarks[i], key: ValueKey(bookmarks[i].id)),
                      ),
                    ),
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
