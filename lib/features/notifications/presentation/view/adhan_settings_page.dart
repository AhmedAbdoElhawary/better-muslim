import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/bm_switcher.dart';
import 'package:better_muslim/core/widgets/compact_app_bar.dart';
import 'package:better_muslim/core/widgets/grouped_section.dart';
import 'package:better_muslim/core/widgets/title_glow.dart';
import 'package:better_muslim/features/notifications/data/notification_scheduler.dart';
import 'package:better_muslim/features/notifications/presentation/view/widgets/adhan_stops_section.dart';
import 'package:better_muslim/features/notifications/presentation/view/widgets/notifications_off_line.dart';
import 'package:better_muslim/features/notifications/presentation/view/widgets/prayer_sound_row.dart';
import 'package:better_muslim/features/notifications/presentation/view/widgets/reminder_row.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// every prayer's sound and recording, the reminder and the countdown, each kept at once. the
/// boot remakes the schedule from the store (FR-026 to FR-030)
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

    /// the off line's first ask answers here, with no trip to the background on some phones
    ref.listenManual(
      settingsProvider.select((settings) => settings.value?.notificationsAsked),
      (_, _) => _check(),
    );
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
    /// a record, so the page rebuilds only when a prayer's sound changes
    final sounds = ref.watch(
      settingsProvider.select((settings) {
        PrayerSound? of(Prayer prayer) => settings.value?.soundOf(prayer);
        return (
          of(Prayer.fajr),
          of(Prayer.dhuhr),
          of(Prayer.asr),
          of(Prayer.maghrib),
          of(Prayer.isha),
        );
      }),
    );
    final soundOf = [sounds.$1, sounds.$2, sounds.$3, sounds.$4, sounds.$5];
    return Scaffold(
      body: TitleGlow(
        child: Column(
          children: [
            const CompactAppBar(StringsManager.adhanAndReminders, heroTag: Routes.adhanSettings),
            Expanded(
              child: ListView(
                padding: REdgeInsets.all(SpaceManager.screen),
                children: [
                  BmSwitcher(
                    child: _allowed
                        ? const SizedBox.shrink()
                        : const BottomPadding(
                            padding: SpaceManager.s3,
                            child: NotificationsOffLine(),
                          ),
                  ),
                  GroupedSection(
                    children: [
                      for (final (index, prayer) in Prayer.values.indexed)
                        Column(
                          children: [
                            PrayerSoundRow(prayer),

                            /// in the same section child, so the row can grow in with its divider
                            BmSwitcher(
                              child: switch (soundOf[index]) {
                                final sound? when sound != PrayerSound.silent => Column(
                                  key: ValueKey(sound),
                                  children: [
                                    Divider(
                                      height: SizeManager.divider,
                                      thickness: SizeManager.divider,
                                      color: context.getColor(ThemeEnum.outline),
                                    ),
                                    if (sound == PrayerSound.adhan)
                                      RecordingRow(prayer)
                                    else
                                      ToneRow(prayer),
                                  ],
                                ),
                                _ => const SizedBox.shrink(),
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                  const RSizedBox.vertical(SpaceManager.s3),
                  const GroupedSection(children: [ReminderRow()]),
                  if (defaultTargetPlatform == TargetPlatform.android) ...[
                    const RSizedBox.vertical(SpaceManager.s3),
                    const AdhanStopsSection(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
