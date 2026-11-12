import 'package:better_muslim/core/hijri/hijri_date.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/grouped_section.dart';
import 'package:better_muslim/core/widgets/nav_row.dart';
import 'package:better_muslim/features/hijri_calendar/model/hijri_events.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// every event covering the day, a several day one on each of its days (FR-018)
class DayEvents extends ConsumerWidget {
  const DayEvents(this.day, {super.key});
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = eventsOn(ref.watch(hijriDateProvider(day)));
    if (events.isEmpty) {
      return const RegularText(
        StringsManager.noEventsOnDay,
        color: ThemeEnum.text2,
        textAlign: TextAlign.center,
      );
    }
    return GroupedSection(
      children: [for (final event in events) NavRow(title: event.nameKey, value: event.noteKey)],
    );
  }
}
