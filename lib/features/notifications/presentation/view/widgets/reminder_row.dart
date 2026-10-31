import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/nav_row.dart';
import 'package:better_muslim/features/notifications/presentation/view/widgets/reminder_sheet.dart';
import 'package:better_muslim/features/notifications/presentation/view/widgets/tone_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the reminder's minutes, the reminder sheet on a tap. 4.12 shows it with the adhan icon
class ReminderRow extends ConsumerWidget {
  const ReminderRow({this.icon = false, this.tone = false, super.key});

  final bool icon;

  /// its play button, android only since ios reminders come silent (FR-035)
  final bool tone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final minutes = ref.watch(
      settingsProvider.select((settings) => settings.value?.reminderMinutes ?? 10),
    );
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    return NavRow(
      startFlex: 4,
      endFlex: 3,
      icon: icon ? BmIcon(BmIconName.adhan, size: SizeManager.iconList.r) : null,
      title: StringsManager.reminderBefore,
      value: minutes == 0 ? StringsManager.reminderOff : StringsManager.reminderValue,
      args: {'minutes': context.formatDigits('$minutes', digits)},
      trailing: tone && minutes > 0 && defaultTargetPlatform == TargetPlatform.android
          ? const ToneButton('reminders')
          : null,
      onTap: () => showReminderSheet(context),
    );
  }
}
