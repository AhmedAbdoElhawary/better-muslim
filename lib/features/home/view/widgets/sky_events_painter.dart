import 'dart:math';
import 'dart:ui' as ui;

import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/design/bm_sky.dart';
import 'package:better_muslim/features/home/view/widgets/sky_header_painter.dart';
import 'package:material_ui/material_ui.dart';

enum SkyEventKind {
  /// a tiny star flares and throws its sparks
  burst(BmMotion.skyBurst),
  shootingStar(BmMotion.skyShootingStar),

  /// slower than a shooting star, tumbling
  rock(BmMotion.skyRock),

  /// a warm spark that leaves the sun, or the three stars by night
  glint(BmMotion.skyGlint);

  const SkyEventKind(this.duration);
  final Duration duration;

  bool get streak => this == shootingStar || this == rock;
}

/// where and how, picked once so the painter only reads it
class SkyEvent {
  const SkyEvent({
    required this.kind,
    required this.at,
    required this.angle,
    required this.fall,
    required this.reach,
    required this.duration,
    required this.bright,
    this.sunShare,
    this.tapped = false,
  });

  /// the sky's 0 to 1 box, a spot clear of the arc's feet and the card, or the [tap] in that box
  factory SkyEvent.next(
    Random random, {
    required bool bright,
    required double? sunShare,
    Offset? tap,
  }) {
    final roll = random.nextDouble();
    final kind = roll < .3
        ? SkyEventKind.glint
        : roll < .6
        ? SkyEventKind.shootingStar
        : roll < .9
        ? SkyEventKind.burst
        : SkyEventKind.rock;
    final angle = random.nextDouble() * 2 * pi;
    final spot = tap ?? Offset(.08 + random.nextDouble() * .84, .1 + random.nextDouble() * .4);
    return SkyEvent(
      kind: kind,

      /// 24 pt on the 393 x 320 sky
      at: tap != null && kind == SkyEventKind.burst
          ? spot + Offset.fromDirection(angle, random.nextDouble()).scale(.06, .075)
          : spot,
      angle: angle,
      fall: .26 + random.nextDouble() * .61,
      reach: .7 + random.nextDouble() * .3,
      duration: kind.streak ? kind.duration * (.85 + random.nextDouble() * .3) : kind.duration,
      bright: bright,
      sunShare: sunShare,
      tapped: tap != null,
    );
  }

  final SkyEventKind kind;
  final Offset at;
  final double angle;
  final double fall; // a streak's angle below the horizon, 15 to 50 degrees
  final double reach; // a streak's share of its full length
  final Duration duration;
  final bool bright;
  final double? sunShare;
  final bool tapped;
}

/// a few strokes, no blur and no layer, so a frame of it costs next to nothing
class SkyEventsPainter extends CustomPainter {
  SkyEventsPainter({
    required this.progress,
    required this.event,
    required this.onSky,
    required this.sun,
    required this.strength,
    required this.unit,
    required this.horizonAboveBottom,
    required this.rtl,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final SkyEvent event;
  final Color onSky;
  final Color sun;
  final double strength; // the theme's star opacity, a light theme's stars are softer
  final double unit;
  final double horizonAboveBottom;
  final bool rtl;

  static const _sparks = 7;
  static const _rock = [1.0, .72, .94, .66, 1.05, .8, .9];
  static const _shooting = (travel: 210.0, tail: 74.0, stroke: 1.4);
  static const _rockTrail = (travel: 120.0, tail: 22.0, stroke: .8);

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    if (t <= 0 || t >= 1) return;
    final at = Offset(event.at.dx * size.width, event.at.dy * size.height);
    switch (event.kind) {
      case SkyEventKind.burst:
        _burst(canvas, at, t);
      case SkyEventKind.shootingStar:
        _streak(canvas, at, size, t, _shooting);
      case SkyEventKind.rock:
        _streak(canvas, at, size, t, _rockTrail);
        _rockBody(canvas, _head(at, size, t, _rockTrail.travel), t);
      case SkyEventKind.glint:
        _glint(canvas, size, t);
    }
  }

  double _fade(double t) => sin(pi * t);

  /// the pale stars would vanish in a bright sky, so by day they take the sun's color
  Color _tone(double alpha) =>
      event.bright ? sun.withValues(alpha: alpha) : onSky.withValues(alpha: strength * alpha);

  void _burst(Canvas canvas, Offset at, double t) {
    final color = _tone(_fade(t));
    final flare = 8 * unit * _fade(t);
    final thin = Paint()
      ..color = color
      ..strokeWidth = .7 * unit
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(at - Offset(flare, 0), at + Offset(flare, 0), thin)
      ..drawLine(at - Offset(0, flare), at + Offset(0, flare), thin)
      ..drawCircle(at, (1 + 1.4 * _fade(t)) * unit, Paint()..color = color);
    final out = Curves.easeOutCubic.transform(t) * 18 * unit;
    canvas.drawPoints(
      ui.PointMode.points,
      [
        for (var i = 0; i < _sparks; i++)
          at + Offset.fromDirection(event.angle + i * 2 * pi / _sparks, out * (.7 + i % 3 * .15)),
      ],
      Paint()
        ..color = _tone(1 - t)
        ..strokeWidth = 1.3 * unit * (1 - t * .6)
        ..strokeCap = StrokeCap.round,
    );
  }

  /// falls away from the middle of the sky, so the whole streak stays on screen
  Offset _direction(Offset at, Size size) {
    final side = at.dx < size.width / 2 ? 1.0 : -1.0;
    return Offset(side * cos(event.fall), sin(event.fall));
  }

  /// a tapped streak crosses the spot halfway, so the eye lands where the finger was
  Offset _head(Offset at, Size size, double t, double travel) =>
      at + _direction(at, size) * travel * event.reach * unit * (event.tapped ? t - .5 : t);

  void _streak(
    Canvas canvas,
    Offset at,
    Size size,
    double t,
    ({double travel, double tail, double stroke}) streak,
  ) {
    final head = _head(at, size, t, streak.travel);
    final end = head - _direction(at, size) * streak.tail * event.reach * unit * _fade(t);
    final color = _tone(_fade(t));
    canvas.drawLine(
      end,
      head,
      Paint()
        ..shader = ui.Gradient.linear(end, head, [color.withValues(alpha: 0), color])
        ..strokeWidth = streak.stroke * unit
        ..strokeCap = StrokeCap.round,
    );
  }

  void _rockBody(Canvas canvas, Offset at, double t) {
    final turn = event.angle + t * 2 * pi;
    canvas.drawPath(
      Path()..addPolygon([
        for (var i = 0; i < _rock.length; i++)
          at + Offset.fromDirection(turn + i * 2 * pi / _rock.length, _rock[i] * 2.2 * unit),
      ], true),
      Paint()..color = _tone(.75 * _fade(t)),
    );
  }

  void _glint(Canvas canvas, Size size, double t) {
    final share = event.sunShare;
    final center = Offset(
      (rtl ? BmSunArc.centerRtl : BmSunArc.center).dx * unit,
      size.height - horizonAboveBottom,
    );
    final from = share == null || event.tapped
        ? Offset(size.width * event.at.dx, size.height * event.at.dy)
        : arcPoint(center, BmSunArc.radius * unit, share);

    /// a ray that always leaves upward, a glint into the horizon reads as a mistake
    final ray = -pi / 2 + (event.at.dx - .5) * pi * .8;
    final at = from + Offset.fromDirection(ray, ((event.tapped ? 0 : 16) + 26 * t) * unit);
    final color = sun.withValues(alpha: _fade(t));
    final size4 = 6 * unit * _fade(t);
    final thin = Paint()
      ..color = color
      ..strokeWidth = .9 * unit
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(at - Offset(size4, 0), at + Offset(size4, 0), thin)
      ..drawLine(at - Offset(0, size4), at + Offset(0, size4), thin)
      ..drawCircle(at, 1.2 * unit * _fade(t), Paint()..color = color);
  }

  @override
  bool shouldRepaint(SkyEventsPainter o) =>
      o.event != event ||
      o.onSky != onSky ||
      o.sun != sun ||
      o.strength != strength ||
      o.unit != unit ||
      o.horizonAboveBottom != horizonAboveBottom ||
      o.rtl != rtl;
}
