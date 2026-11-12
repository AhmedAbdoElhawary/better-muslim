import 'dart:math' as math;

import 'package:better_muslim/core/qibla/wmm2025.dart';

const _maxDegree = 12;
const _wgs84A = 6378.137;
const _wgs84F = 1 / 298.257223563;
const _wgs84E2 = _wgs84F * (2 - _wgs84F);
const _earthRadius = 6371.2;

/// magnetic declination in degrees east, the World Magnetic Model 2025 (NOAA's report, section 1.2)
double declination(
  double latitude,
  double longitude, {
  double altitudeKm = 0,
  required double decimalYear,
}) {
  final lat = latitude * math.pi / 180;
  final lon = longitude * math.pi / 180;

  /// the model works on a sphere, the position comes on the WGS84 ellipsoid
  final rc = _wgs84A / math.sqrt(1 - _wgs84E2 * math.pow(math.sin(lat), 2));
  final p = (rc + altitudeKm) * math.cos(lat);
  final z = (rc * (1 - _wgs84E2) + altitudeKm) * math.sin(lat);
  final r = math.sqrt(p * p + z * z);
  final geocentric = math.asin(z / r);

  final t = decimalYear - wmm2025Epoch;
  final cosTheta = math.sin(geocentric);
  final sinTheta = math.cos(geocentric);

  /// schmidt semi-normalized legendre functions of the colatitude and their derivatives
  final pnm = List.generate(_maxDegree + 1, (_) => List.filled(_maxDegree + 1, 0.0));
  final dpnm = List.generate(_maxDegree + 1, (_) => List.filled(_maxDegree + 1, 0.0));
  pnm[0][0] = 1;
  for (var n = 1; n <= _maxDegree; n++) {
    for (var m = 0; m <= n; m++) {
      if (n == m) {
        pnm[n][m] = sinTheta * pnm[n - 1][m - 1];
        dpnm[n][m] = sinTheta * dpnm[n - 1][m - 1] + cosTheta * pnm[n - 1][m - 1];
      } else if (n == 1) {
        pnm[n][m] = cosTheta * pnm[n - 1][m];
        dpnm[n][m] = cosTheta * dpnm[n - 1][m] - sinTheta * pnm[n - 1][m];
      } else {
        final k = m > n - 2 ? 0.0 : ((n - 1) * (n - 1) - m * m) / ((2 * n - 1) * (2 * n - 3));
        final before = m > n - 2 ? 0.0 : pnm[n - 2][m];
        final dBefore = m > n - 2 ? 0.0 : dpnm[n - 2][m];
        pnm[n][m] = cosTheta * pnm[n - 1][m] - k * before;
        dpnm[n][m] = cosTheta * dpnm[n - 1][m] - sinTheta * pnm[n - 1][m] - k * dBefore;
      }
    }
  }

  /// the recursion above is gauss normalized, these factors turn it schmidt
  final schmidt = List.generate(_maxDegree + 1, (_) => List.filled(_maxDegree + 1, 0.0));
  schmidt[0][0] = 1;
  for (var n = 1; n <= _maxDegree; n++) {
    schmidt[n][0] = schmidt[n - 1][0] * (2 * n - 1) / n;
    for (var m = 1; m <= n; m++) {
      schmidt[n][m] = schmidt[n][m - 1] * math.sqrt((n - m + 1) * (m == 1 ? 2 : 1) / (n + m));
    }
  }

  var north = 0.0;
  var east = 0.0;
  var down = 0.0;
  for (final (n, m, g, h, gDot, hDot) in wmm2025) {
    final gnm = g + t * gDot;
    final hnm = h + t * hDot;
    final ratio = math.pow(_earthRadius / r, n + 2);
    final cosM = math.cos(m * lon);
    final sinM = math.sin(m * lon);
    final legendre = pnm[n][m] * schmidt[n][m];
    final dLegendre = dpnm[n][m] * schmidt[n][m];
    north += ratio * (gnm * cosM + hnm * sinM) * dLegendre;
    east += ratio * m * (gnm * sinM - hnm * cosM) * legendre / sinTheta;
    down -= (n + 1) * ratio * (gnm * cosM + hnm * sinM) * legendre;
  }

  /// back from the sphere to the ellipsoid's north. east doesn't change
  final tilt = geocentric - lat;
  final x = north * math.cos(tilt) - down * math.sin(tilt);
  return math.atan2(east, x) * 180 / math.pi;
}

double decimalYear(DateTime date) {
  final start = DateTime.utc(date.year);
  final day = DateTime.utc(date.year, date.month, date.day).difference(start).inDays;
  final days = DateTime.utc(date.year + 1).difference(start).inDays;
  return date.year + day / days;
}
