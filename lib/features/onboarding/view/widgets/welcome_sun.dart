import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/ambient.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 4.10's sun as designed, so the welcome at rest runs no shader (R6). it fades in as the glass
/// fills and breathes like home's sun
class WelcomeSun extends StatelessWidget {
  const WelcomeSun({
    required this.center,
    required this.radius,
    required this.opacity,
    required this.horizonY,
    required this.unit,
    required this.ambient,
    super.key,
  });

  final Offset center;
  final double radius;
  final double opacity;

  /// the tree's box ends on the horizon and hides the rest
  final double horizonY;
  final double unit;
  final ValueListenable<Duration>? ambient;

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0) return const SizedBox.shrink();
    return RepaintBoundary(
      child: CustomPaint(
        painter: _SunPainter(
          center: center,
          radius: radius,
          opacity: opacity,
          horizonY: horizonY,
          unit: unit,
          sun: context.getColor(ThemeEnum.sun),
          ambient: ambient,
        ),
      ),
    );
  }
}

class _SunPainter extends CustomPainter {
  _SunPainter({
    required this.center,
    required this.radius,
    required this.opacity,
    required this.horizonY,
    required this.unit,
    required this.sun,
    this.ambient,
  }) : super(repaint: ambient);

  final Offset center;
  final double radius;
  final double opacity;
  final double horizonY;
  final double unit;
  final Color sun;
  final ValueListenable<Duration>? ambient;

  /// box-shadow 0 0 40px 14px sun at 45%, a css blur is twice the sigma
  static const _glowAlpha = .45;
  static const _pulse = 3000.0;
  static const _breath = .12;
  static const _fadeIn = 300.0;

  @override
  void paint(Canvas canvas, Size size) {
    final ms = ambient?.value.inMilliseconds.toDouble();
    final loop = ms == null ? 0.0 : (ms / _fadeIn).clamp(0.0, 1.0);
    final scale = 1 + loop * _breath * ambientBreathe(ms ?? 0, _pulse);
    canvas
      ..save()
      ..clipRect(Rect.fromLTRB(0, 0, size.width, horizonY));
    canvas.drawCircle(
      center,
      (radius + SizeManager.welcomeSunSpread * unit) * scale,
      Paint()
        ..color = sun.withValues(alpha: _glowAlpha * opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, SizeManager.welcomeSunBlur / 2 * unit),
    );
    canvas
      ..drawCircle(center, radius * scale, Paint()..color = sun.withValues(alpha: opacity))
      ..restore();
  }

  @override
  bool shouldRepaint(_SunPainter old) =>
      old.center != center ||
      old.radius != radius ||
      old.opacity != opacity ||
      old.horizonY != horizonY ||
      old.unit != unit ||
      old.sun != sun ||
      old.ambient != ambient;
}
