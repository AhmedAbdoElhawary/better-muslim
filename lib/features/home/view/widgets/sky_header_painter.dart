import 'dart:math' as math;

import 'package:better_muslim/core/resources/design/bm_sky.dart';
import 'package:flutter/material.dart';

/// Home sky header (4.1 / 4.2 / 4.16). 393 × 380 at iPhone 15 width; scale x with width, keep y.
/// Layers: gradient (drifting) → stars (opacity palette.starOpacity, twinkle) → dotted arc → progress arc → sun.
class SkyHeaderPainter extends CustomPainter {
  final BmSkyStops stops;
  final double drift; // 0..1, from the 12 s alternate controller
  final double? sunFraction; // null at night
  final Color onSky;
  final Color sun;
  final double starOpacity;
  final List<double> twinkle; // 9 values 0.15..1
  final bool rtl;
  SkyHeaderPainter({
    this.rtl = false,
    required this.stops,
    required this.drift,
    required this.sunFraction,
    required this.onSky,
    required this.sun,
    required this.starOpacity,
    required this.twinkle,
  });

  static const stars = [
    // x, y, size (from the mockup)
    [30.0, 70.0, 2.0],
    [92.0, 96.0, 1.5],
    [150.0, 66.0, 2.0],
    [214.0, 104.0, 1.5],
    [262.0, 78.0, 2.0],
    [336.0, 120.0, 1.5], [120.0, 136.0, 1.5], [366.0, 82.0, 2.0], [58.0, 150.0, 1.5],
  ];

  @override
  void paint(Canvas c, Size s) {
    final sx = s.width / 393;
    final r = Offset.zero & s;
    c.drawRect(r, Paint()..shader = bmSkyGradient(stops, drift).createShader(r));
    for (var i = 0; i < stars.length; i++) {
      final st = stars[i];
      c.drawCircle(
        Offset(st[0] * sx + st[2] / 2, st[1] + st[2] / 2),
        st[2] / 2,
        Paint()..color = Colors.white.withAlpha((255 * starOpacity * twinkle[i]).round()),
      );
    }
    final cx = (rtl ? BmSunArc.centerRtl : BmSunArc.center).dx * sx,
        cy = BmSunArc.horizonY,
        rad = BmSunArc.radius * sx;
    final arcRect = Rect.fromCircle(center: Offset(cx, cy), radius: rad);
    // dotted full arc: dash 1, gap 5, round caps, 40% onSky
    final dotted = Paint()
      ..color = onSky.withAlpha(102)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final circumference = math.pi * rad;
    for (double d = 0; d < circumference; d += 6) {
      final a = math.pi + d / rad;
      c.drawLine(
        Offset(cx + rad * math.cos(a), cy + rad * math.sin(a)),
        Offset(cx + rad * math.cos(a + 1 / rad), cy + rad * math.sin(a + 1 / rad)),
        dotted,
      );
    }
    // horizon: full width, 22% onSky
    c.drawLine(
      Offset(0, cy),
      Offset(s.width, cy),
      Paint()
        ..color = onSky.withAlpha(56)
        ..strokeWidth = 1,
    );
    final f = sunFraction;
    if (f != null) {
      c.drawArc(
        arcRect,
        math.pi,
        math.pi * f,
        false,
        Paint()
          ..color = onSky.withAlpha(204)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      final a = math.pi * (1 - f);
      final p = Offset(cx + rad * math.cos(a), cy - rad * math.sin(a));
      // glow: box-shadow 0 0 22px 8px sun@50%
      c.drawCircle(
        p,
        8 + 8,
        Paint()
          ..color = sun.withAlpha(128)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 11),
      );
      c.drawCircle(p, 8, Paint()..color = sun);
    }
  }

  @override
  bool shouldRepaint(SkyHeaderPainter o) => true;
}
// Labels under the horizon (11 px, 85% onSky, no wrap):
//   LTR: top 306, "Sunrise 06:15" left 94; "Maghrib 17:56" right-aligned 14 from the right edge.
//   RTL: top 300, line-height 1.2, "الشروق ٠٦:١٥" left 14; "المغرب ١٧:٥٦" right edge 100 from the right (sits under the arc's right foot).
// At night (after Maghrib, before Sunrise) there is no sun: left label "Isha 19:26", right label "Fajr 04:58". Arc stays dotted only.
// The sun dot breathes scale 1 → 1.12 over 3 s alternate (breathe curve). Stars twinkle: duration 1800 + (i % 7) * 410 ms, alternate, opacity .15 → 1.
// Reduce motion: no drift, no twinkle (opacity 1), no breathing.
