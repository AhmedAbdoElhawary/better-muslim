import 'dart:async';

import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/flavor/design_scenario.dart';
import 'package:better_muslim/core/flavor/flavor_config.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/location/place_list.dart';
import 'package:better_muslim/core/location/position_source.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

typedef QiblaPlace = ({double latitude, double longitude, String? name, String? nameAr});

/// where the phone was last seen for the qibla and its north, never saved (R10). a city picked by
/// hand is only for prayer times (spec 027)
final qiblaFixProvider = NotifierProvider<QiblaFix, QiblaPlace?>(QiblaFix.new);

class QiblaFix extends Notifier<QiblaPlace?> {
  static const _renameAfterMeters = 1000.0;
  static const _staleAfter = Duration(minutes: 30);

  DateTime? _at;

  @override
  QiblaPlace? build() => null;

  /// home's, one fix unless a fresh one is already here. never asks for permission
  Future<void> once() async {
    final at = _at;
    if (at != null && ref.read(clockProvider)().difference(at) < _staleAfter) return;
    final source = ref.read(positionSourceProvider);
    if (!_granted(await source.permission())) return;
    final fix = await source.fix(accuracy: LocationAccuracy.high);
    if (fix != null) await update(fix);
  }

  /// a kilometre off in makkah turns the needle by up to 11°, so the fix is used as it is. only
  /// the name waits for the phone to move
  Future<void> update(LatLng fix) async {
    _at = ref.read(clockProvider)();
    final last = state;
    if (last != null &&
        Geolocator.distanceBetween(last.latitude, last.longitude, fix.latitude, fix.longitude) <
            _renameAfterMeters) {
      state = (
        latitude: fix.latitude,
        longitude: fix.longitude,
        name: last.name,
        nameAr: last.nameAr,
      );
      return;
    }
    final place = (await _placeList()).nearest(fix.latitude, fix.longitude);
    state = (
      latitude: fix.latitude,
      longitude: fix.longitude,
      name: place.name,
      nameAr: place.nameAr,
    );
  }

  /// listened, not read, so the auto dispose list stays loaded until the future is done
  Future<PlaceList> _placeList() async {
    final subscription = ref.listen(placeListProvider.future, (_, _) {});
    try {
      return await subscription.read();
    } finally {
      subscription.close();
    }
  }
}

bool _granted(LocationPermission permission) =>
    permission == LocationPermission.whileInUse || permission == LocationPermission.always;

/// the fix, else the saved place. the design scenario is always london (R12)
final qiblaPlaceProvider = Provider.autoDispose<QiblaPlace?>((ref) {
  final isDesign = ref.watch(flavorProvider.select((config) => config.isDesignScenario));
  if (isDesign) return designQiblaPlace;
  final fix = ref.watch(qiblaFixProvider);
  if (fix != null) return fix;
  return ref.watch(
    locationProvider.select(
      (location) => location == null
          ? null
          : (
              latitude: location.latitude,
              longitude: location.longitude,
              name: location.placeName,
              nameAr: location.placeNameAr,
            ),
    ),
  );
});

/// home's card listens to it, one fix each time it shows
final qiblaOnceProvider = FutureProvider.autoDispose<void>(
  (ref) => ref.read(qiblaFixProvider.notifier).once(),
);

/// the qibla page listens to it: the phone every 10 m while the page is shown and the app is in
/// front. it asks for permission while the phone still lets it
final qiblaFollowProvider = Provider.autoDispose<void>((ref) {
  final source = ref.read(positionSourceProvider);
  final fix = ref.read(qiblaFixProvider.notifier);
  StreamSubscription<LatLng>? subscription;

  /// shown and in front, a pause while the permission is read must not start it after
  var on = true;

  /// once per page, the phone's dialog pauses the app on android and the resume would ask again
  var asked = false;

  Future<void> start() async {
    on = true;
    var permission = await source.permission();
    if (permission == LocationPermission.denied && !asked) {
      asked = true;
      permission = await source.request();
    }
    if (!on || subscription != null || !_granted(permission)) return;
    subscription = source.positions().listen(fix.update);
  }

  void stop() {
    on = false;
    subscription?.cancel();
    subscription = null;
  }

  start();
  final lifecycle = AppLifecycleListener(onPause: stop, onResume: start);
  ref.onDispose(() {
    lifecycle.dispose();
    stop();
  });
});
