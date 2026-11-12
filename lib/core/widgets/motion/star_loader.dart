import 'dart:math' as math;
import 'dart:ui';

import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// the self-drawing star of Brand's Noor motif. progress null draws, rests and fades in a loop,
/// 0 to 1 draws the line up to it
class BmStarLoader extends StatefulWidget {
  const BmStarLoader({this.size = SizeManager.loader, this.progress, super.key});

  final double size;
  final double? progress;

  @override
  State<BmStarLoader> createState() => _BmStarLoaderState();
}

class _BmStarLoaderState extends State<BmStarLoader> with TickerProviderStateMixin {
  late final _loop = AnimationController(vsync: this);
  late final _level = AnimationController.unbounded(vsync: this, value: widget.progress ?? 0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _run();
  }

  @override
  void didUpdateWidget(BmStarLoader old) {
    super.didUpdateWidget(old);
    _run();
    final progress = widget.progress;
    if (progress != null && progress != old.progress) {
      _level.animateWith(
        SpringSimulation(BmMotion.gentle, _level.value, progress, _level.velocity),
      );
    }
  }

  /// the loop draws and fades, or breathes with reduce motion. a progress only moves the level
  void _run() {
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (widget.progress != null) {
      _loop.stop();
      return;
    }
    final duration = reduce ? BmMotion.starBreathe : BmMotion.starCycle;
    if (_loop.duration != duration || !_loop.isAnimating) {
      _loop
        ..duration = duration
        ..repeat(reverse: reduce);
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    _level.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.progress;
    return Semantics(
      label: context.tr(StringsManager.loading),
      value: progress == null ? null : '${(progress * 100).round()}%',
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.square(widget.size.r),
          painter: BmStarPainter(
            loop: _loop,
            level: progress == null ? null : _level,
            reduce: MediaQuery.disableAnimationsOf(context),
            line: SizeManager.loaderLine.r,
            color: context.getColor(ThemeEnum.primary),
          ),
        ),
      ),
    );
  }
}

/// drawn in the design's 100 x 100 box: the outer circle, the star, the star turned 22.5° and the
/// inner circle, one after another
class BmStarPainter extends CustomPainter {
  BmStarPainter({
    required this.loop,
    required this.level,
    required this.reduce,
    required this.line,
    required this.color,
  }) : super(repaint: Listenable.merge([loop, level]));

  final Animation<double> loop;

  /// null loops, a value is how much of the line is drawn
  final Animation<double>? level;
  final bool reduce;

  /// the stroke in logical px, whatever the size
  final double line;
  final Color color;

  static const _center = Offset(50, 50);
  static const _dot = 2.0;
  static const _outer = 46.0;
  static const _inner = 15.0;

  static final _strokes = [
    Path()..addOval(Rect.fromCircle(center: _center, radius: _outer)),
    _path([
      (50, 8), (62.3, 20.3), (79.7, 20.3), (79.7, 37.7), (92, 50), (79.7, 62.3), (79.7, 79.7), //
      (62.3, 79.7), (50, 92), (37.7, 79.7), (20.3, 79.7), (20.3, 62.3), (8, 50), (20.3, 37.7),
      (20.3, 20.3), (37.7, 20.3),
    ]),
    _path([
      (50, 20), (58.79, 28.79), (71.21, 28.79), (71.21, 41.21), (80, 50), (71.21, 58.79), //
      (71.21, 71.21), (58.79, 71.21), (50, 80), (41.21, 71.21), (28.79, 71.21), (28.79, 58.79),
      (20, 50), (28.79, 41.21), (28.79, 28.79), (41.21, 28.79),
    ]).transform(
      (Matrix4.translationValues(50, 50, 0)
            ..rotateZ(math.pi / 8)
            ..translateByDouble(-50, -50, 0, 1))
          .storage,
    ),
    Path()..addOval(Rect.fromCircle(center: _center, radius: _inner)),
  ];

  static Path _path(List<(double, double)> points) {
    final path = Path()..moveTo(points.first.$1, points.first.$2);
    for (final (x, y) in points.skip(1)) {
      path.lineTo(x, y);
    }
    return path..close();
  }

  /// how much of stroke [index] is drawn [elapsed] into a cycle
  static double drawn(int index, Duration elapsed) {
    final from = BmMotion.starStarts[index];
    final t = ((elapsed - from).inMicroseconds / BmMotion.starDraw.inMicroseconds).clamp(0.0, 1.0);
    return Curves.easeInOut.transform(t);
  }

  /// 1 until the rest ends, then down to 0 over the fade
  static double fade(Duration elapsed) {
    final from = BmMotion.starStarts.last + BmMotion.starDraw + BmMotion.starRest;
    return 1 - ((elapsed - from).inMicroseconds / BmMotion.starFade.inMicroseconds).clamp(0.0, 1.0);
  }

  @override
  void paint(Canvas canvas, Size box) {
    final unit = box.width / 100;
    final elapsed = BmMotion.starCycle * loop.value;
    final level = this.level?.value.clamp(0.0, 1.0);
    final breathe = BmMotion.breathe.transform(loop.value);
    final (scale, opacity) = switch ((level, reduce)) {
      (null, true) => (lerpDouble(.96, 1.04, breathe)!, lerpDouble(.7, 1, breathe)!),
      (null, false) => (1.0, fade(elapsed)),
      _ => (1.0, 1.0),
    };
    if (opacity <= 0) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = line / unit / scale
      ..strokeJoin = StrokeJoin.round
      ..color = color.withValues(alpha: color.a * opacity);
    canvas
      ..save()
      ..scale(unit)
      ..translate(_center.dx, _center.dy)
      ..scale(scale)
      ..translate(-_center.dx, -_center.dy);
    for (final (index, stroke) in _strokes.indexed) {
      final share = switch ((level, reduce)) {
        (final level?, _) => (level * _strokes.length - index).clamp(0.0, 1.0),
        (null, true) => 1.0,
        (null, false) => drawn(index, elapsed),
      };
      if (share <= 0) continue;
      if (share >= 1) {
        canvas.drawPath(stroke, paint);
        continue;
      }
      for (final metric in stroke.computeMetrics()) {
        canvas.drawPath(metric.extractPath(0, metric.length * share), paint);
      }
    }
    if (level == null || level >= 1) {
      canvas.drawCircle(_center, _dot, Paint()..color = paint.color);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(BmStarPainter old) =>
      old.reduce != reduce || old.line != line || old.color != color || old.level != level;
}
