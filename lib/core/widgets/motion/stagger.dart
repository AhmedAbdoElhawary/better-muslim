import 'dart:math' as math;

import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// a list's rows rise in one after another the first time it shows on its screen. rows past the
/// eighth come with it, and rows built later (a scroll, a return to the tab) just appear
class BmStagger extends StatefulWidget {
  const BmStagger({required this.index, required this.child, super.key});

  final int index;
  final Widget child;

  @override
  State<BmStagger> createState() => _BmStaggerState();
}

/// kept in the route's page storage, so the screen remembers it played
const _played = #bmStaggerPlayed;

class _BmStaggerState extends State<BmStagger> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: _total);
  late final Animation<double> _progress;

  static final _total = BmMotion.staggerStep * (BmMotion.staggerMax - 1) + BmMotion.standard;

  @override
  void initState() {
    super.initState();
    final start = BmMotion.staggerStep * math.min(widget.index, BmMotion.staggerMax - 1);
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        start.inMicroseconds / _total.inMicroseconds,
        (start + BmMotion.standard).inMicroseconds / _total.inMicroseconds,
        curve: BmMotion.decelerate,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) return;
    final storage = PageStorage.maybeOf(context);
    final played = storage?.readState(context, identifier: _played) == true;
    if (played || MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }
    _controller.forward();

    /// every row of the first frame is built by now, later ones don't run
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) storage?.writeState(context, true, identifier: _played);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rise = BmMotion.staggerRise.r;
    return FadeTransition(
      opacity: _progress,
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, child) =>
            Transform.translate(offset: Offset(0, rise * (1 - _progress.value)), child: child),
        child: widget.child,
      ),
    );
  }
}
