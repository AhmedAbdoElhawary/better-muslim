import 'dart:ui';

import 'package:better_muslim/core/app/app_localizations.dart';
import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/flavor/flavor_config.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/adhan_recording.dart';
import 'package:better_muslim/core/settings/onboarding.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/surfaces/surfaces_channel.dart';
import 'package:better_muslim/core/surfaces/write_surfaces.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/grouped_section.dart';
import 'package:better_muslim/core/widgets/motion/oil_drop.dart';
import 'package:better_muslim/core/widgets/nav_row.dart';
import 'package:better_muslim/core/widgets/title_glow.dart';
import 'package:better_muslim/features/notifications/data/alert_texts.dart';
import 'package:better_muslim/features/notifications/data/notification_scheduler.dart';
import 'package:better_muslim/features/notifications/domain/alert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// dev builds only (FR-041). its text is for me, so it is not in the arb files
class DevNotificationsPage extends ConsumerWidget {
  const DevNotificationsPage({super.key});

  static const _title = 'Notifications (dev)';
  static const _openAdhan = 'Open adhan screen';
  static const _testIn1Minute = 'Test notification in 1 min';
  static const _replayOnboarding = 'Replay onboarding';
  static const _refreshWidgets = 'Refresh widgets';
  static const _startCountdown = 'Start countdown now';

  /// the next prayer as an alert, on its own prayer day
  static Alert? nextAlert(WidgetRef ref) {
    final next = ref.read(nextPrayerProvider);
    if (next == null) return null;
    final (prayer, at) = next;
    final today = ref.read(todayProvider);
    return Alert(
      day: prayer == Prayer.fajr && at.day != today.day
          ? DateTime(at.year, at.month, at.day)
          : today,
      prayer: prayer,
      kind: AlertKind.adhan,
      at: at,
      sound: ref.read(settingsProvider).value?.soundOf(prayer) ?? PrayerSound.tone,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /// the design scenario never schedules a real notification (FR-013)
    final isScenario = ref.watch(flavorProvider.select((config) => config.isDesignScenario));
    return Scaffold(
      body: TitleGlow(
        child: SafeArea(
          child: ListView(
            padding: REdgeInsets.all(SpaceManager.screen),
            children: [
              const SemiBoldText(_title, translate: false),
              const RSizedBox.vertical(SpaceManager.s4),
              _Row(
                _openAdhan,
                onTap: () {
                  final alert = nextAlert(ref);
                  if (alert != null) context.push(Routes.adhan(alert.prayer, alert.day));
                },
              ),
              if (!isScenario) ...[
                _Row(
                  _testIn1Minute,
                  onTap: () async {
                    final alert = nextAlert(ref);
                    final location = ref.read(locationProvider);
                    if (alert == null || location == null) return;
                    final texts = await AlertTexts.load(
                      locale: AppLocalizations.localeOf(ref.read(settingsProvider).value?.language),
                      use24h: PlatformDispatcher.instance.alwaysUse24HourFormat,
                      digits: ref.read(settingsProvider).value?.digits ?? Digits.eastern,
                      location: location,
                    );
                    await ref
                        .read(notificationSchedulerProvider)
                        .testIn1Minute(
                          alert,
                          texts,
                          ref.read(settingsProvider).value?.recordingOf(alert.prayer) ??
                              AdhanRecording.makkah,
                        );
                  },
                ),

                /// past the plugin's equal check, so the widgets reload even with the same data
                _Row(
                  _refreshWidgets,
                  onTap: () => writeSurfaces(
                    ref.read(databaseProvider),
                    channel: ref.read(surfacesChannelProvider),
                    locale: AppLocalizations.localeOf(ref.read(settingsProvider).value?.language),
                    use24h: PlatformDispatcher.instance.alwaysUse24HourFormat,
                    phoneZone: ref.read(phoneZoneProvider),
                    force: true,
                  ),
                ),

                /// the next prayer's countdown whatever the 2 hours, so it shows without waiting
                _Row(_startCountdown, onTap: () => ref.read(surfacesChannelProvider).startNow()),
                const _FastDayRow(),
              ],

              /// from the first screen, nothing is cleared (FR-004)
              _Row(
                _replayOnboarding,
                onTap: () {
                  ref.read(onboardingProvider.notifier).replay();
                  context.go(Routes.onboarding);
                },
              ),
              const RSizedBox.vertical(SpaceManager.sectionGap),
              const _Loader(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, {required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: SizeManager.listRow.r),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: RegularText(
              label,
              translate: false,
              fontSize: FontSizeManager.body,
              color: ThemeEnum.accent,
            ),
          ),
        ),
      ),
    );
  }
}

/// no notifications or widgets are scheduled while it runs, so its fake times stay in the app
class _FastDayRow extends ConsumerWidget {
  const _FastDayRow();

  static const _label = 'Fast day (24 h in 5 min)';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(fastDayProvider);
    return GroupedSection(
      children: [
        NavRow(
          title: _label,
          translateTitle: false,
          toggled: on,
          onTap: () => ref.read(fastDayProvider.notifier).set(!on),
        ),
      ],
    );
  }
}

/// the oil drop at its three sizes and one following a slider (FR-059). shut until tapped, its
/// loops would keep the page from ever settling
class _Loader extends StatefulWidget {
  const _Loader();

  @override
  State<_Loader> createState() => _LoaderState();
}

class _LoaderState extends State<_Loader> {
  static const _label = 'Loader';
  static const _sizes = [SizeManager.oilDrop, SizeManager.oilDropInline, SizeManager.oilDropSmall];

  double _progress = .43;
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Row(_label, onTap: () => setState(() => _open = !_open)),
        if (_open)
          GroupedSection(
            children: [
              AllPadding(
                padding: SpaceManager.card,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [for (final size in _sizes) BmOilDrop(size: size)],
                ),
              ),
              AllPadding(
                padding: SpaceManager.card,
                child: Row(
                  children: [
                    BmOilDrop(progress: _progress),
                    Expanded(
                      child: Slider(
                        value: _progress,
                        onChanged: (value) => setState(() => _progress = value),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}
