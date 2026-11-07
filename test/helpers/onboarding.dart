import 'package:better_muslim/core/app/app.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/features/onboarding/model/sun_choreography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'providers.dart';

/// a new install on the welcome at 393 x 852
Future<void> pumpWelcome(
  WidgetTester tester, {
  List<Override>? overrides,
  Size size = const Size(393, 852),
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.dark,
  double textScale = 1,
  bool reduceMotion = false,
  bool use24 = true,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.localesTestValue = [locale];
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides ?? testOverrides(onboarded: false),
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
  await frames(tester, const Duration(milliseconds: 1500));
}

/// 20 ms frames, a single long pump starts springs late
Future<void> frames(WidgetTester tester, Duration time) async {
  const step = Duration(milliseconds: 20);
  for (var waited = Duration.zero; waited < time; waited += step) {
    await tester.pump(step);
  }
}

SunChoreography choreography(WidgetTester tester) {
  final size = tester.view.physicalSize / tester.view.devicePixelRatio;
  return SunChoreography(size, EdgeInsets.zero);
}

/// a drag on the sun from where it rests to a point, at a finger's pace
Future<void> dragSun(WidgetTester tester, Offset from, Offset to, {Duration? time}) async {
  final gesture = await tester.startGesture(from);
  const steps = 30;
  final step = (to - from) / steps.toDouble();
  final pause = (time ?? const Duration(milliseconds: 600)) ~/ steps;
  for (var i = 0; i < steps; i++) {
    await gesture.moveBy(step, timeStamp: pause * (i + 1));
    await tester.pump(pause);
  }
  await frames(tester, const Duration(milliseconds: 200));
  await gesture.up(timeStamp: pause * steps + const Duration(milliseconds: 220));
}

/// the welcome, then a step pushed on it as Get started does, built
Future<void> pumpStep(
  WidgetTester tester,
  String location, {
  List<Override>? overrides,
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.dark,
  double textScale = 1,
  bool use24 = true,
}) async {
  await pumpWelcome(
    tester,
    overrides: overrides,
    locale: locale,
    brightness: brightness,
    textScale: textScale,
    use24: use24,
  );
  final container = ProviderScope.containerOf(tester.element(find.byType(App)));
  container.read(routerProvider).push(location);
  await frames(tester, const Duration(milliseconds: 1000));
}
