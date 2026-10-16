import 'package:flutter/widgets.dart';

abstract final class BmMotion {
  static const micro = Duration(milliseconds: 150);
  static const standard = Duration(milliseconds: 300);
  static const emphasized = Duration(milliseconds: 520);
  static const ambient = Duration(milliseconds: 6000);

  static const standardCurve = Cubic(0.2, 0, 0, 1);
  static const decelerate = Cubic(0.05, 0.7, 0.1, 1);
  static const accelerate = Cubic(0.3, 0, 0.8, 0.15);
  static const breathe = Cubic(0.37, 0, 0.63, 1);
  static const sacred = Cubic(0.4, 0, 0.2, 1);

  static final gentle = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 180,
    ratio: 0.90,
  ); // ≈520 ms
  static final snappy = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 420,
    ratio: 0.80,
  ); // ≈380 ms
  static final needle = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 120,
    ratio: 0.55,
  ); // ≈1030 ms

  // Per-animation constants (see MOTION.md for the full table)
  static const launch = Duration(milliseconds: 1200);
  static const skyChange = Duration(milliseconds: 1800);
  static const skyLoop = Duration(milliseconds: 12000); // Living Sky gradient drift, alternate
  static const glowLoop = Duration(milliseconds: 3000); // half-cycle; repeat(reverse: true) = 6 s
  static const checkStroke = Duration(milliseconds: 220);
  static const burst = Duration(milliseconds: 700);
  static const alignPulse = Duration(milliseconds: 900);
  static const beadStep = 44.0; // px the tasbih strip moves per count
}

/// Reduce motion = OS setting OR in-app switch (pass the in-app value in via BmPrefs).
extension BmMotionX on BuildContext {
  bool reduceMotion(bool inAppSetting) => MediaQuery.disableAnimationsOf(this) || inAppSetting;
}

Duration bmMotion(bool reduce, Duration d) => reduce ? BmMotion.micro : d;
Curve bmCurve(bool reduce, Curve c) => reduce ? Curves.linear : c;
