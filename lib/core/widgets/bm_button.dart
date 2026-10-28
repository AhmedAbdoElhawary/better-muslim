import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/design/bm_tokens.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 4.11's full width buttons. the adhan screen and onboarding use them too
class BmButton extends StatelessWidget {
  const BmButton.primary(
    this.label, {
    required this.onPressed,
    this.args = const {},
    this.busy = false,
    super.key,
  }) : _filled = true,
       _text = null;

  const BmButton.secondary(
    this.label, {
    required this.onPressed,
    this.args = const {},
    this.busy = false,
    super.key,
  }) : _filled = false,
       _text = null;

  /// 01 Actions' text button, no fill and no border
  const BmButton.text(
    this.label, {
    required this.onPressed,
    ThemeEnum color = ThemeEnum.primary,
    this.args = const {},
    this.busy = false,
    super.key,
  }) : _filled = false,
       _text = color;

  /// a StringsManager key
  final String label;
  final Map<String, String> args;
  final VoidCallback onPressed;

  /// taps are ignored and the label dims while the action runs
  final bool busy;
  final bool _filled;
  final ThemeEnum? _text;

  @override
  Widget build(BuildContext context) {
    final textColor = _filled ? ThemeEnum.onPrimary : _text ?? ThemeEnum.text;
    final radius = BorderRadius.circular(RadiusManager.md.r);
    return Semantics(
      button: true,
      enabled: !busy,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: SizeManager.buttonLarge.r),
        child: Material(
          color: _filled ? context.getColor(ThemeEnum.primary) : null,
          type: _filled ? MaterialType.canvas : MaterialType.transparency,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: _filled || _text != null
                ? BorderSide.none
                : BorderSide(color: context.getColor(ThemeEnum.outlineStrong)),
          ),
          child: InkWell(
            onTap: busy ? null : onPressed,
            borderRadius: radius,
            highlightColor: context.getColor(textColor).withValues(alpha: BmOpacity.pressed),

            /// in a row with room above it, a plain center would fill the screen's height
            child: Center(
              heightFactor: 1,
              child: AnimatedOpacity(
                opacity: busy ? BmOpacity.disabled : 1,
                duration: BmMotion.micro,
                child: MediumText(label, args: args, color: textColor, textAlign: TextAlign.center),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
