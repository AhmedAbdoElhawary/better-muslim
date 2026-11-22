import 'package:better_muslim/core/flavor/flavor_config.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/design/bm_sky.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// null = no period, the sky shows the theme's own base sky
BmSkyState? skyState(Period? period) => switch (period) {
  null => null,
  Period.fajr => BmSkyState.fajr,
  Period.duha => BmSkyState.sunrise,
  Period.dhuhr => BmSkyState.dhuhr,
  Period.asr => BmSkyState.asr,
  Period.maghrib => BmSkyState.maghrib,
  Period.isha => BmSkyState.isha,
};

bool starsOn(BmSkyState? state) =>
    state == null ||
    state == BmSkyState.fajr ||
    state == BmSkyState.maghrib ||
    state == BmSkyState.isha;

/// null = the theme's base sky: no location, or the design scenario so the screens match the PNGs.
/// home and the welcome read the same sky
final skyStateProvider = Provider<BmSkyState?>((ref) {
  if (ref.watch(flavorProvider.select((config) => config.isDesignScenario))) return null;
  return skyState(ref.watch(periodProvider));
});
