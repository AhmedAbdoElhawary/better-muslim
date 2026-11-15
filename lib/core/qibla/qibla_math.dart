import 'dart:math' as math;

import 'package:adhan_dart/adhan_dart.dart' show Coordinates, Qibla;
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:intl/intl.dart';

/// the mean radius, the equatorial one makes london 4,800 km instead of the design's 4,790 (R4)
const _earthRadiusKm = 6371.0088;

const _wgs84F = 1 / 298.257223563;

/// degrees from true north on the WGS84 ellipsoid (vincenty), the sphere was up to 0.25° off.
/// near the kaaba's antipode it may not converge, the great circle is used there
double qiblaBearing(double latitude, double longitude) {
  double rad(double degrees) => degrees * math.pi / 180;
  final u1 = math.atan((1 - _wgs84F) * math.tan(rad(latitude)));
  final u2 = math.atan((1 - _wgs84F) * math.tan(rad(Qibla.makkah.latitude)));
  final (sinU1, cosU1, sinU2, cosU2) = (math.sin(u1), math.cos(u1), math.sin(u2), math.cos(u2));
  final l = rad(Qibla.makkah.longitude - longitude);
  var lambda = l;
  for (var i = 0; i < 200; i++) {
    final sinLambda = math.sin(lambda);
    final cosLambda = math.cos(lambda);
    final sinSigma = math.sqrt(
      math.pow(cosU2 * sinLambda, 2) + math.pow(cosU1 * sinU2 - sinU1 * cosU2 * cosLambda, 2),
    );
    if (sinSigma == 0) return 0;
    final cosSigma = sinU1 * sinU2 + cosU1 * cosU2 * cosLambda;
    final sigma = math.atan2(sinSigma, cosSigma);
    final sinAlpha = cosU1 * cosU2 * sinLambda / sinSigma;
    final cos2Alpha = 1 - sinAlpha * sinAlpha;

    /// on the equator cos2Alpha is 0 and the line runs along it
    final cos2SigmaM = cos2Alpha == 0 ? 0.0 : cosSigma - 2 * sinU1 * sinU2 / cos2Alpha;
    final c = _wgs84F / 16 * cos2Alpha * (4 + _wgs84F * (4 - 3 * cos2Alpha));
    final previous = lambda;
    lambda =
        l +
        (1 - c) *
            _wgs84F *
            sinAlpha *
            (sigma +
                c * sinSigma * (cos2SigmaM + c * cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM)));
    if ((lambda - previous).abs() < 1e-12) {
      final azimuth = math.atan2(
        cosU2 * math.sin(lambda),
        cosU1 * sinU2 - sinU1 * cosU2 * math.cos(lambda),
      );
      return (azimuth * 180 / math.pi + 360) % 360;
    }
  }
  return Qibla.qibla(Coordinates(latitude, longitude));
}

/// haversine to the kaaba
double kaabaDistanceKm(double latitude, double longitude) {
  double rad(double degrees) => degrees * math.pi / 180;
  final dLat = rad(Qibla.makkah.latitude - latitude);
  final dLon = rad(Qibla.makkah.longitude - longitude);
  final a =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(latitude)) *
          math.cos(rad(Qibla.makkah.latitude)) *
          math.pow(math.sin(dLon / 2), 2);
  return 2 * _earthRadiusKm * math.asin(math.sqrt(a));
}

/// within this many degrees the phone faces the qibla
const qiblaAlignedWithin = 3.0;

/// the shortest signed turn from the heading to the bearing, in (−180, 180], positive = right
double qiblaDiff(double bearing, double heading) {
  final diff = (bearing - heading + 540) % 360 - 180;
  return diff == -180 ? 180 : diff;
}

/// "Turn 0° right" would read as aligned, so it never goes below 1
int turnDegrees(double diff) => math.max(1, diff.abs().round());

/// FR-009, the unit picked after rounding so 999.6 m shows 1 km, not 1,000 m
({String key, String value}) formatDistance(
  double km, {
  required String language,
  required Digits digits,
}) {
  final metres = (km * 100).round() * 10;
  final whole = km.round();
  final (key, number) = metres < 1000
      ? (StringsManager.distanceM, metres)
      : whole < 100
      ? (StringsManager.distanceKm, whole)
      : (StringsManager.distanceKm, (km / 10).round() * 10);
  final text = formatDigitsIn(
    NumberFormat('#,##0', 'en').format(number),
    language: language,
    digits: digits,
  );
  final eastern = language == 'ar' && digits == Digits.eastern;
  return (key: key, value: eastern ? text.replaceAll(',', '٬') : text);
}
