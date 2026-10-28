import 'dart:ui' show lerpDouble;

import 'package:better_muslim/core/prayer_times/sky_state.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/ambient.dart';
import 'package:better_muslim/features/onboarding/model/sun_choreography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 4.10's ten stars: out of the sun to their places, then twinkling (R7)
class WelcomeStars extends ConsumerWidget {
  const WelcomeStars({
    required this.ch,
    required this.origin,
    required this.flight,
    required this.shown,
    required this.ambient,
    super.key,
  });

  final SunChoreography ch;

  /// the sun's centre, where they leave from
  final Offset origin;

  /// the build value they fly on, it never goes back while the welcome is undone by a drag
  final double flight;

  /// 0 hides them, the fade when going back and 4.11 covering the welcome
  final double shown;

  final ValueListenable<Duration>? ambient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(skyStateProvider.select(starsOn));
    return RepaintBoundary(
      child: CustomPaint(
        painter: WelcomeStarsPainter(
          ch: ch,
          origin: origin,
          flight: flight,
          shown: shown,
          strength: on ? 1 : 0,
          starOpacity: context.starOpacity,
          color: context.getColor(ThemeEnum.onSkyBright),
          still: MediaQuery.disableAnimationsOf(context),
          ambient: ambient,
        ),
      ),
    );
  }
}

class WelcomeStarsPainter extends CustomPainter {
  WelcomeStarsPainter({
    required this.ch,
    required this.origin,
    required this.flight,
    required this.shown,
    required this.strength,
    required this.starOpacity,
    required this.color,
    required this.still,
    this.ambient,
  }) : super(repaint: ambient);

  final SunChoreography ch;
  final Offset origin;
  final double flight;
  final double shown;

  /// the sky's star strength, a day sky has none so they fade as they land
  final double strength;
  final double starOpacity;
  final Color color;

  /// reduce motion: they fade in place, no flight
  final bool still;
  final ValueListenable<Duration>? ambient;

  /// x, y, size from the 4.10 tree
  static const stars = [
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

  static const _fadeIn = 300.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (shown <= 0) return;
    final u = ch.unit;

    /// the tree's 393 pt frame, centred on a wider screen like the sun
    final left = size.width / 2 - SunChoreography.designWidth / 2 * u;
    final ms = ambient?.value.inMilliseconds.toDouble();
    final loop = ms == null ? 0.0 : (ms / _fadeIn).clamp(0.0, 1.0);
    for (final (i, star) in stars.indexed) {
      final t = still ? ch.starsInPlace(flight) : ch.starFlight(flight, i);
      if (t <= 0) continue;
      final place = Offset(left + (star[0] + star[2] / 2) * u, (star[1] + star[2] / 2) * u);
      final at = still ? place : Offset.lerp(origin, place, t)!;
      final twinkle = .15 + .85 * ambientBreathe((ms ?? 0) + (i % 5) * 600, 1800 + (i % 7) * 410);

      /// bright as they leave the sun, the sky's own strength once landed
      final land = lerpDouble(1, strength, t)!;
      final opacity = starOpacity * land * shown * (still ? t : 1) * (1 + loop * t * (twinkle - 1));
      canvas.drawCircle(
        at,
        star[2] / 2 * u * (still ? 1 : t),
        Paint()..color = color.withValues(alpha: color.a * opacity.clamp(0, 1)),
      );
    }
  }

  @override
  bool shouldRepaint(WelcomeStarsPainter old) =>
      old.ch.size != ch.size ||
      old.ch.unit != ch.unit ||
      old.origin != origin ||
      old.flight != flight ||
      old.shown != shown ||
      old.strength != strength ||
      old.starOpacity != starOpacity ||
      old.color != color ||
      old.still != still ||
      old.ambient != ambient;
}
