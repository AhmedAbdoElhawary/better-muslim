import 'package:better_muslim/core/azkar/azkar_content.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/dua_text.dart';
import 'package:better_muslim/features/duas/model/dua.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// the shared image: the dua in the brand's arch frame with the wordmark, in the app's theme.
/// no design, checked in the app (FR-027)
class ShareCard extends StatelessWidget {
  const ShareCard({required this.dua, required this.category, super.key});
  final Dua dua;
  final DuaCategory category;

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final mode = context.isThemeDark ? 'dark' : 'light';
    return ConstrainedBox(
      constraints: const BoxConstraints.tightFor(width: SizeManager.shareCard),
      child: ColoredBox(
        color: context.getColor(ThemeEnum.bg),
        child: Stack(
          children: [
            Positioned.fill(
              child: AllPadding(
                padding: SpaceManager.s4,
                child: SvgPicture.asset(
                  'assets/ornaments/frame_arch.svg',
                  fit: BoxFit.fill,
                  colorFilter: ColorFilter.mode(
                    context.getColor(ThemeEnum.primary),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            OnlyPadding(
              top: SpaceManager.shareCardTop,
              start: SpaceManager.shareCardSide,
              end: SpaceManager.shareCardSide,
              bottom: SpaceManager.s8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DuaText(
                    title: category.name.inLanguage(language),
                    translateTitle: false,
                    source: dua.sourceIn(language),
                    arabic: dua.arabic,
                    transliteration: dua.transliteration,
                    translation: dua.translation,
                  ),
                  const RSizedBox.vertical(SpaceManager.s8),
                  Center(
                    child: language == 'ar'
                        ? Image.asset(
                            'assets/brand/wordmark_ar_qiyam_$mode-3x.png',
                            height: SizeManager.icon.r,
                          )
                        : SvgPicture.asset(
                            'assets/brand/wordmark_en_qiyam_$mode.svg',
                            height: SizeManager.iconChip.r,
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
