import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/features/home/model/home_moment.dart';
import 'package:better_muslim/features/home/view_model/home_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// the wheel at sunrise and maghrib (R17): [turn] runs 0 → 1 when the arc's kind changes. the
/// painter and the labels each hold one, both start on the same frame so they stay together
class ArcTurn extends ConsumerStatefulWidget {
  const ArcTurn({required this.builder, super.key});

  final Widget Function(BuildContext context, ArcPoints? points, ArcPoints? outgoing, double turn)
  builder;

  @override
  ConsumerState<ArcTurn> createState() => _ArcTurnState();
}

class _ArcTurnState extends ConsumerState<ArcTurn> {
  ArcPoints? _points;
  ArcPoints? _outgoing;

  /// the tween's end, one more each change, so a change mid turn goes on from where it is
  var _turns = 0;

  @override
  Widget build(BuildContext context) {
    final points = ref.watch(arcPointsProvider);
    final last = _points;
    if (last != null && points != null && last.kind != points.kind) {
      _outgoing = last;
      _turns++;
    }
    _points = points;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    /// home offscreen at maghrib comes back to the night arc, not to a wheel
    final duration = !TickerMode.valuesOf(context).enabled
        ? Duration.zero
        : reduceMotion
        ? BmMotion.standard
        : BmMotion.skyChange;
    return TweenAnimationBuilder(
      tween: Tween(end: _turns.toDouble()),
      duration: duration,
      curve: reduceMotion ? Curves.linear : BmMotion.sacred,
      builder: (context, value, _) =>
          widget.builder(context, points, _outgoing, (value - _turns + 1).clamp(0.0, 1.0)),
    );
  }
}
