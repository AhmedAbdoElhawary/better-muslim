import 'package:flutter/widgets.dart';

/// 4.03 is always dark and gives its own colors, the same in every theme and mode (FR-033)
abstract final class AdhanColors {
  static const skyStops = [
    Color(0xFF14121C),
    Color(0xFF2A1F2A),
    Color(0xFF6A4436),
    Color(0xFFC98E5E),
  ];
  static const skyAt = [0.0, .32, .66, 1.0];
  static const halo = Color(0x73FFCE96);
  static const haloEdge = Color(0x00FFCE96);
  static const sun = Color(0xFFFFE1B8);
  static const sunGlow = Color(0x73FFC88C);
  static const horizon = Color(0x59FFECD2);
  static const text = Color(0xFFFFFFFF);
  static const cream = Color(0xFFF1E3C4);
  static const translation = Color(0xFFEADBC6);
  static const card = Color(0x99181014);
  static const cardHighlight = Color(0x1FFFFFFF);
  static const glass = Color(0x8C181014);
  static const glassBorder = Color(0x33FFFFFF);
  static const primary = Color(0xFFF6EAD6);
  static const onPrimary = Color(0xFF1E1A26);
  static const track = Color(0x38FFFFFF);
  static const fill = Color(0xFFFFFFFF);
}
