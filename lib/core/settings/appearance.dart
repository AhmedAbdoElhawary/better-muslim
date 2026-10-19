import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/resources/design/bm_theme.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeIdProvider = Provider<BmThemeId>(
  (ref) => ref.watch(
    settingsProvider.select((settings) => settings.value?.theme ?? BmThemeId.qiyamEmerald),
  ),
);

final themeModeProvider = Provider<ThemeMode>(
  (ref) => switch (ref.watch(
    settingsProvider.select((settings) => settings.value?.themeMode ?? BmThemeMode.followSky),
  )) {
    BmThemeMode.dark => ThemeMode.dark,
    BmThemeMode.light => ThemeMode.light,
    BmThemeMode.followSky => ref.watch(followSkyProvider),
  },
);

/// what follow sky gives now, also for the theme page's preview. follows the ticker, but only
/// notifies at sunrise and maghrib, so MaterialApp rebuilds twice a day
final followSkyProvider = Provider<ThemeMode>((ref) {
  final (:located, :sunrise, :maghrib) = ref.watch(
    todayTimesProvider.select(
      (times) => (located: times != null, sunrise: times?.sunrise, maghrib: times?.maghrib),
    ),
  );

  /// no location yet, so there is no sky to follow
  if (!located) return ThemeMode.system;

  /// a polar day has no maghrib and a polar night no sunrise
  if (sunrise == null) return ThemeMode.dark;
  if (maghrib == null) return ThemeMode.light;
  final now = ref.watch(tickerProvider).value ?? ref.watch(clockProvider)();
  final brightness = resolveBrightness(
    BmThemeMode.followSky,
    now: now,
    sunrise: sunrise,
    maghrib: maghrib,
  );
  return brightness == Brightness.light ? ThemeMode.light : ThemeMode.dark;
});
