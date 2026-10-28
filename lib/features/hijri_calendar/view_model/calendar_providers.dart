import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/hijri_calendar/model/calendar_month.dart';
import 'package:better_muslim/features/hijri_calendar/model/coming_up.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// a page of the years view holds 12
const yearsPerPage = 12;

final hijriAdjustProvider = Provider<int>(
  (ref) => ref.watch(settingsProvider.select((settings) => settings.value?.hijriAdjust ?? 0)),
);

final calendarModeProvider = Provider<CalendarMode>(
  (ref) => ref.watch(
    settingsProvider.select((settings) => settings.value?.calendarMode ?? CalendarMode.hijri),
  ),
);

final selectedDayProvider = NotifierProvider.autoDispose<SelectedDay, DateTime>(SelectedDay.new);

/// today on open, read once so midnight never moves it (FR-009)
class SelectedDay extends Notifier<DateTime> {
  @override
  DateTime build() => ref.read(todayProvider);

  void select(DateTime day) => state = day;
}

enum DayTab { prayerTimes, comingUp, events }

final dayTabProvider = NotifierProvider.autoDispose<OpenTab, DayTab>(OpenTab.new);

/// prayer times on open, kept when another day is picked (FR-010)
class OpenTab extends Notifier<DayTab> {
  @override
  DayTab build() => DayTab.prayerTimes;

  void open(DayTab tab) => state = tab;
}

enum CalendarView { days, months, years }

typedef CalendarPage = ({CalendarView view, CalendarMonth month});

final calendarPageProvider = NotifierProvider.autoDispose<CalendarPager, CalendarPage>(
  CalendarPager.new,
);

/// what the grid area shows. starts on today's month, read once so midnight never moves it
class CalendarPager extends Notifier<CalendarPage> {
  @override
  CalendarPage build() {
    /// a mode change shows the month holding the selected day in the same view (FR-004)
    ref.listen(calendarModeProvider, (_, mode) {
      state = (view: state.view, month: _monthOf(ref.read(selectedDayProvider), mode));
    });
    return (view: CalendarView.days, month: _monthOf(ref.read(todayProvider)));
  }

  CalendarMonth _monthOf(DateTime day, [CalendarMode? mode]) =>
      CalendarMonth.of(day, mode ?? ref.read(calendarModeProvider), ref.read(hijriAdjustProvider));

  /// the first year of the 12 year page holding year
  int pageStart(int year) {
    final first = state.month.rangeFirst.year;
    return first + (year - first) ~/ yearsPerPage * yearsPerPage;
  }

  bool get canGoBack => switch (state.view) {
    CalendarView.days => state.month.canGoBack,
    CalendarView.months => state.month.year > state.month.rangeFirst.year,
    CalendarView.years => pageStart(state.month.year) > state.month.rangeFirst.year,
  };

  bool get canGoForward => switch (state.view) {
    CalendarView.days => state.month.canGoForward,
    CalendarView.months => state.month.year < state.month.rangeLast.year,
    CalendarView.years => pageStart(state.month.year) + yearsPerPage <= state.month.rangeLast.year,
  };

  void back() => _step(-1);

  void forward() => _step(1);

  void _step(int by) {
    if (by < 0 ? !canGoBack : !canGoForward) return;
    final month = state.month;
    state = (
      view: state.view,
      month: switch (state.view) {
        CalendarView.days => by < 0 ? month.previous : month.next,
        CalendarView.months => month.clamp(month.at(month.year + by, month.month)),
        CalendarView.years => month.clamp(month.at(month.year + by * yearsPerPage, month.month)),
      },
    );
  }

  /// days, then months, then years, then back to the days (FR-007)
  void zoomOut() => state = (
    view: CalendarView.values[(state.view.index + 1) % CalendarView.values.length],
    month: state.month,
  );

  void open(CalendarMonth month) => state = (view: CalendarView.days, month: month);

  void openYear(int year) => state = (
    view: CalendarView.months,
    month: state.month.clamp(state.month.at(year, state.month.month)),
  );

  void today() => state = (view: CalendarView.days, month: _monthOf(ref.read(todayProvider)));
}

/// dimmed only when today is selected and its month shows in the days view (FR-006)
final todayEnabledProvider = Provider.autoDispose<bool>((ref) {
  final today = ref.watch(todayProvider);
  final page = ref.watch(calendarPageProvider);
  final todayMonth = CalendarMonth.of(
    today,
    ref.watch(calendarModeProvider),
    ref.watch(hijriAdjustProvider),
  );
  return ref.watch(selectedDayProvider) != today ||
      page.view != CalendarView.days ||
      page.month != todayMonth;
});

final comingUpProvider = Provider.autoDispose<ComingUp>(
  (ref) => comingUp(
    ref.watch(selectedDayProvider),
    ref.watch(todayProvider),
    ref.watch(hijriAdjustProvider),
    ref.watch(calendarModeProvider),
  ),
);
