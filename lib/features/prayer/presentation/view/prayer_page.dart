import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/compact_app_bar.dart';
import 'package:better_muslim/core/widgets/sheet/location_sheet.dart';
import 'package:better_muslim/features/prayer/presentation/providers/selected_day.dart';
import 'package:better_muslim/features/prayer/presentation/view/widgets/method_sheet.dart';
import 'package:better_muslim/features/prayer/presentation/view/widgets/prayer_header.dart';
import 'package:better_muslim/features/prayer/presentation/view/widgets/prayer_row.dart';
import 'package:better_muslim/features/prayer/presentation/view/widgets/summary_card.dart';
import 'package:better_muslim/features/prayer/presentation/view/widgets/week_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 4.04 and 4.17. a link with a day and a prayer opens that day scrolled to the row
class PrayerPage extends ConsumerStatefulWidget {
  const PrayerPage({this.day, this.prayer, super.key});
  final DateTime? day;
  final Prayer? prayer;

  @override
  ConsumerState<PrayerPage> createState() => _PrayerPageState();
}

class _PrayerPageState extends ConsumerState<PrayerPage> {
  final _rows = {for (final prayer in Prayer.values) prayer: GlobalKey()};

  @override
  void initState() {
    super.initState();
    _openLink();
  }

  @override
  void didUpdateWidget(PrayerPage old) {
    super.didUpdateWidget(old);
    if (old.day != widget.day || old.prayer != widget.prayer) _openLink();
  }

  void _openLink() {
    final day = widget.day;
    if (day == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final today = ref.read(prayerDayProvider);
      ref.read(selectedDayProvider.notifier).select(day == today ? null : day);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final row = _rows[widget.prayer]?.currentContext;
        if (row == null || !row.mounted) return;
        Scrollable.ensureVisible(
          row,
          alignment: .5,
          duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : BmMotion.standard,
          curve: BmMotion.standardCurve,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LargeTitleScrollView(
        title: StringsManager.prayerTimes,
        slivers: [
          SliverToBoxAdapter(
            child: PrayerHeader(
              onPin: () => showLocationSheet(context),
              onSliders: () => showMethodSheet(context),
            ),
          ),
          const SliverToBoxAdapter(child: WeekStrip()),
          const SliverToBoxAdapter(child: SummaryCard()),
          SliverToBoxAdapter(child: _Rows(_rows)),
        ],
      ),
    );
  }
}

class _Rows extends StatelessWidget {
  const _Rows(this.keys);
  final Map<Prayer, GlobalKey> keys;

  @override
  Widget build(BuildContext context) {
    return OnlyPadding(
      top: SpaceManager.s3,
      start: SpaceManager.s2,
      end: SpaceManager.s2,
      bottom: SpaceManager.s6,
      child: Column(
        children: [
          for (final prayer in Prayer.values) ...[
            if (prayer != Prayer.fajr) const RSizedBox.vertical(SpaceManager.rowLineGap),
            PrayerRow(prayer, key: keys[prayer]),
            if (prayer == Prayer.fajr) ...[
              const RSizedBox.vertical(SpaceManager.rowLineGap),
              const SunriseRow(),
            ],
          ],
        ],
      ),
    );
  }
}
