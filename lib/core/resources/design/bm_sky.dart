import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The six anchor sky states (02 Tokens › Living Sky · BmSky). Three stops each, top to bottom.
enum BmSkyState { fajr, sunrise, dhuhr, asr, maghrib, isha }

class BmSkyStops {
  final Color top, mid, bottom;
  const BmSkyStops(this.top, this.mid, this.bottom);
  static BmSkyStops lerp(BmSkyStops a, BmSkyStops b, double t) => BmSkyStops(
    Color.lerp(a.top, b.top, t)!,
    Color.lerp(a.mid, b.mid, t)!,
    Color.lerp(a.bottom, b.bottom, t)!,
  );
}

/// Qiyam Emerald reading of the sky. Same in light and dark mode (the sky is the sky).
const Map<BmSkyState, BmSkyStops> bmSkyQiyamEmerald = {
  BmSkyState.fajr: BmSkyStops(Color(0xFF061411), Color(0xFF1E3A3A), Color(0xFF6E5E5A)),
  BmSkyState.sunrise: BmSkyStops(Color(0xFF2B3B36), Color(0xFF8C8468), Color(0xFFD8C59A)),
  BmSkyState.dhuhr: BmSkyStops(Color(0xFF2C4A44), Color(0xFF6F8F85), Color(0xFFC9D3C8)),
  BmSkyState.asr: BmSkyStops(Color(0xFF3A3A26), Color(0xFF8F7A52), Color(0xFFD9BE86)),
  BmSkyState.maghrib: BmSkyStops(Color(0xFF120E0A), Color(0xFF4A2A1C), Color(0xFFA8643A)),
  BmSkyState.isha: BmSkyStops(Color(0xFF000000), Color(0xFF04100C), Color(0xFF173328)),
};

/// Text on the sky must stay readable on every state: use #FFFFFF at 92% on sunrise/dhuhr/asr,
/// palette.onSky elsewhere. A 0→28% black scrim sits behind the header text block on bright states.
bool bmSkyIsBright(BmSkyState s) =>
    s == BmSkyState.sunrise || s == BmSkyState.dhuhr || s == BmSkyState.asr;

/// Which state is current. The state holds from its prayer time until the next one;
/// the change itself is the 1800 ms "Sky change" animation (Motion 03), not a slow blend.
BmSkyState bmSkyStateAt(
  DateTime now, {
  required DateTime fajr,
  required DateTime sunrise,
  required DateTime dhuhr,
  required DateTime asr,
  required DateTime maghrib,
  required DateTime isha,
}) {
  if (now.isBefore(fajr)) return BmSkyState.isha;
  if (now.isBefore(sunrise)) return BmSkyState.fajr;
  if (now.isBefore(dhuhr)) return BmSkyState.sunrise;
  if (now.isBefore(asr)) return BmSkyState.dhuhr;
  if (now.isBefore(maghrib)) return BmSkyState.asr;
  if (now.isBefore(isha)) return BmSkyState.maghrib;
  return BmSkyState.isha;
}

/// How the Home header gradient is built from three stops:
/// 5-stop vertical gradient [top 0%, mid 30%, bottom 62%, mid 82%, top 100%], painted 160% tall
/// and drifted from offset 0% to 30% over 12 s (alternate, breathe curve) = the "Living Sky" loop (Motion 02).
/// The design mockups 4.1/4.2 use the theme base sky (palette.sky1/2/3, = Isha state in dark).
/// Use [BmSkyMode.themeBase] to reproduce the mockups pixel for pixel during visual QA.
enum BmSkyMode { live, themeBase }

LinearGradient bmSkyGradient(BmSkyStops s, double drift) => LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [s.top, s.mid, s.bottom, s.mid, s.top],
  stops: const [0, .30, .62, .82, 1],
  transform: _Drift(drift),
);

class _Drift extends GradientTransform {
  final double t; // 0..1 → 0%..30% of the 160% tall gradient
  const _Drift(this.t);
  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final h = bounds.height * 1.6;
    return Matrix4.identity()
      ..translateByDouble(0.0, -t * .3 * (h - bounds.height), 0.0, 1.0)
      ..scaleByDouble(1.0, 1.6, 1.0, 1.0);
  }
}

/// Sun arc geometry used in Home (4.1 / 4.2 / 4.16). Coordinates are for a 393 × 380 header.
/// The arc sits to the side of the text block so it never crosses the headline:
/// LTR center x = 249 (arc spans x 131…367); RTL center x = 144 (arc spans x 26…262).
/// The arc itself is never mirrored: sunrise is always on the left.
class BmSunArc {
  static const center = Offset(249, 300);
  static const centerRtl = Offset(144, 300);
  static const radius = 118.0;
  static const horizonY = 300.0;
  static const sunSize = 16.0;

  /// 0 at sunrise (left foot), 1 at maghrib (right foot). Null at night.
  static double? fraction(DateTime now, DateTime sunrise, DateTime maghrib) {
    if (now.isBefore(sunrise) || now.isAfter(maghrib)) return null;
    return now.difference(sunrise).inSeconds / maghrib.difference(sunrise).inSeconds;
  }

  static Offset sunCenter(double f, {bool rtl = false}) {
    final c = rtl ? centerRtl : center;
    final a = math.pi * (1 - f);
    return Offset(c.dx + radius * math.cos(a), c.dy - radius * math.sin(a));
  }
}
