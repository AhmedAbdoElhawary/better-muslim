import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/features/onboarding/model/lens_spec.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

/// intro = the first screen, main = 4.10
enum SunStage { intro, main }

/// the reference's Choreography on 4.10's geometry (R4). two inputs drive everything: the sun's
/// position, whose height alone gives its size, and b, the welcome's build from 0 to 1
class SunChoreography {
  SunChoreography(this.size, this.padding, {this.unit = 1});

  final Size size;
  final EdgeInsets padding;

  /// logical px per design point, the .r factor
  final double unit;

  double get w => size.width;
  double get h => size.height;

  /// the reference's physics, in logical px and seconds
  static const springK = 170.0;
  static const springC = 20.0;
  static const grabCatchUp = 180.0;
  static const flickUp = 1200.0;
  static const flickDown = 900.0;
  static const commitFraction = .45;
  static const throwCarry = .5;
  static const maxThrow = 2500.0;
  static const build = Duration(milliseconds: 1800);
  static const unbuild = Duration(milliseconds: 900);
  static const rebuild = Duration(milliseconds: 700);
  static const starsFade = Duration(milliseconds: 1400);
  static const glowFlash = .35;
  static const entrance = Duration(milliseconds: 1200);

  /// the stars start leaving the sun a third of the way in
  static const emitAt = .35;
  static const starsLand = .75;
  static const starStagger = .02;

  /// the trees' frame
  static const designWidth = 393.0;

  /// the dome: 0.55 of the width in radius, its top at 0.745 of the height (FR-005)
  static const domeShare = .55;
  static const domeTopShare = .745;
  static const headlineShare = .40;
  static const readyHintShare = .56;
  static const reverseZoneShare = .60;
  static const reverseZoneLengthShare = .30;

  double get domeRadius => w * domeShare;
  Offset get domeCenter => Offset(w / 2, h * domeTopShare + domeRadius);

  /// 4.10's sun, half below the horizon
  double get restRadius => SizeManager.welcomeSun / 2 * unit;
  Offset get restCenter => Offset(w / 2, horizonY);
  double get horizonY => SpaceManager.welcomeHorizon * unit;

  /// around the rest spot, so a thumb that lands a little off still grabs the sun
  double get grabMargin => SpaceManager.welcomeGrabMargin * unit;

  /// held above this on the first screen = ready to begin
  double get startLine => horizonY;

  double get headlineCenter => h * headlineShare;
  double get readyHintTop => h * readyHintShare;

  /// on 4.10 a drag below this undoes the welcome
  double get reverseZoneTop => h * reverseZoneShare;
  double get reverseZoneLength => h * reverseZoneLengthShare;

  /// where the dome starts on the first launch, out of sight under the bottom edge (FR-006)
  Offset get entranceStart => domeCenter + Offset(0, h * (1 - domeTopShare));

  /// 0 at the dome, 1 on the horizon and above
  double liftAt(double y) =>
      ((domeCenter.dy - y) / (domeCenter.dy - restCenter.dy)).clamp(0.0, 1.0);

  LensSpec lensAt(
    Offset center, {
    double glow = 0,
    Offset velocity = Offset.zero,
    double fill = 0,
    double opacity = 1,
    double clipY = double.infinity,
  }) {
    /// 0 small to 1 dome, in log space so it reads as bigger and bigger, not a linear inflate
    final s = math.pow(1 - liftAt(center.dy), 1.15).toDouble();
    final radius = restRadius * math.pow(domeRadius / restRadius, s);
    return LensSpec(
      center: center,
      radius: radius.toDouble(),
      magnify: lerpDouble(1.55, 1.03, s)!,
      refraction: lerpDouble(1, .35, s)!,
      chroma: lerpDouble(.18, .04, s)!,
      glow: glow,
      opacity: opacity,
      shadow: lerpDouble(1, .6, s)!,
      specular: lerpDouble(1, 0, s)!,
      rimLight: lerpDouble(1, .2, s)!,
      velocity: velocity,
      fill: math.max(fill, warmthAt(liftAt(center.dy))),
      clipY: clipY,
    );
  }

  /// the glass warms toward the sun's color as it rises (FR-008)
  double warmthAt(double lift) => .25 * lift;

  /// the arc lights quickly while lifting, then fades as the sun gets small
  double glowForLift(double lift) =>
      Curves.easeOut.transform((lift / .25).clamp(0.0, 1.0)) *
      (1 - _iv(lift, .7, 1, Curves.easeIn));

  double headlineOpacity(double lift, double b) => (1 - _iv(lift, 0, .5, Curves.easeOut)) * (1 - b);
  double headlineBlur(double lift, double b) => 8 * (1 - headlineOpacity(lift, b));
  double hintOpacity(double lift, double b) => (1 - _iv(lift, 0, .25, Curves.easeOut)) * (1 - b);

  /// the welcome, in the order FR-013 starts them
  double titleOpacity(double b) => _iv(b, 0, .2, Curves.easeOut);

  /// the title starts inside the sun, so the glass bends it, and slides down to its place
  double titleTravel(double b) {
    final top = SpaceManager.welcomeTitleTop * unit;
    final line = FontSizeManager.wordmark * LineHeightManager.wordmark * unit;
    return (restCenter.dy - (top + line / 2)) * (1 - _iv(b, 0, .45, Curves.easeInOutCubic));
  }

  double horizonIn(double b) => _iv(b, .05, .35, Curves.easeOut);
  double markIn(double b) => _iv(b, .10, .40, Curves.easeOut);
  double fillAt(double b) => _iv(b, .30, .75, Curves.easeInOut);

  /// each star leaves the sun a little after the one before
  double starFlight(double b, int index) {
    final start = emitAt + index * starStagger;
    return _iv(b, start, start + (starsLand - emitAt) / 2, BmMotion.decelerate);
  }

  /// reduce motion: they fade in place over the whole 300 ms build
  double starsInPlace(double b) => b.clamp(0.0, 1.0);

  double taglineOpacity(double b) => _iv(b, .35, .55, Curves.easeOut);

  /// faint to full, the tagline develops
  double taglineInk(double b) => _iv(b, .50, .75, Curves.easeInOut);
  double getStartedIn(double b) => _iv(b, .60, .85, Curves.easeOutCubic);

  /// 4.11 covering the welcome over its first 300 ms (c 0 to 1): buttons, tagline, title, stars,
  /// then mark and horizon (FR-015)
  static double covered(double c, WelcomePart part) =>
      _iv(c, part.index * .15, part.index * .15 + .4, Curves.easeOut);

  static double _iv(double p, double a, double b, Curve curve) =>
      curve.transform(((p - a) / (b - a)).clamp(0.0, 1.0));
}

/// in the order they leave when 4.11 covers the welcome
enum WelcomePart { buttons, tagline, title, stars, sky }
