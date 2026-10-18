import 'dart:math' as math;

import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/design/bm_sky.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Home sky header (4.1 / 4.2 / 4.16), drawn in the mockup's 393 × 380 frame times [unit].
/// The stars hang from the top, the horizon and the arc sit from the bottom.
/// Layers: gradient (drifting) → stars (opacity palette.starOpacity, twinkle) → dotted arc →
/// progress arc → sun. Drift, twinkle and the sun pulse all come from [elapsed], so one notifier
/// drives the whole loop and nothing above it rebuilds.
class SkyHeaderPainter extends CustomPainter {
  SkyHeaderPainter({
    required this.stops,
    required this.starsStrength,
    required this.sunFraction,
    required this.onSky,
    required this.sun,
    required this.starOpacity,
    required this.unit,
    required this.horizonAboveBottom,
    this.overlap = 0,
    this.bleed = 0,
    this.rtl = false,
    this.elapsed,
  }) : super(repaint: elapsed);

  final BmSkyStops stops;
  final double starsStrength; // 0 by day, 1 at night, lerped with the sky change
  final double? sunFraction; // null at night
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

  @override
  void paint(Canvas c, Size s) {
    final ms = elapsed?.value.inMilliseconds.toDouble();

    /// 0 = the still state, so a restarted loop blends in instead of jumping
    final strength = ms == null ? 0.0 : (ms / _fadeIn).clamp(0.0, 1.0);
    final t = ms ?? 0;
    final drift = strength * _breathe(t, BmMotion.skyLoop.inMilliseconds.toDouble());

    final sky = Rect.fromLTWH(0, 0, s.width, s.height + overlap);
    c.drawRect(
      Rect.fromLTRB(0, -bleed, s.width, sky.bottom),
      Paint()..shader = bmSkyGradient(stops, drift).createShader(sky),
    );

    if (starsStrength > 0) {
      final list = rtl ? starsRtl : stars;
      for (var i = 0; i < list.length; i++) {
        final st = list[i];
        final twinkle = .15 + .85 * _breathe(t + (i % 5) * 600, 1800 + (i % 7) * 410.0);
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
    final f = sunFraction;
    if (f != null) {
      c.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: rad),
        math.pi,
        math.pi * f,
        false,
        Paint()
          ..color = onSky.withValues(alpha: .8)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      final a = math.pi * (1 - f);
      final p = Offset(cx + rad * math.cos(a), cy - rad * math.sin(a));
      final pulse = 1 + strength * .12 * _breathe(t, _sunPulse);
      final r = BmSunArc.sunSize / 2 * unit * pulse;
      // glow: box-shadow 0 0 22px 8px sun@50%
      c.drawCircle(
        p,
        r + 8 * unit * pulse,
        Paint()
          ..color = sun.withValues(alpha: .5)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 11 * unit),
      );
      c.drawCircle(p, r, Paint()..color = sun);
    }
  }

  /// an alternate loop of [half] ms each way on the breathe curve, 0..1
  static double _breathe(double ms, double half) {
    final phase = ms % (2 * half) / half;
    return BmMotion.breathe.transform(phase <= 1 ? phase : 2 - phase);
  }

  @override
  bool shouldRepaint(SkyHeaderPainter o) =>
      o.stops.top != stops.top ||
      o.stops.mid != stops.mid ||
      o.stops.bottom != stops.bottom ||
      o.starsStrength != starsStrength ||
      o.sunFraction != sunFraction ||
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
// At night (after Maghrib, before Sunrise) there is no sun: left label "Isha 19:26", right label "Fajr 04:58". Arc stays dotted only.
// The sun dot breathes scale 1 → 1.12 over 3 s alternate (breathe curve). Stars twinkle: duration 1800 + (i % 7) * 410 ms, alternate, opacity .15 → 1.
// Reduce motion: no drift, no twinkle (opacity 1), no breathing.
