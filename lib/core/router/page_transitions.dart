import 'package:flutter/cupertino.dart';

/// apple's push on both phones, with the edge swipe back. reduce motion fades the first 150 ms and
/// leaves the page under where it is (FR-031)
class BmPageTransitionsBuilder extends PageTransitionsBuilder {
  const BmPageTransitionsBuilder();

  static const _cupertino = CupertinoPageTransitionsBuilder();

  /// the route's length can't read the context, so the fade takes the first .3 of its 500 ms
  static const _fade = Interval(0, .3);

  @override
  Duration get transitionDuration => _cupertino.transitionDuration;

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      (context, animation, secondaryAnimation, allowSnapshotting, child) =>
          MediaQuery.disableAnimationsOf(context)
          ? child
          : _cupertino.delegatedTransition?.call(
              context,
              animation,
              secondaryAnimation,
              allowSnapshotting,
              child,
            );

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return FadeTransition(
        opacity: animation.drive(CurveTween(curve: _fade)),
        child: child,
      );
    }
    return _cupertino.buildTransitions(route, context, animation, secondaryAnimation, child);
  }
}
