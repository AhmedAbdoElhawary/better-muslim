import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/title_hero.dart';
import 'package:better_muslim/core/widgets/toggle_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// above this the value goes under the title, like the prayer rows stack
const _stackAt = 1.4;

/// the components' 52 pt list row: icon, title, then the value and chevron or a toggle. the whole
/// row is the hit target
class NavRow extends StatelessWidget {
  const NavRow({
    required this.title,
    this.translateTitle = true,
    this.icon,
    this.value,
    this.args = const {},
    this.translateValue = true,
    this.toggled,
    this.onTap,
    this.heroTag,
    this.startFlex = 2,
    this.endFlex = 3,
    super.key,
  });

  /// a StringsManager key, or a name like a credit's source with translateTitle false
  final String title;
  final bool translateTitle;
  final int startFlex;
  final int endFlex;

  /// a BmIcon at the list size, tinted text2 here
  final Widget? icon;

  /// a StringsManager key with its args, or the text itself with translateValue false
  final String? value;
  final Map<String, String> args;
  final bool translateValue;

  /// set for a toggle row, the tap then flips it with the selection haptic
  final bool? toggled;

  /// null draws the value with no chevron and no tap (Version)
  final VoidCallback? onTap;

  /// the route its title flies into, see TitleHero
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    final value = this.value;
    final toggled = this.toggled;
    final onTap = this.onTap;
    final stacked = MediaQuery.textScalerOf(context).scale(1) > _stackAt;

    /// a new value after a sheet closes crossfades in place, no slide
    final valueText = value == null
        ? null
        : AnimatedSwitcher(
            duration: BmMotion.micro,
            layoutBuilder: (current, previous) => Stack(
              alignment: stacked
                  ? AlignmentDirectional.centerStart
                  : AlignmentDirectional.centerEnd,
              children: [...previous, ?current],
            ),
            child: RegularText(
              value,
              key: ValueKey('$value$args'),
              args: args,
              translate: translateValue,
              fontSize: FontSizeManager.secondary,
              color: ThemeEnum.text2,
              textAlign: stacked ? null : TextAlign.end,
            ),
          );
    final text = RegularText(this.title, translate: translateTitle, fontSize: FontSizeManager.body);
    final title = heroTag == null
        ? text
        : Align(
            alignment: AlignmentDirectional.centerStart,
            child: TitleHero(tag: heroTag, child: text),
          );
    return MergeSemantics(
      child: Semantics(
        button: onTap != null && toggled == null,
        toggled: toggled,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap == null
              ? null
              : () {
                  if (toggled != null) BmHaptics.selection();
                  onTap();
                },
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: SizeManager.listRow.r),
            child: OnlyPadding(
              start: SpaceManager.listRowStart,
              end: SpaceManager.listRowEnd,
              top: SpaceManager.s2,
              bottom: SpaceManager.s2,
              child: Row(
                children: [
                  if (icon != null) ...[
                    IconTheme.merge(
                      data: IconThemeData(color: context.getColor(ThemeEnum.text2)),
                      child: icon,
                    ),
                    const RSizedBox.horizontal(SpaceManager.listRowGap),
                  ],
                  Expanded(
                    flex: startFlex,
                    child: stacked && valueText != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              title,
                              const RSizedBox.vertical(SpaceManager.rowLineGap),
                              valueText,
                            ],
                          )
                        : title,
                  ),
                  if (!stacked && valueText != null) ...[
                    const RSizedBox.horizontal(SpaceManager.listRowGap),
                    Expanded(flex: endFlex, child: valueText),
                  ],
                  if (toggled != null) ...[
                    const RSizedBox.horizontal(SpaceManager.listRowGap),
                    BmToggle(toggled),
                  ] else if (onTap != null) ...[
                    const RSizedBox.horizontal(SpaceManager.listRowGap),
                    const _Chevron(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron();

  @override
  Widget build(BuildContext context) {
    return Transform.flip(
      flipX: Directionality.of(context) == TextDirection.rtl,
      child: BmIcon.ui(
        BmUiIcon.forward,
        size: SizeManager.iconInline.r,
        color: context.getColor(ThemeEnum.text3),
      ),
    );
  }
}
