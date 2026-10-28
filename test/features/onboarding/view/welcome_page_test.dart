import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/widgets/custom_opacity.dart';
import 'package:better_muslim/features/onboarding/view/location_step_page.dart';
import 'package:better_muslim/features/onboarding/view/welcome_page.dart';
import 'package:better_muslim/features/onboarding/view/widgets/glass/liquid_glass.dart';
import 'package:better_muslim/features/onboarding/view/widgets/welcome_stars.dart';
import 'package:better_muslim/features/onboarding/view/widgets/welcome_sun.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../helpers/fonts.dart';
import '../../../helpers/onboarding.dart';
import '../../../helpers/providers.dart';
import '../../../helpers/widgets.dart';

const _selection = 'HapticFeedbackType.selectionClick';
const _light = 'HapticFeedbackType.lightImpact';

void main() {
  setUpAll(() async {
    tz.initializeTimeZones();
    await loadAppFonts();
  });
  setUp(() => BmHaptics.enabled = true);

  late List<String> haptics;
  setUp(() => haptics = recordHaptics());

  /// the product of every opacity above it, 0 when it isn't there. a custom opacity counts by the
  /// value it is given, not by the 300 ms it takes to get there
  double seen(WidgetTester tester, Finder finder) {
    if (finder.evaluate().isEmpty) return 0;
    var opacity = 1.0;
    for (final element in find.ancestor(of: finder, matching: find.byType(Opacity)).evaluate()) {
      opacity *= (element.widget as Opacity).opacity;
    }
    for (final element
        in find.ancestor(of: finder, matching: find.byType(CustomOpacity)).evaluate()) {
      opacity *= (element.widget as CustomOpacity).opacity;
    }
    final fades = find.ancestor(of: finder, matching: find.byType(FadeTransition)).evaluate();
    for (final element in fades) {
      final above = <Widget>[];
      element.visitAncestorElements((ancestor) {
        above.add(ancestor.widget);
        return above.length < 2;
      });
      if (above.length == 2 && above[0] is AnimatedOpacity && above[1] is CustomOpacity) continue;
      opacity *= (element.widget as FadeTransition).opacity.value;
    }
    return opacity;
  }

  PopScope<Object?> popScope(WidgetTester tester) =>
      tester.widget(find.byWidgetPredicate((widget) => widget is PopScope).first);

  /// where the sun is: the glass while it shows, the designed sun once settled
  Offset sun(WidgetTester tester) {
    final glass = find.byType(SunGlass);
    if (glass.evaluate().isNotEmpty) return tester.widget<SunGlass>(glass).lens().center;
    return tester.widget<WelcomeSun>(find.byType(WelcomeSun)).center;
  }

  double radius(WidgetTester tester) =>
      tester.widget<SunGlass>(find.byType(SunGlass)).lens().radius;

  Offset domeTop(WidgetTester tester) {
    final ch = choreography(tester);
    return ch.domeCenter - Offset(0, ch.domeRadius - 30);
  }

  bool onWelcome(WidgetTester tester) =>
      seen(tester, find.text('Get started')) == 1 &&
      seen(tester, find.text('Better Muslim')) == 1 &&
      seen(tester, find.text('Restore from backup')) == 1 &&
      tester.widget<WelcomeSun>(find.byType(WelcomeSun)).opacity > .99 &&
      find.byType(SunGlass).evaluate().isEmpty;

  bool onFirst(WidgetTester tester) =>
      seen(tester, find.text('Every prayer, in its time.')) > .99 &&
      seen(tester, find.text('Swipe up to begin')) > .99 &&
      seen(tester, find.text('Get started')) == 0;

  WelcomeStarsPainter stars(WidgetTester tester) =>
      tester
              .widget<CustomPaint>(
                find.descendant(of: find.byType(WelcomeStars), matching: find.byType(CustomPaint)),
              )
              .painter!
          as WelcomeStarsPainter;

  Future<void> raise(WidgetTester tester) async {
    await dragSun(tester, domeTop(tester), const Offset(196.5, 380));
    await frames(tester, const Duration(milliseconds: 2200));
  }

  testWidgets('the first screen: the headline, the hint, the dome, no stars', (tester) async {
    await pumpWelcome(tester);
    final ch = choreography(tester);

    expect(onFirst(tester), isTrue);
    expect(sun(tester), ch.domeCenter);
    expect(radius(tester), closeTo(ch.domeRadius, 1e-6));
    expect(stars(tester).flight, 0);
    expect(seen(tester, find.text('Let go to begin')), 0);
    await unmount(tester);
  });

  testWidgets('let go below the horizon and it sinks back, nothing else', (tester) async {
    await pumpWelcome(tester);
    await dragSun(tester, domeTop(tester), const Offset(196.5, 500));
    expect(haptics, isNot(contains(_selection)));
    await frames(tester, const Duration(milliseconds: 1500));

    expect(onFirst(tester), isTrue);
    expect(sun(tester), choreography(tester).domeCenter);
    expect(haptics, isEmpty);
    await unmount(tester);
  });

  testWidgets('above the horizon: let go to begin with a tick, then the welcome builds', (
    tester,
  ) async {
    await pumpWelcome(tester);
    final gesture = await tester.startGesture(domeTop(tester));
    for (var i = 0; i < 40; i++) {
      await gesture.moveBy(const Offset(0, -10));
      await tester.pump(const Duration(milliseconds: 20));
    }
    await frames(tester, const Duration(milliseconds: 400));
    expect(sun(tester).dy, lessThan(452));
    expect(seen(tester, find.text('Let go to begin')), 1);
    expect(haptics, [_selection]);
    expect(seen(tester, find.text('Every prayer, in its time.')), lessThan(.01));

    await gesture.up();
    await tester.pump();
    expect(haptics, [_selection, _light]);
    await frames(tester, const Duration(milliseconds: 1800));
    await frames(tester, const Duration(milliseconds: 600));

    expect(onWelcome(tester), isTrue);
    expect(sun(tester), const Offset(196.5, 452));
    expect(stars(tester).flight, 1);
    expect(stars(tester).shown, 1);
    expect(haptics, [_selection, _light]);
    await unmount(tester);
  });

  testWidgets('a flick up from just above the dome begins too', (tester) async {
    await pumpWelcome(tester);
    await tester.flingFrom(domeTop(tester), const Offset(0, -120), 2400);
    await frames(tester, const Duration(milliseconds: 2400));
    expect(onWelcome(tester), isTrue);
    await unmount(tester);
  });

  testWidgets('a tap on the hint or the sun begins', (tester) async {
    await pumpWelcome(tester);
    await tester.tap(find.text('Swipe up to begin'));
    await frames(tester, const Duration(milliseconds: 2400));
    expect(onWelcome(tester), isTrue);
    await unmount(tester);

    await pumpWelcome(tester);
    await tester.tapAt(domeTop(tester));
    await frames(tester, const Duration(milliseconds: 2400));
    expect(onWelcome(tester), isTrue);
    await unmount(tester);
  });

  testWidgets('a screen reader hears the sun and can begin with a tap', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpWelcome(tester);
    expect(find.bySemanticsLabel(RegExp('^Sun. Drag it up past the horizon')), findsOneWidget);
    tester.semantics.tap(find.semantics.byLabel(RegExp('^Sun. Drag it up past the horizon')));
    await frames(tester, const Duration(milliseconds: 2400));
    expect(onWelcome(tester), isTrue);
    expect(find.bySemanticsLabel('Sun. Drag it down to go back.'), findsOneWidget);
    semantics.dispose();
    await unmount(tester);
  });

  testWidgets('a tap anywhere while it builds ends the build at once', (tester) async {
    await pumpWelcome(tester);
    await tester.tap(find.text('Swipe up to begin'));
    await frames(tester, const Duration(milliseconds: 300));
    expect(seen(tester, find.text('Get started')), 0);

    await tester.tapAt(const Offset(40, 160));
    await tester.pump();
    expect(seen(tester, find.text('Get started')), 1);
    expect(seen(tester, find.text('Restore from backup')), 1);
    await unmount(tester);
  });

  testWidgets('on 4.10 down past the line goes back, a short drag builds again', (tester) async {
    await pumpWelcome(tester);
    await raise(tester);
    expect(onWelcome(tester), isTrue);
    haptics.clear();

    await dragSun(tester, const Offset(196.5, 445), const Offset(196.5, 560));
    expect(haptics.where((haptic) => haptic == _selection), isEmpty);
    await frames(tester, const Duration(milliseconds: 1500));
    expect(onWelcome(tester), isTrue);

    haptics.clear();
    await dragSun(tester, const Offset(196.5, 445), const Offset(196.5, 820));
    expect(haptics, [_selection, _light]);
    await frames(tester, const Duration(milliseconds: 1800));
    expect(onFirst(tester), isTrue);
    expect(sun(tester), choreography(tester).domeCenter);
    expect(stars(tester).shown, 0);
    await unmount(tester);
  });

  testWidgets('a second finger never takes the sun', (tester) async {
    await pumpWelcome(tester);
    final first = await tester.startGesture(domeTop(tester));
    await first.moveBy(const Offset(0, -60));
    await frames(tester, const Duration(milliseconds: 300));
    final held = sun(tester);

    final second = await tester.startGesture(domeTop(tester) + const Offset(40, 10));
    await second.moveBy(const Offset(0, -300));
    await frames(tester, const Duration(milliseconds: 300));
    expect((sun(tester) - held).distance, lessThan(1));

    await second.up();
    await first.up();
    await frames(tester, const Duration(milliseconds: 1500));
    expect(onFirst(tester), isTrue);
    await unmount(tester);
  });

  testWidgets('a pointer cancelled mid drag springs the sun home, nothing starts', (tester) async {
    await pumpWelcome(tester);
    final gesture = await tester.startGesture(domeTop(tester));
    for (var i = 0; i < 40; i++) {
      await gesture.moveBy(const Offset(0, -10));
      await tester.pump(const Duration(milliseconds: 20));
    }
    await gesture.cancel();
    await frames(tester, const Duration(milliseconds: 2400));

    expect(onFirst(tester), isTrue);
    expect(sun(tester), choreography(tester).domeCenter);
    expect(haptics, [_selection]);
    await unmount(tester);
  });

  testWidgets('back on 4.10 sinks the sun to the first screen, the first screen lets it go', (
    tester,
  ) async {
    await pumpWelcome(tester);
    expect(popScope(tester).canPop, isTrue);
    await raise(tester);
    expect(popScope(tester).canPop, isFalse);

    await tester.binding.handlePopRoute();
    await frames(tester, const Duration(milliseconds: 1800));
    expect(onFirst(tester), isTrue);
    expect(find.byType(WelcomePage), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('get started: buttons go first, the welcome is gone by 300 ms, back brings it', (
    tester,
  ) async {
    await pumpWelcome(tester);
    await raise(tester);
    await tester.tap(find.text('Get started'));
    await frames(tester, const Duration(milliseconds: 150));
    expect(seen(tester, find.text('Get started')), 0);
    expect(seen(tester, find.text('Better Muslim')), greaterThan(0));

    await frames(tester, const Duration(milliseconds: 160));
    expect(seen(tester, find.text('Better Muslim')), 0);
    expect(seen(tester, find.textContaining('moving with the sky')), 0);
    await frames(tester, const Duration(milliseconds: 700));
    expect(find.byType(LocationStepPage), findsOneWidget);

    await tester.binding.handlePopRoute();
    await frames(tester, const Duration(milliseconds: 400));
    expect(find.byType(LocationStepPage), findsNothing);
    expect(onWelcome(tester), isTrue);
    await unmount(tester);
  });

  testWidgets('reduce motion: a fade in place, a 300 ms crossfade, nothing flies', (tester) async {
    await pumpWelcome(tester, reduceMotion: true);
    expect(sun(tester), choreography(tester).domeCenter);
    expect(onFirst(tester), isTrue);

    await tester.tap(find.text('Swipe up to begin'));
    expect(haptics, [_light]);
    await frames(tester, const Duration(milliseconds: 320));
    expect(seen(tester, find.text('Get started')), 1);
    await frames(tester, const Duration(milliseconds: 500));
    expect(onWelcome(tester), isTrue);
    expect(stars(tester).still, isTrue);
    expect(stars(tester).ambient, isNull);
    await unmount(tester);
  });

  testWidgets('the ambient loop runs on 4.10, stopped by reduce motion', (tester) async {
    await pumpWelcome(tester, ambient: true);
    await tester.tap(find.text('Swipe up to begin'));
    await frames(tester, const Duration(milliseconds: 2400));
    expect(stars(tester).ambient, isNotNull);
    await unmount(tester);
  });

  for (final (name, locale, brightness, scale) in [
    ('arabic', const Locale('ar'), Brightness.dark, 1.0),
    ('light, text scale 2.0', const Locale('en'), Brightness.light, 2.0),
    ('arabic at 2.0', const Locale('ar'), Brightness.dark, 2.0),
  ]) {
    testWidgets('$name: the same gesture, nothing cut', (tester) async {
      await pumpWelcome(tester, locale: locale, brightness: brightness, textScale: scale);
      await raise(tester);
      expect(tester.takeException(), isNull);
      expect(sun(tester), const Offset(196.5, 452));
      expect(tester.widget<WelcomeSun>(find.byType(WelcomeSun)).opacity, greaterThan(.99));
      await unmount(tester);
    });
  }

  testWidgets('the haptics switch stops them', (tester) async {
    await pumpWelcome(tester);
    BmHaptics.enabled = false;
    await tester.tap(find.text('Swipe up to begin'));
    await frames(tester, const Duration(milliseconds: 300));
    expect(haptics, isEmpty);
    BmHaptics.enabled = true;
    await unmount(tester);
  });
}
