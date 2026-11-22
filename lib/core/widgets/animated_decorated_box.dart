import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:flutter/widgets.dart';

/// a fill or ring that tweens in and out. an AnimatedContainer would pad the child by the border's
/// width
class AnimatedDecoratedBox extends StatelessWidget {
  const AnimatedDecoratedBox({required this.decoration, this.child, super.key});
  final Decoration decoration;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: DecorationTween(end: decoration),
      duration: BmMotion.micro,
      builder: (context, decoration, child) => DecoratedBox(decoration: decoration, child: child),
      child: child,
    );
  }
}
