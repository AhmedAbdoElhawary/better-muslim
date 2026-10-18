import 'package:better_muslim/core/resources/design/bm_tokens.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 4.11's full width buttons. the adhan screen and onboarding use them too
class BmButton extends StatelessWidget {
  const BmButton.primary(this.label, {required this.onPressed, this.busy = false, super.key})
    : _filled = true;

  const BmButton.secondary(this.label, {required this.onPressed, this.busy = false, super.key})
    : _filled = false;

  /// a StringsManager key
  final String label;
  final VoidCallback onPressed;

  /// taps are ignored and the label dims while the action runs
  final bool busy;
  final bool _filled;

  @override
  Widget build(BuildContext context) {
    final textColor = _filled ? ThemeEnum.onPrimary : ThemeEnum.text;
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
            side: _filled
                ? BorderSide.none
                : BorderSide(color: context.getColor(ThemeEnum.outlineStrong)),
          ),
          child: InkWell(
            onTap: busy ? null : onPressed,
            borderRadius: radius,
            highlightColor: context.getColor(textColor).withValues(alpha: BmOpacity.pressed),
            child: Center(
              child: Opacity(
                opacity: busy ? BmOpacity.disabled : 1,
                child: MediumText(label, color: textColor, textAlign: TextAlign.center),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
