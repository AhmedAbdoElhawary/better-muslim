import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/hijri/hijri_date.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/design/bm_tokens.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/bm_button.dart';
import 'package:better_muslim/core/widgets/sheet/bm_sheet.dart';
import 'package:better_muslim/core/widgets/sheet/sheet_title.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// the store's check, -2 to 2 days
const _most = 2;

extension AdjustmentFormat on BuildContext {
  /// "+1 day", "−2 days", "0 days"
  String adjustment(int adjust, Digits digits) => tr(StringsManager.days, {
    'sign': adjust > 0 ? '+' : (adjust < 0 ? '−' : ''),
    'n': formatDigits('${adjust.abs()}', digits),
  });
}

Future<void> showAdjustmentSheet(BuildContext context) => showBmSheet(
  context,
  title: const SheetTitle(
    StringsManager.hijriDateAdjustment,
    subtitle: StringsManager.adjustmentBody,
  ),
  builder: (_) => const _AdjustmentSheet(),
);

/// a step from −2 to +2 shows today's hijri date at once, only save keeps it (FR-024)
class _AdjustmentSheet extends ConsumerStatefulWidget {
  const _AdjustmentSheet();

  @override
  ConsumerState<_AdjustmentSheet> createState() => _AdjustmentSheetState();
}

class _AdjustmentSheetState extends ConsumerState<_AdjustmentSheet> {
  late int _adjust = ref.read(settingsProvider).value?.hijriAdjust ?? 0;

  void _step(int by) {
    BmHaptics.selection();
    setState(() => _adjust += by);
  }

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(todayProvider);
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    return SingleChildScrollView(
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const RSizedBox.vertical(SpaceManager.s6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StepButton(icon: BmUiIcon.minus, onTap: _adjust > -_most ? () => _step(-1) : null),
                const RSizedBox.horizontal(SpaceManager.stepperGap),
                Flexible(
                  child: Semantics(
                    liveRegion: true,
                    child: Column(
                      children: [
                        SemiBoldText(
                          context.adjustment(_adjust, digits),
                          translate: false,
                          tabularFigures: true,
                        ),
                        const RSizedBox.vertical(SpaceManager.rowLineGap),
                        RegularText(
                          context.hijriFull(HijriDate.of(today, _adjust), digits),
                          translate: false,
                          color: ThemeEnum.text2,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const RSizedBox.horizontal(SpaceManager.stepperGap),
                _StepButton(icon: BmUiIcon.plus, onTap: _adjust < _most ? () => _step(1) : null),
              ],
            ),
            const RSizedBox.vertical(SpaceManager.s6),
            OnlyPadding(
              start: SpaceManager.s5,
              end: SpaceManager.s5,
              bottom: SpaceManager.s6,
              child: BmButton.primary(
                StringsManager.save,
                onPressed: () {
                  ref
                      .read(databaseProvider)
                      .updateSettings(SettingsCompanion(hijriAdjust: Value(_adjust)));
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});
  final BmUiIcon icon;

  /// null at −2 and +2
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: icon == BmUiIcon.minus ? '−' : '+',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedOpacity(
          duration: BmMotion.standard,
          opacity: onTap == null ? BmOpacity.disabled : 1,
          child: RSizedBox.square(
            dimension: SizeManager.playButton,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.getColor(ThemeEnum.variant),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: BmIcon.ui(
                  icon,
                  size: SizeManager.icon.r,
                  color: context.getColor(ThemeEnum.text),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
