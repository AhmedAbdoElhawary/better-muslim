import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/prayer_log/prayer_log.dart';
import 'package:better_muslim/core/prayer_log/prayer_row_state.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/bm_switcher.dart';
import 'package:better_muslim/core/widgets/grouped_section.dart';
import 'package:better_muslim/core/widgets/nav_row.dart';
import 'package:better_muslim/core/widgets/sheet/location_choices.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// the day's six times at the current place and method, each prayer with its status (FR-011)
class DayTimes extends ConsumerWidget {
  const DayTimes(this.day, {super.key});
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final located = ref.watch(dayTimesProvider(day).select((times) => times != null));
    if (!located) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RegularText(
            StringsManager.noLocationYet,
            color: ThemeEnum.text2,
            textAlign: TextAlign.center,
          ),
          RSizedBox.vertical(SpaceManager.s4),
          LocationChoices(),
        ],
      );
    }
    return GroupedSection(
      children: [
        _PrayerTime(day, Prayer.fajr),
        _SunriseTime(day),
        for (final prayer in Prayer.values.skip(1)) _PrayerTime(day, prayer),
      ],
    );
  }
}

class _SunriseTime extends ConsumerWidget {
  const _SunriseTime(this.day);
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final at = ref.watch(dayTimesProvider(day).select((times) => times?.sunrise));
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    return NavRow(
      title: StringsManager.sunrise,
      value: at == null ? null : context.formatTime(at, digits),
      translateValue: false,
    );
  }
}

/// no chevron, so its time lines up with sunrise's
class _PrayerTime extends ConsumerWidget {
  const _PrayerTime(this.day, this.prayer);
  final DateTime day;
  final Prayer prayer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final at = ref.watch(dayTimesProvider(day).select((times) => times?.timeOf(prayer)));
    final state = ref.watch(rowStateProvider((day, prayer)).select((row) => row.state));
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context.go(Routes.prayerAt(day, prayer)),
          child: NavRow(
            title: prayer.nameKey,
            value: at == null ? null : context.formatTime(at, digits),
            translateValue: false,
            mark: BmSwitcher(
              child: _Mark(state, key: ValueKey((state.done, state == PrayerRowState.inQada))),
            ),
          ),
        ),
      ),
    );
  }
}

/// the home strip's check for prayed or made up, a muted in qada, nothing otherwise
class _Mark extends StatelessWidget {
  const _Mark(this.state, {super.key});
  final PrayerRowState state;

  @override
  Widget build(BuildContext context) {
    if (state.done) {
      return BmIcon.ui(
        BmUiIcon.check,
        size: SizeManager.iconChipSmall.r,
        color: context.getColor(ThemeEnum.success),
      );
    }
    if (state == PrayerRowState.inQada) {
      return const RegularText(
        StringsManager.inQada,
        fontSize: FontSizeManager.label,
        color: ThemeEnum.text2,
      );
    }
    return const SizedBox.shrink();
  }
}
