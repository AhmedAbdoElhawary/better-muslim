import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/styles_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/sheet/bm_sheet.dart';
import 'package:better_muslim/core/widgets/sheet/sheet_title.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the store's check: 0 to 30 in steps of 5, 0 is off
const _step = 5;
const _most = 30;
const _overlayAlpha = .18;

Future<void> showReminderSheet(BuildContext context) =>
    showBmSheet(context, builder: (_) => const _ReminderSheet());

/// the components' slider. kept when the sheet closes, so a drag doesn't remake the schedule six
/// times (R9)
class _ReminderSheet extends ConsumerStatefulWidget {
  const _ReminderSheet();

  @override
  ConsumerState<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends ConsumerState<_ReminderSheet> {
  late final AppDatabase _db;
  late final int _saved;
  late int _minutes;

  @override
  void initState() {
    super.initState();

    /// read here, ref can't be read any more when dispose writes the value
    _db = ref.read(databaseProvider);
    _saved = _minutes = ref.read(settingsProvider).value?.reminderMinutes ?? 10;
  }

  @override
  void dispose() {
    if (_minutes != _saved) {
      _db.updateSettings(SettingsCompanion(reminderMinutes: Value(_minutes)));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final label = _minutes == 0
        ? context.tr(StringsManager.reminderOff)
        : context.tr(StringsManager.reminderValue, {
            'minutes': context.formatDigits('$_minutes', digits),
          });
    final primary = context.getColor(ThemeEnum.primary);
    return SafeArea(
      top: false,
      child: BottomPadding(
        padding: SpaceManager.s6,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetTitle(StringsManager.reminderBefore),
            MediumText(label, translate: false, textAlign: TextAlign.center),
            const RSizedBox.vertical(SpaceManager.s2),
            HorizontalPadding(
              padding: SpaceManager.s4,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: SizeManager.sliderTrack.r,
                  activeTrackColor: primary,
                  inactiveTrackColor: context.getColor(ThemeEnum.variant),
                  thumbColor: primary,
                  overlayColor: primary.withValues(alpha: _overlayAlpha),
                  activeTickMarkColor: context.getColor(ThemeEnum.transparent),
                  inactiveTickMarkColor: context.getColor(ThemeEnum.transparent),
                  thumbShape: RoundSliderThumbShape(
                    enabledThumbRadius: SizeManager.sliderThumb.r / 2,
                  ),
                  valueIndicatorColor: context.getColor(ThemeEnum.text),
                  valueIndicatorTextStyle: GetMediumStyle(
                    fontSize: FontSizeManager.label.sp,
                    color: context.getColor(ThemeEnum.bg),
                  ),
                  showValueIndicator: ShowValueIndicator.onDrag,
                ),
                child: Semantics(
                  label: context.tr(StringsManager.reminderBefore),
                  child: Slider(
                    value: _minutes.toDouble(),
                    max: _most.toDouble(),
                    divisions: _most ~/ _step,
                    label: label,
                    onChanged: (value) {
                      final minutes = value.round();
                      if (minutes == _minutes) return;
                      BmHaptics.selection();
                      setState(() => _minutes = minutes);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
