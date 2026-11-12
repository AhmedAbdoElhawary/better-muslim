import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/title_hero.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// a 64 pt row of home's shortcuts card and the azkar tab. it grows with large text instead of clipping
class ShortcutRow extends StatelessWidget {
  const ShortcutRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.args = const {},
    this.divider = false,
    this.heroTag,
    super.key,
  });
  final BmIconName icon;
  final String title;
  final String subtitle;
  final Map<String, String> args;
  final VoidCallback onTap;

  /// the line under every row but the last
  final bool divider;

  /// the route its title flies into, see TitleHero
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: divider
                ? Border(bottom: BorderSide(color: context.getColor(ThemeEnum.outline)))
                : null,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: SizeManager.linkRow.r),
            child: SymmetricPadding(
              horizontal: SpaceManager.s4,
              vertical: SpaceManager.s2,
              child: Row(
                children: [
                  RSizedBox.square(
                    dimension: SizeManager.shortcutIconBox,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: context.getColor(ThemeEnum.primaryContainer),
                        borderRadius: BorderRadius.circular(RadiusManager.shortcutIcon.r),
                      ),
                      child: Center(
                        child: BmIcon(
                          icon,
                          size: SizeManager.iconList.r,
                          color: context.getColor(ThemeEnum.onPrimaryContainer),
                        ),
                      ),
                    ),
                  ),
                  const RSizedBox.horizontal(SpaceManager.shortcutGap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TitleHero(tag: heroTag, child: MediumText(title)),
                        RSizedBox.vertical(
                          isArabic ? SpaceManager.shortcutTextGapAr : SpaceManager.shortcutTextGap,
                        ),
                        RegularText(subtitle, args: args, color: ThemeEnum.text2),
                      ],
                    ),
                  ),
                  const RSizedBox.horizontal(SpaceManager.shortcutGap),
                  BmIcon.ui(
                    rtl ? BmUiIcon.back : BmUiIcon.forward,
                    size: SizeManager.iconChevron.r,
                    color: context.getColor(ThemeEnum.text3),
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
