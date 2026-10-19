import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/compact_app_bar.dart';
import 'package:better_muslim/core/widgets/grouped_section.dart';
import 'package:better_muslim/core/widgets/nav_row.dart';
import 'package:better_muslim/features/notifications/data/notification_scheduler.dart';
import 'package:better_muslim/features/notifications/presentation/view/widgets/notifications_off_line.dart';
import 'package:better_muslim/features/notifications/presentation/view/widgets/prayer_sound_row.dart';
import 'package:better_muslim/features/notifications/presentation/view/widgets/reminder_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// every prayer's sound and recording and the reminder, each kept at once. the boot remakes the
/// schedule from the store (FR-026 to FR-030)
class AdhanSettingsPage extends ConsumerStatefulWidget {
  const AdhanSettingsPage({super.key});

  @override
  ConsumerState<AdhanSettingsPage> createState() => _AdhanSettingsPageState();
}

class _AdhanSettingsPageState extends ConsumerState<AdhanSettingsPage> {
  late final AppLifecycleListener _lifecycle;
  var _allowed = true;

  @override
  void initState() {
    super.initState();

    /// a permission given in the phone's settings shows when the app comes back
    _lifecycle = AppLifecycleListener(onResume: _check);
    _check();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final allowed = await ref.read(notificationSchedulerProvider).isAllowed();
    if (mounted) setState(() => _allowed = allowed);
  }

  @override
  Widget build(BuildContext context) {
    /// a record, so the page rebuilds only when a prayer goes on or off adhan
    final adhan = ref.watch(
      settingsProvider.select((settings) {
        bool on(Prayer prayer) => settings.value?.soundOf(prayer) == PrayerSound.adhan;
        return (
          on(Prayer.fajr),
          on(Prayer.dhuhr),
          on(Prayer.asr),
          on(Prayer.maghrib),
          on(Prayer.isha),
        );
      }),
    );
    final onAdhan = [adhan.$1, adhan.$2, adhan.$3, adhan.$4, adhan.$5];
    return Scaffold(
      body: Column(
        children: [
          const CompactAppBar(StringsManager.adhanAndReminders),
          Expanded(
            child: ListView(
              padding: REdgeInsets.all(SpaceManager.screen),
              children: [
                if (!_allowed) ...[
                  const NotificationsOffLine(),
                  const RSizedBox.vertical(SpaceManager.s3),
                ],
                GroupedSection(
                  children: [
                    for (final (index, prayer) in Prayer.values.indexed) ...[
                      PrayerSoundRow(prayer),
                      if (onAdhan[index]) RecordingRow(prayer),
                    ],
                  ],
                ),
                const RSizedBox.vertical(SpaceManager.s3),
                const GroupedSection(children: [_ReminderRow()]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderRow extends ConsumerWidget {
  const _ReminderRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final minutes = ref.watch(
      settingsProvider.select((settings) => settings.value?.reminderMinutes ?? 10),
    );
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    return NavRow(
      title: StringsManager.reminderBefore,
      value: minutes == 0 ? StringsManager.reminderOff : StringsManager.reminderValue,
      args: {'minutes': context.formatDigits('$minutes', digits)},
      onTap: () => showReminderSheet(context),
    );
  }
}
