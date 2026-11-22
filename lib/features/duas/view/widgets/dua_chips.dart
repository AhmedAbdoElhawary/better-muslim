import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/sliding_selection.dart';
import 'package:better_muslim/features/duas/model/dua.dart';
import 'package:better_muslim/features/duas/view_model/duas_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// 4.14's chips from the start edge, saved last and off screen
class DuaChips extends ConsumerWidget {
  const DuaChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(duaChipProvider);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: REdgeInsetsDirectional.only(start: SpaceManager.s4, end: SpaceManager.s4),
      child: SlidingSelection(
        selected: selected.index,
        highlight: const _Fill(),
        layout: (children) => Row(
          children: [
            for (final (i, chip) in children.indexed) ...[
              if (i > 0) const RSizedBox.horizontal(SpaceManager.s2),
              chip,
            ],
          ],
        ),
        children: [
          for (final chip in DuaChip.values)
            _DuaChip(
              chip: chip,
              selected: chip == selected,
              onTap: () {
                BmHaptics.selection();
                ref.read(duaChipProvider.notifier).select(chip);
              },
            ),
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
                borderRadius: BorderRadius.circular(RadiusManager.pill.r),
                border: Border.all(
                  color: context.getColor(
                    selected ? ThemeEnum.transparent : ThemeEnum.outlineStrong,
                  ),
                ),
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

/// the selected chip's fill, the chip's height inside the 44 pt target
class _Fill extends StatelessWidget {
  const _Fill();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RSizedBox(
        height: SizeManager.chip,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.getColor(ThemeEnum.primary),
            borderRadius: BorderRadius.circular(RadiusManager.pill.r),
          ),
        ),
      ),
    );
  }
}
