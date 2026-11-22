import 'dart:math' as math;

import 'package:better_muslim/core/prayer_times/sky_state.dart';
import 'package:better_muslim/core/resources/design/bm_sky.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/resources/theme_sky.dart';
import 'package:better_muslim/core/settings/appearance.dart';
import 'package:better_muslim/features/onboarding/model/sun_choreography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// 4.10's sky at the current hour, the horizon, the dotted sun arc and the mark (R7)
class WelcomeSky extends ConsumerWidget {
  const WelcomeSky({
    required this.ch,
    required this.shown,
    required this.horizon,
    required this.mark,
    super.key,
  });

  final SunChoreography ch;

  /// the sky's own fade in on the first launch
  final double shown;

  /// 0 to 1, the horizon and the arc draw out from the middle
  final double horizon;
  final double mark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(skyStateProvider);
    final stops = state == null
        ? BmSkyStops(
            context.getColor(ThemeEnum.sky1),
            context.getColor(ThemeEnum.sky2),
            context.getColor(ThemeEnum.sky3),
          )
        : themeSky(ref.watch(themeIdProvider))[state]!;
    return CustomPaint(
      painter: WelcomeSkyPainter(
        ch: ch,
        stops: stops,
        shown: shown,
        horizon: horizon,
        mark: mark,
        onSky: context.getColor(ThemeEnum.onSky),
        primary: context.getColor(ThemeEnum.primary),
        scrim: context.getColor(ThemeEnum.welcomeScrim),
      ),
    );
  }
}

class WelcomeSkyPainter extends CustomPainter {
  WelcomeSkyPainter({
    required this.ch,
    required this.stops,
    required this.shown,
    required this.horizon,
    required this.mark,
    required this.onSky,
    required this.primary,
    required this.scrim,
  });

  final SunChoreography ch;
  final BmSkyStops stops;
  final double shown;
  final double horizon;
  final double mark;
  final Color onSky;
  final Color primary;
  final Color scrim;

  /// the tree's svg: the arc at 45% onSky, dash 1 gap 5, the horizon at 30%
  static const _arcAlpha = .45;
  static const _horizonAlpha = .3;
  static const _dash = 1.0;
  static const _gap = 5.0;

  /// the 8 point star of the mark in its -11..11 viewBox, its stroke is .6 there
  static const _markBox = 22.0;
  static const _markStroke = .6;
  static const _markPoints = [
    [0.0, -10.0], [2.93, -7.07], [7.07, -7.07], [7.07, -2.93], //
    [10.0, 0.0], [7.07, 2.93], [7.07, 7.07], [2.93, 7.07], //
    [0.0, 10.0], [-2.93, 7.07], [-7.07, 7.07], [-7.07, 2.93], //
    [-10.0, 0.0], [-7.07, -2.93], [-7.07, -7.07], [-2.93, -7.07],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final full = Offset.zero & size;

    /// a layer only reads its paint's alpha
    canvas.saveLayer(full, Paint()..color = scrim.withValues(alpha: shown));
    canvas.drawRect(full, Paint()..shader = bmSkyGradient(stops, 0).createShader(full));

    /// fades in under the horizon, full from where the title starts
    final fade = SizeManager.skyScrimFade * ch.unit;
    canvas.drawRect(
      Rect.fromLTRB(0, ch.horizonY, size.width, size.height),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [scrim.withValues(alpha: 0), scrim, scrim],
          stops: [0, fade / (size.height - ch.horizonY), 1],
        ).createShader(Rect.fromLTRB(0, ch.horizonY, size.width, size.height)),
    );
    canvas.restore();

    final u = ch.unit;
    final cx = size.width / 2;
    final y = ch.horizonY;
    if (horizon > 0) {
      canvas.drawLine(
        Offset(cx - cx * horizon, y),
        Offset(cx + cx * horizon, y),
        Paint()
          ..color = onSky.withValues(alpha: _horizonAlpha * horizon)
          ..strokeWidth = SizeManager.divider,
      );
      final radius = SizeManager.welcomeArcRadius * u;
      final dotted = Paint()
        ..color = onSky.withValues(alpha: _arcAlpha * horizon)
        ..strokeWidth = SizeManager.divider
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      /// out from the top of the arc both ways, like the horizon from the middle
      final half = math.pi / 2 * horizon;
      final step = (_dash + _gap) * u / radius;
      for (var a = -half; a < half; a += step) {
        final start = -math.pi / 2 + a;
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, y), radius: radius),
          start,
          _dash * u / radius,
          false,
          dotted,
        );
      }
    }

    if (mark > 0) {
      final side = SizeManager.welcomeMark * u;
      final scale = side / _markBox * (.8 + .2 * mark);
      final center = Offset(cx, (SpaceManager.welcomeMarkTop * u) + side / 2);
      final path = Path();
      for (final (i, point) in _markPoints.indexed) {
        final p = center + Offset(point[0], point[1]) * scale;
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = primary.withValues(alpha: mark)
          ..style = PaintingStyle.stroke
          ..strokeWidth = _markStroke * scale
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(WelcomeSkyPainter old) =>
      old.ch.size != ch.size ||
      old.ch.unit != ch.unit ||
      old.stops.top != stops.top ||
      old.stops.mid != stops.mid ||
      old.stops.bottom != stops.bottom ||
      old.shown != shown ||
      old.horizon != horizon ||
      old.mark != mark ||
      old.onSky != onSky ||
      old.primary != primary ||
      old.scrim != scrim;
}
