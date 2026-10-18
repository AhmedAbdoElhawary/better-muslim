import 'dart:math' as math;

import 'package:adhan_dart/adhan_dart.dart' show Coordinates, Qibla;
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:intl/intl.dart';

/// the mean radius, the equatorial one makes london 4,800 km instead of the design's 4,790 (R4)
const _earthRadiusKm = 6371.0088;

/// degrees from true north, great circle
double qiblaBearing(double latitude, double longitude) =>
    Qibla.qibla(Coordinates(latitude, longitude));

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
