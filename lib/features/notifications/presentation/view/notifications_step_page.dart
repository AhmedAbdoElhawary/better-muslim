import 'dart:math' as math;

import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/bm_button.dart';
import 'package:better_muslim/core/widgets/grouped_section.dart';
import 'package:better_muslim/core/widgets/step/step_dots.dart';
import 'package:better_muslim/core/widgets/step/step_reveal.dart';
import 'package:better_muslim/features/notifications/data/notification_scheduler.dart';
import 'package:better_muslim/features/notifications/presentation/view/widgets/prayer_sound_row.dart';
import 'package:better_muslim/features/notifications/presentation/view/widgets/reminder_row.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// 4.12: each prayer's sound before the phone's dialog, so the ask has a purpose (FR-022 to FR-025)
class NotificationsStepPage extends ConsumerStatefulWidget {
  const NotificationsStepPage({super.key});

  @override
  ConsumerState<NotificationsStepPage> createState() => _NotificationsStepPageState();
}

class _NotificationsStepPageState extends ConsumerState<NotificationsStepPage> {
  var _busy = false;

  /// always asks: already allowed gives no dialog, and android 12 still needs its alarms page
  Future<void> _allow() async {
    setState(() => _busy = true);
    final scheduler = ref.read(notificationSchedulerProvider);
    if (await scheduler.askPermission()) await scheduler.askExactAlarms();

    /// after the answer, so the boot sees a grant in its inputs and schedules at once (R10)
    await ref
        .read(databaseProvider)
        .updateSettings(const SettingsCompanion(notificationsAsked: Value(true)));
    if (!mounted) return;
    setState(() => _busy = false);
    _next();
  }

  void _next() => context.push(Routes.onboardingTheme);

  @override
  Widget build(BuildContext context) {
    /// 46 from the bottom as designed, but never under a 3 button navigation bar
    final bottom = math.max(
      SpaceManager.stepButtonsBottom,
      MediaQuery.viewPaddingOf(context).bottom / ScreenUtil().radius(1),
    );
    return StepReveal(
      slot: StepSlot.background,
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const RSizedBox.vertical(SpaceManager.stepDotsTop),
                    const StepDots(step: 2),
                    const RSizedBox.vertical(
                      SpaceManager.stepContentTop - SpaceManager.stepDotsTop - SizeManager.stepDot,
                    ),
                    HorizontalPadding(
                      padding: SpaceManager.stepContentSide,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StepReveal(
                            slot: StepSlot.title,
                            child: Semantics(
                              header: true,
                              child: const RegularText(
                                StringsManager.notifTitle,
                                font: FontEnum.display,
                                fontSize: FontSizeManager.onboardingTitle,
                                height: LineHeightManager.onboardingTitle,
                              ),
                            ),
                          ),
                          const RSizedBox.vertical(SpaceManager.stepTitleGap),
                          const StepReveal(
                            slot: StepSlot.body,
                            child: RegularText(
                              StringsManager.notifBody,
                              fontSize: FontSizeManager.body,
                              height: LineHeightManager.stepBody,
                              color: ThemeEnum.text2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const RSizedBox.vertical(SpaceManager.stepBodyCardGap),
                    const HorizontalPadding(
                      padding: SpaceManager.stepCardSide,
                      child: StepReveal(
                        slot: StepSlot.cards,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _SoundCard(),
                            RSizedBox.vertical(SpaceManager.stepCardGap),
                            GroupedSection(children: [ReminderRow(icon: true)]),
                          ],
                        ),
                      ),
                    ),
                    const RSizedBox.vertical(SpaceManager.s4),
                  ],
                ),
              ),
            ),
            StepReveal(
              slot: StepSlot.buttons,
              child: OnlyPadding(
                start: SpaceManager.stepButtonsSide,
                end: SpaceManager.stepButtonsSide,
                bottom: bottom,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BmButton.primary(
                      StringsManager.allowNotifications,
                      busy: _busy,
                      onPressed: _allow,
                    ),
                    const RSizedBox.vertical(SpaceManager.notificationsButtonGap),
                    BmButton.text(StringsManager.notNow, busy: _busy, onPressed: _next),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoundCard extends StatelessWidget {
  const _SoundCard();

  @override
  Widget build(BuildContext context) {
    return GroupedSection(children: [for (final prayer in Prayer.values) PrayerSoundRow(prayer)]);
  }
}
