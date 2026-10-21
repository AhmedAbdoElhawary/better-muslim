import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/prayer_log/prayer_log.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/animated_decorated_box.dart';
import 'package:better_muslim/features/prayer/presentation/providers/selected_day.dart';
import 'package:better_muslim/features/prayer/presentation/view/widgets/day_dots.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

/// one day of the week strip: filled when it is the shown day, grey numbers in the future
class DayCell extends ConsumerWidget {
  const DayCell(this.day, {super.key});
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shown = ref.watch(shownDayProvider.select((shown) => shown == day));
    final future = ref.watch(prayerDayProvider.select((today) => day.isAfter(today)));
    final prayed = ref.watch(
      weekLogProvider(weekStart(day)).select((log) => log.value?[day] ?? const {}),
    );
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final locale = Localizations.localeOf(context).languageCode;
    final isArabic = locale == 'ar';
    final letter = DateFormat('EEEEE', locale).format(day);
    final number = context.formatDigits('${day.day}', digits);
    final label = DateFormat.MMMMEEEEd(locale).format(day);
    return Semantics(
      button: true,
      selected: shown,
      label: context.formatDigits(label, digits),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          /// today again follows the prayer day, so the screen moves on at fajr
          final today = ref.read(prayerDayProvider);
          ref.read(selectedDayProvider.notifier).select(day == today ? null : day);
        },
        child: AnimatedDecoratedBox(
          decoration: BoxDecoration(
            color: shown ? context.getColor(ThemeEnum.primaryContainer) : null,
            borderRadius: BorderRadius.circular(RadiusManager.md.r),
            border: shown ? Border.all(color: shownBorder(context)) : null,
          ),
          child: RSizedBox(
            height: SizeManager.weekCell,
            child: Center(
              /// at text scale 2 the three lines outgrow the 68 pt cell
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RegularText(
                      letter,
                      translate: false,
                      fontSize: isArabic ? FontSizeManager.label : FontSizeManager.overline,
                      color: shown ? ThemeEnum.onPrimaryContainer : ThemeEnum.text2,
                    ),
                    RSizedBox.vertical(isArabic ? SpaceManager.s1 : SpaceManager.weekCellGap),
                    if (shown)
                      SemiBoldText(
                        number,
                        translate: false,
                        color: ThemeEnum.onPrimaryContainer,
                        tabularFigures: true,
                      )
                    else
                      MediumText(
                        number,
                        translate: false,
                        fontSize: FontSizeManager.title,
                        color: future ? ThemeEnum.text2 : ThemeEnum.text,
                        tabularFigures: true,
                      ),
                    RSizedBox.vertical(isArabic ? SpaceManager.s1 : SpaceManager.weekCellGap),
                    DayDots(prayed),
                    const RSizedBox(height: SpaceManager.weekCellGap),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// the shown cell's inset ring, primary at 35%
  static Color shownBorder(BuildContext context) =>
      context.getColor(ThemeEnum.primary).withValues(alpha: .35);
}
