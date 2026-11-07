import 'dart:math' as math;

import 'package:better_muslim/core/resources/design/bm_sky.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/widgets/mushaf_star.dart';
import 'package:better_muslim/features/home/model/home_moment.dart';
import 'package:flutter/material.dart';

/// a share of the day on the arc, 0 at the left foot and 1 at the right
Offset arcPoint(Offset center, double radius, double share) {
  final a = math.pi * (1 - share);
  return center + Offset(radius * math.cos(a), -radius * math.sin(a));
}

/// Home sky header (4.1 / 4.2 / 4.16), drawn in the mockup's 393 × 380 frame times [unit].
/// The stars hang from the top, the horizon and the arc sit from the bottom.
/// Layers: gradient → stars (opacity palette.starOpacity) → dotted arc → progress arc → point
/// dots → sun or the night's three stars.
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
  });

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

  @override
  void paint(Canvas c, Size s) {
    final sky = Rect.fromLTWH(0, 0, s.width, s.height + overlap);
    c.drawRect(
      Rect.fromLTRB(0, -bleed, s.width, sky.bottom),
      Paint()..shader = bmSkyGradient(stops, 0).createShader(sky),
    );

    if (starsStrength > 0) {
      final list = rtl ? starsRtl : stars;
      for (var i = 0; i < list.length; i++) {
        final st = list[i];
        final opacity = starOpacity * starsStrength;
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
      _arc(c, center, rad, points, markerShare, 1);
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
        _arc(c, center, rad, content, share, 1);
        c.restore();
      }
      c.restore();
    } else {
      _arc(c, center, rad, old, 1, 1 - turn);
      _arc(c, center, rad, points, markerShare, turn);
    }
  }

  /// the progress up to the marker, a dot on each point, then the sun by day or the stars by night
  void _arc(Canvas c, Offset center, double rad, ArcPoints? content, double? share, double alpha) {
    if (content == null || alpha <= 0) return;
    Offset at(double f) => arcPoint(center, rad, f);

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
      for (var i = 0; i < 3; i++) {
        final a = -math.pi / 2 + i * 2 * math.pi / 3;
        c.drawPath(
          mushafStar(
            p + Offset(math.cos(a), math.sin(a)) * SizeManager.arcStarSpread * unit,
            SizeManager.arcStar * unit,
          ),
          Paint()..color = sun.withValues(alpha: alpha),
        );
      }
      return;
    }
    final r = BmSunArc.sunSize / 2 * unit;
    // glow: box-shadow 0 0 22px 8px sun, stronger than the mockup's 50% (R17)
    c.drawCircle(
      p,
      r + 8 * unit,
      Paint()
        ..color = sun.withValues(alpha: .6 * alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 11 * unit),
    );
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
      o.rtl != rtl;
}
// Labels under the horizon (11 px, 85% onSky, no wrap):
//   LTR: top 306, "Sunrise 06:15" left 94; "Maghrib 17:56" right-aligned 14 from the right edge.
//   RTL: top 300, line-height 1.2, "الشروق ٠٦:١٥" left 14; "المغرب ١٧:٥٦" right edge 100 from the right (sits under the arc's right foot).
// specs/008 replaces the night note: by day Sunrise, Dhuhr, Asr, Maghrib, by night Maghrib, Isha, Last third, Fajr, Sunrise, each with a dot.
// At night three stars sit on the arc at the current time instead of the sun. At sunrise and maghrib the arc turns half a circle (R17).
// The sun dot breathes scale 1 → 1.18 over 3 s alternate (breathe curve), twelve rays turn once a minute. Stars twinkle: duration 1800 + (i % 7) * 410 ms, alternate, opacity .15 → 1.
// Reduce motion: no drift, no twinkle (opacity 1), no breathing, no rays, the turn is a crossfade.
