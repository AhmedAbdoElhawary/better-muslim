import 'dart:math' as math;

import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the loader is the logo: a drop of oil forms at the star's top, falls and fills the lamp.
/// progress null loops at the default level, 0 to 1 is how full the pool is
class BmOilDrop extends StatefulWidget {
  const BmOilDrop({this.size = SizeManager.oilDrop, this.progress, super.key});

  final double size;
  final double? progress;

  @override
  State<BmOilDrop> createState() => _BmOilDropState();
}

class _BmOilDropState extends State<BmOilDrop> with TickerProviderStateMixin {
  late final _loop = AnimationController(vsync: this, duration: BmMotion.oilCycle)..repeat();
  late final _wave = AnimationController(vsync: this, duration: _waveCycle);
  late final _level = AnimationController.unbounded(
    vsync: this,
    value: widget.progress ?? _idleLevel,
  );

  static const _waveCycle = Duration(milliseconds: 2400);

  /// the pool at 80 of the 100 box, 92 empty and 64 full
  static const _idleLevel = .43;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _wave.stop();
    } else if (!_wave.isAnimating) {
      _wave.repeat();
    }
  }

  @override
  void didUpdateWidget(BmOilDrop old) {
    super.didUpdateWidget(old);
    final progress = widget.progress;
    if (progress != null && progress != old.progress) {
      _level.animateWith(
        SpringSimulation(BmMotion.gentle, _level.value, progress, _level.velocity),
      );
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    _wave.dispose();
    _level.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final progress = widget.progress;
    return Semantics(
      label: context.tr(StringsManager.loading),
      value: progress == null ? null : '${(progress * 100).round()}%',
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.square(widget.size.r),
          painter: BmOilDropPainter(
            loop: _loop,
            wave: _wave,
            level: _level,
            showDrop: widget.size >= SizeManager.oilDropMin && !reduce,
            reduce: reduce,
            size: widget.size,
            star: context.getColor(ThemeEnum.primary),
            sun: context.getColor(ThemeEnum.sun),
            oilLight: context.getColor(ThemeEnum.oilLight),
            oilDark: context.getColor(ThemeEnum.oilDark),
            ripple: context.getColor(ThemeEnum.oilRipple),
          ),
        ),
      ),
    );
  }
}

/// drawn in the design's 100 x 100 box. one cycle's beats: form .00 to .35, hang to .50, fall to
/// .73, splash to .80, ripple and sun halo from .74
class BmOilDropPainter extends CustomPainter {
  BmOilDropPainter({
    required this.loop,
    required this.wave,
    required this.level,
    required this.showDrop,
    required this.reduce,
    required this.size,
    required this.star,
    required this.sun,
    required this.oilLight,
    required this.oilDark,
    required this.ripple,
  }) : super(repaint: Listenable.merge([loop, wave, level]));

  final Animation<double> loop;
  final Animation<double> wave;
  final Animation<double> level;
  final bool showDrop;
  final bool reduce;

  /// the design size, the strokes get heavier as it gets smaller
  final double size;
  final Color star;
  final Color sun;
  final Color oilLight;
  final Color oilDark;
  final Color ripple;

  static final _star = _path([
    (50, 8), (62.3, 20.3), (79.7, 20.3), (79.7, 37.7), (92, 50), (79.7, 62.3), (79.7, 79.7), //
    (62.3, 79.7), (50, 92), (37.7, 79.7), (20.3, 79.7), (20.3, 62.3), (8, 50), (20.3, 37.7),
    (20.3, 20.3), (37.7, 20.3),
  ]);
  static final _drop = Path()
    ..moveTo(0, 0)
    ..cubicTo(1.6, 2.6, 3.6, 4.8, 3.6, 7.2)
    ..arcToPoint(const Offset(-3.6, 7.2), radius: const Radius.circular(_dropBulb))
    ..cubicTo(-3.6, 4.8, -1.6, 2.6, 0, 0)
    ..close();

  /// two quarter waves every 50, so a move of 50 loops without a seam
  static final _wavePath = () {
    final path = Path()..moveTo(-100, 0);
    for (var x = -100.0; x < 150; x += 25) {
      path.quadraticBezierTo(x + 12.5, (x + 100) % 50 == 0 ? -2.4 : 2.4, x + 25, 0);
    }
    return path
      ..lineTo(150, 40)
      ..lineTo(-100, 40)
      ..close();
  }();

  static const _sunCenter = Offset(66.06, 46.16);
  static const _dropBulb = 3.6;
  static const _ripple = Size(18, 2.8);
  static const _lampRadius = 24.0;
  static const _impact = .74;
  static const _rippleShare = 410 / 1600;
  static const _haloShare = 400 / 1600;
  static const _haloDelay = 30 / 1600;

  static Path _path(List<(double, double)> points) {
    final path = Path()..moveTo(points.first.$1, points.first.$2);
    for (final (x, y) in points.skip(1)) {
      path.lineTo(x, y);
    }
    return path..close();
  }

  /// the reduce motion pulse, 1 to .45 and back over one cycle
  static double sunOpacity(double t) =>
      _keys(BmMotion.breathe.transform(t), [(0, 1), (.5, .45), (1, 1)]);

  /// the pool's surface in the box, 92 empty and 64 full
  double get poolY => 92 - 28 * level.value.clamp(0, 1);

  @override
  void paint(Canvas canvas, Size box) {
    final t = loop.value;
    final stroke = size < 32
        ? 5.0
        : size < 64
        ? 3.0
        : size < 120
        ? 2.2
        : 1.6;
    canvas
      ..save()
      ..scale(box.width / 100);

    final pool = poolY;
    final dip = reduce
        ? 0.0
        : _impactKeys(t, 0, _haloShare, BmMotion.standardCurve, [
            (0, 0),
            (.25, 1.4),
            (.6, -.5),
            (1, 0),
          ]);
    canvas
      ..save()
      ..clipPath(_star)
      ..translate(0, pool + dip);
    canvas
      ..save()
      ..translate(reduce ? 0 : -50 * wave.value, 0)
      ..drawPath(_wavePath, Paint()..shader = _oil(-2.4, 40))
      ..restore();
    if (!reduce) {
      final rippleOpacity = _impactKeys(t, 0, _rippleShare, BmMotion.decelerate, [
        (0, 0),
        (.08, .95),
        (1, 0),
      ]);
      if (rippleOpacity > 0) {
        final scale = _impactKeys(t, 0, _rippleShare, BmMotion.decelerate, [
          (0, .3),
          (.08, .45),
          (1, 2.3),
        ], rest: 1);
        canvas.drawOval(
          Rect.fromCenter(
            center: const Offset(50, 0),
            width: _ripple.width * scale,
            height: _ripple.height * scale,
          ),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = size < 64 ? 1.6 : .9
            ..color = ripple.withValues(alpha: rippleOpacity),
        );
      }
    }
    canvas.restore();

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = star;
    canvas
      ..drawPath(_star, line)
      ..drawArc(
        Rect.fromCircle(center: const Offset(50, 64), radius: _lampRadius),
        math.pi,
        math.pi,
        false,
        line,
      )
      ..drawLine(const Offset(20.3, 64), const Offset(79.7, 64), line..strokeCap = StrokeCap.butt);

    if (reduce) {
      canvas.drawCircle(_sunCenter, 4.2, Paint()..color = sun.withValues(alpha: sunOpacity(t)));
    } else {
      final haloOpacity = _impactKeys(t, _haloDelay, _haloShare, BmMotion.decelerate, [
        (0, 0),
        (.35, .5),
        (1, 0),
      ]);
      if (haloOpacity > 0) {
        final scale = _impactKeys(t, _haloDelay, _haloShare, BmMotion.decelerate, [
          (0, .5),
          (.35, 1),
          (1, 1.6),
        ], rest: 1);
        canvas.drawCircle(
          _sunCenter,
          10 * scale,
          Paint()..color = sun.withValues(alpha: haloOpacity),
        );
      }
      final sunScale = _impactKeys(t, _haloDelay, _haloShare, BmMotion.standardCurve, [
        (0, 1),
        (.35, 1.28),
        (1, 1),
      ], rest: 1);
      canvas.drawCircle(_sunCenter, 4.2 * sunScale, Paint()..color = sun);
    }

    if (showDrop) {
      final (dy, sx, sy) = _dropAt(t, pool - 25.8);
      if (sx > 0 && sy > 0) {
        canvas
          ..save()
          ..translate(50, 15 + dy)
          ..scale(sx, sy)
          ..drawPath(_drop, Paint()..shader = _oil(0, 10.8))
          ..restore();
      }
    }
    canvas.restore();
  }

  Shader _oil(double top, double bottom) => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [oilLight, oilDark],
  ).createShader(Rect.fromLTRB(-100, top, 150, bottom));

  /// css keyframes eased per segment: form, hang, fall, then the splash flattens and goes
  static (double, double, double) _dropAt(double t, double fall) {
    final frames = <(double, double, double, double, Curve)>[
      (0, 0, 0, 0, BmMotion.decelerate),
      (.35, 0, 1, 1, BmMotion.breathe),
      (.5, 1.2, .9, 1.18, Curves.easeInQuad),
      (.73, fall, .8, 1.32, Curves.linear),
      (.76, fall + 2.5, 1.7, .22, Curves.linear),
      (.8, fall + 2.5, 0, 0, Curves.linear),
      (1, fall + 2.5, 0, 0, Curves.linear),
    ];
    for (var i = 1; i < frames.length; i++) {
      final (end, y1, x1, h1, _) = frames[i];
      if (t > end) continue;
      final (start, y0, x0, h0, curve) = frames[i - 1];
      final p = curve.transform((t - start) / (end - start));
      return (y0 + (y1 - y0) * p, x0 + (x1 - x0) * p, h0 + (h1 - h0) * p);
    }
    return (fall + 2.5, 0, 0);
  }

  /// an animation that starts at the splash, its keys linear on the eased time. rest outside it
  static double _impactKeys(
    double t,
    double delay,
    double share,
    Curve curve,
    List<(double, double)> keys, {
    double rest = 0,
  }) {
    final u = (t - _impact - delay) / share;
    if (u < 0 || u > 1) return rest;
    return _keys(curve.transform(u), keys);
  }

  static double _keys(double p, List<(double, double)> keys) {
    for (var i = 1; i < keys.length; i++) {
      final (end, v1) = keys[i];
      if (p > end) continue;
      final (start, v0) = keys[i - 1];
      return v0 + (v1 - v0) * (p - start) / (end - start);
    }
    return keys.last.$2;
  }

  @override
  bool shouldRepaint(BmOilDropPainter old) =>
      old.showDrop != showDrop ||
      old.reduce != reduce ||
      old.size != size ||
      old.star != star ||
      old.sun != sun ||
      old.oilLight != oilLight ||
      old.oilDark != oilDark ||
      old.ripple != ripple;
}
