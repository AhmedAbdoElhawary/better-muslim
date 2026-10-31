import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/azkar.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the text of a 4.14 dua card: title and source, the arabic, then in english the
/// transliteration and the translation. arabic shows only the arabic and its source
class DuaText extends ConsumerWidget {
  const DuaText({
    required this.arabic,
    required this.transliteration,
    required this.translation,
    this.title,
    this.source,
    this.translateTitle = true,
    this.quran = false,
    super.key,
  }) : centered = false;

  /// the components' azkar card: no header, everything centered and a size larger
  const DuaText.zikr({
    required this.arabic,
    required this.transliteration,
    required this.translation,
    this.quran = false,
    super.key,
  }) : title = null,
       source = null,
       translateTitle = false,
       centered = true;

  final String arabic;
  final String transliteration;
  final String translation;

  /// a StringsManager key, or the category's name with translateTitle false
  final String? title;
  final String? source;
  final bool translateTitle;

  /// a verse keeps the quran font
  final bool quran;
  final bool centered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final font = ref.watch(azkarFontProvider);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final title = this.title;
    final source = this.source;
    final gap = centered ? SpaceManager.s3 : SpaceManager.duaGap;
    final align = centered ? TextAlign.center : TextAlign.start;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null || source != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: RegularText(
                  title ?? '',
                  translate: translateTitle,
                  fontSize: FontSizeManager.label,
                  color: ThemeEnum.text2,
                ),
              ),
              if (source != null)
                Flexible(
                  child: MediumText(
                    source,
                    translate: false,
                    fontSize: FontSizeManager.label,
                    color: ThemeEnum.accent,
                    textAlign: TextAlign.end,
                  ),
                ),
            ],
          ),
          RSizedBox.vertical(gap),
        ],
        Directionality(
          textDirection: TextDirection.rtl,
          child: RegularText(
            arabic,
            translate: false,
            font: quran ? FontEnum.quran : font,
            fontSize: centered ? FontSizeManager.zikrAr : FontSizeManager.duaAr,
            height: quran ? LineHeightManager.quranAr : LineHeightManager.duaAr,
            textAlign: align,
          ),
        ),

        /// empty until the english comes, the arabic stands alone then
        if (!isArabic && transliteration.isNotEmpty) ...[
          RSizedBox.vertical(gap),
          RegularText(
            transliteration,
            translate: false,
            fontSize: centered ? FontSizeManager.caption : FontSizeManager.rowValue,
            height: LineHeightManager.secondary,
            fontStyle: FontStyle.italic,
            color: ThemeEnum.text2,
            textAlign: align,
          ),
        ],
        if (!isArabic && translation.isNotEmpty) ...[
          RSizedBox.vertical(gap),
          RegularText(
            translation,
            translate: false,
            fontSize: centered ? FontSizeManager.zikrTranslation : FontSizeManager.secondary,
            height: centered ? LineHeightManager.body : LineHeightManager.secondary,
            textAlign: align,
          ),
        ],
      ],
    );
  }
}
