import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/surface_card.dart';
import 'package:better_muslim/features/home/model/home_samples.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// the verse of the day. quran text is never animated, overlapped or cropped
class VerseCard extends ConsumerWidget {
  const VerseCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final reference = isArabic
        ? context.formatDigits('${HomeSamples.verseSurahAr} ${HomeSamples.verseAyah}', digits)
        : '${HomeSamples.verseSurah} ${HomeSamples.verseSurahNumber}:${HomeSamples.verseAyah}';
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.go(Routes.quran),
        child: SurfaceCard(
          child: OnlyPadding(
            top: isArabic ? SpaceManager.s3 : SpaceManager.verseCardTop,
            bottom: isArabic ? SpaceManager.verseCardBottomAr : SpaceManager.card,
            start: SpaceManager.homeCardSide,
            end: SpaceManager.homeCardSide,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: RegularText(
                        StringsManager.verseOfTheDay,
                        fontSize: FontSizeManager.label,
                        color: ThemeEnum.text2,
                      ),
                    ),
                    const RSizedBox.horizontal(SpaceManager.s3),
                    MediumText(
                      reference,
                      translate: false,
                      fontSize: FontSizeManager.label,
                      color: ThemeEnum.accent,
                    ),
                  ],
                ),
                RSizedBox.vertical(isArabic ? SpaceManager.s1 : SpaceManager.verseGap),
                const Directionality(
                  textDirection: TextDirection.rtl,
                  child: RegularText(
                    HomeSamples.verseText,
                    translate: false,
                    font: FontEnum.quran,
                    fontSize: FontSizeManager.quranAr,
                    height: LineHeightManager.quranAr,
                    textAlign: TextAlign.center,
                  ),
                ),
                if (!isArabic) ...[
                  const RSizedBox.vertical(SpaceManager.verseGap),
                  const RegularText(
                    HomeSamples.verseTranslation,
                    translate: false,
                    height: LineHeightManager.verseTranslation,
                    textAlign: TextAlign.center,
                    color: ThemeEnum.text2,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
