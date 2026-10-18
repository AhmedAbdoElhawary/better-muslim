---

description: "Tasks for milestone 4, prayer"
---

# Tasks: Milestone 4, Prayer

**Input**: Design documents from `specs/002-milestone-4-prayer/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/prayer-log.md,
quickstart.md

**Tests**: Included. Constitution VI asks for unit tests on logic and widget tests on screens, and
SC-004 asks for every row state a minute either side of every boundary.

**Organization**: Grouped by user story, so each story can be built and checked on its own.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an unfinished task)
- **[Story]**: The user story the task belongs to (US1 to US5)

## Before starting

- Built after milestone 3 (Home), on `feature/milestone-4` cut from `feature/milestone-2` once
  milestone 2 is committed (Q8).
- Milestone 3 goes first, so check what it already put in `core/`: a bottom sheet, a toast, a
  compact bar, the location sheet. Reuse what is there. T014 to T016 only add what is missing.
- Every UI file follows the `adaptive-widgets` rules, and `flutter test test/architecture_test.dart`
  stays green.
- Parallel sessions share `.specify/feature.json`, so speckit commands get this folder passed
  explicitly (`SPECIFY_FEATURE_DIRECTORY=specs/002-milestone-4-prayer`).

---

## Phase 1: Setup

**Purpose**: Branch, layer folders and the journey test package. No new pub.dev package: `intl` is
already a direct dependency (R7), `integration_test` comes with the Flutter SDK (approved
2026-10-18).

- [ ] T001 Ask before cutting `feature/milestone-4` from `feature/milestone-2`, once milestone 2 is committed and milestone 3 is merged into it. Then confirm `flutter pub get`, `flutter analyze` and `flutter test` are green before any change.
- [ ] T002 Create the empty layer folders `lib/features/prayer/domain/`, `lib/features/prayer/data/`, `lib/features/prayer/presentation/providers/` and `lib/features/prayer/presentation/view/widgets/`, next to the existing `lib/features/prayer/presentation/view/prayer_page.dart`.
- [ ] T003 [P] Add `integration_test: sdk: flutter` under `dev_dependencies` in `pubspec.yaml` (approved 2026-10-18), run `flutter pub get`, and create the empty `integration_test/` folder.

---

## Phase 2: Foundational

**Purpose**: What every story stands on: the store v2, the log, the prayer day, the row state
function, the strings, the core widgets and the design scenario.

**⚠️ CRITICAL**: No story work starts before this phase is done

### Tests for the foundation

- [ ] T004 [P] Write `test/core/database/civil_date_test.dart`: `DateTime(2026, 10, 15)` ↔ `'2026-10-15'`, a single digit month and day pad to two, reading `'2026-03-29'` gives a local midnight `DateTime(2026, 3, 29)` whatever the test zone, and string order equals date order.
- [ ] T005 [P] Write `test/core/database/prayer_log_test.dart` on `AppDatabase.forTesting(NativeDatabase.memory())`:
  - `markPrayed` twice for the same day and prayer leaves one row
  - `unmarkPrayed` removes it
  - a qada entry with the same `(missedOn, prayer)` twice fails on the unique index, and two
    entries with `missedOn` null for the same prayer don't
  - `watchSettings(now: DateTime(2026, 10, 1, 9))` on a new store sets `firstUse` to
    `DateTime(2026, 10, 1)`, and a second call with another `now` doesn't change it
- [ ] T006 [P] Write `test/core/prayer_times/prayer_day_test.dart`:
  - `DayTimes.endOf` gives sunrise for Fajr, Asr for Dhuhr, Maghrib for Asr, Isha for Maghrib,
    and tomorrow's Fajr for Isha
  - with a null time it skips to the next time that exists, and gives null when none is left
  - in Ramadan with Umm al-Qura, Maghrib ends 120 minutes after its start
  - `prayerDayProvider` with the clock frozen one minute before today's Fajr gives yesterday,
    and at Fajr it gives today
  - it doesn't notify on ticks inside the same day
  - at 23:59 and at 00:01 the prayer day is the same (SC-004, midnight)
- [ ] T007 [P] Write `test/features/prayer/domain/prayer_row_state_test.dart` (SC-004): for each prayer, at its time −1 min, +1 min, its end −1 min and +1 min, check the state and `isOpen` against the data-model.md table, first match wins. Run it on four days:
  - the scenario day in Makkah
  - a Ramadan day with Umm al-Qura
  - Europe/London on 25 Oct 2026, the daylight saving end
  - a day computed after the location zone changes from Asia/Riyadh to Europe/Istanbul

  Also: logged beats every other state, Isha at 23:59 and 00:01 stays `mark` and open, a future
  day only gives `next` or `later`, and
  `next` only for the exact instant `nextPrayerProvider` gives.
- [ ] T008 [P] Write `test/features/prayer/domain/week_test.dart`:
  - `weekStart` of Thu 15 Oct 2026 is Sun 11 Oct
  - a Sunday is its own start
  - pages from first use Thu 1 Oct to the week of 15 Oct are 3 (27 Sep, 4 Oct, 11 Oct)
  - a first use after today counts as today (1 page)
  - the month range of 15 Oct 2026 is `'2026-10-01'` to `'2026-10-31'`
- [ ] T009 [P] Extend `test/core/app/app_localizations_test.dart`:
  - an Arabic ICU plural string formats for 0 to 12 with Western and Eastern digit args and
    picks the CLDR form: 1 → "صلاة واحدة", 2 → "صلاتان", 3, 10 and 103 → few, and 0, 11 and
    99 → the other branch (CLDR zero and many have no branch of their own)
  - English strings without plural syntax come back unchanged
  - no plural string in either arb contains `'`

### Implementation for the foundation

- [ ] T010 Create `lib/core/database/civil_date.dart`: `class CivilDate extends TypeConverter<DateTime, String>`, `toSql` writes `yyyy-MM-dd` from year, month and day only, and `fromSql` returns `DateTime(y, m, d)` (R2).
- [ ] T011 Extend `lib/core/database/app_database.dart` (data-model.md):
  - `PrayerLog` table: `date` text mapped with `CivilDate` ("the prayer day the prayer belongs
    to, not the clock time it was marked"), `prayer` `textEnum<Prayer>()`, primary key
    `{date, prayer}`
  - `QadaEntries` table: `id` int autoIncrement, `prayer` `textEnum<Prayer>()`, `missedOn` text
    nullable mapped with `CivilDate` ("null = missed before using the app"), `madeUpAt` dateTime
    nullable ("null = still open"), and `@TableIndex(name: 'qada_day', columns: {#missedOn, #prayer}, unique: true)`
  - `Settings.firstUse`: text nullable mapped with `CivilDate`
  - `@DriftDatabase(tables: [Settings, PrayerLog, QadaEntries])` and `schemaVersion => 2`
  - `watchSettings({DateTime? now})` inserts the default row with
    `firstUse: Value(CivilDate day of now ?? DateTime.now())`, so an existing row keeps its value
  - `markPrayed(DateTime day, Prayer prayer)` as `insertOrIgnore`, and
    `unmarkPrayed(DateTime day, Prayer prayer)` as a delete. One-line `///` on each, saying they
    work without Riverpod for milestone 5
- [ ] T012 Run `dart run build_runner build --delete-conflicting-outputs`, then `dart run drift_dev make-migrations`. Keep these generated files in the change set, since CI doesn't run build_runner: `lib/core/database/app_database.g.dart`, `drift_schemas/app_database/drift_schema_v2.json`, `lib/core/database/app_database.steps.dart`, the v2 schema in `test/drift/app_database/generated/` and `test/drift/app_database/migration_test.dart`.
- [ ] T013 Add `migration => MigrationStrategy(onUpgrade: stepByStep(from1To2: ...))` in `lib/core/database/app_database.dart`. `from1To2` creates `prayerLog` and `qadaEntries`, adds `settings.firstUse`, then runs `update settings set first_use = date('now', 'localtime')` (R6). Extend the generated `test/drift/app_database/migration_test.dart`: a v1 row with every column set keeps every value after the upgrade, and `first_use` is filled. Update `test/drift/app_database/schema_test.dart` to check v2.
- [ ] T014 [P] Add the toast in `lib/core/widgets/toast/toast.dart`, unless milestone 3 already has one: `showToast(BuildContext context, String key, {Map<String, String> args = const {}, VoidCallback? onUndo})`.
  - a floating `SnackBar`, duration 4 s, content built from the "With action" toast of
    `03 Components.dc.html` with the weight text widgets and `ThemeEnum` colors
  - Undo is our own text button (`StringsManager.undo`) that calls `onUndo`, then hides the toast
  - a new toast replaces the old one
  - it shows on the shell's root Scaffold above the tab bar (R8)
- [ ] T015 [P] Add the sheet in `lib/core/widgets/sheet/bm_sheet.dart` and `lib/core/widgets/sheet/picker_row.dart`, unless milestone 3 already has them:
  - `showBmSheet(BuildContext context, {required String title, required Widget child})`: the
    "Bottom sheet" component with grabber, xl top radius, surface color and scrim 64% dark / 48%
    light, opening with MOTION 15
  - `PickerRow({title, subtitle?, value?, selected, onTap})`: the "Selected (picker)" list row
    with `value` as the trailing text (like "Muslim World League" in the components file), at
    least 44 pt tall, giving `BmHaptics.selection()` on tap
- [ ] T016 [P] Add the compact bar in `lib/core/widgets/compact_app_bar.dart`, unless milestone 3 already has one: the 56 pt bar with a 44 × 44 `BmIcon.ui(BmUiIcon.back)` that mirrors in RTL, and `LargeTitleScrollView` (large title in Marcellus or Reem Kufi with `LineHeightManager.largeTitle`, which fades into the compact bar's title once scrolled under it).
- [ ] T017 [P] Add the 21 strings of spec FR-028 to `lib/core/resources/strings_manager.dart` and both `assets/l10n/app_en.arb` and `assets/l10n/app_ar.arb`, with `@` placeholder notes:
  - keys: `prayerUnmarked`, `undo`, `prayerPassedTitle`, `prayerPassedBody`, `iPrayedIt`,
    `addedToQada`, `removedFromQada`, `inQada`, `madeUp`, `nothingToMakeUp`, `qadaList`, `qadaTotal`, `qadaLeft`,
    `madeOneUp`, `prayerMadeUp`, `addOlderQada`, `addMissedTitle`, `add`, `byCountry`,
    `chosenForCountry`, `asrCalculation`
  - Arabic `qadaTotal` and the existing `missedToMakeUp` become ICU plurals with the R7 forms
    (one, two, few `{count} صلوات …`, other `{count} صلاة …`)
  - `test/core/resources/strings_manager_test.dart` stays green
- [ ] T018 [P] Add plural support in `lib/core/app/app_localizations.dart` (R7):
  - keep `languageCode` from `load()`
  - in `tr`, after the `{placeholder}` swap, a string matching `\{(\w+), plural,` goes through
    `MessageFormat(text, locale: languageCode).format({name: count})`, where `count` is
    `int.parse` of that arg with Eastern digits turned Western
  - nothing changes for call sites
- [ ] T019 [P] Add named sizes from 4.04 to `lib/core/resources/dimensions_manager.dart`:
  - `SizeManager`: `prayerRow` 62, `sunriseRow` 44, `rowTrailing` 96, `weekCell` 68, `dayDot` 4,
    `ring` 56, `markChip` 32, `stateChip` 26
  - `SizeManager.ringStroke` 4
  - `SpaceManager`: `dayDotGap` 2
  - `RadiusManager`: `weekCell` 14, `prayerRow` 16

  Reuse an existing entry wherever the value and meaning already exist.
- [ ] T020 Add `endOf(Prayer prayer, DayTimes? tomorrow)` to `lib/core/prayer_times/day_times.dart` (the next period start that has a time, R3), and `prayerDayProvider` to `lib/core/prayer_times/prayer_times_providers.dart`: today's date from `todayProvider`, or the day before when the ticker's now is before today's Fajr. It returns a `DateTime` date, so it only notifies when the day changes. T006 passes.
- [ ] T021 Create `lib/core/prayer_log/prayer_log.dart` (contracts/prayer-log.md):
  - `weekLogProvider = StreamProvider.autoDispose.family<Map<DateTime, Set<Prayer>>, DateTime>`,
    one query on `prayer_log` with `date` between the Sunday and the Saturday
  - `prayedProvider = Provider.autoDispose.family<Set<Prayer>, DateTime>`, reading the week of
    its date
  - pass the clock in `lib/core/settings/settings.dart`:
    `watchSettings(now: ref.read(clockProvider)())`

  T005 passes.
- [ ] T022 Create `lib/features/prayer/domain/prayer_row_state.dart`: `enum PrayerRowState { unavailable, prayed, next, later, mark, madeUp, inQada, addToQada }` and `({PrayerRowState state, bool isOpen}) rowState({TZDateTime? time, TZDateTime? end, required DateTime now, required bool logged, QadaEntry? qada, (Prayer, TZDateTime)? next, required Prayer prayer})` with the six rules of research R4, pure Dart. T007 passes.
- [ ] T023 Create `lib/features/prayer/domain/week.dart`: `weekStart(DateTime day)`, `weekPages(DateTime firstUse, DateTime today)` (the Sundays from the week of the clamped first use to the week of today), and `monthRange(DateTime day)` as two `CivilDate` strings. T008 passes.
- [ ] T024 Move the design scenario onto a seeded in-memory store (R12):
  - in `lib/core/flavor/design_scenario.dart` add `Future<AppDatabase> designScenarioStore()`,
    seeded with: `firstUse` 1 Oct 2026; all five prayers on Sun 11, Mon 12 and Wed 14 Oct; Fajr,
    Dhuhr, Asr, Maghrib on Tue 13; Fajr and Dhuhr on Thu 15; open qada entries for Isha Tue 13,
    Fajr Tue 6 and Fajr Thu 8 Oct
  - replace the `todayTimesProvider` override with `dayTimesProvider.overrideWith((ref, date) => ...)`:
    the handoff's six times for 15 Oct, `DayTimes.compute` for Makkah with Umm al-Qura and
    Standard Asr for every other date
  - in `lib/bootstrap.dart` the scenario uses `designScenarioStore()` instead of
    `AppDatabase.open()`
  - update `test/core/flavor/design_scenario_test.dart`: 15 Oct shows the handoff times, 16 Oct
    gives computed times, the week log and the 3 qada entries are there, and the real store is
    never opened

**Checkpoint**: store v2 with migration, the log and prayer day in core, row states tested at every
boundary, strings and core widgets ready. `flutter test` green.

---

## Phase 3: User Story 1 - Mark the prayer I just prayed (Priority: P1) 🎯 MVP

**Goal**: the Prayer tab as in 4.04 and 4.17 for the prayer day, with Mark, unmark with Undo, the
ring, the count, this week's dots and Day complete.

**Independent Test**: design scenario, tap Mark on Asr: "3 of 5 prayed today", ring at 3/5,
Thursday with 3 dots. Tap "Prayed": back to 2 and a toast with Undo for 4 s. Undo brings it back.

### Tests for User Story 1

- [ ] T025 [P] [US1] Write `test/features/prayer/presentation/prayer_page_test.dart` with the scenario overrides and `testOverrides()`:
  - the six rows show the times from SCREENS.md, Sunrise has no action, Asr is filled with NOW
    and Mark, Maghrib shows "in 1:24" and Isha the adhan icon
  - tapping Mark shows "3 of 5 prayed today" and Thursday 3 filled dots
  - tapping "Prayed" goes back to 2 and shows the toast, Undo gives 3 again, and with no tap the
    toast is gone after 4 s
  - a double tap on Mark leaves one log row
  - in Arabic the digits are Eastern, the strip reads Sunday on the right, and the ring and dots
    sit inside an LTR `Directionality`
  - at text scale 2.0 there is no overflow, and each row uses its stacked layout
  - with `alwaysUse24HourFormat` off the times read "5:56 PM" and fit the row (spec edge case)
  - every action has at least 44 × 44 hit area
  - `unmount(tester)` at the end
- [ ] T026 [P] [US1] Write `test/features/prayer/presentation/day_complete_test.dart`:
  - marking the fifth plays Day complete once
  - opening a day that is already complete doesn't play it
  - unmarking the fifth and marking it again plays it again
  - with reduce motion it uses the 300 ms star fade

### Implementation for User Story 1

- [ ] T027 [P] [US1] Create `lib/features/prayer/presentation/providers/selected_day.dart`: `selectedDayProvider` (a `Notifier<DateTime?>`, null = follow the prayer day) and `shownDayProvider = selectedDay ?? prayerDayProvider` (R10).
- [ ] T028 [P] [US1] Create `lib/features/prayer/presentation/providers/prayer_actions.dart`:
  - `prayerActionsProvider` with `Future<bool> mark(DateTime day, Prayer prayer)`, which calls
    `markPrayed` and returns true when the day now has all five (R11)
  - `Future<void> unmark(DateTime day, Prayer prayer)`
- [ ] T029 [US1] Create `lib/features/prayer/presentation/providers/row_state.dart`: `rowStateProvider.family<({PrayerRowState state, bool isOpen}), (DateTime, Prayer)>`. It reads the ticker's now, `dayTimesProvider(day)`, `dayTimesProvider(day + 1)` for `endOf`, `prayedProvider(day)` and `nextPrayerProvider`, then calls `rowState()`. It notifies only when the record changes. Qada stays null until US2.
- [ ] T030 [P] [US1] Create `lib/features/prayer/presentation/view/widgets/progress_ring.dart`: the 56 pt ring (r 24, stroke 4, `ThemeEnum.variant` track, `ThemeEnum.primary` arc with round cap, starting at the top), which animates the sweep `BmMotion.standard` with `BmMotion.standardCurve` on count changes, and the count in the middle (15, semibold, tabular). Inside `Directionality(ltr)`.
- [ ] T031 [P] [US1] Create `lib/features/prayer/presentation/view/widgets/day_dots.dart` (5 dots of 4 pt with a 2 pt gap: filled `ThemeEnum.primary` for each logged prayer in prayer order, the others with a 1 pt `ThemeEnum.outlineStrong` ring, inside `Directionality(ltr)`) and `day_cell.dart` (68 pt cell with the radius-14 primaryContainer fill and its 35% primary outline when it is the shown day, the day letter and the date number, grey numbers for future days, as in 4.04 and 4.17).
- [ ] T032 [US1] Create `lib/features/prayer/presentation/view/widgets/week_strip.dart`: the 7-column grid with a 4 pt gap for the week of the shown day, each cell reading `weekLogProvider(weekStart)`, `.select()` per day. Paging and taps come in US4.
- [ ] T033 [P] [US1] Create `lib/features/prayer/presentation/view/widgets/mark_button.dart` (Motion 07):
  - the primary 32 pt "Mark" pill morphs into the 26 pt success "Prayed" chip with a
    `BmMotion.snappy` spring scale and the check stroke drawn over `BmMotion.checkStroke` with
    `PathMetric.extractPath`
  - `BmHaptics.markPrayed()` fires when the check fills
  - with reduce motion (`context.reduceMotion(settings.reduceMotion)`) it is a 150 ms crossfade
  - the "Prayed" chip is a toggle with checked semantics (R13)
- [ ] T034 [P] [US1] Create `lib/features/prayer/presentation/view/widgets/day_complete.dart` (Motion 08, as `05 Motion.dc.html` and MOTION.md draw it, `BmMotion.gentle`, 1400 ms, `BmHaptics.dayComplete()`, reduce motion: the star fades in over 300 ms), shown as an overlay the page triggers.
- [ ] T035 [US1] Create `lib/features/prayer/presentation/view/widgets/row_trailing.dart` (the 96 × 44 trailing area: `mark` → `MarkButton`, `prayed` → the "Prayed" chip, `next` → the accent "in h:mm" chip reading the ticker with `.select()` on minutes left, `later` → `BmIcon(BmIconName.adhan)` 20 in `ThemeEnum.text2`, `unavailable` → nothing) and `prayer_row.dart`:
  - 62 pt rows, Sunrise 44 pt with its own smaller name and time
  - the icons from 4.04 (sunrise, sun, night)
  - name in `FontEnum.display`, time through `context.formatTime`
  - NOW tag and the primaryContainer fill when `isOpen`
  - the stacked layout above text scale 1.4
  - one `Semantics` node built from the prayer, the time and the chip label (R13)
- [ ] T036 [US1] Create `lib/features/prayer/presentation/view/widgets/summary_card.dart`: the 20-radius surface card with a 1 pt outline, `ProgressRing` and "{count} of 5 prayed today" from `prayedProvider(prayerDay)` (FR-014, FR-015), and the forward chevron. The second line and the tap come in US3.
- [ ] T037 [US1] Rewrite `lib/features/prayer/presentation/view/prayer_page.dart` from 4.04 and 4.17:
  - `LargeTitleScrollView` with the header row (pin and sliders 44 × 44 buttons, wired in US5
    and Polish), "Prayer times" and the "place · method" subtitle
  - the radial sky3 glow behind the header
  - `WeekStrip`, `SummaryCard` and the six `PrayerRow`s for `shownDayProvider`
  - unmark shows `showToast(StringsManager.prayerUnmarked, args: {'prayer': ...}, onUndo: mark)`
  - a `mark` that returns true plays `DayComplete`

  T025 and T026 pass.

**Checkpoint**: Mark, unmark with Undo, ring, count, dots and Day complete work for the prayer day,
in both languages, both modes and text scale 2.0.

---

## Phase 4: User Story 2 - A prayer that passed without being logged (Priority: P1)

**Goal**: passed rows offer "I prayed it" or "Add to qada", with the "In qada" and "Made up"
states.

**Independent Test**: clock at 16:32 with Dhuhr unlogged. Dhuhr shows "Add to qada". "I prayed it"
turns it "Prayed" with no toast. Unmark, then "Add to qada": "In qada" and the toast with Undo.

### Tests for User Story 2

- [ ] T038 [P] [US2] Write `test/features/prayer/data/qada_repository_test.dart` (part 1) on an in-memory store: `add(day, prayer)` makes an open dated entry, a second `add` for the same day and prayer changes nothing, `remove(day, prayer)` deletes only the open dated one, and `watchWeek(weekStart)` gives the dated entries of those 7 days.
- [ ] T039 [P] [US2] Write `test/features/prayer/presentation/passed_prayer_test.dart`:
  - Dhuhr unlogged at 16:32 shows "Add to qada", and the tap opens the sheet "Dhuhr has passed"
    with the body and both options
  - "I prayed it" logs it with no toast
  - "Add to qada" shows "In qada" and the toast, and Undo goes back to "Add to qada"
  - tapping "In qada" removes it with the "Dhuhr removed from qada" toast, and Undo brings "In
    qada" back
  - a made up dated entry shows "Made up" as text, and a tap changes nothing

### Implementation for User Story 2

- [ ] T040 [US2] Create `lib/features/prayer/data/qada_repository.dart` with `qadaRepositoryProvider` over `databaseProvider`: `add(DateTime day, Prayer prayer)` as `insertOrIgnore` with `missedOn: day`, `remove(DateTime day, Prayer prayer)` for the open dated entry, and `watchWeek(DateTime weekStart)` for the week's dated entries keyed by `(day, prayer)`. T038 passes.
- [ ] T041 [US2] Feed the day's dated qada entry into `rowStateProvider` in `lib/features/prayer/presentation/providers/row_state.dart`, reading a `qadaWeekProvider` (autoDispose family over `watchWeek`) with `.select()` on its `(day, prayer)`.
- [ ] T042 [P] [US2] Create `lib/features/prayer/presentation/view/widgets/passed_sheet.dart`: `showBmSheet` titled `prayerPassedTitle` with `{prayer}`, the `prayerPassedBody` line, and two `PickerRow`-style options. `iPrayedIt` calls `prayer_actions.mark` with no toast. `addToQada` calls `add`, closes, and shows `showToast(addedToQada, onUndo: remove)`.
- [ ] T043 [US2] Add three states to `lib/features/prayer/presentation/view/widgets/row_trailing.dart`, using the "Passed, not logged" chip look of `03 Components.dc.html`:
  - `addToQada`: outline chip, the tap opens the passed sheet
  - `inQada`: outline chip, the tap calls `remove` and shows
    `showToast(StringsManager.removedFromQada, args: {'prayer': ...}, onUndo: add)`
  - `madeUp`: green chip, plain text, no button

  T039 passes.

**Checkpoint**: every passed prayer has a path. Take screenshots of the passed sheet and the two
new chips for my OK (FR-022).

---

## Phase 5: User Story 3 - My qada list (Priority: P2)

**Goal**: the summary card's month line and the qada list with "Made one up", + and the count
sheet.

**Independent Test**: design scenario, the card says "3 missed this month to make up". The list
shows Fajr 2 and Isha 1. "Made one up" on Isha gives 2 and a toast, Undo gives 3. + on Fajr, count
2, Add: Fajr 4, the month count stays 3, Undo removes both.

### Tests for User Story 3

- [ ] T044 [P] [US3] Extend `test/features/prayer/data/qada_repository_test.dart` (part 2):
  - `makeUpOldest(prayer)` takes a dateless entry before any dated one, then the oldest
    `missedOn`, then the lowest id, and returns its id
  - `undoMadeUp(id)` sets `madeUpAt` back to null on the same id
  - `addOlder(prayer, count)` inserts `count` dateless rows in one batch and returns their ids
  - `removeIds(ids)` deletes exactly those
  - `watchOpenCounts()` gives the open count per prayer, and made up entries never count
  - `watchMonthCount(day)` counts only open dated entries in that Gregorian month
- [ ] T045 [P] [US3] Write `test/features/prayer/presentation/qada_page_test.dart`:
  - the scenario card shows "3 missed this month to make up", and Arabic shows the few form
  - tapping the card pushes the qada list with the compact bar, the total and five rows (Fajr 2,
    Dhuhr 0, Asr 0, Maghrib 0, Isha 1)
  - "Made one up" is disabled at 0
  - "Made one up" on Isha gives the toast and "2 missed this month", and Undo goes back
  - + opens the sheet "Add missed Fajr" at 1: − at 1 stays 1, holding + runs and stops at 999,
    and Add with 2 gives Fajr 4 and the toast, whose Undo gives Fajr 2
  - at 0 open this month the card says "Nothing to make up this month"

### Implementation for User Story 3

- [ ] T046 [US3] Add `makeUpOldest`, `undoMadeUp`, `addOlder(Prayer prayer, int count)` (asserts 1 to 999), `removeIds`, `watchOpenCounts` (one grouped `count(*)`) and `watchMonthCount(DateTime day)` (a `missedOn` range from `monthRange`) to `lib/features/prayer/data/qada_repository.dart`. T044 passes.
- [ ] T047 [US3] Register `Routes.qada = '/prayer/qada'` as a child `GoRoute` of the Prayer branch in `lib/core/router/app_router.dart`, opening `QadaPage`.
- [ ] T048 [US3] Finish `lib/features/prayer/presentation/view/widgets/summary_card.dart`: the second line `missedToMakeUp` with the month count of the prayer day, `nothingToMakeUp` at 0 (FR-016), and a tap that pushes `Routes.qada`.
- [ ] T049 [P] [US3] Create `lib/features/prayer/presentation/view/widgets/add_older_sheet.dart` (R15):
  - `showBmSheet` titled `addMissedTitle` with `{prayer}`
  - − and + as 44 × 44 `BmIcon.ui(BmUiIcon.minus)` and `BmIcon.ui(BmUiIcon.plus)` buttons around
    the count, kept 1 to 999 and starting at 1
  - holding repeats on a timer that speeds up, a tap gives `BmHaptics.selection()` and repeats
    don't
  - the `add` button calls `addOlder` and shows `showToast(addedToQada, onUndo: removeIds)`
- [ ] T050 [US3] Create `lib/features/prayer/presentation/view/qada_page.dart` and `lib/features/prayer/presentation/view/widgets/qada_row.dart` from the components file only (FR-022): the compact bar titled `qadaList`, the `qadaTotal` line, and a grouped section of five rows. Each row has the prayer name in display font, `qadaLeft` with the count, a `madeOneUp` button (disabled at 0, its toast `prayerMadeUp` with Undo calling `undoMadeUp`), and a + button with the `addOlderQada` screen reader label that opens `add_older_sheet`. T045 passes.

**Checkpoint**: the qada list works on its own. Take screenshots of the qada list and the + sheet
in both modes and languages for my OK (FR-022).

---

## Phase 6: User Story 4 - Other days of the week (Priority: P2)

**Goal**: tap a day, page back to the week of first use, deep link to a day and prayer.

**Independent Test**: design scenario. Tap Tuesday: Tuesday fills, four "Prayed", Isha "In qada".
Tap Saturday: times only. The card still shows today. Swipe back twice to the week of 27 Sep, then
it stops. Forward stops at this week.

### Tests for User Story 4

- [ ] T051 [P] [US4] Write `test/features/prayer/presentation/week_strip_test.dart`:
  - tapping Tuesday fills Tuesday and not Thursday, the rows show Tuesday, and the card still
    shows 2 of 5
  - tapping Saturday shows times with no Mark, chip or sheet
  - two swipes back reach 27 Sep and a third doesn't move
  - forward from this week doesn't move
  - in Arabic the earlier week comes from the right
  - with no day picked, moving the clock past Fajr moves the shown day, and with a day picked it
    stays
- [ ] T052 [P] [US4] Write `test/core/router/prayer_route_test.dart`: `Routes.prayerAt(DateTime(2026, 10, 13), Prayer.isha)` gives `/prayer?day=2026-10-13&prayer=isha`, and opening it shows Tuesday with the Isha row visible. Bad params fall back to the prayer day.

### Implementation for User Story 4

- [ ] T053 [US4] Turn `lib/features/prayer/presentation/view/widgets/week_strip.dart` into a `PageView` over `weekPages(settings.firstUse, prayerDay)`, opening on the last page with no page after it (R9). Each page reads its own `weekLogProvider`. A day cell tap sets `selectedDayProvider`, and today again sets null.
- [ ] T054 [US4] Add `Routes.prayerAt(DateTime day, Prayer prayer)` to `lib/core/router/app_router.dart` and read the `day` and `prayer` query params in the Prayer branch's builder. `lib/features/prayer/presentation/view/prayer_page.dart` then sets `selectedDayProvider` and scrolls the row into view with `Scrollable.ensureVisible` (contracts/prayer-log.md). T051 and T052 pass.

**Checkpoint**: any day back to first use can be fixed, and Home and notifications can link to a
day and prayer.

---

## Phase 7: User Story 5 - Change the calculation method (Priority: P3)

**Goal**: the sliders icon opens the method sheet.

**Independent Test**: plain Dev in Makkah. The sheet shows "By country · Umm al-Qura" selected.
Muslim World League changes the subtitle and times. "By country" goes back.

### Tests for User Story 5

- [ ] T055 [P] [US5] Write `test/features/prayer/presentation/method_sheet_test.dart` with a Makkah location and no picks:
  - "By country" with "Chosen for your country" under it and "Umm al-Qura" as its value is
    selected, then the 11 methods, then "Asr
    calculation" with By country, Standard and Hanafi
  - picking Muslim World League stores it and the subtitle changes
  - picking "By country" stores null
  - Asr Hanafi stores hanafi and Asr's time moves later
  - each pick gives the selection haptic

### Implementation for User Story 5

- [ ] T056 [US5] Create `lib/features/prayer/presentation/view/widgets/method_sheet.dart`: `showBmSheet` titled `calculationMethod` with `PickerRow`s. The first is `byCountry` with `chosenForCountry` as its subtitle and the country's method name as its `value`, then the `PrayerMethod` values by their name keys, then an `asrCalculation` section with `byCountry`, `asrStandard`, `asrHanafi`. A pick writes `updateSettings(SettingsCompanion(method: Value(...)))` or `asrMethod`, and `Value(null)` means by country. Wire the sliders button in `lib/features/prayer/presentation/view/prayer_page.dart`. T055 passes.

**Checkpoint**: take screenshots of the method sheet for my OK (FR-022).

---

## Phase 8: Polish & Cross-Cutting Concerns

- [ ] T057 Wire the pin in `lib/features/prayer/presentation/view/prayer_page.dart` to milestone 3's location sheet (FR-025, R14). If milestone 3 left the sheet under `lib/features/home/`, first move it to `lib/core/` unchanged, update Home's import, and keep milestone 3's tests green.
- [ ] T058 Feed Home's prayer strip checks from `prayedProvider(ref.watch(prayerDayProvider))` in milestone 3's strip widget under `lib/features/home/view/widgets/`, if milestone 3 left them on sample data (FR-027). Also link each strip cell to `Routes.prayerAt` if it isn't already.
- [ ] T059 [P] Write `test/core/database/prayer_log_zone_test.dart` (FR-010): log Asr on 15 Oct with the location in Asia/Riyadh, switch the phone zone to America/New_York, and `prayedProvider(DateTime(2026, 10, 15))` still has Asr.
- [ ] T060 Write `integration_test/prayer_journey_test.dart` (constitution VI, R16):
  - pump `App` with `designScenarioOverrides()` on `designScenarioStore()`
  - Mark Asr ("3 of 5"), tap "Prayed" and Undo
  - tap Tuesday; Isha's "In qada", then "Add to qada" opens the sheet, then "I prayed it", and
    Tuesday shows 5 dots
  - open the qada list, "Made one up" on Fajr, and Undo
  - run it with `flutter test integration_test/prayer_journey_test.dart --flavor dev -d <device id>`
    on an iOS simulator and an Android emulator
- [ ] T061 [P] Check SC-002 and SC-006 on a mid-range Android phone in profile mode:
  - make a local change, never committed, so `designScenarioStore()` also seeds 5 × 365 log rows
    and moves `firstUse` back a year
  - open the Prayer tab and swipe back 10 weeks. No frame over 16 ms in DevTools
  - tap Mark: the chip's first animated frame comes within 100 ms of the tap in the timeline
    (SC-002)
  - revert the change
- [ ] T062 Run `dart format --set-exit-if-changed lib test tool integration_test`, `flutter analyze` and `flutter test`. Fix every hit, including `test/architecture_test.dart`.
- [ ] T063 Run quickstart.md sections 2 to 4 on a phone. Put the design scenario next to `4.04-prayer.png` and `4.17-prayer-arabic.png` within 1 pt (SC-001). Take screenshots: phone and tablet, dark and light, English and Arabic, text scale 1.0 and 2.0, reduce motion on and off. Check WCAG AA contrast of the "In qada" and "Made up" chips and the three sheets in both modes (SC-007). Stop there for my review.
- [ ] T064 Update the milestone list in `CLAUDE.md`: "4. Prayer: logging, qada, method sheet. **Done, waiting for my review.**"

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: after milestone 3 is merged, no other dependency.
- **Foundational (Phase 2)**: after Setup. Blocks every story.
  - T010 → T011 → T012 → T013
  - T020 → T021 → T024
  - T022 and T023 only need T010 and T011
- **US1 (Phase 3)**: after Foundational. The MVP.
- **US2 (Phase 4)**: after US1, since it adds states to US1's rows.
- **US3 (Phase 5)**: after US2, since it shares `qada_repository.dart`. Its page itself only needs
  Foundational.
- **US4 (Phase 6)**: after US1, independent of US2 and US3.
- **US5 (Phase 7)**: after US1, independent of the others.
- **Polish (Phase 8)**: after the stories wanted.

### Within Each Story

Tests first and failing, then providers, then widgets, then the page wiring.

## Parallel Examples

```text
Foundational tests, all at once:
  T004 civil_date_test   T005 prayer_log_test   T006 prayer_day_test
  T007 prayer_row_state_test   T008 week_test   T009 app_localizations_test

Foundational, independent files:
  T014 toast   T015 sheet   T016 compact bar   T017 strings   T018 plurals   T019 sizes

US1 widgets once T027 to T029 are in:
  T030 progress_ring   T031 day_dots + day_cell   T033 mark_button   T034 day_complete

After US1, US4 and US5 in parallel:
  T051 to T054 (week strip, deep link)   T055 to T056 (method sheet)
```

## Implementation Strategy

### MVP First (User Story 1)

1. Setup and Foundational, with the migration test green.
2. US1, then check the design scenario against 4.04 for the rows, ring and dots.
3. Stop and check: Mark, unmark and Undo, Day complete.

### Incremental Delivery

1. US1: logging.
2. US2: passed prayers. Screenshots of the sheet and chips.
3. US3: the qada list. Screenshots of the list and the + sheet.
4. US4: other days and deep links, which milestones 3 and 5 rely on.
5. US5: the method sheet. Screenshots.
6. Polish: the pin, Home checks, the PNG check, the review stop.
