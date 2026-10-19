import 'package:better_muslim/core/hijri/hijri_date.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/hijri_calendar/model/coming_up.dart';
import 'package:better_muslim/features/hijri_calendar/model/hijri_month.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final hijriAdjustProvider = Provider<int>(
  (ref) => ref.watch(settingsProvider.select((settings) => settings.value?.hijriAdjust ?? 0)),
);

/// today's hijri date with the adjustment, the same as home's. moves at midnight
final todayHijriProvider = Provider<HijriDate>(
  (ref) => ref.watch(hijriDateProvider(ref.watch(todayProvider))),
);

final shownMonthProvider = NotifierProvider.autoDispose<ShownMonth, HijriMonth>(ShownMonth.new);

/// starts on today's month, read once so midnight never moves what is shown (FR-021)
class ShownMonth extends Notifier<HijriMonth> {
  @override
  HijriMonth build() => HijriMonth.of(ref.read(todayHijriProvider));

  void back() {
    if (state.canGoBack) state = state.previous;
  }

  void forward() {
    if (state.canGoForward) state = state.next;
  }

  void today() => state = HijriMonth.of(ref.read(todayHijriProvider));
}

final comingUpProvider = Provider.autoDispose<List<ComingUpItem>>(
  (ref) => comingUp(ref.watch(todayProvider), ref.watch(hijriAdjustProvider)),
);

final selectedDayProvider = NotifierProvider.autoDispose<SelectedDay, DateTime?>(SelectedDay.new);

/// lives while the day sheet is open (FR-023)
class SelectedDay extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void select(DateTime? day) => state = day;
}
