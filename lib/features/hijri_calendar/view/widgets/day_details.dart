import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/hijri/hijri_date.dart';
import 'package:better_muslim/core/prayer_log/prayer_log.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/bm_switcher.dart';
import 'package:better_muslim/core/widgets/day_dots.dart';
import 'package:better_muslim/core/widgets/segmented.dart';
import 'package:better_muslim/features/hijri_calendar/model/hijri_events.dart';
import 'package:better_muslim/features/hijri_calendar/view/widgets/coming_up_list.dart';
import 'package:better_muslim/features/hijri_calendar/view/widgets/day_events.dart';
import 'package:better_muslim/features/hijri_calendar/view/widgets/day_times.dart';
import 'package:better_muslim/features/hijri_calendar/view_model/calendar_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' show DateFormat;

/// what the day sheet showed, under the grid: the dates, then the three tabs (FR-010)
class DayDetails extends ConsumerWidget {
  const DayDetails({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(selectedDayProvider);
    final tab = ref.watch(dayTabProvider);
    final hasEvents = ref.watch(
      hijriDateProvider(day).select((hijri) => eventsOn(hijri).isNotEmpty),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BmSwitcher(child: _DateLine(day, key: ValueKey(day))),
        const RSizedBox.vertical(SpaceManager.s4),
        Segmented<DayTab>(
          values: DayTab.values,
          selected: tab,
          labelOf: (tab) => switch (tab) {
            DayTab.prayerTimes => StringsManager.tabPrayerTimes,
            DayTab.comingUp => StringsManager.tabComingUp,
            DayTab.events => StringsManager.tabEvents,
          },
          empty: hasEvents ? const {} : const {DayTab.events},
          onChanged: ref.read(dayTabProvider.notifier).open,
        ),
        const RSizedBox.vertical(SpaceManager.s4),
        _TabContent(tab: tab, day: day),
      ],
    );
  }
}

class _DateLine extends ConsumerWidget {
  const _DateLine(this.day, {super.key});
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hijri = ref.watch(hijriDateProvider(day));
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final locale = Localizations.localeOf(context).languageCode;
    return HorizontalPadding(
      padding: SpaceManager.comingUpLabelSide,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RegularText(
            context.hijriFull(hijri, digits),
            translate: false,
            font: FontEnum.display,
            fontSize: FontSizeManager.sheetTitle,
          ),
          const RSizedBox.vertical(SpaceManager.s1),
          RegularText(
            context.formatDigits(DateFormat.yMMMMEEEEd(locale).format(day), digits),
            translate: false,
            color: ThemeEnum.text2,
          ),
          _Prayed(day),
        ],
      ),
    );
  }
}

class _Prayed extends ConsumerWidget {
  const _Prayed(this.day);
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final past = ref.watch(todayProvider.select((today) => !day.isAfter(today)));
    if (!past) return const SizedBox.shrink();
    return TopPadding(padding: SpaceManager.s2, child: DayDots(ref.watch(prayedProvider(day))));
  }
}

/// a new tab comes in from the side of the tapped segment, a new day rises in
class _TabContent extends StatefulWidget {
  const _TabContent({required this.tab, required this.day});
  final DayTab tab;
  final DateTime day;

  @override
  State<_TabContent> createState() => _TabContentState();
}

class _TabContentState extends State<_TabContent> {
  var _from = AxisDirection.down;

  @override
  void didUpdateWidget(_TabContent old) {
    super.didUpdateWidget(old);
    if (old.tab != widget.tab) {
      _from = widget.tab.index > old.tab.index ? AxisDirection.right : AxisDirection.left;
    } else if (old.day != widget.day) {
      _from = AxisDirection.down;
    }
  }

  @override
  Widget build(BuildContext context) {
    final key = ValueKey((widget.tab, widget.day));
    return BmSwitcher(
      from: _from,
      child: switch (widget.tab) {
        DayTab.prayerTimes => DayTimes(widget.day, key: key),
        DayTab.comingUp => ComingUpList(key: key),
        DayTab.events => DayEvents(widget.day, key: key),
      },
    );
  }
}
