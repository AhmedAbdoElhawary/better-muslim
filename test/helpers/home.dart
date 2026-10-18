import 'package:better_muslim/core/app/app.dart';
import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;

import 'providers.dart';

/// the app on home at 393 x 852 like the PNGs, on a 24 hour phone unless a test says otherwise
Future<void> pumpHome(
  WidgetTester tester,
  List<Override> overrides, {
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.dark,
  double textScale = 1,
  bool use24 = true,
  bool reduceMotion = false,
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(393, 852) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.localesTestValue = [locale];
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MediaQuery(
        data: MediaQueryData.fromView(tester.view).copyWith(
          alwaysUse24HourFormat: use24,
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reduceMotion,
        ),
        child: const App(),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

Location makkah() => Location(
  latitude: 21.4225,
  longitude: 39.8262,
  placeName: 'Makkah',
  placeNameAr: 'مكة المكرمة',
  countryCode: 'SA',
  zone: tz.getLocation('Asia/Riyadh'),
  mode: LocationMode.auto,
);

/// makkah with the real calculation (maghrib is 17:56 there too) and a clock that moves with the
/// test's fake time
List<Override> makkahAt(WidgetTester tester, DateTime start, {List<Override> extra = const []}) {
  final origin = tester.binding.clock.now();
  return [
    ...testOverrides(),
    clockProvider.overrideWithValue(() => start.add(tester.binding.clock.now().difference(origin))),
    locationProvider.overrideWithValue(makkah()),
    ...extra,
  ];
}
