import 'package:better_muslim/core/audio/ui_sounds.dart';
import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// a grouped list row with the components' 52 x 32 toggle, the whole row is the hit target
class ToggleRow extends StatelessWidget {
  const ToggleRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.args = const {},
    super.key,
  });

  /// StringsManager keys, args fill the subtitle
  final String title;
  final String? subtitle;
  final Map<String, String> args;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    return Semantics(
      toggled: value,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          BmHaptics.selection();
          BmSounds.toggle();
          onChanged(!value);
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: SizeManager.linkRow.r),
          child: SymmetricPadding(
            horizontal: SpaceManager.s4,
            vertical: SpaceManager.s2,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MediumText(title),
                      if (subtitle != null) ...[
                        const RSizedBox.vertical(SpaceManager.shortcutTextGap),
                        RegularText(subtitle, args: args, color: ThemeEnum.text2),
                      ],
                    ],
                  ),
                ),
                const RSizedBox.horizontal(SpaceManager.shortcutGap),
                BmToggle(value),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// the components' 52 x 32 toggle, drawn only, the row around it takes the tap
class BmToggle extends StatelessWidget {
  const BmToggle(this.value, {super.key});
  final bool value;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context) ? Duration.zero : BmMotion.micro;
    final knob = value ? SizeManager.toggleKnobOn : SizeManager.toggleKnobOff;

    /// the knob sits 4 in when on and 6 in when off, both centered in the 32 track
    final inset = (SizeManager.toggleH - knob) / 2;
    return AnimatedContainer(
      duration: duration,
      curve: BmMotion.standardCurve,
      width: SizeManager.toggleW.r,
      height: SizeManager.toggleH.r,
      decoration: BoxDecoration(
        color: context.getColor(value ? ThemeEnum.primary : ThemeEnum.variant),
        borderRadius: BorderRadius.circular(RadiusManager.pill.r),
        border: value
            ? null
            : Border.all(
                color: context.getColor(ThemeEnum.outlineStrong),
                width: SizeManager.toggleRingOff.r,
              ),
      ),
      child: AnimatedAlign(
        duration: duration,
        curve: BmMotion.standardCurve,
        alignment: value ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
        child: AllPadding(
          padding: value ? inset : inset - SizeManager.toggleRingOff,
          child: AnimatedContainer(
            duration: duration,
            curve: BmMotion.standardCurve,
            width: knob.r,
            height: knob.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.getColor(value ? ThemeEnum.onPrimary : ThemeEnum.outlineStrong),
            ),
          ),
        ),
      ),
    );
  }
}
