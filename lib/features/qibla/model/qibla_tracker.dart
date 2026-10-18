enum QiblaPhase { turning, aligned }

enum QiblaEvent { approach, aligned }

/// turns each difference into the phase and the haptic events (R6). the gaps between 3 and 5 and
/// between 10 and 15 keep ±1° jitter from repeating a haptic
class QiblaTracker {
  static const _alignIn = 3.0;
  static const _alignOut = 5.0;
  static const _approachIn = 10.0;
  static const _rearm = 15.0;
  static const _hold = Duration(milliseconds: 400);

  QiblaPhase phase = QiblaPhase.turning;
  DateTime? _insideSince;
  bool _armed = true;
  double? _lastDiff;

  List<QiblaEvent> update(double diff, DateTime now) {
    final size = diff.abs();
    final last = _lastDiff;
    _lastDiff = diff;
    final events = <QiblaEvent>[];
    if (size > _rearm) _armed = true;

    /// opening already inside 10° entered nothing
    if (size <= _approachIn && _armed && last != null && last.abs() > _approachIn) {
      _armed = false;
      events.add(QiblaEvent.approach);
    }
    if (phase == QiblaPhase.aligned) {
      if (size > _alignOut) phase = QiblaPhase.turning;
    } else if (size <= _alignIn) {
      _insideSince ??= now;
    } else {
      _insideSince = null;
    }
    return events..addAll(check(now));
  }

  /// called by a timer too, a still phone sends no reading to end the 400 ms
  List<QiblaEvent> check(DateTime now) {
    final alignAt = this.alignAt;
    if (alignAt == null || now.isBefore(alignAt)) return const [];
    phase = QiblaPhase.aligned;
    _insideSince = null;
    return const [QiblaEvent.aligned];
  }

  DateTime? get alignAt {
    final since = _insideSince;
    return phase == QiblaPhase.turning && since != null ? since.add(_hold) : null;
  }

  void reset() {
    phase = QiblaPhase.turning;
    _insideSince = null;
    _armed = true;
    _lastDiff = null;
  }
}
