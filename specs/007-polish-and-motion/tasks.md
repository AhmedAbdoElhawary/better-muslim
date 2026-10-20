---

description: "Tasks for milestone 12, polish and motion"
---

# Tasks: Milestone 12, Polish and Motion

**Input**: Design documents from `specs/007-polish-and-motion/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/system-channel.md,
contracts/routes.md, quickstart.md

**Tests**: Included. Constitution VI asks for unit tests on logic and widget tests on screens.
FR-021 asks for the 48 sky contrast test before any motion work, the spec's last clarification asks
for the migration's test. Feel, flights and frame times are checked on the phones with
quickstart.md (no goldens, no screenshots).

**Organization**: Two parts, each stopping for my review (spec clarification "One build or two").
Part 1 is US3, US1, US2, US4, US5 and US8, part 2 is US6 and US7. Inside a part, grouped by user
story so each can be checked on its own.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an unfinished task)
- **[Story]**: The user story the task belongs to (US1 to US8)

## Before starting

- Built after milestone 11 is reviewed and committed, on `feature/milestone-12`, which I cut.
- Read `design_handoff_better_muslim/specs/HOW_TO_READ.md`, then the 4.04, 4.08, 4.09 and 4.13
  trees, MOTION.md (Motion 11, 12, 15, 16 and the reduce motion rule) and TOKENS.md. The spec's
  Approved breaks are the only changes to them.
- Every new animation: a purpose, values from `BmMotion`, a reduce motion fallback read through
  `MediaQuery.disableAnimationsOf(context)` (App already joins the phone's setting and the Reduce
  motion switch), interruptible, transform and opacity only where it can be.
- Dart files follow the `adaptive-widgets` rules and `flutter test test/architecture_test.dart`
  stays green after every task. New sizes go into the managers as named entries first.
- A string key nothing reads any more is removed from `StringsManager` and both arbs in the task
  that removes its last reader, so `strings_manager_test.dart` stays green.
- `.specify/feature.json` points at this folder.
- Quran text (Ayat al-Kursi on an azkar card, a Quranic dua) only moves with its whole card, as the
  azkar pager already does, never on its own (constitution III).

---

## Phase 1: Setup

- [ ] T001 Confirm milestone 11 is committed, the branch is `feature/milestone-12`, `.specify/feature.json` points at `specs/007-polish-and-motion`, and `flutter pub get`, `flutter analyze` and `flutter test` are green before any change.

---

## Phase 2: Foundational (part 1)

**Purpose**: Schema 8 with every new column, the new strings, the new motion tokens and the three
small motion widgets the calendar and Tasbih already need.

**⚠️ CRITICAL**: No part 1 story starts before this phase is done

### Tests for the foundation

- [ ] T002 [P] Add v7 → v8 to `test/drift/app_database/migration_test.dart` (needs T006's generated `schema_v8.dart`): every row kept; `calendar_mode` reads `hijri` and `top_glow` true; a v7 row with `tasbih_dhikr` 1 and `tasbih_count` 12 reads `subhanallah_count` 0, `alhamdulillah_count` 12, `allahu_akbar_count` 0 and `tasbih_dhikr` 1; a row with `tasbih_dhikr` 2 and `tasbih_count` 34 reads 0, 0, 34.
- [ ] T003 [P] Add to `test/core/backup/backup_file_test.dart`: a v7 backup with `tasbih_dhikr` 0 and `tasbih_count` 20 goes through `readBackup` and `restore` and reads `subhanallahCount` 20, the other two 0 (research R4).
- [ ] T004 [P] Write `test/core/widgets/bm_switcher_test.dart` for `BmSwitcher` (T010): a new child keyed differently shows both mid way, the new one starts `BmMotion.shift` toward `from` and ends at 0, the box height animates between the two sizes; a third child during the swap takes over from where it is; with `disableAnimations` a 150 ms fade, no offset, the size jumps; mirrored for an `AxisDirection` start/end `from` in RTL.
- [ ] T005 [P] Write `test/core/widgets/sliding_selection_test.dart` for `SlidingSelection` (T011) and add to `test/core/widgets/segmented_test.dart`: the highlight's rect moves over frames from the old item to the new one; a new pick mid way turns from where it is; with `disableAnimations` it jumps; RTL; a segment in the new `empty` set draws its label in `text2` (the `muted` look, also when picked) with a `BmUiIcon.close` icon after it and still calls `onChanged`; the change between empty and full animates.

### Implementation for the foundation

- [ ] T006 Schema 8 (data-model.md "Stored" and "Migration 7 → 8"):
  - `lib/core/settings/settings.dart`: `enum CalendarMode { hijri, gregorian }` next to `Digits`.
  - `lib/core/database/app_database.dart`: add `calendarMode` (`textEnum<CalendarMode>()`, default `'hijri'`), `topGlow` (bool, default true), `subhanallahCount`, `alhamdulillahCount`, `allahuAkbarCount` (int, default 0, `.check(x.isBiggerOrEqualValue(0))` with the same `// ignore: recursive_getters` line as `tasbihCount`), remove `tasbihCount`, keep `tasbihDhikr`. `schemaVersion` 8.
  - `from7To8`: one `m.alterTable(TableMigration(schema.settings, newColumns: [calendarMode, topGlow], columnTransformer: {...}))`, each count a `CustomExpression<int>('case when tasbih_dhikr = N then tasbih_count else 0 end')`, with the v4 → v5 one-line why.
  - Run `dart run build_runner build` and `dart run drift_dev make-migrations`: `drift_schemas/app_database/drift_schema_v8.json`, `app_database.steps.dart`, `test/drift/app_database/generated/schema_v8.dart` and `schema.dart`.
  - Keep the build green until US5: `lib/features/azkar/view_model/tasbih_controller.dart` reads the shown dhikr's column as the count and writes only that column; fix `test/helpers/providers.dart` and any test naming `tasbihCount`. T002 and T003 pass.
- [ ] T007 [P] Add every new string of FR-046 to `lib/core/resources/strings_manager.dart`, `assets/l10n/app_en.arb` and `assets/l10n/app_ar.arb` with the spec's exact English and Arabic: `gregorianCalendar`, `showMonths`, `showYears`, `showDays`, `previousYear`, `nextYear`, `previousYears`, `nextYears`, `yearSpan` (`{first} – {last}`), `tabPrayerTimes`, `tabComingUp`, `tabEvents`, `comingUpThisYear` (`This year ({year})`), `comingUpNextYear` (`Next year ({year})`), `thisMonth`, `noMoreEvents`, `noEventsOnDay`, `hijriDateAdjustment`, `topGlow`, `acknowledgements`, `sectionContact`, `sendFeedback`, `rateApp`, `shareApp`, `developer`, `feedbackSubject`, `feedbackBody` (`Version {version} · {device} · {os}`), `shareLine` (`... {link}`), `noMailApp` (`No mail app. Write to {email}`). The day pill reuses `days`. Nothing is removed here. `strings_manager_test.dart` green.
- [ ] T008 [P] Append to the end of `BmMotion` in `lib/core/resources/design/bm_motion.dart`, nothing above changed (research R15): `completionPause = Duration(milliseconds: 1000)` with `/// the ring fill and the burst, standard + burst`, `shift = 8.0` (design points a swapped child slides), `dialogFrom = 1.08`, `zoomNear = 1.1` and `zoomFar = .9` (the calendar's views zooming in and out).
- [ ] T009 [P] Move `lib/features/home/view/widgets/countdown_digit.dart` to `lib/core/widgets/rolling_digits.dart`, class `RollingDigit`, unchanged inside; update Home's imports. Home's tests green.
- [ ] T010 [P] `lib/core/widgets/bm_switcher.dart`: `BmSwitcher(child, {from})` per research R11: `AnimatedSize` (standard, `standardCurve`) around an `AnimatedSwitcher` (standard in, the old child out on the same path) with a `FadeTransition` and a `SlideTransition` of `BmMotion.shift` design points (`.r`) from `from` (`AxisDirection`, start and end read in the text direction), default `AxisDirection.down`. Reduce motion: `BmMotion.micro` fade, no slide, the size jumps. One `///` line on the class. T004 passes.
- [ ] T011 `lib/core/widgets/sliding_selection.dart`: `SlidingSelection(selected, children, highlight)`: a `Stack` with the highlight painted behind the selected child's rect, measured after layout (a `GlobalKey` per child), moved on `BmMotion.snappy` with an `AnimationController.unbounded` per edge or one `RectTween` driven from the current value, so a new pick turns from where it is. Reduce motion: it jumps. Then `lib/core/widgets/segmented.dart` draws its selected decoration through it (both sizes) and gets an `empty` set (the `muted` text2 label, also when picked, with `BmUiIcon.close` at `SizeManager.iconChip` after it, the color and the icon animating in micro), `muted` unchanged. T005 passes.

**Checkpoint**: T002 to T005 green, the app runs as before.

---

## Phase 3: User Story 3 - Home's sky in my theme (Priority: P1) 🎯 first

**Goal**: each theme's own six skies, Qiyam Emerald untouched, readable everywhere.

**Independent Test**: spec US3. Dev with a place, pick each theme: its own sky for the current
state, Emerald the same as before.

### Tests for User Story 3

- [ ] T012 [US3] Before anything else in the sky, extend `test/features/home/view/sky_contrast_test.dart` (FR-021): the still sky loop runs for every `BmThemeId` × the 6 states × both brightnesses (48 skies × 2), the theme set in the in-memory settings that `makkahAt` builds (add a `theme` parameter to `makkahAt` in `test/helpers/home.dart`), and the theme base sky per theme; the same `expectAA` checks; test names carry the theme. The drift test stays skipped with its `TODO(ahmed)`. It passes on today's Emerald skies and guards T014.
- [ ] T013 [P] [US3] Write `test/core/resources/theme_sky_test.dart`: `themeSky(BmThemeId.qiyamEmerald)` equals `bmSkyQiyamEmerald` in all 18 colors; every other theme's Isha is its dark `sky1`, `sky2`, `sky3`; every other state's three stops keep Emerald's OKLCH lightness within 0.01, are opaque and inside sRGB, and where chroma > 0.02 their hue is within 10° of the theme's dark `sky3` hue plus Emerald's offset for that stop; two calls return the same map instance.

### Implementation for User Story 3

- [ ] T014 [US3] `lib/core/resources/theme_sky.dart`: `Map<BmSkyState, BmSkyStops> themeSky(BmThemeId id)` per research R5 and data-model "Theme sky": Emerald returns `bmSkyQiyamEmerald`; others Isha from `bmThemes[id]!.dark`, Fajr to Maghrib each stop of Emerald's state turned in OKLCH by the hue offset of the two dark `sky3`, chroma scaled by their ratio clamped 0.5 to 1.5, chroma reduced until inside sRGB; private sRGB ↔ linear ↔ OKLab helpers; a private cache per theme. One `///` line each on why OKLCH and why sky3. T012 and T013 pass.
- [ ] T015 [US3] Read it everywhere the live sky is drawn (FR-022): `lib/features/home/view/widgets/sky_header.dart` (`bmSkyQiyamEmerald[state]!` → `themeSky(ref.watch(themeIdProvider))[state]!`, the existing stops tween crossfades a theme change in `skyChange`), `lib/features/onboarding/view/widgets/welcome_sky.dart` (the same), `lib/features/theme_picker/view/widgets/snippet_sky.dart` (with a state, the previewed theme's `themeSky(id)[state]` from `skyStateProvider` and `themePreviewProvider`; without one the base sky as now). `adhan_sky.dart` and `core/surfaces/` untouched.
- [ ] T016 [P] [US3] Update `test/core/resources/welcome_contrast_test.dart` and `test/features/home/view/sky_header_test.dart` to expect `themeSky`, and add a rule to `test/architecture_test.dart`: `bmSkyQiyamEmerald` allowed only in `lib/core/resources/` and `lib/features/notifications/presentation/view/widgets/adhan_sky.dart`.

**Checkpoint**: 48 skies AA, Emerald unchanged, every theme's sky in its hue.

---

## Phase 4: User Story 1 - The day under the calendar (Priority: P1)

**Goal**: the day sheet becomes the area under the grid, Coming up lists the year.

**Independent Test**: spec US1, in the design scenario.

### Tests for User Story 1

- [ ] T017 [P] [US1] Rewrite `test/features/hijri_calendar/model/coming_up_test.dart` for `comingUp(selected, today, adjust, mode)` (data-model "ComingUp"): from 15 Oct 2026 (4 Jumada I 1448) the first group is the selected day's month and holds the white days, later groups in month order skip empty months, Ramadan's first day has `estimated` true and Jumada I's items false, `daysAway` counts from the selected day (13 Jumada I is 9); an event running on the selected day isn't listed; the last day of Dhu al-Hijjah 1447 gives `next` true, year 1448, Islamic New Year first; a day in Dhu al-Hijjah 1500 after its last event gives no groups; Gregorian mode from 15 Oct 2026 walks to 31 Dec 2026 grouped by Gregorian month, from 31 Dec gives 2027 with `next` true; each adjustment −2 to +2 moves the dates and never throws at the table's ends.
- [ ] T018 [P] [US1] Add to `test/features/hijri_calendar/view/hijri_calendar_page_test.dart` (design scenario): today selected and Prayer times listing six times on open; a day tap moves the selection, changes the date line and the open tab's content, and pushes no route or sheet; the open tab stays on another day; Coming up shows "This year (1448)", "This month" and "N days" pills; a Coming up row tap shows its month, selects its first day and opens Events; a day with no event shows "No events on this day" with the Events segment dimmed and still tappable; changing `hijriAdjust` in the store with the page open moves the grid and keeps the selected Gregorian day selected; with no place the no location line and its button open the location sheet; Arabic and text scale 2.0 overflow nothing. Remove the day sheet cases from `test/features/hijri_calendar/view/sheets_test.dart` (the adjustment sheet cases move in T049).

### Implementation for User Story 1

- [ ] T019 [US1] Rewrite `lib/features/hijri_calendar/model/coming_up.dart` per research R6 and data-model "ComingUp": `ComingUp(year, next, groups)`, `ComingUpGroup(month, items)` (`month` a Hijri or Gregorian month number and year by mode, `current` for "This month"), `ComingUpItem(event, first, daysAway, estimated)`; the walk to the year's last day, never past the table; the next year when empty. `ComingUpLine`, `_count` and `_reach` go. T017 passes.
- [ ] T020 [US1] `lib/features/hijri_calendar/view_model/calendar_providers.dart`: `selectedDayProvider` a never null `DateTime` (today read once, `select(day)`), `enum DayTab { prayerTimes, comingUp, events }` and `dayTabProvider` (autoDispose, Prayer times on open), `comingUpProvider` from the selected day, `todayProvider`, `hijriAdjustProvider` and the settings' `calendarMode`. Remove the "while the day sheet is open" comment.
- [ ] T021 [US1] `lib/features/hijri_calendar/view/widgets/month_grid.dart` and `day_cell.dart`: a day tap calls `selectedDayProvider.notifier.select` with `BmHaptics.selection`, no sheet; the selected ring is drawn by `SlidingSelection` over the grid so it slides between cells (FR-009), today keeps its fill under the ring when it is selected; delete `day_sheet.dart`.
- [ ] T022 [P] [US1] `lib/features/hijri_calendar/view/widgets/day_times.dart` (Prayer times: the six rows of the old sheet in a `GroupedSection` from `dayTimesProvider(selected)`; null → `noLocationYet` and a `BmButton` with Home's no location card label opening `showLocationSheet`) and `day_events.dart` (Events: `eventsOn(hijri)` as `NavRow(title: nameKey, value: noteKey)`, none → `noEventsOnDay` in `text2`).
- [ ] T023 [P] [US1] `lib/features/hijri_calendar/view/widgets/coming_up_list.dart` in place of `coming_up_card.dart` (delete it): heading `comingUpThisYear` or `comingUpNextYear` with the year in the mode's digits; each group's label `thisMonth` or the month's name; rows in 4.13's item look (day and short month on the start side in the mode's calendar, the name, under it the note and the dates in the other calendar, `estimated` before the date when set), a pill at the end with `days` (`sign` empty) in a `primaryContainer` capsule that wraps under the name at text scale 2.0; empty → `noMoreEvents`. A row tap shows the event's month (US2's page provider once T028 lands, the shown month until then), selects `first`, opens `DayTab.events`, `BmHaptics.selection`.
- [ ] T024 [US1] `lib/features/hijri_calendar/view/widgets/day_details.dart`: the date line (`hijriFull` over the Gregorian `yMMMMEEEEd`, as the old sheet title, crossfading on a new day with `BmSwitcher`), `Segmented<DayTab>` with `tabPrayerTimes`, `tabComingUp`, `tabEvents` and `empty: {DayTab.events}` when the day has no event, then the open tab in a `BmSwitcher` whose `from` is the side of the tapped tab. Put it in `hijri_calendar_page.dart` in place of `ComingUpCard`, spacing from `SpaceManager` (new named entries if the old `comingUpTop` doesn't fit). Remove the keys `comingUp` and `monthBegins`, and `sectionEvents` if nothing else reads it. T018 passes.

**Checkpoint**: the calendar never opens a sheet, everything the sheet showed sits under the grid.

---

## Phase 5: User Story 2 - Move around the calendar (Priority: P2)

**Goal**: Gregorian mode, the months and years views, the Today word.

**Independent Test**: spec US2.

### Tests for User Story 2

- [ ] T025 [P] [US2] Rename `test/features/hijri_calendar/model/hijri_month_test.dart` to `calendar_month_test.dart` and add `GregorianMonth`: days and blanks, `of` for both kinds, the ends April 1937 and October 2077 (`canGoBack` / `canGoForward` false there), every day of both end months converting with each adjustment −2 to +2 without throwing.
- [ ] T026 [P] [US2] Add to `hijri_calendar_page_test.dart`: the title tap switches to "Gregorian calendar", keeps the selected day, writes `calendarMode` and a new pump opens in Gregorian; Gregorian header "October 2026" over "Rabi II – Jumada I 1448" and a cell with "Rab II"; the header tap shows months, then a "1440 – 1451" style years page, then days; a year opens its months and a month its days; the arrows step a month, a year and 12 years and stop at the ends; Today's semantics disabled when today is selected in today's month in the days view, enabled otherwise, its tap goes back to today; past midnight the shown month and the selected day stay, the today look moves to the new day and Today turns enabled.

### Implementation for User Story 2

- [ ] T027 [US2] `lib/features/hijri_calendar/model/calendar_month.dart`: `sealed class CalendarMonth` with `HijriMonth` (moved unchanged from `hijri_month.dart`, delete that file) and `GregorianMonth` (data-model "CalendarMonth", first `GregorianMonth(1937, 4)`, last `GregorianMonth(2077, 10)`), shared `days(adjust)`, `blanks(adjust)`, `previous`, `next`, `canGoBack`, `canGoForward`, `compareTo`, and `CalendarMonth.of(day, mode, adjust)`. T025 passes.
- [ ] T028 [US2] `calendar_providers.dart`: `calendarModeProvider` (`settingsProvider.select` on `calendarMode`, `hijri` while loading) and a `setMode` that writes it; `enum CalendarView { days, months, years }`; `calendarPageProvider` in place of `shownMonthProvider`: `(view, month)` with `back`, `forward` (a month, a year or 12 years by view, the 12 year pages from 1356 + 12k or 1937 + 12k), `zoomOut` (days → months → years → days), `open(month)` and `openYear(year)`, `today()`, and a mode change mapping to the month holding the selected day in the same view; `todayEnabledProvider` (data-model). Point T023's row tap at `open`.
- [ ] T029 [P] [US2] `lib/features/hijri_calendar/view/widgets/calendar_format.dart`: the Gregorian header (`DateFormat.yMMMM` in the locale, the digits setting) and the Hijri span under it ("Rabi II – Jumada I 1448", across years "Dhu al-Hijjah 1447 – Muharram 1448") the same way `monthSpan` builds the Gregorian one.
- [ ] T030 [US2] `lib/features/hijri_calendar/view/widgets/calendar_title.dart`: `hijriCalendar` or `gregorianCalendar` crossfading (`BmSwitcher`), a small chevron after it (`BmUiIcon.forward` in a `RotatedBox(quarterTurns: 1)`, `SizeManager.iconChevron`), a 44 pt target, a button for screen readers. `lib/core/widgets/compact_app_bar.dart` takes an optional `titleChild` in place of its title text (only this page passes it). `_TodayButton` in `hijri_calendar_page.dart` becomes the word `today` (`MediumText` in `accent`), `AnimatedOpacity` (micro) to `BmOpacity.disabled` when `todayEnabledProvider` is false, `Semantics(enabled:)`, its tap `calendarPageProvider.today()` + selecting today.
- [ ] T031 [US2] `lib/features/hijri_calendar/view/widgets/month_header.dart`: the title tappable (`zoomOut`, semantics `showMonths`, `showYears`, `showDays` by view); by view the month and its span, the year, or `yearSpan`; arrow labels `previousMonth`/`nextMonth`, `previousYear`/`nextYear`, `previousYears`/`nextYears`; arrows disabled past the ends as now.
- [ ] T032 [US2] `lib/features/hijri_calendar/view/widgets/picker_grid.dart`: the 12 months or 12 years in 3 rows of 4, the current one marked like today, the shown one with the `SlidingSelection` ring, past the ends at `BmOpacity.disabled` and not tappable, a tap `open`/`openYear` with `BmHaptics.selection`. In `hijri_calendar_page.dart` the days, months and years views swap in an `AnimatedSwitcher` (standard, `standardCurve`): zooming out the new view scales from `BmMotion.zoomNear` to 1 and the old from 1 to `BmMotion.zoomFar`, zooming in the reverse, both fading; reduce motion the fade only.
- [ ] T033 [US2] `month_grid.dart` and `day_cell.dart` by mode: Gregorian mode big Gregorian day, small Hijri day with `hijriShort{n}` on the first cell and on each Hijri 1; the same looks on their Hijri days with the adjustment (FR-003). A new shown month slides the whole grid a full width in the way it travels (`compareTo`), mirrored in RTL, with a fade, an `AnimatedSize` for 5 ↔ 6 rows; a mode change crossfades without the slide; reduce motion the fade. T026 passes.

**Checkpoint**: any month in either range in 4 taps or fewer (SC-003).

---

## Phase 6: User Story 4 - Azkar that move on by themselves (Priority: P1)

**Goal**: the next card after the completion moment.

**Independent Test**: spec US4.

- [ ] T034 [P] [US4] Add to `test/features/azkar/view/azkar_set_page_test.dart` with fake time: a count 1 card's tap moves to the next page `BmMotion.completionPause` later; a tap in the wait moves at once and the next card's count stays 0; a swipe back in the wait cancels the move; the last card stays and shows complete; a tap on a done card swiped back to moves to the next card at once (FR-024); popping the page in the wait throws nothing and moves nothing; reduce motion takes the jump and fade path.
- [ ] T035 [US4] `lib/features/azkar/view/azkar_set_page.dart` (data-model "Azkar set: the automatic move"): `Timer? _advance` in `_CardsState`; on `SetTap.done` start `Timer(BmMotion.completionPause, ...)` that runs the done card's tap path (`controller.tap()` answers `moved`, then `moveNext()`); `_tap` and `onPageChanged` cancel it first; `dispose` cancels it. T034 passes.

**Checkpoint**: the morning set needs one tap less per card (SC-005).

---

## Phase 7: User Story 5 - A tasbih that remembers and ends (Priority: P1)

**Goal**: three counts, the automatic move, the round, a 99 bead string.

**Independent Test**: spec US5.

### Tests for User Story 5

- [ ] T036 [P] [US5] Rewrite `test/features/azkar/model/tasbih_state_test.dart` against data-model "Tasbih round": 100 `tap()` from `reset()` end at counts 33, 33, 34 and `complete` (SC-005), moving by `tap()` on a done dhikr; `tap()` on complete gives `(0, [1, 0, 0])`; `select` keeps the counts; `advance` picks the next not done going around and keeps a complete state; `reset`; a count never passes its target; `position`: `(0, [0,0,0])` −1, `(0, [1,0,0])` 0, `(1, [33,0,0])` 33, `(1, [33,1,0])` 34, `(2, [33,33,34])` 101.
- [ ] T037 [P] [US5] Rewrite the affected cases of `test/features/azkar/view/tasbih_page_test.dart` with fake time: the move `completionPause` after a dhikr is done; a tap in the wait counts 1 on the next; a chip in the wait cancels and shows that chip's own count; counts and the shown dhikr survive popping and pushing the page and a new `ProviderScope` on the same store (SC-006); Reset sets all to 0 with the toast, Undo brings back the three counts and the dhikr; all done shows "Set complete" and the next tap starts at SubhanAllah 1; the strip's offset never passes its ends; in Arabic the strip isn't mirrored.

### Implementation for User Story 5

- [ ] T038 [US5] Rewrite `lib/features/azkar/model/tasbih_state.dart`: `TasbihState(dhikr, counts)` with `counts` an unmodifiable list of three ints, members exactly as data-model's table (`count`, `target`, `done`, `doneAt`, `complete`, `nextOpen`, `tap`, `advance`, `select`, `reset`, `position`, with `start` 0, 34, 68), "a count never passes its target", `==`/`hashCode`/`toString` over both. T036 passes.
- [ ] T039 [US5] `lib/features/azkar/view_model/tasbih_controller.dart`: build from the three columns and `tasbihDhikr`; `_set` writes all four in one `updateSettings`; add `advance()`; `reset` and `restore` keep returning and taking the whole state (Undo). Drop T006's single column bridge.
- [ ] T040 [US5] Rewrite `lib/features/azkar/view/widgets/bead_strip.dart` as the finite string (FR-030, data-model "The string"): driven by `position` instead of `taps`; one count steps one bead on `BmMotion.snappy` (stepping over a marker), a chip or the automatic move slides to the new place on the same spring, a new round slides back to the start, retargeted from the current value; jumps with reduce motion; clamped so the free end of the string shows before bead 0 and nothing passes the tassel; marker beads a little larger in `accent`, the head bead larger with a short tassel in `accent`, sizes as new `SizeManager` entries (`beadMarker`, `beadHead`, `tassel`) I tune in the app; painted left to right in both directions.
- [ ] T041 [US5] `lib/features/azkar/view/tasbih_page.dart` (data-model "The automatic move"): `_taps` goes, the strip reads `position` with `.select`; a tap finishing a dhikr while another is open starts `Timer(BmMotion.completionPause, controller.advance)`; a tap, a chip, Reset and `dispose` cancel it; the per dhikr haptic and sound stay, the "Set complete" announcement only when the round completes. T037 passes.
- [ ] T042 [P] [US5] `lib/features/azkar/view/widgets/dhikr_chips.dart` (the selection through `SlidingSelection`), `dhikr_text.dart` (the Arabic line, name and meaning in a `BmSwitcher` keyed by dhikr), `tasbih_counter.dart` (the count with `RollingDigit`, the ring tweening to its new fraction on `standard` and jumping with reduce motion, "Set complete" crossfading in).

**Checkpoint**: a full round is 100 taps with no tap only to move on.

---

## Phase 8: User Story 8 - A cleaner More (Priority: P3)

**Goal**: Acknowledgements, CONTACT, the adjustment in PRAYER.

**Independent Test**: spec US8.

### Tests for User Story 8

- [ ] T043 [P] [US8] Add to `test/core/system/system_channel_test.dart`: `mail` sends `to`, `subject`, `body` and returns the phone's bool, false on null; `device` maps `{"model", "os"}` to the record, empty strings on null.
- [ ] T044 [P] [US8] Add to `test/features/more/more_page_test.dart` (and `test/helpers/more.dart`): no Credits row, ABOUT ends with Acknowledgements and Version; CONTACT hidden with `Contact.mine` all null; `ContactSection(contact: fake)` shows each row only when its value is set, Send feedback calls `mail` with the subject and the body's version, model and OS, a `false` shows the `noMailApp` toast with the address, Rate and Developer call `openUrl` with the platform's link and the website; Hijri date adjustment sits right after Adhan and reminders and its sheet changes `hijriAdjust`; Acknowledgements lists the credits before the licenses and a license opens.

### Implementation for User Story 8

- [ ] T045 [US8] Add `mail` and `device` per `contracts/system-channel.md` to `lib/core/system/system_channel.dart`, `ios/Runner/AppDelegate.swift` (`registerSystem`) and `android/app/src/main/kotlin/com/elhawary/bettermuslim/MainActivity.kt`, and update the "three small calls" comments. Both debug builds pass. T043 passes.
- [ ] T046 [P] [US8] `lib/features/more/model/contact.dart`: `class Contact` with nullable `email`, `developerName`, `website`, `appStoreUrl`, `playStoreUrl`, and `static const mine` with every value null, a `TODO(ahmed):` above each saying what goes there (the address people write to, my name, my site, the two store links once the app is listed) and that a wrong one sends people nowhere.
- [ ] T047 [US8] `lib/features/more/view/widgets/contact_section.dart`: `ContactSection({Contact contact = Contact.mine})`, a `GroupedSection` labelled `sectionContact` with the rows of `contracts/system-channel.md` "Who calls it", each hidden when its value is null, the whole section when all are; Share through `lib/core/system/share.dart` with `shareLine` and the platform's link. Put it above `AboutSection` in `more_page.dart`.
- [ ] T048 [US8] Acknowledgements per `contracts/routes.md`: `lib/features/more/view/licenses_page.dart` becomes `acknowledgements_page.dart` (`AcknowledgementsPage` titled `acknowledgements`: the credits of `model/credits.dart` as `credits_page.dart` lays them out, then the licenses list; `PackageLicensePage` moves with it); `Routes.acknowledgements` and `Routes.license` in `lib/core/router/app_router.dart`, `Routes.credits` and `Routes.licenses` go; delete `credits_page.dart`; `about_section.dart`'s row becomes Acknowledgements; remove the `credits` key.
- [ ] T049 [US8] Move `lib/features/hijri_calendar/view/widgets/adjustment_sheet.dart` to `lib/features/more/view/widgets/adjustment_sheet.dart` with the `adjustment` formatter from `calendar_format.dart` (its only users are now in More), the sheet titled `hijriDateAdjustment`; in `more_page.dart`'s `_PrayerSection` add the `hijriDateAdjustment` row after Adhan and reminders (`BmIconName.hijri`, the formatted value, opens the sheet); remove `_AdjustmentRow` from `hijri_calendar_page.dart` and the `dateAdjustment` key; move the adjustment cases of `sheets_test.dart` to `test/features/more/adjustment_sheet_test.dart` and delete `sheets_test.dart` if empty. T044 passes.

**Checkpoint**: part 1 is built.

---

## Phase 9: Part 1 checks, then stop for my review

- [ ] T050 Run the `adaptive-widgets` self check on every new and changed Dart file of part 1 and `flutter test test/architecture_test.dart`, fix every hit.
- [ ] T051 Run `dart format --set-exit-if-changed lib test integration_test`, `flutter analyze` and `flutter test`, all clean. Build Android dev and iOS dev (`--no-codesign`).
- [ ] T052 Run Dev on the iOS simulator and an Android emulator long enough to open the calendar, Tasbih and More with no error, then add to `CLAUDE.md`'s milestones "12. Polish and motion, before the Quran reader (7): part 1 (the calendar's day area, Gregorian mode and pickers, the theme skies, the azkar and Tasbih moves, the 99 bead string, Acknowledgements and CONTACT). **Part 1 done, waiting for my review.**", list `grep -rn "TODO(ahmed)" lib` in the reply, hand me quickstart.md section 2, and stop.

---

## Phase 10: User Story 6 - Nothing jumps (Priority: P1, part 2)

**Goal**: Apple's push, the flights, dialogs, and every FR-036 change animated.

**Independent Test**: spec US6.

### Tests for User Story 6

- [ ] T053 [P] [US6] Write `test/core/router/page_transitions_test.dart`: on `TargetPlatform.android` and `iOS` a `context.push` builds a `CupertinoPageTransition`; mid push the page under is offset; with `disableAnimations` there's only a `FadeTransition`, done after 150 ms, and the page under doesn't move; the shell and the onboarding steps keep their `CustomTransitionPage`.
- [ ] T054 [P] [US6] Add to `test/core/widgets/bm_dialog_test.dart`: the dialog's scale is `BmMotion.dialogFrom` at the first frame and 1 at the end, with the fade; with `disableAnimations` no `ScaleTransition` and a 150 ms fade.
- [ ] T055 [P] [US6] Write `test/core/widgets/title_hero_test.dart`: a push from a row with a `TitleHero` tag shows one flight shuttle mid way whose text style lies between the two ends; none with `disableAnimations`; a source scrolled off screen gives no flight.

### Implementation for User Story 6

- [ ] T056 [US6] `lib/core/router/page_transitions.dart`: `BmPageTransitionsBuilder` per research R8 (delegates `buildTransitions`, `transitionDuration` and `delegatedTransition` to `CupertinoPageTransitionsBuilder`; under `MediaQuery.disableAnimationsOf` a `FadeTransition` on `Interval(0, .3)` and a `delegatedTransition` that returns the page under as it is). Set it for iOS and Android in `AppTheme._build` in `lib/core/resources/theme_manager.dart` (`pageTransitionsTheme`). T053 passes.
- [ ] T057 [P] [US6] `lib/core/widgets/bm_dialog.dart`: the transition per `contracts/routes.md` (scale `BmMotion.dialogFrom` → 1 with the fade on `decelerate`, `standard` in, `micro` out; reduce motion the fade). T054 passes.
- [ ] T058 [US6] `lib/core/widgets/title_hero.dart`: `TitleHero(tag, child)` per research R9 (a `flightShuttleBuilder` lerping the two `DefaultTextStyle`s and crossfading the two texts, `transitionOnUserGestures: true`, `HeroMode(enabled: false)` with reduce motion). Add `heroTag` to `CompactAppBar` (wraps its title), `QiblaBar` (`lib/features/qibla/view/widgets/qibla_bar.dart`), `_TasbihBar` (`tasbih_page.dart`) and `NavRow` (wraps its title). T055 passes.
- [ ] T059 [US6] The sources and targets of `contracts/routes.md` "Hero tags": `more_tiles.dart` (Qibla, Hijri calendar, Duas tiles' labels), `more_page.dart` (Theme, Adhan and reminders rows), `azkar_page.dart` (`_SetRow`, `_TasbihRow`), `lib/features/duas/view/widgets/category_rows.dart`, and the matching bars' `heroTag` on the Qibla, calendar, Duas, Theme, Adhan and reminders, set, Tasbih and category pages. Home's shortcuts get none.
- [ ] T060 [P] [US6] FR-036 Home (`lib/features/home/view/widgets/`): the no location card ↔ next prayer card in a `BmSwitcher`; `sky_labels.dart` fading in with a place; `strip_cell.dart` current and logged marks with color and opacity tweens (micro); `location_pill.dart`'s text in a `BmSwitcher`; the bright state scrim with `AnimatedOpacity` (standard).
- [ ] T061 [P] [US6] FR-036 Prayer (`lib/features/prayer/presentation/view/`): `prayer_row.dart` opening and closing with `AnimatedSize` and its content fading; `state_chip.dart`'s check fading; `week_strip.dart` scrolling to a linked day with `animateTo` (standard); `day_dots.dart` filling with a color tween; `qada_page.dart` rows in an `AnimatedList` sliding and fading. Each with its reduce motion fallback.
- [ ] T062 [P] [US6] FR-036 Azkar: `zikr_card.dart`'s counter with `RollingDigit`; the loaded swap in `azkar_set_page.dart` and Tasbih's count area in a `BmSwitcher` instead of appearing in one frame.
- [ ] T063 [P] [US6] FR-036 Duas (`lib/features/duas/view/`): `dua_chips.dart` through `SlidingSelection`; `duas_page.dart` results, saved and empty states in a `BmSwitcher`; search results changing in a `BmSwitcher` keyed by the query's result ids.
- [ ] T064 [P] [US6] FR-036 Theme (`lib/features/theme_picker/view/`): `theme_swatches.dart`'s ring through `SlidingSelection`; the preview restyling with `AnimatedTheme` (standard); `mode_control.dart`'s selection (the `Segmented` from T011, or `SlidingSelection` if it isn't one).
- [ ] T065 [P] [US6] FR-036 Adhan and reminders (`lib/features/notifications/presentation/view/adhan_settings_page.dart` and its widgets): the notifications off line and the recording row appearing with `AnimatedSize` and a fade; the segment selections through `Segmented`.
- [ ] T066 [P] [US6] FR-036 shared: `lib/core/widgets/nav_row.dart`'s value in a `BmSwitcher` (crossfade, no slide); `toast/toast.dart`'s `_Toast` sliding `BmMotion.shift` up as it fades in, the fade only with reduce motion; `sheet/location_sheet.dart` results and `location_choices.dart` in a `BmSwitcher`; `sheet/method_sheet.dart` and `picker_row.dart` checks with `AnimatedOpacity` (micro); `backup/backup_sheet.dart` and `restore_sheet.dart` working → done in a `BmSwitcher`.
- [ ] T067 [US6] Walk every screen once more in the code (the spec asks the plan to check again): any state change still swapping in one frame is added as a row to FR-036 in `spec.md` and fixed by the FR-035 rule.

**Checkpoint**: nothing swaps in one frame, reduce motion calms everything to fades.

---

## Phase 11: User Story 7 - Titles and the glow (Priority: P2, part 2)

**Goal**: the title into the bar with the finger, the glow on every page with its switch.

**Independent Test**: spec US7.

### Tests for User Story 7

- [ ] T068 [P] [US7] Write `test/core/widgets/large_title_test.dart` on More: a drag of half the collapse distance puts the moving title half way between its rest and the bar's center at the matching scale; letting go there animates to the nearer end; scrolling back reverses it; the subtitle's opacity is 0 past half; with `disableAnimations` the old fade in at the collapse point.
- [ ] T069 [P] [US7] Add to `test/core/resources/contrast_test.dart`: the bar title (`text`) over `surface` at `BmGlass.surfaceOpacity` over the glow's strongest point (`sky3` at .7 over `bg`), and over the cards that scroll under it (`raised`, the text under them blurred away by `BmGlass.blurSigma`), in all 8 themes, dark and light, at least 4.5:1. If a pair fails, stop and tell me which, don't change a token.
- [ ] T070 [P] [US7] Add to `more_page_test.dart`: Top glow in Appearance toggles `topGlow`; off, no `TitleGlow` paints anything on More and the bar uses .8.

### Implementation for User Story 7

- [ ] T071 [US7] `lib/core/widgets/title_glow.dart`: a full width layer pinned at the top of a page's `Stack` (same size and gradient), watching `settingsProvider.select((settings) => settings.value?.topGlow ?? true)` and fading with `AnimatedOpacity` (standard). `CompactAppBar` uses `BmGlass.surfaceOpacity` with the glow on and the current .8 off (research R12).
- [ ] T072 [US7] Put the glow on every FR-040 page as the first child of a page level `Stack` (the bar and content above it): Prayer and More (moved out of `prayer_header.dart` and More's `_Header`), Azkar, the azkar sets, Tasbih, Duas, a category, the Hijri calendar, Theme, Adhan and reminders, Qada, Qibla, Acknowledgements, a license, the Quran placeholder and the dev page.
- [ ] T073 [US7] `LargeTitleScrollView` in `compact_app_bar.dart` per research R10 with a new `LargeTitle` used by `prayer_header.dart`, `azkar_page.dart`'s `_Header` and More's `_Header` in place of their large `RegularText`; their subtitles read the progress and fade out by 0.5. T068 passes.
- [ ] T074 [US7] More › Appearance: a `topGlow` row (`BmUiIcon.sun`, `toggled`) after Reduce motion in `_AppearanceSection` of `more_page.dart`. T069 and T070 pass.

**Checkpoint**: everything the spec asks for is built.

---

## Phase 12: Polish & Cross-Cutting Concerns

- [ ] T075 Run the `adaptive-widgets` self check on every new and changed Dart file of part 2 and `flutter test test/architecture_test.dart`, fix every hit.
- [ ] T076 Run `dart format --set-exit-if-changed lib test integration_test`, `flutter analyze` and `flutter test`, all clean. Build Android dev and iOS dev.
- [ ] T077 Run Dev on the iOS simulator and an Android emulator long enough to push every page of `contracts/routes.md` once with no error, then hand me quickstart.md section 3 to run myself, the profile check on an older phone (SC-008, SC-009) included. If frames go over budget, note where for a follow up, don't tune blind.
- [ ] T078 [P] Change the milestone 12 line in `CLAUDE.md` to "12. Polish and motion, before the Quran reader (7): the calendar's day area, Gregorian mode and pickers, the theme skies, the azkar and Tasbih moves with the 99 bead string, Acknowledgements and CONTACT, Apple's push and the title flights, every state change animated, the large titles into the bar and the top glow with its switch. **Done, waiting for my review.**"
- [ ] T079 Run `grep -rn "TODO(ahmed)" lib assets ios android packages pubspec.yaml` and list in the reply what I still have to supply, the contact values from T046 first.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: first.
- **Foundational (Phase 2)**: after Setup, blocks every part 1 story.
- **US3 (Phase 3)**: first after Phase 2, T012 before T014 (the clarification "a test on the text
  over all 48 skies before any motion work").
- **US1 (Phase 4)** then **US2 (Phase 5)**: both in the calendar, US2 builds on US1's providers.
- **US4, US5, US8 (Phases 6 to 8)**: after Phase 2, independent of each other and of the calendar.
- **Part 1 checks (Phase 9)**: after Phases 3 to 8, then stop for my review.
- **US6 (Phase 10)** and **US7 (Phase 11)**: after my review of part 1. US7's T073 touches
  `compact_app_bar.dart` after US6's T058, and T072 after T071.
- **Polish (Phase 12)**: after the stories.

### Inside Phase 2

- T002 and T003 need T006's generated schema to run, they are written first.
- T004 before T010, T005 before T011.
- T007, T008, T009, T010 in parallel with T006.

### Inside the stories

- US3: T012 first, T013 beside it, then T014, T015, then T016.
- US1: T017 and T018 first. T019, then T020, then T021. T022 and T023 in parallel, then T024.
- US2: T025 and T026 first. T027, then T028, then T029 to T033 (T029 in parallel, T030 to T033
  one after the other in the calendar's widgets).
- US4: T034, then T035.
- US5: T036 and T037 first, then T038, T039, then T040 and T042 in parallel, then T041.
- US8: T043 and T044 first. T045 and T046 in parallel, then T047, T048, T049.
- US6: T053 to T055 first. T056, T057, T058 (T057 in parallel), then T059. T060 to T066 in
  parallel after T058, then T067.
- US7: T068 to T070 first. T071, then T072, then T073, then T074.

### Parallel Opportunities

- Phase 2: T002 to T005 together, then T007 to T010 beside T006.
- After Phase 2: US4 and US8 can run beside the calendar (US1, US2) and US3.
- US6: T060 to T066 together, each a different screen.

## Parallel Example: Phase 2

```text
Task: "T007 strings"
Task: "T008 motion tokens"
Task: "T009 RollingDigit into core"
Task: "T010 BmSwitcher"
```

## Parallel Example: User Story 6

```text
Task: "T060 FR-036 Home"
Task: "T061 FR-036 Prayer"
Task: "T063 FR-036 Duas"
Task: "T064 FR-036 Theme"
Task: "T065 FR-036 Adhan and reminders"
Task: "T066 FR-036 shared"
```

## Implementation Strategy

### MVP First (User Story 3, then User Story 1)

1. Phase 1 and Phase 2 (schema 8, strings, tokens, the three motion widgets).
2. US3: the 48 sky test, then the theme skies. The most visible fix, checked first.
3. US1: the day under the calendar.

### Incremental Delivery

1. Part 1: US3 → US1 → US2 → US4 → US5 → US8, then Phase 9 and stop for my review.
2. Part 2: US6 → US7 → Polish, then stop for my review (constitution workflow).
