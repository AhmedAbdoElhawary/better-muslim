import 'package:better_muslim/core/azkar/azkar_content.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/surface_card.dart';
import 'package:better_muslim/core/widgets/title_hero.dart';
import 'package:better_muslim/features/duas/model/dua.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// 4.14's grouped rows, each opens its category's page
class CategoryRows extends ConsumerWidget {
  const CategoryRows(this.categories, {super.key});
  final List<DuaCategory> categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final language = Localizations.localeOf(context).languageCode;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return SurfaceCard(
      child: Column(
        children: [
          for (final (i, category) in categories.indexed)
            Semantics(
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => context.push(Routes.duaCategory(category.id)),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: i < categories.length - 1
                        ? Border(bottom: BorderSide(color: context.getColor(ThemeEnum.outline)))
                        : null,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: SizeManager.categoryRow.r),
                    child: OnlyPadding(
                      start: SpaceManager.s4,
                      end: SpaceManager.categoryRowEnd,
                      top: SpaceManager.s2,
                      bottom: SpaceManager.s2,
                      child: Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: TitleHero(
                                tag: Routes.duaCategory(category.id),
                                child: RegularText(
                                  category.name.inLanguage(language),
                                  translate: false,
                                  fontSize: FontSizeManager.body,
                                ),
                              ),
                            ),
                          ),
                          const RSizedBox.horizontal(SpaceManager.shortcutGap),
                          RegularText(
                            StringsManager.duaCount,
                            args: {
                              'count': context.formatDigits('${category.duas.length}', digits),
                            },
                            color: ThemeEnum.text2,
                          ),
                          const RSizedBox.horizontal(SpaceManager.shortcutGap),
                          BmIcon.ui(
                            rtl ? BmUiIcon.back : BmUiIcon.forward,
                            size: SizeManager.iconInline.r,
                            color: context.getColor(ThemeEnum.text3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
