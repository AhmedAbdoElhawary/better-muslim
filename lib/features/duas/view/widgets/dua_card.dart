import 'package:better_muslim/core/azkar/azkar_content.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/dua_text.dart';
import 'package:better_muslim/core/widgets/surface_card.dart';
import 'package:better_muslim/features/duas/model/dua.dart';
import 'package:better_muslim/features/duas/view/widgets/dua_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 4.14's dua card. a long dua makes it taller, the arabic is never cut
class DuaCard extends StatelessWidget {
  const DuaCard({required this.dua, required this.category, super.key});
  final Dua dua;
  final DuaCategory category;

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    return SurfaceCard(
      child: OnlyPadding(
        top: SpaceManager.s4,

        /// the actions reach 8 further out than the text, like the tree's margin 0 -8
        start: SpaceManager.duaCardH - SpaceManager.s2,
        end: SpaceManager.duaCardH - SpaceManager.s2,
        bottom: SpaceManager.duaCardBottom,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HorizontalPadding(
              padding: SpaceManager.s2,
              child: DuaText(
                title: category.name.inLanguage(language),
                translateTitle: false,
                source: dua.sourceIn(language),
                arabic: dua.arabic,
                transliteration: dua.transliteration,
                translation: dua.translation,
                quran: dua.quran,
              ),
            ),
            const RSizedBox.vertical(SpaceManager.duaGap),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: context.getColor(ThemeEnum.outline))),
              ),
              child: TopPadding(
                padding: SpaceManager.duaActionsTop,
                child: DuaActions(dua: dua),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
