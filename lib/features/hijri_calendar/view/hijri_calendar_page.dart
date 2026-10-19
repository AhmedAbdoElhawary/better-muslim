import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/compact_app_bar.dart';
import 'package:better_muslim/core/widgets/grouped_section.dart';
import 'package:better_muslim/core/widgets/nav_row.dart';
import 'package:better_muslim/features/hijri_calendar/view/widgets/adjustment_sheet.dart';
import 'package:better_muslim/features/hijri_calendar/view/widgets/calendar_format.dart';
import 'package:better_muslim/features/hijri_calendar/view/widgets/coming_up_card.dart';
import 'package:better_muslim/features/hijri_calendar/view/widgets/month_grid.dart';
import 'package:better_muslim/features/hijri_calendar/view/widgets/month_header.dart';
import 'package:better_muslim/features/hijri_calendar/view_model/calendar_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 4.13: one scroll view, so a six row month pushes the rest down instead of squeezing (FR-017)
class HijriCalendarPage extends StatelessWidget {
  const HijriCalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const CompactAppBar(StringsManager.hijriCalendar, action: _TodayButton()),
          Expanded(
            child: ListView(
              padding: REdgeInsets.only(bottom: SpaceManager.s6),
              children: const [
                RSizedBox.vertical(SpaceManager.monthHeaderTop),
                HorizontalPadding(padding: SpaceManager.screen, child: MonthHeader()),
                RSizedBox.vertical(SpaceManager.gridTop),
                HorizontalPadding(padding: SpaceManager.gridSide, child: MonthGrid()),
                RSizedBox.vertical(SpaceManager.comingUpTop),
                HorizontalPadding(padding: SpaceManager.screen, child: ComingUpCard()),
                RSizedBox.vertical(SpaceManager.adjustmentTop),
                HorizontalPadding(padding: SpaceManager.screen, child: _AdjustmentRow()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayButton extends ConsumerWidget {
  const _TodayButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: context.tr(StringsManager.today),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: ref.read(shownMonthProvider.notifier).today,
        child: RSizedBox.square(
          dimension: SizeManager.hit,
          child: Center(
            child: BmIcon.ui(
              BmUiIcon.calendar,
              size: SizeManager.icon.r,
              color: context.getColor(ThemeEnum.text),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdjustmentRow extends ConsumerWidget {
  const _AdjustmentRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adjust = ref.watch(hijriAdjustProvider);
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    return GroupedSection(
      children: [
        NavRow(
          title: StringsManager.dateAdjustment,
          value: context.adjustment(adjust, digits),
          translateValue: false,
          onTap: () => showAdjustmentSheet(context),
        ),
      ],
    );
  }
}
