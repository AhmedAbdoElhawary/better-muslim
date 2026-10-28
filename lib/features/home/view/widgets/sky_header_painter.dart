import 'dart:math' as math;

import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/design/bm_sky.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/widgets/ambient.dart';
import 'package:better_muslim/core/widgets/mushaf_star.dart';
import 'package:better_muslim/features/home/model/home_moment.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Home sky header (4.1 / 4.2 / 4.16), drawn in the mockup's 393 × 380 frame times [unit].
/// The stars hang from the top, the horizon and the arc sit from the bottom.
/// Layers: gradient (drifting) → stars (opacity palette.starOpacity, twinkle) → dotted arc →
/// progress arc → point dots → sun or the night's three stars. Drift, twinkle, the sun pulse and
/// its rays all come from [elapsed], so one notifier drives the whole loop and nothing above it
/// rebuilds.
class SkyHeaderPainter extends CustomPainter {
  SkyHeaderPainter({
    required this.stops,
    required this.starsStrength,
    required this.points,
    required this.markerShare,
    required this.onSky,
    required this.sun,
    required this.starOpacity,
    required this.unit,
    required this.horizonAboveBottom,
    this.overlap = 0,
    this.bleed = 0,
    this.rtl = false,
    this.outgoing,
    this.turn = 1,
    this.wheel = true,
    this.elapsed,
  }) : super(repaint: elapsed);

  final BmSkyStops stops;
  final double starsStrength; // 0 by day, 1 at night, lerped with the sky change
  final ArcPoints? points; // null without a location or both ends
  final double? markerShare; // the sun by day, the three stars by night
  final ArcPoints? outgoing; // the arc turning away at sunrise and maghrib, its marker at the end
  final double turn; // 0 → 1 while the arc turns, 1 settled
  final bool wheel; // false with reduce motion, the two arcs crossfade
  final Color onSky;
  final Color sun;
  final double starOpacity;
  final double unit; // logical px per mockup px
  final double horizonAboveBottom; // so a sky grown for large text takes the arc down with it
  final double overlap; // the sky goes on under the next-prayer card, below the box
  final double bleed; // filled above the box, so an overscroll shows sky
  final bool rtl;
  final ValueListenable<Duration>? elapsed; // null = still (reduce motion, power saving)

  // x, y, size (from the mockups)
  static const stars = [
    [30.0, 70.0, 2.0],
    [92.0, 96.0, 1.5],
    [150.0, 66.0, 2.0],
    [214.0, 104.0, 1.5],
    [262.0, 78.0, 2.0],
    [336.0, 120.0, 1.5],
    [120.0, 136.0, 1.5],
    [366.0, 82.0, 2.0],
    [58.0, 150.0, 1.5],
  ];
  static const starsRtl = [
    [30.0, 90.0, 2.0],
    [92.0, 140.0, 1.5],
    [150.0, 76.0, 2.0],
    [214.0, 170.0, 1.5],
    [262.0, 98.0, 2.0],
    [336.0, 150.0, 1.5],
    [120.0, 220.0, 1.5],
    [366.0, 230.0, 2.0],
    [58.0, 300.0, 1.5],
    [300.0, 320.0, 1.5],
  ];

  static const _fadeIn = 300.0; // ms, the loop fades back in when it starts again (MOTION tiers)
  static const _sunPulse = 3000.0;
  static const _sunGrow = .18;
  static const _raysTurn = 60000.0;
  static const _starPeriods = [2100.0, 2700.0, 3300.0];

  @override
  void paint(Canvas c, Size s) {
    final ms = elapsed?.value.inMilliseconds.toDouble();

    /// 0 = the still state, so a restarted loop blends in instead of jumping
    final strength = ms == null ? 0.0 : (ms / _fadeIn).clamp(0.0, 1.0);
    final t = ms ?? 0;
    final drift = strength * ambientBreathe(t, BmMotion.skyLoop.inMilliseconds.toDouble());

    final sky = Rect.fromLTWH(0, 0, s.width, s.height + overlap);
    c.drawRect(
      Rect.fromLTRB(0, -bleed, s.width, sky.bottom),
      Paint()..shader = bmSkyGradient(stops, drift).createShader(sky),
    );

    if (starsStrength > 0) {
      final list = rtl ? starsRtl : stars;
      for (var i = 0; i < list.length; i++) {
        final st = list[i];
        final twinkle = .15 + .85 * ambientBreathe(t + (i % 5) * 600, 1800 + (i % 7) * 410.0);
        final opacity = starOpacity * starsStrength * (1 + strength * (twinkle - 1));
        c.drawCircle(
          Offset((st[0] + st[2] / 2) * unit, (st[1] + st[2] / 2) * unit),
          st[2] / 2 * unit,
          Paint()..color = Colors.white.withValues(alpha: opacity),
        );
      }
    }

    final cx = (rtl ? BmSunArc.centerRtl : BmSunArc.center).dx * unit,
        cy = s.height - horizonAboveBottom,
        rad = BmSunArc.radius * unit;
    // dotted full arc: dash 1, gap 5, round caps, 40% onSky
    final dotted = Paint()
      ..color = onSky.withValues(alpha: .4)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final circumference = math.pi * rad;
    for (double d = 0; d < circumference; d += 6 * unit) {
      final a = math.pi + d / rad;
      c.drawLine(
        Offset(cx + rad * math.cos(a), cy + rad * math.sin(a)),
        Offset(cx + rad * math.cos(a + unit / rad), cy + rad * math.sin(a + unit / rad)),
        dotted,
      );
    }
    // horizon: full width, 22% onSky
    c.drawLine(
      Offset(0, cy),
      Offset(s.width, cy),
      Paint()
        ..color = onSky.withValues(alpha: .22)
        ..strokeWidth = 1,
    );
    final center = Offset(cx, cy);
    final old = outgoing;
    if (old == null || turn >= 1) {
      _arc(c, center, rad, points, markerShare, 1, t, strength);
    } else if (wheel) {
      /// under the horizon only the label strip shows the arc going round
      c.save();
      c.clipRect(Rect.fromLTRB(0, -bleed, s.width, s.height));
      for (final (content, share, angle) in [
        (old, 1.0, math.pi * turn),
        (points, markerShare, math.pi * (turn - 1)),
      ]) {
        c.save();
        c.translate(cx, cy);
        c.rotate(angle);
        c.translate(-cx, -cy);
        _arc(c, center, rad, content, share, 1, t, strength);
        c.restore();
      }
      c.restore();
    } else {
      _arc(c, center, rad, old, 1, 1 - turn, t, strength);
      _arc(c, center, rad, points, markerShare, turn, t, strength);
    }
  }

  /// the progress up to the marker, a dot on each point, then the sun by day or the stars by night
  void _arc(
    Canvas c,
    Offset center,
    double rad,
    ArcPoints? content,
    double? share,
    double alpha,
    double t,
    double strength,
  ) {
    if (content == null || alpha <= 0) return;
    Offset at(double f) {
      final a = math.pi * (1 - f);
      return center + Offset(rad * math.cos(a), -rad * math.sin(a));
    }

    if (share != null) {
      c.drawArc(
        Rect.fromCircle(center: center, radius: rad),
        math.pi,
        math.pi * share,
        false,
        Paint()
          ..color = onSky.withValues(alpha: .8 * alpha)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
    final dot = Paint()..color = onSky.withValues(alpha: .8 * alpha);
    for (final point in content.points) {
      c.drawCircle(at(point.share), SizeManager.arcPointDot / 2 * unit, dot);
    }
    if (share == null) return;
    final p = at(share);
    if (content.kind == ArcKind.night) {
      for (var i = 0; i < _starPeriods.length; i++) {
        final twinkle = .4 + .6 * ambientBreathe(t, _starPeriods[i]);
        final a = -math.pi / 2 + i * 2 * math.pi / 3;
        c.drawPath(
          mushafStar(
            p + Offset(math.cos(a), math.sin(a)) * SizeManager.arcStarSpread * unit,
            SizeManager.arcStar * unit,
          ),
          Paint()..color = sun.withValues(alpha: alpha * (1 + strength * (twinkle - 1))),
        );
      }
      return;
    }
    final pulse = 1 + strength * _sunGrow * ambientBreathe(t, _sunPulse);
    final r = BmSunArc.sunSize / 2 * unit * pulse;
    // glow: box-shadow 0 0 22px 8px sun, stronger than the mockup's 50% (R17)
    c.drawCircle(
      p,
      r + 8 * unit * pulse,
      Paint()
        ..color = sun.withValues(alpha: .6 * alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 11 * unit),
    );
    if (strength > 0) {
      final rays = Paint()
        ..color = sun.withValues(alpha: .25 * strength * alpha)
        ..strokeWidth = unit
        ..strokeCap = StrokeCap.round;
      final spin = 2 * math.pi * (t % _raysTurn) / _raysTurn;
      for (var i = 0; i < 12; i++) {
        final a = spin + i * math.pi / 6;
        final direction = Offset(math.cos(a), math.sin(a));
        c.drawLine(p + direction * r * 1.5, p + direction * r * 2.1, rays);
      }
    }
    c.drawCircle(p, r, Paint()..color = sun.withValues(alpha: alpha));
  }

  @override
  bool shouldRepaint(SkyHeaderPainter o) =>
      o.stops.top != stops.top ||
      o.stops.mid != stops.mid ||
      o.stops.bottom != stops.bottom ||
      o.starsStrength != starsStrength ||
      o.points != points ||
      o.outgoing != outgoing ||
      o.markerShare != markerShare ||
      o.turn != turn ||
      o.wheel != wheel ||
      o.onSky != onSky ||
      o.sun != sun ||
      o.starOpacity != starOpacity ||
      o.unit != unit ||
      o.horizonAboveBottom != horizonAboveBottom ||
      o.overlap != overlap ||
      o.bleed != bleed ||
      o.rtl != rtl ||
      o.elapsed != elapsed;
}
// Labels under the horizon (11 px, 85% onSky, no wrap):
//   LTR: top 306, "Sunrise 06:15" left 94; "Maghrib 17:56" right-aligned 14 from the right edge.
//   RTL: top 300, line-height 1.2, "الشروق ٠٦:١٥" left 14; "المغرب ١٧:٥٦" right edge 100 from the right (sits under the arc's right foot).
// specs/008 replaces the night note: by day Sunrise, Dhuhr, Asr, Maghrib, by night Maghrib, Isha, Last third, Fajr, Sunrise, each with a dot.
// At night three stars sit on the arc at the current time instead of the sun. At sunrise and maghrib the arc turns half a circle (R17).
// The sun dot breathes scale 1 → 1.18 over 3 s alternate (breathe curve), twelve rays turn once a minute. Stars twinkle: duration 1800 + (i % 7) * 410 ms, alternate, opacity .15 → 1.
// Reduce motion: no drift, no twinkle (opacity 1), no breathing, no rays, the turn is a crossfade.
