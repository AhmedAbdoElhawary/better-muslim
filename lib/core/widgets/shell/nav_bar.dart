import 'dart:math';

import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NavBar extends StatelessWidget {
  const NavBar({required this.index, required this.onTap, this.badge, super.key});
  final int index;
  final ValueChanged<int> onTap;

  /// the tab with the components' dot, null for none
  final int? badge;

  static const _tabs = [
    (BmIconName.home, StringsManager.tabHome),
    (BmIconName.prayer, StringsManager.tabPrayer),
    (BmIconName.quran, StringsManager.tabQuran),
    (BmIconName.azkar, StringsManager.tabAzkar),
    (BmIconName.settings, StringsManager.tabMore),
  ];

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    /// the design's 30 pt sits 4 pt inside the 34 pt home indicator inset
    final bottom = max(SpaceManager.s2, MediaQuery.paddingOf(context).bottom - SpaceManager.s1);
    return Glass(
      border: Border(top: BorderSide(color: context.getColor(ThemeEnum.outline))),
      child: OnlyPadding(
        top: SpaceManager.s2,
        start: SpaceManager.navBarSide,
        end: SpaceManager.navBarSide,
        bottom: bottom,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cell = constraints.maxWidth / _tabs.length;
            return Stack(
              children: [
                AnimatedPositionedDirectional(
                  duration: reduceMotion ? Duration.zero : BmMotion.standard,
                  curve: BmMotion.standardCurve,
                  top: 0,
                  start: cell * index + (cell - SizeManager.navPillW.r) / 2,
                  width: SizeManager.navPillW.r,
                  height: SizeManager.navPillH.r,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.getColor(ThemeEnum.primaryContainer),
                      borderRadius: BorderRadius.circular(RadiusManager.pill.r),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (final (i, (icon, label)) in _tabs.indexed)
                      Expanded(
                        child: _NavItem(
                          icon: icon,
                          label: label,
                          selected: i == index,
                          badge: i == badge,
                          onTap: () => onTap(i),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.badge,
    required this.onTap,
  });
  final BmIconName icon;
  final String label;
  final bool selected;
  final bool badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? ThemeEnum.primary : ThemeEnum.text2;
    return Semantics(
      button: true,
      selected: selected,
      value: badge ? context.tr(StringsManager.newAzkarSet) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RSizedBox(
              width: SizeManager.navPillW,
              height: SizeManager.navPillH,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  BmIcon(
                    icon,
                    filled: selected,
                    size: SizeManager.icon.r,
                    color: context.getColor(color),
                  ),
                  if (badge) const _Badge(),
                ],
              ),
            ),
            const RSizedBox.vertical(SpaceManager.navLabelGap),
            if (selected)
              SemiBoldText(label, fontSize: FontSizeManager.tabLabelSelected, color: color)
            else
              RegularText(label, fontSize: FontSizeManager.tabLabel, color: color),
          ],
        ),
      ),
    );
  }
}

/// the components' "new azkar set" dot on the pill's top end
class _Badge extends StatelessWidget {
  const _Badge();

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      top: SpaceManager.navBadgeTop.r,
      end: SpaceManager.navBadgeEnd.r,
      child: Container(
        width: SizeManager.navBadge.r,
        height: SizeManager.navBadge.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.getColor(ThemeEnum.accent),
          boxShadow: [
            BoxShadow(
              color: context.getColor(ThemeEnum.surface),
              spreadRadius: SizeManager.navBadgeRing.r,
            ),
          ],
        ),
      ),
    );
  }
}
