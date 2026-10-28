import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:flutter/material.dart';

/// MOTION 04: a changed digit slides up out of its slot while the new one slides in from below
class RollingDigit extends StatelessWidget {
  const RollingDigit(this.digit, {this.child, super.key});
  final String digit;

  /// the digit in another style, the countdown's when null
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final text = KeyedSubtree(
      key: ValueKey(digit),
      child:
          child ??
          MediumText(
            digit,
            fontSize: FontSizeManager.countdown,
            color: ThemeEnum.primary,
            translate: false,
            tabularFigures: true,
          ),
    );

    /// no switcher at all, its controllers keep the 300 ms they were made with
    if (MediaQuery.disableAnimationsOf(context)) return text;
    return ClipRect(
      child: AnimatedSwitcher(
        duration: BmMotion.standard,
        switchInCurve: BmMotion.standardCurve,
        switchOutCurve: BmMotion.standardCurve,
        transitionBuilder: (child, animation) {
          /// the old digit plays the animation backwards, so it needs the opposite start
          final incoming = child.key == ValueKey(digit);
          return SlideTransition(
            position: Tween(
              begin: Offset(0, incoming ? 1 : -1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
        layoutBuilder: (current, previous) =>
            Stack(alignment: Alignment.center, children: [...previous, ?current]),
        child: text,
      ),
    );
  }
}
