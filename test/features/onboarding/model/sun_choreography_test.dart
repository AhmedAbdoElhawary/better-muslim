import 'package:better_muslim/features/onboarding/model/sun_choreography.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final ch = SunChoreography(const Size(393, 852), EdgeInsets.zero);

  test('the rest spot is 4.10 sun, half below the horizon', () {
    expect(ch.restCenter, const Offset(196.5, 452));
    expect(ch.restRadius, 22);
    expect(ch.startLine, 452);
  });

  test('the dome is 0.55 of the width, its top at 0.745 of the height', () {
    expect(ch.domeRadius, closeTo(393 * .55, 1e-9));
    expect(ch.domeCenter.dy - ch.domeRadius, closeTo(852 * .745, 1e-9));
  });

  test('lift is 0 at the dome and 1 on the horizon and above', () {
    expect(ch.liftAt(ch.domeCenter.dy), 0);
    expect(ch.liftAt(ch.domeCenter.dy + 50), 0);
    expect(ch.liftAt(452), 1);
    expect(ch.liftAt(100), 1);
  });

  test('the size depends only on the height, growing from the horizon to the dome', () {
    expect(ch.lensAt(const Offset(10, 452)).radius, closeTo(22, 1e-9));
    expect(ch.lensAt(Offset(300, ch.domeCenter.dy)).radius, closeTo(ch.domeRadius, 1e-9));
    var last = 0.0;
    for (var y = 452.0; y <= ch.domeCenter.dy; y += 10) {
      final radius = ch.lensAt(Offset(196.5, y)).radius;
      expect(radius, greaterThanOrEqualTo(last));
      expect(ch.lensAt(Offset(20, y)).radius, radius);
      last = radius;
    }
  });

  test('the glass warms as it rises', () {
    expect(ch.lensAt(ch.domeCenter).fill, 0);
    expect(ch.lensAt(ch.restCenter).fill, greaterThan(0));
    expect(ch.lensAt(ch.restCenter, fill: 1).fill, 1);
  });

  test('the build values at known points', () {
    expect(ch.titleTravel(0), lessThan(0));
    expect(ch.titleTravel(.45), 0);
    expect(ch.titleTravel(.6), 0);
    expect(ch.titleOpacity(.2), 1);

    expect(ch.horizonIn(0), 0);
    expect(ch.horizonIn(.35), 1);
    expect(ch.markIn(.35), allOf(greaterThan(0), lessThan(1)));

    expect(ch.starFlight(.35, 0), 0);
    expect(ch.starFlight(.35, 9), 0);
    expect(ch.starFlight(.6, 0), allOf(greaterThan(0), lessThanOrEqualTo(1)));
    for (var i = 0; i < 10; i++) {
      expect(ch.starFlight(.75, i), 1, reason: 'star $i');
    }

    expect(ch.taglineOpacity(.35), 0);
    expect(ch.taglineOpacity(.6), 1);
    expect(ch.getStartedIn(.6), 0);
    expect(ch.getStartedIn(.85), 1);
    expect(ch.fillAt(1), 1);
  });

  test('the first screen fades its words out as the sun rises', () {
    expect(ch.headlineOpacity(0, 0), 1);
    expect(ch.headlineOpacity(.5, 0), 0);
    expect(ch.headlineBlur(.5, 0), 8);
    expect(ch.hintOpacity(.25, 0), 0);
    expect(ch.glowForLift(0), 0);
    expect(ch.glowForLift(.25), 1);
    expect(ch.glowForLift(1), 0);
  });

  test('covered, the buttons leave first and the sky last', () {
    expect(SunChoreography.covered(.4, WelcomePart.buttons), 1);
    expect(SunChoreography.covered(.4, WelcomePart.sky), 0);
    for (final part in WelcomePart.values) {
      expect(SunChoreography.covered(1, part), 1);
    }
  });
}
