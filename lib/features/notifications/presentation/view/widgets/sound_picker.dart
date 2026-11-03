import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// a row of the adhan and tone sheets: the radio, the name and its play button
class SoundRow extends StatelessWidget {
  const SoundRow({
    required this.title,
    required this.picked,
    required this.onTap,
    required this.trailing,
    this.subtitle,
    this.subtitleArgs = const {},
    super.key,
  });

  final String title;
  final String? subtitle;
  final Map<String, String> subtitleArgs;
  final bool picked;
  final VoidCallback onTap;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: picked,
      inMutuallyExclusiveGroup: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: SizeManager.pickerRow.r),
          child: SymmetricPadding(
            horizontal: SpaceManager.s6,
            vertical: SpaceManager.s1,
            child: Row(
              children: [
                _Radio(picked),
                const RSizedBox.horizontal(SpaceManager.listRowGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RegularText(title, fontSize: FontSizeManager.body),
                      if (subtitle case final subtitle?) ...[
                        const RSizedBox.vertical(SpaceManager.rowLineGap),
                        RegularText(
                          subtitle,
                          args: subtitleArgs,
                          fontSize: FontSizeManager.rowSubtitle,
                          color: ThemeEnum.text2,
                        ),
                      ],
                    ],
                  ),
                ),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio(this.picked);
  final bool picked;

  @override
  Widget build(BuildContext context) {
    return RSizedBox.square(
      dimension: SizeManager.radio,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: context.getColor(picked ? ThemeEnum.primary : ThemeEnum.outlineStrong),
            width: (picked ? SizeManager.radioRing : SizeManager.radioRingOff).r,
          ),
        ),
        child: picked
            ? Center(
                child: RSizedBox.square(
                  dimension: SizeManager.radioDot,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.getColor(ThemeEnum.primary),
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

/// the round play button, child in place of the icon for a download's progress
class SoundPlayButton extends StatelessWidget {
  const SoundPlayButton({
    required this.label,
    required this.onTap,
    this.icon = BmUiIcon.play,
    this.child,
    super.key,
  });

  final String label;
  final BmUiIcon icon;
  final VoidCallback onTap;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.tr(label),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: RSizedBox.square(
          dimension: SizeManager.playButton,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.getColor(ThemeEnum.variant),
            ),
            child: Center(
              child:
                  child ??
                  BmIcon.ui(
                    icon,
                    size: SizeManager.iconList.r,
                    color: context.getColor(ThemeEnum.text),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
