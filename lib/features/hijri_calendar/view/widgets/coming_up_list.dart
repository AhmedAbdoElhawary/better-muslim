import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/hijri/hijri_date.dart';
import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/grouped_section.dart';
import 'package:better_muslim/features/hijri_calendar/model/calendar_month.dart';
import 'package:better_muslim/features/hijri_calendar/model/coming_up.dart';
import 'package:better_muslim/features/hijri_calendar/view/widgets/calendar_format.dart';
import 'package:better_muslim/features/hijri_calendar/view_model/calendar_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

/// above this the pill goes under the name, like the prayer rows stack
const _stackAt = 1.4;

/// every event left in the selected day's year by month, or the next year's (FR-012 to FR-017)
class ComingUpList extends ConsumerWidget {
  const ComingUpList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(comingUpProvider);
    final mode = ref.watch(calendarModeProvider);
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HorizontalPadding(
          padding: SpaceManager.comingUpLabelSide,
          child: SemiBoldText(
            list.next ? StringsManager.comingUpNextYear : StringsManager.comingUpThisYear,
            args: {'year': context.formatDigits('${list.year}', digits)},
          ),
        ),
        if (list.groups.isEmpty) ...[
          const RSizedBox.vertical(SpaceManager.s3),
          const RegularText(
            StringsManager.noMoreEvents,
            color: ThemeEnum.text2,
            textAlign: TextAlign.center,
          ),
        ],
        for (final group in list.groups) ...[
          const RSizedBox.vertical(SpaceManager.s4),
          HorizontalPadding(
            padding: SpaceManager.comingUpLabelSide,
            child: RegularText(
              group.current
                  ? StringsManager.thisMonth
                  : switch (mode) {
                      CalendarMode.hijri => context.tr(
                        HijriDate(day: 1, month: group.month, year: group.year).monthKey,
                      ),
                      CalendarMode.gregorian => context.gregorianMonthName(group.month),
                    },
              translate: group.current,
              color: ThemeEnum.text2,
            ),
          ),
          const RSizedBox.vertical(SpaceManager.sectionLabelGap),
          GroupedSection(children: [for (final item in group.items) _Item(item)]),
        ],
      ],
    );
  }
}

class _Item extends ConsumerWidget {
  const _Item(this.item);
  final ComingUpItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(calendarModeProvider);
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final locale = Localizations.localeOf(context).languageCode;
    final hijri = item.hijri;
    final lastHijri = HijriDate(
      day: hijri.day + item.event.to - item.event.from,
      month: hijri.month,
      year: hijri.year,
    );
    final (day, month, dates) = switch (mode) {
      CalendarMode.hijri => (
        hijri.day,
        context.tr(hijriShortMonths[hijri.month - 1]),
        context.dayRange(item.first, item.last, digits),
      ),
      CalendarMode.gregorian => (
        item.first.day,
        DateFormat.MMM(locale).format(item.first),
        context.hijriRange(hijri, lastHijri, digits),
      ),
    };
    final noteKey = item.event.noteKey;
    final line = [
      if (noteKey != null) context.tr(noteKey),
      if (item.estimated) context.tr(StringsManager.estimated, {'date': dates}) else dates,
    ].join(' · ');
    final stacked = MediaQuery.textScalerOf(context).scale(1) > _stackAt;
    final pill = _Pill(context.daysAway(item.daysAway, digits), past: item.daysAway < 0);
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _open(context, ref, mode),
        child: MergeSemantics(
          child: SymmetricPadding(
            horizontal: SpaceManager.s4,
            vertical: SpaceManager.comingUpRowV,
            child: Row(
              children: [
                RSizedBox(
                  width: SizeManager.comingUpDay,
                  child: Column(
                    children: [
                      SemiBoldText(
                        context.formatDigits('$day', digits),
                        translate: false,
                        height: LineHeightManager.comingUpDay,
                        tabularFigures: true,
                      ),
                      RegularText(
                        month,
                        translate: false,
                        fontSize: FontSizeManager.tabLabel,
                        height: LineHeightManager.comingUpDay,
                        color: ThemeEnum.text2,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const RSizedBox.horizontal(SpaceManager.listRowGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MediumText(item.event.nameKey),
                      const RSizedBox.vertical(SpaceManager.rowLineGap),
                      RegularText(
                        line,
                        translate: false,
                        fontSize: FontSizeManager.cardNote,
                        height: LineHeightManager.caption,
                        color: ThemeEnum.text2,
                      ),
                      if (stacked) ...[const RSizedBox.vertical(SpaceManager.s2), pill],
                    ],
                  ),
                ),
                if (!stacked) ...[const RSizedBox.horizontal(SpaceManager.s3), pill],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// the month slides in, its first day selected and its events open (FR-017)
  void _open(BuildContext context, WidgetRef ref, CalendarMode mode) {
    BmHaptics.selection();
    ref
        .read(calendarPageProvider.notifier)
        .open(CalendarMonth.of(item.first, mode, ref.read(hijriAdjustProvider)));
    ref.read(selectedDayProvider.notifier).select(item.first);
    ref.read(dayTabProvider.notifier).open(DayTab.events);

    /// the grid is above the list, back up so the slide is seen
    final position = Scrollable.maybeOf(context)?.position;
    if (position == null) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      position.jumpTo(0);
    } else {
      position.animateTo(0, duration: BmMotion.standard, curve: BmMotion.standardCurve);
    }
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, {required this.past});

  /// already formatted
  final String label;
  final bool past;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: SizeManager.stateChip.r),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(RadiusManager.pill.r),
          color: context.getColor(past ? ThemeEnum.variant : ThemeEnum.primaryContainer),
        ),
        child: SymmetricPadding(
          horizontal: SpaceManager.chipSide,
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: MediumText(
              label,
              translate: false,
              fontSize: FontSizeManager.chip,
              color: past ? ThemeEnum.text2 : ThemeEnum.onPrimaryContainer,
              tabularFigures: true,
            ),
          ),
        ),
      ),
    );
  }
}
