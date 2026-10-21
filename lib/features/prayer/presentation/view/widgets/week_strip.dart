import 'package:better_muslim/core/prayer_log/prayer_log.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/features/prayer/domain/week.dart';
import 'package:better_muslim/features/prayer/presentation/providers/selected_day.dart';
import 'package:better_muslim/features/prayer/presentation/view/widgets/day_cell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// sunday to saturday, one page per week back to the week of first use and never past this
/// week (R9). pages follow the reading direction, so in arabic earlier weeks come from the right
class WeekStrip extends ConsumerStatefulWidget {
  const WeekStrip({super.key});

  @override
  ConsumerState<WeekStrip> createState() => _WeekStripState();
}

class _WeekStripState extends ConsumerState<WeekStrip> {
  late final PageController _controller;

  List<DateTime> get _pages =>
      weekPages(ref.read(settingsProvider).value?.firstUse, ref.read(prayerDayProvider));

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: _pageOf(ref.read(shownDayProvider)));
  }

  int _pageOf(DateTime day) => _pages.indexOf(weekStart(day)).clamp(0, _pages.length - 1);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firstUse = ref.watch(settingsProvider.select((settings) => settings.value?.firstUse));
    final pages = weekPages(firstUse, ref.watch(prayerDayProvider));

    /// a deep link or fajr can move the shown day to another week
    ref.listen(shownDayProvider, (_, day) {
      final page = _pageOf(day);
      if (!_controller.hasClients || _controller.page?.round() == page) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _controller.jumpToPage(page);
      } else {
        _controller.animateToPage(page, duration: BmMotion.standard, curve: BmMotion.standardCurve);
      }
    });
    return OnlyPadding(
      top: Localizations.localeOf(context).languageCode == 'ar'
          ? SpaceManager.s4
          : SpaceManager.weekTop,
      start: SpaceManager.weekSide,
      end: SpaceManager.weekSide,
      child: RSizedBox(
        height: SizeManager.weekCell,
        child: PageView.builder(
          controller: _controller,
          itemCount: pages.length,
          itemBuilder: (context, index) => _Week(pages[index]),
        ),
      ),
    );
  }
}

class _Week extends StatelessWidget {
  const _Week(this.start);
  final DateTime start;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var offset = 0; offset < DateTime.daysPerWeek; offset++) ...[
          if (offset > 0) const RSizedBox.horizontal(SpaceManager.s1),
          Expanded(child: DayCell(DateTime(start.year, start.month, start.day + offset))),
        ],
      ],
    );
  }
}
