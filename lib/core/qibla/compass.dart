import 'dart:async';
import 'dart:math' as math;

import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/flavor/flavor_config.dart';
import 'package:better_muslim/core/qibla/compass_source.dart';
import 'package:better_muslim/core/qibla/declination.dart';
import 'package:better_muslim/core/qibla/qibla_place.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// the qibla PNGs' two headings, a tap on the dial switches them (R12)
final designHeadingProvider = NotifierProvider.autoDispose<DesignHeading, double>(
  DesignHeading.new,
);

class DesignHeading extends Notifier<double> {
  static const turning = 105.0;
  static const aligned = 119.0;

  @override
  double build() => turning;

  void toggle() => state = state == turning ? aligned : turning;
}

/// at the qibla's own place, a city picked far away would turn north by degrees. 0 with no place,
/// magnetic north
final _declinationProvider = Provider.autoDispose<double>((ref) {
  final place = ref.watch(
    qiblaPlaceProvider.select((place) => place == null ? null : (place.latitude, place.longitude)),
  );
  if (place == null) return 0;
  final year = decimalYear(ref.watch(clockProvider)());
  return declination(place.$1, place.$2, decimalYear: year);
});

/// how long the low pass takes to follow, the same feel at 15 and at 60 readings a second (R5)
const _smoothing = Duration(milliseconds: 150);

/// true north, smoothed on the unit circle so 359° and 1° never average to 180° (R3, R5).
/// the sensor runs only while something listens and the app is in front (R16)
final compassProvider = StreamProvider.autoDispose<CompassReading?>((ref) {
  if (ref.watch(flavorProvider.select((config) => config.isDesignScenario))) {
    return Stream.value((
      heading: ref.watch(designHeadingProvider),
      accuracy: CompassAccuracy.high,
    ));
  }
  final source = ref.watch(compassSourceProvider);
  final clock = ref.watch(clockProvider);
  var offset = 0.0;
  ref.listen(_declinationProvider, (_, next) => offset = next, fireImmediately: true);

  final controller = StreamController<CompassReading?>();
  StreamSubscription<RawHeading?>? subscription;
  double? x;
  double? y;
  DateTime? last;

  void onReading(RawHeading? raw) {
    if (raw == null) {
      controller.add(null);
      return;
    }
    final now = clock();
    final angle = (raw.magnetic + offset) * math.pi / 180;
    final since = last;
    final k = since == null
        ? 1.0
        : 1 - math.exp(-now.difference(since).inMicroseconds / _smoothing.inMicroseconds);
    last = now;
    final sx = x = (x ?? 0) + k * (math.sin(angle) - (x ?? 0));
    final sy = y = (y ?? 0) + k * (math.cos(angle) - (y ?? 0));
    final heading = (math.atan2(sx, sy) * 180 / math.pi + 360) % 360;
    controller.add((heading: heading, accuracy: compassAccuracyOf(raw.accuracy)));
  }

  void start() => subscription ??= source.readings().listen(onReading);
  void stop() {
    subscription?.cancel();
    subscription = null;
    x = null;
    y = null;
    last = null;
  }

  start();
  final lifecycle = AppLifecycleListener(onPause: stop, onResume: start);
  ref.onDispose(() {
    lifecycle.dispose();
    stop();
    controller.close();
  });
  return controller.stream;
});
