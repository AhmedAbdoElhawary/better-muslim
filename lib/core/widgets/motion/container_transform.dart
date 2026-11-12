import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// a card grows into the screen it opens and shrinks back on close (11 Motion v2), OpenContainer's
/// fade through. reduce motion is a plain 150 ms crossfade
class BmContainerTransform extends StatefulWidget {
  const BmContainerTransform({
    required this.closedBuilder,
    required this.openBuilder,
    this.radius = RadiusManager.lg,
    this.closedColor = ThemeEnum.surface,
    super.key,
  });

  /// open is the tap that starts it
  final Widget Function(BuildContext context, VoidCallback open) closedBuilder;
  final WidgetBuilder openBuilder;
  final double radius;
  final ThemeEnum closedColor;

  @override
  State<BmContainerTransform> createState() => _BmContainerTransformState();
}

class _BmContainerTransformState extends State<BmContainerTransform> {
  /// while the route shows its copy of the card
  bool _hidden = false;

  /// where the card sits on the root navigator
  Rect? _rect() {
    if (!mounted) return null;
    final box = context.findRenderObject() as RenderBox?;
    final navigator = Navigator.of(context, rootNavigator: true).context.findRenderObject();
    if (box == null || !box.attached || !box.hasSize || navigator is! RenderBox) return null;
    return MatrixUtils.transformRect(box.getTransformTo(navigator), Offset.zero & box.size);
  }

  void _open() {
    /// root navigator, so the opened screen covers the tab bar like every pushed screen
    final navigator = Navigator.of(context, rootNavigator: true);
    if (MediaQuery.disableAnimationsOf(context)) {
      navigator.push(
        PageRouteBuilder<void>(
          transitionDuration: BmMotion.micro,
          reverseTransitionDuration: BmMotion.micro,
          pageBuilder: (context, _, _) => widget.openBuilder(context),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
      return;
    }
    final rect = _rect();
    if (_hidden || rect == null) return;
    navigator.push(
      _ContainerRoute(
        begin: rect,
        measure: _rect,
        closedBuilder: widget.closedBuilder,
        openBuilder: widget.openBuilder,
        radius: widget.radius.r,
        closedColor: context.getColor(widget.closedColor),
        openColor: context.getColor(ThemeEnum.bg),
        scrim: context.getColor(ThemeEnum.scrim),
        onDismissed: () {
          if (mounted) setState(() => _hidden = false);
        },
      ),
    );
    setState(() => _hidden = true);
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.closedBuilder(context, _open);

    /// hiding it or a new last read repaints only the card, not the list around it
    return RepaintBoundary(
      child: Visibility(
        visible: !_hidden,
        maintainState: true,
        maintainAnimation: true,
        maintainSize: true,
        child: Material(
          clipBehavior: Clip.antiAlias,
          color: context.getColor(widget.closedColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(widget.radius.r)),
          child: widget.closedBuilder(context, _open),
        ),
      ),
    );
  }
}

/// one tree the whole way. OpenContainer moved the screen to another tree as it finished and back
/// as it closed, building all of it again both times
class _ContainerRoute extends ModalRoute<void> {
  _ContainerRoute({
    required this.begin,
    required this.measure,
    required this.closedBuilder,
    required this.openBuilder,
    required this.radius,
    required this.closedColor,
    required this.openColor,
    required this.scrim,
    required this.onDismissed,
  });

  Rect begin;
  final Rect? Function() measure;
  final Widget Function(BuildContext context, VoidCallback open) closedBuilder;
  final WidgetBuilder openBuilder;
  final double radius;
  final Color closedColor;
  final Color openColor;
  final Color scrim;
  final VoidCallback onDismissed;

  /// a scaled screen draws its text again at every new size, one image of it scales for free
  final _snapshot = SnapshotController();
  AnimationStatus? _last;
  AnimationStatus? _status;

  late Rect _end;

  Rect _measureEnd() => Offset.zero & (navigator!.context.findRenderObject()! as RenderBox).size;

  /// a close that turns an open around keeps the open's curve and fades, so nothing jumps
  bool get _interrupted => (_last?.isAnimating ?? false) && (_status?.isAnimating ?? false);

  @override
  TickerFuture didPush() {
    _end = _measureEnd();
    animation!.addStatusListener(_changed);
    return super.didPush();
  }

  void _changed(AnimationStatus status) {
    _last = _status;
    _status = status;

    /// not off as it's dismissed, that would paint the screen live once more just before it goes
    _snapshot.allowSnapshotting = !status.isCompleted;
    if (status.isDismissed) onDismissed();
  }

  /// the card is measured again once its route is laid out under this one
  @override
  bool didPop(void result) {
    _end = _measureEnd();
    SchedulerBinding.instance.addPostFrameCallback((_) => begin = measure() ?? begin);
    return super.didPop(result);
  }

  @override
  void dispose() {
    /// removed with no close animation, like a go() past it
    if (!animation!.isDismissed) {
      SchedulerBinding.instance.addPostFrameCallback((_) => onDismissed());
    }
    _snapshot.dispose();
    super.dispose();
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    /// built once, the frames only move, scale and fade them
    final closed = closedBuilder(context, () {});
    final open = SnapshotWidget(
      controller: _snapshot,
      mode: SnapshotMode.permissive,
      child: RepaintBoundary(child: openBuilder(context)),
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        final done = animation.isCompleted;
        final forward = animation.status != AnimationStatus.reverse || _interrupted;
        final curved = (forward ? Curves.fastOutSlowIn : Curves.fastOutSlowIn.flipped).transform(t);

        /// the card fades out in the first fifth, the screen in over the rest, a close plays it back
        final split = forward ? .2 : .8;
        final closedOpacity = 1 - (t / split).clamp(0.0, 1.0);
        final openOpacity = ((t - split) / (1 - split)).clamp(0.0, 1.0);
        final dim = forward ? (curved / .2).clamp(0.0, 1.0) : curved;
        return Stack(
          children: [
            Positioned.fill(
              child: Visibility(
                visible: !done,
                child: ColoredBox(color: scrim.withValues(alpha: SizeManager.containerScrim * dim)),
              ),
            ),
            Positioned.fromRect(
              rect: Rect.lerp(begin, _end, curved)!,
              child: Material(
                clipBehavior: done ? Clip.none : Clip.antiAlias,
                animationDuration: Duration.zero,
                color: Color.lerp(openColor, closedColor, closedOpacity),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radius * (1 - curved)),
                ),
                child: Stack(
                  fit: StackFit.passthrough,
                  children: [
                    _Fitted(size: begin.size, opacity: closedOpacity, child: closed),
                    _Fitted(size: _end.size, opacity: openOpacity, child: open),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  bool get maintainState => true;

  @override
  bool get opaque => true;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => BmMotion.containerOpen;
}

/// the child laid out at its own size, scaled to the moving width
class _Fitted extends StatelessWidget {
  const _Fitted({required this.size, required this.opacity, required this.child});

  final Size size;
  final double opacity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.fitWidth,
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints.tight(size),
        child: FadeTransition(opacity: AlwaysStoppedAnimation(opacity), child: child),
      ),
    );
  }
}
