import 'package:better_muslim/core/widgets/custom_opacity.dart';
import 'package:flutter/widgets.dart';

/// a title that flies from the row it was tapped on into the pushed page's bar (FR-033). the tag
/// is the destination's route, null is no flight
class TitleHero extends StatelessWidget {
  const TitleHero({required this.tag, required this.child, super.key});
  final String? tag;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tag = this.tag;
    if (tag == null) return child;
    final screen = Offset.zero & MediaQuery.sizeOf(context);
    return HeroMode(
      enabled: !MediaQuery.disableAnimationsOf(context),
      child: Hero(
        tag: tag,
        transitionOnUserGestures: true,
        createRectTween: (begin, end) => _tween(screen, begin!, end!),
        flightShuttleBuilder: _shuttle,
        child: child,
      ),
    );
  }

  /// a row scrolled off screen is still built in the list's cache, so it would fly in from
  /// nowhere. the title waits in the bar instead, the plain push
  static RectTween _tween(Rect screen, Rect begin, Rect end) {
    if (!begin.overlaps(screen)) return RectTween(begin: end, end: end);
    if (!end.overlaps(screen)) return RectTween(begin: begin, end: begin);
    return RectTween(begin: begin, end: end);
  }

  static bool _onScreen(BuildContext context, Rect screen) {
    final box = context.findRenderObject()! as RenderBox;
    return (box.localToGlobal(Offset.zero) & box.size).overlaps(screen);
  }

  /// the two texts crossfade and scale with the rect, so "hijri calendar" can land as "gregorian
  /// calendar". the overlay has no text style of its own, so the two ends' are lerped. a pop's
  /// animation also runs 0 to 1, from the bar to the row
  static Widget _shuttle(
    BuildContext context,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromContext,
    BuildContext toContext,
  ) {
    final screen = Offset.zero & MediaQuery.sizeOf(context);
    final fromShown = _onScreen(fromContext, screen);
    final toShown = _onScreen(toContext, screen);
    final from = DefaultTextStyle.of(fromContext).style;
    final to = DefaultTextStyle.of(toContext).style;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = !fromShown
            ? 1.0
            : !toShown
            ? 0.0
            : animation.value;
        return DefaultTextStyle(
          style: TextStyle.lerp(from, to, t)!,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomOpacity(
                opacity: 1 - t,
                child: FittedBox(child: (fromContext.widget as Hero).child),
              ),
              CustomOpacity(
                opacity: t,
                child: FittedBox(child: (toContext.widget as Hero).child),
              ),
            ],
          ),
        );
      },
    );
  }
}
