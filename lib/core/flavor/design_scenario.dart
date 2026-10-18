import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/location/position_source.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_method.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:timezone/timezone.dart' show TZDateTime, getLocation;

/// the moment every PNG shows: thu 15 oct 2026, 16:32 in makkah (FR-026). dev builds only
List<Override> designScenarioOverrides() {
  final riyadh = getLocation('Asia/Riyadh');
  TZDateTime at(int hour, int minute) => TZDateTime(riyadh, 2026, 10, 15, hour, minute);
  return [
    clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 15, 13, 32)),
    locationProvider.overrideWithValue(
      Location(
        latitude: 21.4225,
        longitude: 39.8262,
        placeName: 'Makkah',
        placeNameAr: 'مكة المكرمة',
        regionName: 'Mecca Region',
        countryCode: 'SA',
        zone: riyadh,
        mode: LocationMode.auto,
      ),
    ),

    /// the handoff's times, a real calculation gives fajr 05:00, sunrise 06:16, dhuhr 12:06 (R10)
    todayTimesProvider.overrideWithValue(
      DayTimes(
        date: DateTime(2026, 10, 15),
        fajr: at(4, 58),
        sunrise: at(6, 15),
        dhuhr: at(12, 5),
        asr: at(15, 27),
        maghrib: at(17, 56),
        isha: at(19, 26),
        method: PrayerMethod.ummAlQura,
        asrMethod: AsrMethod.standard,
      ),
    ),
    positionSourceProvider.overrideWithValue(const _NoPosition()),
  ];
}

/// denied forever, so the location controller never asks and never reaches geolocator
class _NoPosition implements PositionSource {
  const _NoPosition();

  @override
  Future<LocationPermission> permission() async => LocationPermission.deniedForever;

  @override
  Future<LocationPermission> request() async => LocationPermission.deniedForever;

  @override
  Future<LatLng?> fix() async => null;
}
