import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/animated_decorated_box.dart';
import 'package:better_muslim/features/home/view_model/home_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// one prayer of the strip: highlighted when current, checked when logged, a dot while the
/// prayer in its now window isn't logged
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
        child: AnimatedDecoratedBox(
          decoration: decoration(context, cell),
          child: OnlyPadding(
            top: isArabic ? SpaceManager.stripCellTopAr : SpaceManager.stripCellTop,
            bottom: isArabic ? SpaceManager.stripCellBottomAr : SpaceManager.s2,
            child: Column(
              children: [
                if (cell.current)
                  SemiBoldText(
                    cell.prayer.nameKey,
                    fontSize: FontSizeManager.label,
                    color: cell.now ? ThemeEnum.onPrimaryContainer : ThemeEnum.primary,
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

  /// filled in its now window, outlined when it is the next prayer
  static BoxDecoration decoration(BuildContext context, StripEntry cell) {
    final primary = context.getColor(ThemeEnum.primary);
    return BoxDecoration(
      color: cell.now ? context.getColor(ThemeEnum.primaryContainer) : null,
      borderRadius: BorderRadius.circular(RadiusManager.md.r),
      border: !cell.current
          ? null
          : cell.now
          ? Border.all(color: primary.withValues(alpha: .15))
          : Border.all(color: primary, width: SizeManager.nextRing.r),
    );
  }
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

    /// "12:05 PM" needs about 73 pt and a cell is 69, so the strip alone drops am/pm (R15)
    return Semantics(
      label: time == null ? _dash : context.formatTime(time, digits),
      excludeSemantics: true,
      child: MediumText(
        time == null ? _dash : context.formatTime(time, digits, period: false),
        translate: false,
        fontSize: FontSizeManager.timeSmall,
        color: !cell.current && (cell.logged || cell.past) ? ThemeEnum.text2 : ThemeEnum.text,
        tabularFigures: true,
        maxLines: 1,
      ),
    );
  }
}

class StripMark extends StatelessWidget {
  const StripMark({required this.cell, super.key});
  final StripEntry cell;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: BmMotion.micro,
      layoutBuilder: (current, previous) =>
          Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
      child: _Mark(cell, key: ValueKey((cell.logged, cell.now))),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark(this.cell, {super.key});
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
    if (!cell.now) return const SizedBox.shrink();
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
