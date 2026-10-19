import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/hijri/hijri_date.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/grouped_section.dart';
import 'package:better_muslim/core/widgets/nav_row.dart';
import 'package:better_muslim/core/widgets/sheet/bm_sheet.dart';
import 'package:better_muslim/core/widgets/sheet/sheet_title.dart';
import 'package:better_muslim/features/hijri_calendar/model/hijri_events.dart';
import 'package:better_muslim/features/hijri_calendar/view/widgets/calendar_format.dart';
import 'package:better_muslim/features/hijri_calendar/view_model/calendar_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:timezone/timezone.dart' show TZDateTime;

/// selects the day while its sheet is open (FR-023)
Future<void> showDaySheet(BuildContext context, DateTime day) async {
  final selected = ProviderScope.containerOf(context).read(selectedDayProvider.notifier);
  selected.select(day);
  await showBmSheet<void>(context, builder: (_) => _DaySheet(day));
  selected.select(null);
}

/// the day's dates, its six times at the current place and method, and its events
class _DaySheet extends ConsumerWidget {
  const _DaySheet(this.day);
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hijri = ref.watch(hijriDateProvider(day));
    final times = ref.watch(dayTimesProvider(day));
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final locale = Localizations.localeOf(context).languageCode;
    final events = eventsOn(hijri);
    String? time(TZDateTime? at) => at == null ? null : context.formatTime(at, digits);
    return SingleChildScrollView(
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetTitle(
              context.hijriFull(hijri, digits),
              subtitle: context.formatDigits(DateFormat.yMMMMEEEEd(locale).format(day), digits),
              translate: false,
            ),
            SymmetricPadding(
              horizontal: SpaceManager.screen,
              vertical: SpaceManager.s2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (times != null)
                    GroupedSection(
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
                    ),
                  if (events.isNotEmpty) ...[
                    const RSizedBox.vertical(SpaceManager.sectionGap),
                    GroupedSection(
                      label: StringsManager.sectionEvents,
                      children: [
                        for (final event in events)
                          NavRow(title: event.nameKey, value: event.noteKey),
                      ],
                    ),
                  ],
                  const RSizedBox.vertical(SpaceManager.s6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
