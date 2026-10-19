import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/features/duas/model/dua.dart';
import 'package:better_muslim/features/duas/view_model/duas_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 4.14's chips from the start edge, saved last and off screen
class DuaChips extends ConsumerWidget {
  const DuaChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(duaChipProvider);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: REdgeInsetsDirectional.only(start: SpaceManager.s4, end: SpaceManager.s4),
      child: Row(
        children: [
          for (final (i, chip) in DuaChip.values.indexed) ...[
            if (i > 0) const RSizedBox.horizontal(SpaceManager.s2),
            _DuaChip(
              chip: chip,
              selected: chip == selected,
              onTap: () {
                BmHaptics.selection();
                ref.read(duaChipProvider.notifier).select(chip);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _DuaChip extends StatelessWidget {
  const _DuaChip({required this.chip, required this.selected, required this.onTap});
  final DuaChip chip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
              padding: REdgeInsets.symmetric(horizontal: SpaceManager.duaChipSide),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? context.getColor(ThemeEnum.primary) : null,
                borderRadius: BorderRadius.circular(RadiusManager.pill.r),
                border: selected
                    ? null
                    : Border.all(color: context.getColor(ThemeEnum.outlineStrong)),
              ),
              child: selected
                  ? MediumText(
                      chip.labelKey,
                      fontSize: FontSizeManager.duaChip,
                      color: ThemeEnum.onPrimary,
                    )
                  : RegularText(chip.labelKey, fontSize: FontSizeManager.duaChip),
            ),
          ),
        ),
      ),
    );
  }
}
