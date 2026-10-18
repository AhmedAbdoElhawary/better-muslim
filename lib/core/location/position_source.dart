import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

final positionSourceProvider = Provider<PositionSource>((ref) => const PositionSource());

typedef LatLng = ({double latitude, double longitude});

/// geolocator behind one small class, so tests and the design scenario can swap it
class PositionSource {
  const PositionSource();

  Future<LocationPermission> permission() => Geolocator.checkPermission();

  /// while in use only, the app never asks for background location
  Future<LocationPermission> request() => Geolocator.requestPermission();

  /// coarse is enough for prayer times and works offline. null = indoors, gps off or too slow.
  /// the qibla asks for high, a kilometre off in makkah turns the needle by up to 11°
  Future<LatLng?> fix({LocationAccuracy accuracy = LocationAccuracy.low}) async {
    /// with location off android shows a turn it on dialog on every refresh, the saved location
    /// just stays instead (edge cases: gps off)
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: const Duration(seconds: 15),
        ),
      );
      return (latitude: position.latitude, longitude: position.longitude);
    } on TimeoutException {
      return _lastKnown();
    } on LocationServiceDisabledException {
      return null;
    }
  }

  Future<LatLng?> _lastKnown() async {
    final position = await Geolocator.getLastKnownPosition();
    return position == null ? null : (latitude: position.latitude, longitude: position.longitude);
  }
}
