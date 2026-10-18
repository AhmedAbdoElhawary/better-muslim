import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/extensions/window_size.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/features/home/model/home_samples.dart';
import 'package:better_muslim/features/home/view/widgets/card_glow.dart';
import 'package:better_muslim/features/home/view/widgets/countdown.dart';
import 'package:better_muslim/features/home/view/widgets/home_card.dart';
import 'package:better_muslim/features/home/view/widgets/prayer_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class NextPrayerCard extends StatelessWidget {
  const NextPrayerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final gap = isArabic ? SpaceManager.s2 : SpaceManager.nextCardGap;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -SpaceManager.homeGlowInset.r,
          top: -SpaceManager.homeGlowInset.r,
          right: -SpaceManager.homeGlowInset.r,
          bottom: -SpaceManager.homeGlowInset.r,
          child: const CardGlow(),
        ),
        Semantics(
          button: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.go(Routes.prayer),
            child: HomeCard(
              child: OnlyPadding(
                top: isArabic ? SpaceManager.nextCardTopAr : SpaceManager.card,
                bottom: SpaceManager.card,
                start: SpaceManager.homeCardSide,
                end: SpaceManager.homeCardSide,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isArabic)
                      const RegularText(
                        StringsManager.nextPrayer,
                        fontSize: FontSizeManager.label,
                        color: ThemeEnum.text2,
                      )
                    else
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: RegularText(
                              StringsManager.nextPrayer,
                              fontSize: FontSizeManager.label,
                              color: ThemeEnum.text2,
                            ),
                          ),
                          _NameAr(),
                        ],
                      ),
                    RSizedBox.vertical(gap),
                    const _NameAndCountdown(),
                    RSizedBox.vertical(gap),
                    const PrayerBar(),
                    RSizedBox.vertical(gap),
                    const _AdhanLine(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NameAr extends ConsumerWidget {
  const _NameAr();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayer = ref.watch(nextPrayerProvider.select((next) => next?.$1));
    if (prayer == null) return const SizedBox.shrink();
    return RegularText(
      prayer.nameArKey,
      font: FontEnum.display,
      fontSize: FontSizeManager.nextPrayerAr,
      height: LineHeightManager.nextPrayerAr,
      color: ThemeEnum.text2,
    );
  }
}

/// side by side as in the PNGs, stacked above text scale 1.4
class _NameAndCountdown extends ConsumerWidget {
  const _NameAndCountdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayer = ref.watch(nextPrayerProvider.select((next) => next?.$1));
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final name = prayer == null
        ? const SizedBox.shrink()
        : RegularText(
            prayer.nameKey,
            font: FontEnum.display,
            fontSize: isArabic ? FontSizeManager.titleAr : FontSizeManager.cardTitle,
            height: isArabic ? LineHeightManager.cardTitleAr : LineHeightManager.cardTitle,
          );
    if (context.isLargeText) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [name, const Countdown()],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: isArabic ? CrossAxisAlignment.center : CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(child: name),
        const Countdown(),
      ],
    );
  }
}

class _AdhanLine extends ConsumerWidget {
  const _AdhanLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final time = ref.watch(nextPrayerProvider.select((next) => next?.$2));
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    if (time == null) return const SizedBox.shrink();
    return Row(
      children: [
        BmIcon(
          BmIconName.adhan,
          size: SizeManager.iconInline.r,
          color: context.getColor(ThemeEnum.text2),
        ),
        const RSizedBox.horizontal(SpaceManager.adhanLineGap),
        Expanded(
          child: RegularText(
            StringsManager.adhanAtReminder,
            args: {
              'time': context.formatTime(time, digits),
              'minutes': context.formatDigits('${HomeSamples.reminderMinutes}', digits),
            },
            fontSize: FontSizeManager.cardNote,
            color: ThemeEnum.text2,
          ),
        ),
      ],
    );
  }
}
