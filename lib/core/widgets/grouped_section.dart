import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/surface_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the uppercase label over a surface card, a 1 px outline between the rows and none after the last
class GroupedSection extends StatelessWidget {
  const GroupedSection({
    required this.children,
    this.label,
    this.labelSide = SpaceManager.s4,
    super.key,
  });

  /// a StringsManager key
  final String? label;

  /// 4.13's COMING UP sits closer to the card's edge
  final double labelSide;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final label = this.label;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) ...[
          HorizontalPadding(
            padding: labelSide,
            child: RegularText(
              label,
              fontSize: FontSizeManager.sectionLabel,
              letterSpacing: LetterSpacingManager.sectionLabel,
              color: ThemeEnum.text3,
            ),
          ),
          const RSizedBox.vertical(SpaceManager.sectionLabelGap),
        ],
        SurfaceCard(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(RadiusManager.lg.r),
            child: Column(
              children: [
                for (final (index, child) in children.indexed) ...[
                  if (index > 0)
                    Divider(
                      height: SizeManager.divider,
                      thickness: SizeManager.divider,
                      color: context.getColor(ThemeEnum.outline),
                    ),
                  child,
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
