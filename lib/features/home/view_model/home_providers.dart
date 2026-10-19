import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/flavor/flavor_config.dart';
import 'package:better_muslim/core/prayer_log/prayer_log.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/next_prayer.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/design/bm_sky.dart';
import 'package:better_muslim/features/home/model/home_moment.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart';

final glowBreathingProvider = Provider<bool>(
  (ref) => glowBreathing(ref.watch(timeLeftProvider) ?? Duration.zero),
);

typedef StripEntry = ({Prayer prayer, TZDateTime? time, bool current, bool logged, bool past});

/// the prayer day's five times and marks, so last night's isha stays until fajr
final stripProvider = Provider<List<StripEntry>>((ref) {
  final day = ref.watch(prayerDayProvider);
  final times = ref.watch(dayTimesProvider(day));
  final prayed = ref.watch(prayedProvider(day));
  final period = ref.watch(periodProvider);
  return [
    for (final prayer in Prayer.values)
      if (stripCellState(prayer, period, prayed) case (:final current, :final logged, :final past))
        (prayer: prayer, time: times?.timeOf(prayer), current: current, logged: logged, past: past),
  ];
});

/// null = the theme's base sky: no location, or the design scenario so home matches the PNGs
final skyStateProvider = Provider<BmSkyState?>((ref) {
  if (ref.watch(flavorProvider.select((config) => config.isDesignScenario))) return null;
  return skyState(ref.watch(periodProvider));
});

/// the sunrise, dhuhr and asr skies, where the header text turns white over a scrim
final skyBrightProvider = Provider<bool>((ref) {
  final state = ref.watch(skyStateProvider);
  return state != null && bmSkyIsBright(state);
});

final starsOnProvider = Provider<bool>((ref) => starsOn(ref.watch(skyStateProvider)));

final sunShareProvider = Provider<double?>((ref) {
  final times = ref.watch(todayTimesProvider);
  if (times == null) return null;
  final now = ref.watch(tickerProvider).value ?? ref.watch(clockProvider)();
  return sunShare(now, times.sunrise, times.maghrib);
});

final arcLabelsProvider = Provider<ArcLabels?>((ref) {
  final today = ref.watch(todayProvider);
  final times = ref.watch(dayTimesProvider(today));
  if (times == null) return null;
  final now = ref.watch(tickerProvider).value ?? ref.watch(clockProvider)();
  return arcLabels(
    now,
    ref.watch(dayTimesProvider(DateTime(today.year, today.month, today.day - 1))),
    times,
    ref.watch(dayTimesProvider(DateTime(today.year, today.month, today.day + 1))),
  );
});
