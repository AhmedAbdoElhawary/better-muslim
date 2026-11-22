import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:material_ui/material_ui.dart';

/// 4.10's sun as designed, so the welcome at rest runs no shader (R6). it fades in as the glass
/// fills
class WelcomeSun extends StatelessWidget {
  const WelcomeSun({
    required this.center,
    required this.radius,
    required this.opacity,
    required this.horizonY,
    required this.unit,
    super.key,
  });

  final Offset center;
  final double radius;
  final double opacity;

  /// the tree's box ends on the horizon and hides the rest
  final double horizonY;
  final double unit;

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
  });

  final Offset center;
  final double radius;
  final double opacity;
  final double horizonY;
  final double unit;
  final Color sun;

  /// box-shadow 0 0 40px 14px sun at 45%, a css blur is twice the sigma
  static const _glowAlpha = .45;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..clipRect(Rect.fromLTRB(0, 0, size.width, horizonY));
    canvas.drawCircle(
      center,
      radius + SizeManager.welcomeSunSpread * unit,
      Paint()
        ..color = sun.withValues(alpha: _glowAlpha * opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, SizeManager.welcomeSunBlur / 2 * unit),
    );
    canvas
      ..drawCircle(center, radius, Paint()..color = sun.withValues(alpha: opacity))
      ..restore();
  }

  @override
  bool shouldRepaint(_SunPainter old) =>
      old.center != center ||
      old.radius != radius ||
      old.opacity != opacity ||
      old.horizonY != horizonY ||
      old.unit != unit ||
      old.sun != sun;
}
