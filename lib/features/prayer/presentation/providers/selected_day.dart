import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// null = follow the prayer day, so at fajr the screen moves on unless another day was picked
final selectedDayProvider = NotifierProvider<SelectedDay, DateTime?>(SelectedDay.new);

class SelectedDay extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void select(DateTime? day) => state = day;
}

final shownDayProvider = Provider<DateTime>(
  (ref) => ref.watch(selectedDayProvider) ?? ref.watch(prayerDayProvider),
);
