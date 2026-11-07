import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/prayer_log/prayer_log.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/prayer_times/sky_state.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/resources/design/bm_sky.dart';
import 'package:better_muslim/features/home/model/home_moment.dart';
import 'package:better_muslim/features/home/model/verse_of_day.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart';

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

/// the sunrise, dhuhr and asr skies, where the header text turns white over a scrim
final skyBrightProvider = Provider<bool>((ref) {
  final state = ref.watch(skyStateProvider);
  return state != null && bmSkyIsBright(state);
});

final starsOnProvider = Provider<bool>((ref) => starsOn(ref.watch(skyStateProvider)));

/// only notifies when the arc changes, at sunrise and maghrib
final arcPointsProvider = Provider<ArcPoints?>((ref) {
  final today = ref.watch(todayProvider);
  final times = ref.watch(dayTimesProvider(today));
  if (times == null) return null;
  final now = ref.watch(tickerProvider).value ?? ref.watch(clockProvider)();
  return arcPoints(
    now,
    ref.watch(dayTimesProvider(DateTime(today.year, today.month, today.day - 1))),
    times,
    ref.watch(dayTimesProvider(DateTime(today.year, today.month, today.day + 1))),
  );
});

/// the sun by day, the three stars by night
final markerShareProvider = Provider<double?>((ref) {
  final points = ref.watch(arcPointsProvider);
  if (points == null) return null;
  final now = ref.watch(tickerProvider).value ?? ref.watch(clockProvider)();
  return arcShare(now, points.start, points.end);
});

final verseOfDayProvider = FutureProvider<VerseOfDay>((ref) async {
  final today = ref.watch(todayProvider);
  final assets = await ref.watch(quranAssetsProvider.future);
  final key = verseOfDay(today, assets.verseCandidates());
  final text = await assets.ayahText(key);
  final translation = (await assets.surahText(key.surah)).translation[key.ayah - 1];
  return VerseOfDay(key: key, surah: assets.surah(key.surah), text: text, translation: translation);
});
