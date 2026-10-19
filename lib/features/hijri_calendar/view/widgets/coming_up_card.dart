import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/grouped_section.dart';
import 'package:better_muslim/features/hijri_calendar/model/coming_up.dart';
import 'package:better_muslim/features/hijri_calendar/view/widgets/calendar_format.dart';
import 'package:better_muslim/features/hijri_calendar/view_model/calendar_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

const _shortMonths = [
  StringsManager.hijriShort1,
  StringsManager.hijriShort2,
  StringsManager.hijriShort3,
  StringsManager.hijriShort4,
  StringsManager.hijriShort5,
  StringsManager.hijriShort6,
  StringsManager.hijriShort7,
  StringsManager.hijriShort8,
  StringsManager.hijriShort9,
  StringsManager.hijriShort10,
  StringsManager.hijriShort11,
  StringsManager.hijriShort12,
];

/// the next three things from today, whatever month is shown (FR-022)
class ComingUpCard extends ConsumerWidget {
  const ComingUpCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(comingUpProvider);
    return GroupedSection(
      label: StringsManager.comingUp,
      labelSide: SpaceManager.comingUpLabelSide,
      children: [for (final item in items) _Item(item)],
    );
  }
}

class _Item extends ConsumerWidget {
  const _Item(this.item);
  final ComingUpItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final monthKey = item.monthKey;
    final range = context.dayRange(item.start, item.end, digits);
    final date = context.dayMonth(item.start, digits);
    final (lineKey, value) = switch (item.line) {
      ComingUpLine.whiteDays => (StringsManager.ayyamAlBidSub, range),
      ComingUpLine.inMonth => (null, range),
      ComingUpLine.sighting => (StringsManager.estimatedSighting, date),
      ComingUpLine.estimated => (StringsManager.estimated, date),
    };
    return MergeSemantics(
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
                    context.formatDigits('${item.hijri.day}', digits),
                    translate: false,
                    height: LineHeightManager.comingUpDay,
                    tabularFigures: true,
                  ),
                  RegularText(
                    _shortMonths[item.hijri.month - 1],
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
                  MediumText(
                    item.titleKey,
                    args: {if (monthKey != null) 'month': context.tr(monthKey)},
                  ),
                  const RSizedBox.vertical(SpaceManager.rowLineGap),
                  RegularText(
                    lineKey ?? value,
                    translate: lineKey != null,
                    args: {'range': value, 'date': value},
                    fontSize: FontSizeManager.cardNote,
                    height: LineHeightManager.caption,
                    color: ThemeEnum.text2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
