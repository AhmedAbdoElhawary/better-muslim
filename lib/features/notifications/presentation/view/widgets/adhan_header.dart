import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/features/notifications/presentation/view/adhan_colors.dart';
import 'package:better_muslim/features/notifications/presentation/view/widgets/adhan_progress.dart';
import 'package:better_muslim/features/notifications/presentation/view/widgets/adhan_tint.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// the star, "ADHAN · {city}", the prayer's names, its time and the progress (4.03)
class AdhanHeader extends ConsumerWidget {
  const AdhanHeader({required this.prayer, required this.day, super.key});

  final Prayer prayer;
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final place = ref.watch(
      locationProvider.select(
        (location) => (name: location?.placeName, nameAr: location?.placeNameAr),
      ),
    );
    final city = (isArabic ? place.nameAr : null) ?? place.name ?? '';
    final time = ref.watch(dayTimesProvider(day).select((times) => times?.timeOf(prayer)));
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/brand/star_8point.svg',
          width: SizeManager.adhanStar.r,
          height: SizeManager.adhanStar.r,
          colorFilter: const ColorFilter.mode(AdhanColors.cream, BlendMode.srcIn),
        ),
        const RSizedBox.vertical(SpaceManager.adhanHeaderGap),
        AdhanTint(
          AdhanColors.cream,
          child: TopPadding(
            padding: SpaceManager.adhanNameTop,
            child: RegularText(
              StringsManager.adhanHeader,
              args: {'city': city.toUpperCase()},
              fontSize: FontSizeManager.label,
              letterSpacing: LetterSpacingManager.adhanHeader,
              color: null,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const RSizedBox.vertical(SpaceManager.adhanHeaderGap),
        RegularText(
          prayer.nameArKey,
          font: FontEnum.display,
          fontSize: FontSizeManager.adhanAr,
          height: LineHeightManager.adhanAr,
          color: null,
          textAlign: TextAlign.center,
        ),

        /// english shows the name beside the arabic one, arabic has it once
        if (!isArabic) ...[
          const RSizedBox.vertical(SpaceManager.adhanHeaderGap),
          RegularText(
            prayer.nameKey,
            font: FontEnum.display,
            fontSize: FontSizeManager.adhanTitle,
            height: LineHeightManager.adhanTitle,
            color: null,
            textAlign: TextAlign.center,
          ),
        ],
        const RSizedBox.vertical(SpaceManager.adhanHeaderGap),
        AdhanTint(
          AdhanColors.cream,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (time != null)
                RegularText(
                  context.formatTime(time, digits),
                  translate: false,
                  fontSize: FontSizeManager.title,
                  color: null,
                  tabularFigures: true,
                ),
              const RSizedBox.vertical(SpaceManager.adhanHeaderGap),
              const TopPadding(padding: SpaceManager.adhanProgressTop, child: AdhanProgress()),
            ],
          ),
        ),
      ],
    );
  }
}
