import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/adhan_recording.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/nav_row.dart';
import 'package:better_muslim/core/widgets/segmented.dart';
import 'package:better_muslim/features/notifications/presentation/view/widgets/recording_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 4.12's row: the prayer, today's time and adhan, tone or silent (FR-026)
class PrayerSoundRow extends ConsumerWidget {
  const PrayerSoundRow(this.prayer, {super.key});
  final Prayer prayer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sound = ref.watch(
      settingsProvider.select((settings) => settings.value?.soundOf(prayer) ?? PrayerSound.tone),
    );
    final time = ref.watch(todayTimesProvider.select((times) => times?.timeOf(prayer)));
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: SizeManager.pickerRow.r),
      child: OnlyPadding(
        start: SpaceManager.s4,
        end: SpaceManager.segmentSmallSide,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  RegularText(
                    prayer.nameKey,
                    font: FontEnum.display,
                    fontSize: FontSizeManager.notifPrayerName,
                  ),
                  if (time != null)
                    RegularText(
                      context.formatTime(time, digits),
                      translate: false,
                      fontSize: FontSizeManager.label,
                      color: ThemeEnum.text2,
                      tabularFigures: true,
                    ),
                ],
              ),
            ),
            const RSizedBox.horizontal(SpaceManager.s3),
            Segmented(
              values: PrayerSound.values,
              selected: sound,
              small: true,
              labelOf: (sound) => switch (sound) {
                PrayerSound.adhan => StringsManager.soundAdhan,
                PrayerSound.tone => StringsManager.soundTone,
                PrayerSound.silent => StringsManager.soundSilent,
              },
              onChanged: (sound) =>
                  ref.read(databaseProvider).updateSettings(soundChoice(prayer, sound)),
            ),
          ],
        ),
      ),
    );
  }
}

/// under a prayer on adhan, its recording opens the adhan sound sheet (FR-027)
class RecordingRow extends ConsumerWidget {
  const RecordingRow(this.prayer, {super.key});
  final Prayer prayer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recording = ref.watch(
      settingsProvider.select(
        (settings) => settings.value?.recordingOf(prayer) ?? AdhanRecording.makkah,
      ),
    );
    return NavRow(
      title: StringsManager.adhanSound,
      value: recording.isShort ? StringsManager.recordingShort : StringsManager.recordingFull,
      args: {'recording': context.tr(recording.nameKey)},
      onTap: () => showRecordingSheet(context, prayer),
    );
  }
}
