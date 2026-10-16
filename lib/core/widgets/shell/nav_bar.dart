import 'dart:math';

import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NavBar extends StatelessWidget {
  const NavBar({required this.index, required this.onTap, super.key});
  final int index;
  final ValueChanged<int> onTap;

  static const _tabs = [
    (BmIconName.home, StringsManager.tabHome),
    (BmIconName.prayer, StringsManager.tabPrayer),
    (BmIconName.quran, StringsManager.tabQuran),
    (BmIconName.azkar, StringsManager.tabAzkar),
    (BmIconName.settings, StringsManager.tabMore),
  ];

  @override
  Widget build(BuildContext context) {
    // TODO: pass the in-app reduce motion switch once settings exist (milestone 2)
    final reduceMotion = context.reduceMotion(false);

    /// the design's 30 pt sits 4 pt inside the 34 pt home indicator inset
    final bottom = max(SpaceManager.s2, MediaQuery.paddingOf(context).bottom - SpaceManager.s1);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.getColor(ThemeEnum.surface),
        border: Border(top: BorderSide(color: context.getColor(ThemeEnum.outline))),
      ),
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
    required this.onTap,
  });
  final BmIconName icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? ThemeEnum.primary : ThemeEnum.text2;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RSizedBox.square(
              dimension: SizeManager.navPillH,
              child: Center(
                child: BmIcon(
                  icon,
                  filled: selected,
                  size: SizeManager.icon.r,
                  color: context.getColor(color),
                ),
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
