import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/grouped_section.dart';
import 'package:better_muslim/core/widgets/nav_row.dart';
import 'package:better_muslim/core/widgets/sheet/location_choices.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:timezone/timezone.dart' show TZDateTime;

/// the day's six times at the current place and method (FR-011)
class DayTimes extends ConsumerWidget {
  const DayTimes(this.day, {super.key});
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final times = ref.watch(dayTimesProvider(day));
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    if (times == null) {
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
    String? time(TZDateTime? at) => at == null ? null : context.formatTime(at, digits);
    return GroupedSection(
      children: [
        for (final (key, at) in [
          (StringsManager.fajr, times.fajr),
          (StringsManager.sunrise, times.sunrise),
          (StringsManager.dhuhr, times.dhuhr),
          (StringsManager.asr, times.asr),
          (StringsManager.maghrib, times.maghrib),
          (StringsManager.isha, times.isha),
        ])
          NavRow(title: key, value: time(at), translateValue: false),
      ],
    );
  }
}
