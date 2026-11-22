import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// a child with a new key fades and slides in twice BmMotion.shift from `from`, the box follows its size
class BmSwitcher extends StatelessWidget {
  const BmSwitcher({required this.child, this.from = AxisDirection.down, super.key});

  final Widget child;

  /// left is the start side and right the end, so they flip in rtl
  final AxisDirection from;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final shift = (BmMotion.shift * 2).r;
    final offset = switch (from) {
      AxisDirection.up => Offset(0, -shift),
      AxisDirection.down => Offset(0, shift),
      AxisDirection.left => Offset(rtl ? shift : -shift, 0),
      AxisDirection.right => Offset(rtl ? -shift : shift, 0),
    };
    final switcher = AnimatedSwitcher(
      duration: reduce ? BmMotion.micro : BmMotion.standard,
      switchInCurve: BmMotion.standardCurve,
      switchOutCurve: BmMotion.standardCurve,

      /// passthrough keeps the child's constraints, a full width card stays full width
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.center,
        fit: StackFit.passthrough,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: reduce
            ? child
            : AnimatedBuilder(
                animation: animation,
                builder: (context, child) =>
                    Transform.translate(offset: offset * (1 - animation.value), child: child),
                child: child,
              ),
      ),
      child: child,
    );

    /// AnimatedSize asserts on a zero duration, so reduce motion leaves it out
    if (reduce) return switcher;
    return AnimatedSize(
      duration: BmMotion.standard,
      curve: BmMotion.standardCurve,
      child: switcher,
    );
  }
}
