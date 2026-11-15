import 'dart:async';

import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/qibla/compass.dart';
import 'package:better_muslim/core/qibla/qibla_math.dart';
import 'package:better_muslim/core/qibla/qibla_place.dart';
import 'package:better_muslim/features/qibla/model/qibla_tracker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef QiblaTarget = ({double bearing, double distanceKm});

enum QiblaState { noLocation, waiting, noCompass, ready }

final qiblaTargetProvider = Provider.autoDispose<QiblaTarget?>((ref) {
  final place = ref.watch(
    qiblaPlaceProvider.select((place) => place == null ? null : (place.latitude, place.longitude)),
  );
  if (place == null) return null;
  final (latitude, longitude) = place;
  return (
    bearing: qiblaBearing(latitude, longitude),
    distanceKm: kaabaDistanceKm(latitude, longitude),
  );
});

final qiblaStateProvider = Provider.autoDispose<QiblaState>((ref) {
  final hasPlace = ref.watch(qiblaPlaceProvider.select((place) => place != null));
  final compass = ref.watch(compassProvider.select((reading) => (reading.hasValue, reading.value)));
  if (!hasPlace) return QiblaState.noLocation;
  if (!compass.$1) return QiblaState.waiting;
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
