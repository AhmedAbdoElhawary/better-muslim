import 'package:flutter/widgets.dart';

/// the onboarding route's animations, so a step builds on its own transition (R8)
class StepScope extends InheritedWidget {
  const StepScope({
    required this.animation,
    required this.secondaryAnimation,
    required super.child,
    super.key,
  });

  final Animation<double> animation;

  /// the route pushed on top, the step below fades its content out on it
  final Animation<double> secondaryAnimation;

  static StepScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StepScope>();

  @override
  bool updateShouldNotify(StepScope old) =>
      old.animation != animation || old.secondaryAnimation != secondaryAnimation;
}
