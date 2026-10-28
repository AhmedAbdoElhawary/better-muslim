import 'dart:math';

import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/resources/design/bm_sky.dart';
import 'package:better_muslim/core/resources/theme_sky.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// oklch of an opaque color, hue in degrees, worked out here so the test doesn't trust the lib's
({double l, double c, double h}) _oklch(Color color) {
  double linear(double v) => v <= .04045 ? v / 12.92 : pow((v + .055) / 1.055, 2.4).toDouble();
  double cbrt(double v) => pow(v, 1 / 3).toDouble();
  final (r, g, b) = (linear(color.r), linear(color.g), linear(color.b));
  final l = cbrt(.4122214708 * r + .5363325363 * g + .0514459929 * b);
  final m = cbrt(.2119034982 * r + .6806995451 * g + .1073969566 * b);
  final s = cbrt(.0883024619 * r + .2817188376 * g + .6299787005 * b);
  final labA = 1.9779984951 * l - 2.4285922050 * m + .4505937099 * s;
  final labB = .0259040371 * l + .7827717662 * m - .8086757660 * s;
  return (
    l: .2104542553 * l + .7936177850 * m - .0040720468 * s,
    c: sqrt(labA * labA + labB * labB),
    h: atan2(labB, labA) * 180 / pi,
  );
}

double _hueGap(double a, double b) {
  final gap = (a - b).abs() % 360;
  return gap > 180 ? 360 - gap : gap;
}

List<Color> _colors(BmSkyStops stops) => [stops.top, stops.mid, stops.bottom];

void main() {
  test('qiyam emerald keeps its 18 colors', () {
    final sky = themeSky(BmThemeId.qiyamEmerald);
    for (final state in BmSkyState.values) {
      expect(_colors(sky[state]!), _colors(bmSkyQiyamEmerald[state]!), reason: state.name);
    }
  });

  final emeraldSky3 = _oklch(bmThemes[BmThemeId.qiyamEmerald]!.dark.sky3);
  for (final id in BmThemeId.values.where((id) => id != BmThemeId.qiyamEmerald)) {
    test('${id.name}: isha is its base sky, the rest emerald turned to its hue', () {
      final dark = bmThemes[id]!.dark;
      final sky = themeSky(id);
      expect(_colors(sky[BmSkyState.isha]!), [dark.sky1, dark.sky2, dark.sky3]);

      final themeHue = _oklch(dark.sky3).h;
      for (final state in BmSkyState.values.where((state) => state != BmSkyState.isha)) {
        final turned = _colors(sky[state]!);
        final emerald = _colors(bmSkyQiyamEmerald[state]!);
        for (var i = 0; i < 3; i++) {
          final look = '${state.name} stop $i';
          final color = turned[i];
          expect(color.a, 1, reason: look);
          for (final channel in [color.r, color.g, color.b]) {
            expect(channel, inInclusiveRange(0, 1), reason: look);
          }
          final (got, from) = (_oklch(color), _oklch(emerald[i]));
          expect(got.l, closeTo(from.l, .01), reason: look);
          if (got.c > .02) {
            expect(
              _hueGap(got.h, themeHue + from.h - emeraldSky3.h),
              lessThanOrEqualTo(10),
              reason: look,
            );
          }
        }
      }
    });
  }

  test('a theme is worked out once', () {
    expect(identical(themeSky(BmThemeId.andalus), themeSky(BmThemeId.andalus)), isTrue);
  });
}
