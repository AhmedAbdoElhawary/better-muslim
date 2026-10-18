import 'dart:async';

import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/location/place.dart';
import 'package:better_muslim/core/location/place_list.dart';
import 'package:better_muslim/core/location/position_source.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

final locationControllerProvider = Provider<LocationController>(LocationController.new);

/// the only writer of the location. nothing here logs or reports a position or a name (FR-025)
class LocationController {
  LocationController(this._ref) {
    final listener = AppLifecycleListener(onResume: _onResume);
    _ref.onDispose(listener.dispose);
  }

  final Ref _ref;
  DateTime? _lastRefresh;
  final _firstLocate = Completer<void>();

  static const _minMoveMeters = 30000.0;
  static const _refreshEvery = Duration(minutes: 30);

  Future<void> refresh() => _locate(force: false);

  /// done once the first locate ends, saved, refused or no fix. the notification ask waits for it
  Future<void> get firstLocate => _firstLocate.future;

  Future<void> choose(Place place) =>
      _save(place, (latitude: place.latitude, longitude: place.longitude), LocationMode.manual);

  /// the user asked for it, so unlike refresh it asks again even with a location saved. false =
  /// denied, location off or no fix, and nothing is changed
  Future<bool> useAuto() async {
    final source = _ref.read(positionSourceProvider);
    var permission = await source.permission();
    if (permission == LocationPermission.denied) permission = await source.request();
    if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
      return false;
    }
    final position = await source.fix();
    if (position == null) return false;
    _lastRefresh = _ref.read(clockProvider)();

    /// the manual place may be under 30 km away, auto still has to name where the phone is
    final place = (await _placeList()).nearest(position.latitude, position.longitude);
    await _save(place, position, LocationMode.auto);
    return true;
  }

  Future<void> _onResume() async {
    await _ref.read(phoneZoneProvider.notifier).refresh();

    /// the midnight timer counts elapsed time, a clock changed by hand is only seen here
    _ref.invalidate(todayProvider);
    final last = _lastRefresh;
    if (last != null && _ref.read(clockProvider)().difference(last) < _refreshEvery) return;
    await refresh();
  }

  Future<void> _locate({required bool force}) async {
    try {
      await _locateOnce(force: force);
    } finally {
      if (!_firstLocate.isCompleted) _firstLocate.complete();
    }
  }

  Future<void> _locateOnce({required bool force}) async {
    _lastRefresh = _ref.read(clockProvider)();

    /// riverpod pauses a provider nobody listens to, so settingsProvider.future could wait forever
    final settings = await _ref.read(databaseProvider).watchSettings().first;

    /// a place picked by hand is never replaced by gps
    if (settings.locationMode == LocationMode.manual) return;
    final source = _ref.read(positionSourceProvider);
    var permission = await source.permission();

    /// android says denied before the first ask too, so with a location saved the app never nags
    if (permission == LocationPermission.denied && settings.latitude == null) {
      permission = await source.request();
    }
    if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
      return;
    }
    final position = await source.fix();
    if (position == null) return;
    final latitude = settings.latitude;
    final longitude = settings.longitude;
    if (!force &&
        latitude != null &&
        longitude != null &&
        Geolocator.distanceBetween(latitude, longitude, position.latitude, position.longitude) <
            _minMoveMeters) {
      return;
    }

    final place = (await _placeList()).nearest(position.latitude, position.longitude);
    await _save(place, position, LocationMode.auto);
  }

  /// method and asr are left alone, null stays by country and a user's pick stays (FR-012)
  Future<void> _save(Place place, LatLng position, LocationMode mode) => _ref
      .read(databaseProvider)
      .updateSettings(
        SettingsCompanion(
          latitude: Value(position.latitude),
          longitude: Value(position.longitude),
          placeName: Value(place.name),
          placeNameAr: Value(place.nameAr),
          regionName: Value(place.region),
          regionNameAr: Value(place.regionAr),
          countryCode: Value(place.countryCode),
          timeZone: Value(place.timeZone),
          locationMode: Value(mode),
        ),
      );

  /// listened, not read, so the auto dispose list stays loaded until the future is done
  Future<PlaceList> _placeList() async {
    final subscription = _ref.listen(placeListProvider.future, (_, _) {});
    try {
      return await subscription.read();
    } finally {
      subscription.close();
    }
  }
}
