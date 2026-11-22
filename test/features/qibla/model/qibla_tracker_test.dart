import 'dart:math' as math;

import 'package:better_muslim/features/qibla/model/qibla_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime(2026, 10, 15, 16, 32);
  DateTime at(int ms) => start.add(Duration(milliseconds: ms));

  late QiblaTracker tracker;
  setUp(() => tracker = QiblaTracker());

  test('3° held 400 ms aligns once', () {
    expect(tracker.update(3, at(0)), isEmpty);
    expect(tracker.alignAt, at(400));
    expect(tracker.check(at(399)), isEmpty);
    expect(tracker.phase, QiblaPhase.turning);
    expect(tracker.check(at(400)), [QiblaEvent.aligned]);
    expect(tracker.phase, QiblaPhase.aligned);
    expect(tracker.check(at(800)), isEmpty);
    expect(tracker.alignAt, isNull);
  });

  test('a reading past 3° restarts the 400 ms', () {
    tracker.update(3, at(0));
    tracker.update(3.1, at(200));
    expect(tracker.alignAt, isNull);
    tracker.update(2, at(300));
    expect(tracker.check(at(400)), isEmpty);
    expect(tracker.check(at(700)), [QiblaEvent.aligned]);
  });

  test('aligned stays inside 5°, turns back past it', () {
    tracker.update(0, at(0));
    tracker.check(at(400));
    expect(tracker.update(4.9, at(500)), isEmpty);
    expect(tracker.phase, QiblaPhase.aligned);
    expect(tracker.update(-5.1, at(600)), isEmpty);
    expect(tracker.phase, QiblaPhase.turning);
    tracker.update(1, at(700));
    expect(tracker.check(at(1100)), [QiblaEvent.aligned]);
  });

  test('approach fires inside 10°, again only after 15°', () {
    tracker.update(12, at(0));
    expect(tracker.update(9.9, at(50)), [QiblaEvent.approach]);
    expect(tracker.update(12, at(100)), isEmpty);
    expect(tracker.update(9.9, at(150)), isEmpty);
    expect(tracker.update(15.1, at(200)), isEmpty);
    expect(tracker.update(9.9, at(250)), [QiblaEvent.approach]);
  });

  test('opening inside 10° gives no approach, inside 3° still aligns', () {
    expect(tracker.update(8, at(0)), isEmpty);
    tracker.reset();
    expect(tracker.update(2, at(0)), isEmpty);
    expect(tracker.check(at(400)), [QiblaEvent.aligned]);
  });

  test('±1° jitter on every boundary fires each haptic once per pass (SC-005)', () {
    final random = math.Random(7);
    var ms = 0;
    final events = <QiblaEvent>[];
    void feed(double base) {
      events.addAll(tracker.update(base + random.nextDouble() * 2 - 1, at(ms)));
      ms += 50;
      events.addAll(tracker.check(at(ms)));
    }

    for (var pass = 0; pass < 3; pass++) {
      events.clear();
      for (var base = 20.0; base > 0; base -= .5) {
        feed(base);
      }
      for (var i = 0; i < 20; i++) {
        feed(0);
      }
      for (var base = 0.0; base < 20; base += .5) {
        feed(base);
      }
      expect(events.where((event) => event == QiblaEvent.approach), hasLength(1));
      expect(events.where((event) => event == QiblaEvent.aligned), hasLength(1));
      expect(tracker.phase, QiblaPhase.turning);
    }
  });

  test('reset starts from turning, armed, with no last reading', () {
    tracker.update(12, at(0));
    tracker.update(0, at(50));
    tracker.check(at(450));
    tracker.reset();
    expect(tracker.phase, QiblaPhase.turning);
    expect(tracker.alignAt, isNull);
    expect(tracker.update(8, at(500)), isEmpty);
    tracker.update(12, at(550));
    expect(tracker.update(9, at(600)), [QiblaEvent.approach]);
  });
}
