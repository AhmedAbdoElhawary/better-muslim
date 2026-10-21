import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 4.30's background picks, a 44 pt circle over its name, ringed in primary when picked. the
/// bookmark menu's colors use it too
class Swatch extends StatelessWidget {
  const Swatch({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.fill,
    super.key,
  });

  /// a StringsManager key
  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// what the circle shows, it may bring its own theme
  final Widget fill;

  @override
  Widget build(BuildContext context) {
    final ring = SizeManager.shareSwatchGapRing.r + SizeManager.shareSwatchRing.r;
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: bmMotion(MediaQuery.disableAnimationsOf(context), BmMotion.micro),
              decoration: BoxDecoration(
                shape: BoxShape.circle,

                /// flutter paints each shadow over the one before, css the other way round
                boxShadow: [
                  if (selected) ...[
                    BoxShadow(color: context.getColor(ThemeEnum.primary), spreadRadius: ring),
                    BoxShadow(
                      color: context.getColor(ThemeEnum.raised),
                      spreadRadius: SizeManager.shareSwatchGapRing.r,
                    ),
                  ],
                  BoxShadow(
                    color: context.getColor(ThemeEnum.outline),
                    spreadRadius: SizeManager.divider.r,
                  ),
                ],
              ),
              child: ClipOval(
                child: RSizedBox.square(dimension: SizeManager.shareSwatch, child: fill),
              ),
            ),
            const RSizedBox.vertical(SpaceManager.shareSwatchLabelGap),
            RegularText(
              label,
              fontSize: FontSizeManager.label,
              color: selected ? ThemeEnum.text : ThemeEnum.text2,
            ),
          ],
        ),
      ),
    );
  }
}
