import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/resources/design/bm_sky.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/resources/theme_sky.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// wcag's ratio of the lighter to the darker relative luminance
double _ratio(Color a, Color b) {
  final (light, dark) = (a.computeLuminance(), b.computeLuminance());
  return light > dark ? (light + .05) / (dark + .05) : (dark + .05) / (light + .05);
}

/// bmSkyGradient's colour at t of its 160% height
Color _at(BmSkyStops s, double t) {
  const stops = [0.0, .30, .62, .82, 1.0];
  final colors = [s.top, s.mid, s.bottom, s.mid, s.top];
  for (var i = 1; i < stops.length; i++) {
    if (t <= stops[i]) {
      return Color.lerp(colors[i - 1], colors[i], (t - stops[i - 1]) / (stops[i] - stops[i - 1]))!;
    }
  }
  return colors.last;
}

/// the welcome's title and tagline sit from 500 to 640 of the 852 frame, the drift moves the
/// gradient up by up to 30% of its extra 60%
Iterable<Color> _behindText(BmSkyStops stops) sync* {
  for (final drift in [0.0, .5, 1.0]) {
    for (var y = 500.0; y <= 640; y += 10) {
      yield _at(stops, (y / 852 + drift * .3 * .6) / 1.6);
    }
  }
}

Color _over(Color top, Color under) => Color.alphaBlend(top, under);

void main() {
  for (final id in bmThemeOrder) {
    for (final (mode, palette) in [('dark', bmThemes[id]!.dark), ('light', bmThemes[id]!.light)]) {
      final base = BmSkyStops(palette.sky1, palette.sky2, palette.sky3);
      final skies = <String, (BmSkyStops, bool)>{
        'theme base': (base, false),
        for (final state in BmSkyState.values)
          state.name: (themeSky(id)[state]!, bmSkyIsBright(state)),
      };
      for (final MapEntry(key: name, value: (stops, bright)) in skies.entries) {
        test('${id.name} $mode, the welcome on the $name sky (FR-040)', () {
          final text = (bright ? ThemeEnum.onSkyBright : ThemeEnum.onSky).resolve(palette);
          final scrim = ThemeEnum.welcomeScrim.resolve(palette);
          for (final sky in _behindText(stops)) {
            final under = _over(scrim, sky);
            final title = _over(text, under);
            final tagline = _over(text.withValues(alpha: text.a * .85), under);
            expect(_ratio(title, under), greaterThanOrEqualTo(3), reason: 'title on $under');
            expect(_ratio(tagline, under), greaterThanOrEqualTo(4.5), reason: 'tagline on $under');
          }
        });
      }
    }
  }
}
