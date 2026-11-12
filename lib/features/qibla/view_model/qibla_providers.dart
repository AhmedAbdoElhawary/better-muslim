import 'dart:async';

import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/flavor/design_scenario.dart';
import 'package:better_muslim/core/flavor/flavor_config.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/location/position_source.dart';
import 'package:better_muslim/core/qibla/compass.dart';
import 'package:better_muslim/core/qibla/qibla_math.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/qibla/model/qibla_tracker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

typedef QiblaPlace = ({double latitude, double longitude, String? name, String? nameAr});

typedef QiblaTarget = ({double bearing, double distanceKm});

enum QiblaState { noLocation, waiting, noCompass, ready }

final _isDesignProvider = Provider.autoDispose<bool>(
  (ref) => ref.watch(flavorProvider.select((config) => config.isDesignScenario)),
);

/// the saved place at once, then a precise fix in auto mode. the fix is never saved (R10)
final qiblaPlaceProvider = StreamProvider.autoDispose<QiblaPlace?>((ref) async* {
  if (ref.watch(_isDesignProvider)) {
    yield (
      latitude: designQiblaPlace.latitude,
      longitude: designQiblaPlace.longitude,
      name: designQiblaPlace.name,
      nameAr: designQiblaPlace.nameAr,
    );
    return;
  }

  /// a record, a new zone on resume would otherwise take another fix
  final location = ref.watch(
    locationProvider.select(
      (location) => location == null
          ? null
          : (
              latitude: location.latitude,
              longitude: location.longitude,
              name: location.placeName,
              nameAr: location.placeNameAr,
              mode: location.mode,
            ),
    ),
  );
  if (location == null) {
    yield null;
    return;
  }
  final (:latitude, :longitude, :name, :nameAr, :mode) = location;
  yield (latitude: latitude, longitude: longitude, name: name, nameAr: nameAr);

  /// a city picked by hand is used as it is
  if (mode != LocationMode.auto) return;
  final source = ref.read(positionSourceProvider);
  final permission = await source.permission();
  if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
    return;
  }
  final fix = await source.fix(accuracy: LocationAccuracy.high);
  if (fix == null) return;
  yield (latitude: fix.latitude, longitude: fix.longitude, name: name, nameAr: nameAr);
});

final qiblaTargetProvider = Provider.autoDispose<QiblaTarget?>((ref) {
  final place = ref.watch(qiblaPlaceProvider.select((place) => place.value));
  if (place == null) return null;
  return (
    bearing: qiblaBearing(place.latitude, place.longitude),
    distanceKm: kaabaDistanceKm(place.latitude, place.longitude),
  );
});

final qiblaStateProvider = Provider.autoDispose<QiblaState>((ref) {
  final place = ref.watch(qiblaPlaceProvider.select((place) => (place.hasValue, place.value)));
  final compass = ref.watch(compassProvider.select((reading) => (reading.hasValue, reading.value)));
  if (place == (true, null)) return QiblaState.noLocation;
  if (!compass.$1 || !place.$1) return QiblaState.waiting;
  if (compass.$2 == null) return QiblaState.noCompass;
  return QiblaState.ready;
});

/// the smoothed heading's turn to the bearing, never the needle mid spring (FR-014)
final qiblaDiffProvider = Provider.autoDispose<double?>((ref) {
  final bearing = ref.watch(qiblaTargetProvider.select((target) => target?.bearing));
  final heading = ref.watch(compassProvider.select((reading) => reading.value?.heading));
  if (bearing == null || heading == null) return null;
  return qiblaDiff(bearing, heading);
});

/// whole degrees, so the title rebuilds once a degree and not on every reading
final turnDegreesProvider = Provider.autoDispose<int?>((ref) {
  final diff = ref.watch(qiblaDiffProvider);
  return diff == null ? null : turnDegrees(diff);
});

/// the tracker's phase only counts with a compass and a place
final qiblaAlignedProvider = Provider.autoDispose<bool>(
  (ref) =>
      ref.watch(qiblaStateProvider) == QiblaState.ready &&
      ref.watch(qiblaTrackerProvider.select((track) => track.phase == QiblaPhase.aligned)),
);

/// the counts go up once per haptic, the page listens for the change
typedef QiblaTrack = ({QiblaPhase phase, int approaches, int alignments});

final qiblaTrackerProvider = NotifierProvider.autoDispose<QiblaTrackerNotifier, QiblaTrack>(
  QiblaTrackerNotifier.new,
);

class QiblaTrackerNotifier extends Notifier<QiblaTrack> {
  final _tracker = QiblaTracker();
  Timer? _timer;

  @override
  QiblaTrack build() {
    ref.listen(qiblaDiffProvider, (_, diff) {
      if (diff != null) _apply(_tracker.update(diff, ref.read(clockProvider)()));
    });
    ref.listen(qiblaTargetProvider, (_, _) => _reset());
    final lifecycle = AppLifecycleListener(onPause: _reset);
    ref.onDispose(() {
      lifecycle.dispose();
      _timer?.cancel();
    });
    return (phase: QiblaPhase.turning, approaches: 0, alignments: 0);
  }

  void _apply(List<QiblaEvent> events) {
    _timer?.cancel();
    final alignAt = _tracker.alignAt;

    /// a still phone sends no reading, so a timer ends the 400 ms. it checks at alignAt itself,
    /// the design scenario's clock never moves
    if (alignAt != null) {
      _timer = Timer(alignAt.difference(ref.read(clockProvider)()), () {
        _apply(_tracker.check(alignAt));
      });
    }
    state = (
      phase: _tracker.phase,
      approaches: state.approaches + events.where((e) => e == QiblaEvent.approach).length,
      alignments: state.alignments + events.where((e) => e == QiblaEvent.aligned).length,
    );
  }

  void _reset() {
    _timer?.cancel();
    _tracker.reset();
    state = (phase: QiblaPhase.turning, approaches: state.approaches, alignments: state.alignments);
  }
}
