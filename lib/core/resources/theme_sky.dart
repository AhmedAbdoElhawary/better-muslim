import 'dart:math' as math;

import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/resources/design/bm_sky.dart';
import 'package:flutter/painting.dart';

final _cache = <BmThemeId, Map<BmSkyState, BmSkyStops>>{};

/// the six skies of a theme: emerald's turned to the theme's hue, isha the theme's own base sky
Map<BmSkyState, BmSkyStops> themeSky(BmThemeId id) {
  if (id == BmThemeId.qiyamEmerald) return bmSkyQiyamEmerald;
  return _cache[id] ??= _build(bmThemes[id]!.dark);
}

Map<BmSkyState, BmSkyStops> _build(BmPalette dark) {
  /// sky3, the black top has no hue to turn from
  final from = _Oklch.of(bmThemes[BmThemeId.qiyamEmerald]!.dark.sky3);
  final to = _Oklch.of(dark.sky3);
  final turn = to.h - from.h;
  final scale = (to.c / from.c).clamp(.5, 1.5);
  Color shift(Color color) {
    final c = _Oklch.of(color);
    return _Oklch(c.l, c.c * scale, c.h + turn).toColor();
  }

  return {
    for (final MapEntry(key: state, value: stops) in bmSkyQiyamEmerald.entries)
      state: state == BmSkyState.isha
          ? BmSkyStops(dark.sky1, dark.sky2, dark.sky3)
          : BmSkyStops(shift(stops.top), shift(stops.mid), shift(stops.bottom)),
  };
}

/// oklch keeps the lightness the eye sees, so a turned sky keeps emerald's text contrast
class _Oklch {
  const _Oklch(this.l, this.c, this.h);

  final double l;
  final double c;

  /// radians
  final double h;

  factory _Oklch.of(Color color) {
    final (r, g, b) = (_linear(color.r), _linear(color.g), _linear(color.b));
    final l = _cbrt(.4122214708 * r + .5363325363 * g + .0514459929 * b);
    final m = _cbrt(.2119034982 * r + .6806995451 * g + .1073969566 * b);
    final s = _cbrt(.0883024619 * r + .2817188376 * g + .6299787005 * b);
    final labA = 1.9779984951 * l - 2.4285922050 * m + .4505937099 * s;
    final labB = .0259040371 * l + .7827717662 * m - .8086757660 * s;
    return _Oklch(
      .2104542553 * l + .7936177850 * m - .0040720468 * s,
      math.sqrt(labA * labA + labB * labB),
      math.atan2(labB, labA),
    );
  }

  /// out of srgb the chroma goes down until it fits, so lightness and hue stay
  Color toColor() {
    var rgb = _rgb(c);
    if (!_fits(rgb)) {
      var (low, high) = (0.0, c);
      for (var i = 0; i < 30; i++) {
        final mid = (low + high) / 2;
        _fits(_rgb(mid)) ? low = mid : high = mid;
      }
      rgb = _rgb(low);
    }
    final (r, g, b) = rgb;
    return Color.from(
      alpha: 1,
      red: _gamma(r.clamp(0.0, 1.0)),
      green: _gamma(g.clamp(0.0, 1.0)),
      blue: _gamma(b.clamp(0.0, 1.0)),
    );
  }

  (double, double, double) _rgb(double chroma) {
    final (labA, labB) = (chroma * math.cos(h), chroma * math.sin(h));
    final l = math.pow(this.l + .3963377774 * labA + .2158037573 * labB, 3).toDouble();
    final m = math.pow(this.l - .1055613458 * labA - .0638541728 * labB, 3).toDouble();
    final s = math.pow(this.l - .0894841775 * labA - 1.2914855480 * labB, 3).toDouble();
    return (
      4.0767416621 * l - 3.3077115913 * m + .2309699292 * s,
      -1.2684380046 * l + 2.6097574011 * m - .3413193965 * s,
      -.0041960863 * l - .7034186147 * m + 1.7076147010 * s,
    );
  }

  static bool _fits((double, double, double) rgb) {
    const edge = 1e-6;
    final (r, g, b) = rgb;
    return [r, g, b].every((v) => v >= -edge && v <= 1 + edge);
  }
}

double _linear(double v) => v <= .04045 ? v / 12.92 : math.pow((v + .055) / 1.055, 2.4).toDouble();

double _gamma(double v) =>
    v <= .0031308 ? v * 12.92 : 1.055 * math.pow(v, 1 / 2.4).toDouble() - .055;

double _cbrt(double v) => v < 0 ? -math.pow(-v, 1 / 3).toDouble() : math.pow(v, 1 / 3).toDouble();
