import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 4.18's tools and 4.22's ayah actions: the icon over its label on a raised tile
class QuranTile extends StatelessWidget {
  const QuranTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.height = SizeManager.quranTool,
    this.radius = RadiusManager.quranTool,
    super.key,
  });

  final BmIcon icon;

  /// a StringsManager key
  final String label;
  final VoidCallback? onTap;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.getColor(ThemeEnum.surface),
            borderRadius: BorderRadius.circular(radius.r),
            boxShadow: [BoxShadow(color: context.getColor(ThemeEnum.outline), spreadRadius: 1)],
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: height.r),
            child: VerticalPadding(
              padding: SpaceManager.s2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconTheme(
                    data: IconThemeData(color: context.getColor(ThemeEnum.primary)),
                    child: icon,
                  ),
                  const RSizedBox.vertical(SpaceManager.quranToolIconGap),
                  RegularText(label, fontSize: FontSizeManager.label, maxLines: 1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
