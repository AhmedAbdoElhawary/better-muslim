import 'dart:async';

import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/qibla/compass_source.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;

import 'home.dart';
import 'prayer.dart';

/// More › Qibla at 393 x 852, the way its tile opens it
Future<void> pumpQibla(
  WidgetTester tester,
  List<Override> overrides, {
  Size size = const Size(393, 852),
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.dark,
  double textScale = 1,
  bool reduceMotion = false,
}) async {
  await pumpHome(
    tester,
    overrides,
    size: size,
    locale: locale,
    brightness: brightness,
    textScale: textScale,
    reduceMotion: reduceMotion,
    settle: false,
  );
  await tester.pump();
  final router = containerOf(tester).read(routerProvider);
  router.go(Routes.more);
  await tester.pumpAndSettle();
  router.push(Routes.qibla);
  await tester.pumpAndSettle();
}

/// readings a test sends by hand, and whether the page is listening
class FakeCompassSource implements CompassSource {
  FakeCompassSource() {
    _controller = StreamController<RawHeading?>.broadcast(
      onListen: () => listens++,
      onCancel: () => cancels++,
    );
  }

  late final StreamController<RawHeading?> _controller;
  int listens = 0;
  int cancels = 0;

  bool get listening => _controller.hasListener;

  void send(double magnetic, {double accuracy = 10}) =>
      _controller.add((magnetic: magnetic, accuracy: accuracy));

  /// what a phone with no compass sends
  void none() => _controller.add(null);

  @override
  Stream<RawHeading?> readings() => _controller.stream;
}

Location london({LocationMode mode = LocationMode.manual}) => Location(
  latitude: 51.5074,
  longitude: -0.1278,
  placeName: 'London',
  placeNameAr: 'لندن',
  countryCode: 'GB',
  zone: tz.getLocation('Europe/London'),
  mode: mode,
);

/// the app to the background, through the states flutter expects
void toBackground(WidgetsBinding binding) {
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]) {
    binding.handleAppLifecycleStateChanged(state);
  }
}

void toFront(WidgetsBinding binding) {
  for (final state in [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    binding.handleAppLifecycleStateChanged(state);
  }
}
