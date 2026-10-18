import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/features/home/view_model/home_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// one prayer of the strip: highlighted when current, checked when logged, a dot while the
/// current one isn't logged
class StripCell extends ConsumerWidget {
  const StripCell(this.index, {super.key});
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cell = ref.watch(stripProvider.select((cells) => cells[index]));
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final gap = isArabic ? SpaceManager.stripCellInnerGapAr : SpaceManager.s1;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.go(Routes.prayerAt(ref.read(prayerDayProvider), cell.prayer)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cell.current ? context.getColor(ThemeEnum.primaryContainer) : null,
            borderRadius: BorderRadius.circular(RadiusManager.md.r),
            border: cell.current ? Border.all(color: currentBorder(context)) : null,
          ),
          child: OnlyPadding(
            top: isArabic ? SpaceManager.stripCellTopAr : SpaceManager.stripCellTop,
            bottom: isArabic ? SpaceManager.stripCellBottomAr : SpaceManager.s2,
            child: Column(
              children: [
                if (cell.current)
                  SemiBoldText(
                    cell.prayer.nameKey,
                    fontSize: FontSizeManager.label,
                    color: ThemeEnum.onPrimaryContainer,
                    maxLines: 1,
                  )
                else
                  RegularText(
                    cell.prayer.nameKey,
                    fontSize: FontSizeManager.label,
                    color: ThemeEnum.text2,
                    maxLines: 1,
                  ),
                RSizedBox.vertical(gap),
                StripTime(cell: cell),
                RSizedBox.vertical(gap),
                RSizedBox(
                  height: SizeManager.stripMarkSlot,
                  child: StripMark(cell: cell),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// the current cell's inset ring, primary at 35%
  static Color currentBorder(BuildContext context) =>
      context.getColor(ThemeEnum.primary).withValues(alpha: .35);
}

/// the time, or a dash on a polar day that has none
class StripTime extends ConsumerWidget {
  const StripTime({required this.cell, super.key});
  final StripEntry cell;

  static const _dash = '—';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final time = cell.time;
    return MediumText(
      time == null ? _dash : context.formatTime(time, digits),
      translate: false,
      fontSize: FontSizeManager.timeSmall,
      color: !cell.current && (cell.logged || cell.past) ? ThemeEnum.text2 : ThemeEnum.text,
      tabularFigures: true,
      maxLines: 1,
    );
  }
}

class StripMark extends StatelessWidget {
  const StripMark({required this.cell, super.key});
  final StripEntry cell;

  @override
  Widget build(BuildContext context) {
    if (cell.logged) {
      return BmIcon.ui(
        BmUiIcon.check,
        size: SizeManager.iconChipSmall.r,
        color: context.getColor(ThemeEnum.success),
      );
    }
    if (!cell.current) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.topCenter,
      widthFactor: 1,
      child: TopPadding(
        padding: SpaceManager.s1,
        child: RSizedBox.square(
          dimension: SizeManager.stripDot,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.getColor(ThemeEnum.onPrimaryContainer),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
