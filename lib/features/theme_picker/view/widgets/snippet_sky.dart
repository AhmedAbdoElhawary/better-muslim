import 'dart:math' as math;

import 'package:better_muslim/core/prayer_times/sky_state.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/resources/theme_sky.dart';
import 'package:better_muslim/features/theme_picker/view_model/theme_preview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// the snippet's svg and dots, in its 300 x 176 box. still: no drift, twinkle or particle loop (R4)
const _stars = [
  (30.0, 22.0, 2.0),
  (96.0, 44.0, 1.5),
  (150.0, 18.0, 2.0),
  (200.0, 58.0, 1.5),
  (250.0, 34.0, 2.0),
  (276.0, 80.0, 1.5),
  (120.0, 84.0, 1.5),
];
const _particles = [
  (60.0, 120.0, 10.0),
  (140.0, 132.0, 8.0),
  (210.0, 110.0, 12.0),
  (100.0, 96.0, 8.0),
];
const _particleAlpha = .4;
const _arcCenter = Offset(190, 150);
const _arcRadius = 90.0;
const _sun = Offset(273.4, 116.3);
const _dashedAlpha = .45;
const _doneAlpha = .75;
const _doneWidth = 1.2;
const _horizonAlpha = .22;
const _dash = 1.0;
const _gap = 5.0;
const _sunGlowAlpha = .55;
const _sky2Stop = .56;

/// the previewed theme's sky at this hour, its base sky with no place yet. the other colors come
/// from the theme the preview is in
class SnippetSky extends ConsumerWidget {
  const SnippetSky({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(skyStateProvider);
    final stops = state == null
        ? null
        : themeSky(ref.watch(themePreviewProvider.select((pick) => pick.theme)))[state]!;
    return CustomPaint(
      painter: _SkyPainter(
        sky1: stops?.top ?? context.getColor(ThemeEnum.sky1),
        sky2: stops?.mid ?? context.getColor(ThemeEnum.sky2),
        sky3: stops?.bottom ?? context.getColor(ThemeEnum.sky3),
        onSky: context.getColor(ThemeEnum.onSky),
        sun: context.getColor(ThemeEnum.sun),
        star: context.getColor(ThemeEnum.onSkyBright).withValues(alpha: context.starOpacity),
      ),
    );
  }
}

class _SkyPainter extends CustomPainter {
  const _SkyPainter({
    required this.sky1,
    required this.sky2,
    required this.sky3,
    required this.onSky,
    required this.sun,
    required this.star,
  });

  final Color sky1;
  final Color sky2;
  final Color sky3;
  final Color onSky;
  final Color sun;
  final Color star;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    /// css shows the top half of a 200% gradient: sky1, sky2 at 28%, sky3 at 50%
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [sky1, sky2, sky3],
          stops: const [0, _sky2Stop, 1],
        ).createShader(rect),
    );
    canvas.save();
    final scale = size.width / SizeManager.snippet;
    canvas.scale(scale);

    for (final (x, y, diameter) in _stars) {
      canvas.drawCircle(Offset(x, y), diameter / 2, Paint()..color = star);
    }
    for (final (x, y, diameter) in _particles) {
      final center = Offset(x + diameter / 2, y + diameter / 2);
      canvas.drawCircle(
        center,
        diameter / 2,
        Paint()
          ..shader = RadialGradient(
            colors: [
              sun.withValues(alpha: _particleAlpha),
              sun.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: diameter / 2)),
      );
    }

    final arc = Rect.fromCircle(center: _arcCenter, radius: _arcRadius);
    final dashed = Paint()
      ..color = onSky.withValues(alpha: _dashedAlpha)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const half = math.pi * _arcRadius;
    for (var along = 0.0; along < half; along += _dash + _gap) {
      canvas.drawArc(arc, math.pi + along / _arcRadius, _dash / _arcRadius, false, dashed);
    }

    /// from the start of the arc, at the horizon on the left, clockwise to the sun
    canvas.drawArc(
      arc,
      math.pi,
      (_sun - _arcCenter).direction + math.pi,
      false,
      Paint()
        ..color = onSky.withValues(alpha: _doneAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _doneWidth
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      const Offset(0, SizeManager.snippetHorizon),
      const Offset(SizeManager.snippet, SizeManager.snippetHorizon),
      Paint()..color = onSky.withValues(alpha: _horizonAlpha),
    );
    canvas.drawCircle(
      _sun,
      SizeManager.snippetSun / 2 + SizeManager.snippetSunSpread,
      Paint()
        ..color = sun.withValues(alpha: _sunGlowAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, SizeManager.snippetSunBlur / 2),
    );
    canvas.drawCircle(_sun, SizeManager.snippetSun / 2, Paint()..color = sun);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SkyPainter old) =>
      old.sky1 != sky1 ||
      old.sky2 != sky2 ||
      old.sky3 != sky3 ||
      old.onSky != onSky ||
      old.sun != sun ||
      old.star != star;
}
