import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// the components' "Selected (picker)" list row, with the value at the end like the focused one
class PickerRow extends StatelessWidget {
  const PickerRow({
    required this.title,
    required this.selected,
    required this.onTap,
    this.args = const {},
    this.subtitle,
    this.value,
    this.trailing,
    this.font = FontEnum.body,
    super.key,
  });

  /// StringsManager keys
  final String title;
  final Map<String, String> args;
  final String? subtitle;
  final String? value;

  /// in place of the value, like a download's size or progress
  final Widget? trailing;

  /// a font row writes its name in itself
  final FontEnum font;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    final value = this.value;
    final trailing = this.trailing;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          BmHaptics.selection();
          onTap();
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: SizeManager.pickerRow.r),
          child: SymmetricPadding(
            horizontal: SpaceManager.s4,
            vertical: SpaceManager.s2,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RegularText(title, args: args, font: font, fontSize: FontSizeManager.body),
                      if (subtitle != null) ...[
                        const RSizedBox.vertical(SpaceManager.rowLineGap),
                        RegularText(
                          subtitle,
                          fontSize: FontSizeManager.rowSubtitle,
                          color: ThemeEnum.text2,
                        ),
                      ],
                    ],
                  ),
                ),
                if (value != null) ...[
                  const RSizedBox.horizontal(SpaceManager.s2),
                  RegularText(value, fontSize: FontSizeManager.rowValue, color: ThemeEnum.text2),
                ],
                if (trailing != null) ...[const RSizedBox.horizontal(SpaceManager.s2), trailing],
                if (selected) ...[
                  const RSizedBox.horizontal(SpaceManager.s3),
                  RSizedBox.square(
                    dimension: SizeManager.pickerCheck,
                    child: AnimatedOpacity(
                      opacity: selected ? 1 : 0,
                      duration: BmMotion.micro,
                      child: const _Check(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: context.getColor(ThemeEnum.primary), shape: BoxShape.circle),
      child: Center(
        child: BmIcon.ui(
          BmUiIcon.check,
          size: SizeManager.iconChip.r,
          color: context.getColor(ThemeEnum.onPrimary),
        ),
      ),
    );
  }
}
