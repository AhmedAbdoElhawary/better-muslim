import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/system/system_channel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the adhan sound sheet's round play button, for the tone of a notification channel
class ToneButton extends StatelessWidget {
  const ToneButton(this.channel, {super.key});
  final String channel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.tr(StringsManager.play),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          BmHaptics.selection();
          SystemChannel.playTone(channel);
        },
        child: RSizedBox.square(
          dimension: SizeManager.playButton,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.getColor(ThemeEnum.variant),
            ),
            child: Center(
              child: BmIcon.ui(
                BmUiIcon.play,
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
