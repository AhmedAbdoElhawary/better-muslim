import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO: milestone 4 fills it from the store
final prayedProvider = Provider.autoDispose.family<Set<Prayer>, DateTime>((ref, day) => const {});
