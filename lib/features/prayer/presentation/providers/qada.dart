import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/features/prayer/data/qada_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final qadaOpenCountsProvider = StreamProvider.autoDispose<Map<Prayer, int>>(
  (ref) => ref.watch(qadaRepositoryProvider).watchOpenCounts(),
);

final qadaMonthCountProvider = StreamProvider.autoDispose.family<int, DateTime>(
  (ref, day) => ref.watch(qadaRepositoryProvider).watchMonthCount(day),
);
