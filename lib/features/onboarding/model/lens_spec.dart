import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

/// everything the glass shader needs for one frame, from the reference's LensSpec
@immutable
class LensSpec {
  const LensSpec({
    required this.center,
    required this.radius,
    this.magnify = 1,
    this.refraction = 1,
    this.chroma = .12,
    this.glow = 0,
    this.opacity = 1,
    this.shadow = 1,
    this.specular = 1,
    this.rimLight = 1,
    this.velocity = Offset.zero,
    this.fill = 0,
    this.clipY = double.infinity,
  });

  static const hidden = LensSpec(center: Offset.zero, radius: 0, opacity: 0);

  final Offset center;
  final double radius;
  final double magnify;
  final double refraction;
  final double chroma;
  final double glow;
  final double opacity;
  final double shadow;
  final double specular;
  final double rimLight;

  /// squash and stretch, zero with reduce motion
  final Offset velocity;

  /// 0 clear glass, 1 the sun's color
  final double fill;

  /// nothing of the lens below this y, the horizon once the sun has settled on 4.10
  final double clipY;

  Rect get bounds => Rect.fromCircle(center: center, radius: radius);

  /// unclamped, so a spring's overshoot reads as jelly
  static LensSpec lerp(LensSpec a, LensSpec b, double t) {
    double l(double x, double y) => x + (y - x) * t;
    return LensSpec(
      center: Offset.lerp(a.center, b.center, t)!,
      radius: math.max(0, l(a.radius, b.radius)),
      magnify: math.max(.2, l(a.magnify, b.magnify)),
      refraction: l(a.refraction, b.refraction),
      chroma: l(a.chroma, b.chroma),
      glow: l(a.glow, b.glow).clamp(0, 1),
      opacity: l(a.opacity, b.opacity).clamp(0, 1),
      shadow: l(a.shadow, b.shadow).clamp(0, 1),
      specular: l(a.specular, b.specular).clamp(0, 1),
      rimLight: l(a.rimLight, b.rimLight).clamp(0, 1),
      velocity: Offset.lerp(a.velocity, b.velocity, t)!,
      fill: l(a.fill, b.fill).clamp(0, 1),
      clipY: t < .5 ? a.clipY : b.clipY,
    );
  }
}
