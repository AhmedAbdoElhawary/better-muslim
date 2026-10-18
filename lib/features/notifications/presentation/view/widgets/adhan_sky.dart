import 'dart:math' as math;

import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/design/bm_sky.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/widgets/ellipse_transform.dart';
import 'package:better_muslim/features/notifications/presentation/view/adhan_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// maghrib is 4.03 exactly. the others get their own sky with the sun where it really is, and no
/// sun at fajr and isha (FR-029)
class AdhanSky extends ConsumerStatefulWidget {
  const AdhanSky({required this.prayer, required this.day, super.key});

  final Prayer prayer;
  final DateTime day;

  /// where the sun's center sits in the 393 x 852 frame, null at night
  static double? sunY(Prayer prayer, DayTimes? times) {
    if (prayer == Prayer.maghrib) return SpaceManager.adhanSunTop + SizeManager.adhanSun / 2;
    final time = times?.timeOf(prayer);
    final sunrise = times?.sunrise;
    final maghrib = times?.maghrib;
    if (time == null || sunrise == null || maghrib == null) return null;
    final fraction = BmSunArc.fraction(time, sunrise, maghrib);
    if (fraction == null) return null;
    const horizon = SpaceManager.adhanHorizonTop;
    return horizon - math.sin(math.pi * fraction) * (horizon - SpaceManager.adhanHeaderTop);
  }

  @override
  ConsumerState<AdhanSky> createState() => _AdhanSkyState();
}

class _AdhanSkyState extends ConsumerState<AdhanSky> with SingleTickerProviderStateMixin {
  /// MOTION halo: 3000 ms each way
  late final _controller = AnimationController(vsync: this, duration: BmMotion.glowLoop);
  late final _breath = CurvedAnimation(parent: _controller, curve: BmMotion.breathe);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final times = ref.watch(dayTimesProvider(widget.day));
    final sunY = AdhanSky.sunY(widget.prayer, times);
    final still = MediaQuery.disableAnimationsOf(context) || sunY == null;
    if (still) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _AdhanSkyPainter(
          prayer: widget.prayer,
          sunY: sunY,
          breath: still ? null : _breath,

          /// the .r factor, the painter works in the mockup's points
          scale: ScreenUtil().radius(1),
        ),
      ),
    );
  }
}

class _AdhanSkyPainter extends CustomPainter {
  _AdhanSkyPainter({
    required this.prayer,
    required this.sunY,
    required this.breath,
    required this.scale,
  }) : super(repaint: breath);

  final Prayer prayer;
  final double? sunY;

  /// null stands still at full opacity and size
  final Animation<double>? breath;
  final double scale;

  /// 4.03 puts the halo's center 2 pt above the sun's
  static const _haloBelowSun =
      SpaceManager.adhanHaloTop +
      SizeManager.adhanHaloH / 2 -
      SpaceManager.adhanSunTop -
      SizeManager.adhanSun / 2;

  static const _skyOf = {
    Prayer.fajr: BmSkyState.fajr,
    Prayer.dhuhr: BmSkyState.dhuhr,
    Prayer.asr: BmSkyState.asr,
    Prayer.isha: BmSkyState.isha,
  };

  @override
  void paint(Canvas canvas, Size size) {
    final full = Offset.zero & size;
    final stops = bmSkyQiyamEmerald[_skyOf[prayer]];
    canvas.drawRect(
      full,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: stops == null ? AdhanColors.skyStops : [stops.top, stops.mid, stops.bottom],
          stops: stops == null ? AdhanColors.skyAt : null,
        ).createShader(full),
    );

    final horizon = SpaceManager.adhanHorizonTop * scale;
    canvas.drawRect(
      Rect.fromLTWH(0, horizon, size.width, SizeManager.adhanHorizon),
      Paint()..color = AdhanColors.horizon,
    );

    final sunY = this.sunY;
    if (sunY == null) return;
    final center = Offset(size.width / 2, sunY * scale);

    /// opacity .7 to 1 and scale .97 to 1.04, the halo's center stays on the sun
    final t = breath?.value;
    final opacity = t == null ? 1.0 : .7 + .3 * t;
    final grow = t == null ? 1.0 : .97 + .07 * t;
    final halo = Rect.fromCenter(
      center: center.translate(0, _haloBelowSun * scale),
      width: SizeManager.adhanHaloW * scale * grow,
      height: SizeManager.adhanHaloH * scale * grow,
    );
    canvas.drawOval(
      halo,
      Paint()
        ..shader = RadialGradient(
          /// css "ellipse" reaches the corners, half the diagonal of a square
          radius: math.sqrt1_2,
          colors: [
            AdhanColors.halo.withValues(alpha: AdhanColors.halo.a * opacity),
            AdhanColors.haloEdge,
          ],
          stops: const [0, .65],
          transform: const EllipseTransform(),
        ).createShader(halo),
    );

    /// the sun sets behind the horizon, so it and its glow stop there
    canvas
      ..save()
      ..clipRect(Rect.fromLTWH(0, 0, size.width, horizon));
    final radius = SizeManager.adhanSun / 2 * scale;
    canvas
      ..drawCircle(
        center,
        radius + SizeManager.adhanSunSpread * scale,
        Paint()
          ..color = AdhanColors.sunGlow
          /// a css blur radius is twice the sigma
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, SizeManager.adhanSunBlur / 2 * scale),
      )
      ..drawCircle(center, radius, Paint()..color = AdhanColors.sun)
      ..restore();
  }

  @override
  bool shouldRepaint(_AdhanSkyPainter old) =>
      old.prayer != prayer || old.sunY != sunY || old.breath != breath || old.scale != scale;
}
