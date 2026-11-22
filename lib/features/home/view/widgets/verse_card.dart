import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/motion/skeleton.dart';
import 'package:better_muslim/core/widgets/surface_card.dart';
import 'package:better_muslim/features/home/model/verse_of_day.dart';
import 'package:better_muslim/features/home/view_model/home_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// the verse of the day. quran text is never animated, overlapped or cropped
class VerseCard extends ConsumerWidget {
  const VerseCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final verse = ref.watch(verseOfDayProvider.select((verse) => verse.value));
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final reference = switch (verse) {
      null => '',
      VerseOfDay(:final surah, :final key) when isArabic => context.formatDigits(
        '${surah.ar} ${key.ayah}',
        digits,
      ),
      VerseOfDay(:final surah, :final key) => '${surah.en} ${key.surah}:${key.ayah}',
    };
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          if (verse == null) return;
          final ayah = verse.key;
          final assets = await ref.read(quranAssetsProvider.future);
          if (!context.mounted) return;
          await context.push(Routes.quranPage(assets.pageOf(ayah), ayah: ayah));
        },
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
                BmSkeletonSwitch(
                  loading: verse == null,
                  skeleton: const Column(
                    children: [
                      BmSkeleton(height: FontSizeManager.quranAr),
                      RSizedBox.vertical(SpaceManager.verseGap),
                      BmSkeleton(height: FontSizeManager.verseTranslation),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: RegularText(
                          QuranFont.amiri.drawn(verse?.text ?? ''),
                          translate: false,
                          font: QuranFont.amiri.font,
                          fontSize: FontSizeManager.quranAr,
                          height: LineHeightManager.quranAr,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (!isArabic) ...[
                        const RSizedBox.vertical(SpaceManager.verseGap),
                        RegularText(
                          verse?.translation ?? '',
                          translate: false,
                          height: LineHeightManager.verseTranslation,
                          textAlign: TextAlign.center,
                          color: ThemeEnum.text2,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
