import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/features/notifications/data/dua_after_adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the full dua after the adhan, laid out like a 4.14 dua card. arabic shows only the arabic and
/// its source (FR-032)
class DuaSheet extends StatelessWidget {
  const DuaSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return SingleChildScrollView(
      child: SafeArea(
        top: false,
        child: SymmetricPadding(
          horizontal: SpaceManager.duaCardH,
          vertical: SpaceManager.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: RegularText(
                      DuaAfterAdhan.titleKey,
                      fontSize: FontSizeManager.label,
                      color: ThemeEnum.text2,
                    ),
                  ),
                  MediumText(
                    isArabic ? DuaAfterAdhan.sourceAr : DuaAfterAdhan.sourceEn,
                    translate: false,
                    fontSize: FontSizeManager.label,
                    color: ThemeEnum.accent,
                  ),
                ],
              ),
              const RSizedBox.vertical(SpaceManager.duaGap),
              const Directionality(
                textDirection: TextDirection.rtl,
                child: RegularText(
                  DuaAfterAdhan.arabic,
                  translate: false,
                  font: FontEnum.dua,
                  fontSize: FontSizeManager.duaAr,
                  height: LineHeightManager.duaAr,
                  textAlign: TextAlign.start,
                ),
              ),
              if (!isArabic) ...[
                const RSizedBox.vertical(SpaceManager.duaGap),
                const RegularText(
                  DuaAfterAdhan.transliteration,
                  translate: false,
                  fontSize: FontSizeManager.rowValue,
                  height: LineHeightManager.secondary,
                  fontStyle: FontStyle.italic,
                  color: ThemeEnum.text2,
                ),
                const RSizedBox.vertical(SpaceManager.duaGap),
                const RegularText(
                  DuaAfterAdhan.translation,
                  translate: false,
                  fontSize: FontSizeManager.secondary,
                  height: LineHeightManager.secondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
