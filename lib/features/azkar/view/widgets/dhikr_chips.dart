import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/features/azkar/model/tasbih_dhikr.dart';
import 'package:better_muslim/features/azkar/view_model/tasbih_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 4.08's three chips, centered, scrolling sideways once large text no longer fits them
class DhikrChips extends ConsumerWidget {
  const DhikrChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(tasbihControllerProvider.select((state) => state?.dhikr));
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: REdgeInsets.symmetric(horizontal: SpaceManager.s4),
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth - 2 * SpaceManager.s4.r),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final (i, dhikr) in tasbihDhikr.indexed) ...[
                if (i > 0) const RSizedBox.horizontal(SpaceManager.chipGap),
                _DhikrChip(
                  dhikr: dhikr,
                  selected: i == selected,
                  onTap: () {
                    BmHaptics.selection();
                    ref.read(tasbihControllerProvider.notifier).select(i);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DhikrChip extends ConsumerWidget {
  const _DhikrChip({required this.dhikr, required this.selected, required this.onTap});
  final TasbihDhikr dhikr;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: SizeManager.hit.r),
          child: Center(
            child: Container(
              constraints: BoxConstraints(minHeight: SizeManager.chip.r),
              padding: REdgeInsets.symmetric(horizontal: SpaceManager.chipSide),
              decoration: BoxDecoration(
                color: selected ? context.getColor(ThemeEnum.primaryContainer) : null,
                borderRadius: BorderRadius.circular(RadiusManager.pill.r),
                border: Border.all(
                  color: selected
                      ? context.getColor(ThemeEnum.primary).withValues(alpha: .4)
                      : context.getColor(ThemeEnum.outline),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RegularText(
                    isArabic ? dhikr.arabicName : dhikr.name,
                    translate: false,
                    fontSize: FontSizeManager.dhikrChip,
                  ),
                  const RSizedBox.horizontal(SpaceManager.s1),
                  RegularText(
                    context.formatDigits('${dhikr.target}', digits),
                    translate: false,
                    fontSize: FontSizeManager.dhikrChip,
                    color: ThemeEnum.text2,
                    tabularFigures: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
