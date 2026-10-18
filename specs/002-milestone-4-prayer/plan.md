# Implementation Plan: Milestone 4, Prayer

**Branch**: `feature/milestone-4`, cut from `feature/milestone-2` once milestone 2 is committed |
**Date**: 2026-10-17 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/002-milestone-4-prayer/spec.md`

## Summary

The Prayer tab (4.04, 4.17) on top of milestone 2's times:
- **Core**: the prayer log, the prayer day (Fajr to Fajr) and the window ends. Home, the adhan and
  the widgets use them too (R1).
- **Prayer feature, clean**: qada, the row states, the week strip, the qada list and the method
  sheet.
- **Store**: schema v2 adds `prayer_log`, `qada_entries` and `settings.first_use`, with a step by
  step migration (R6).
- **Core widgets**: the toast, the bottom sheet and the compact bar come from the components file
  (R8). Arabic counts get real plural forms through intl's `MessageFormat` (R7).
- **Checking it**: the design scenario opens a seeded in-memory store, so the screen matches the
  PNGs before and after Mark on Asr (R12).
- **Shared with milestone 3**: the pin opens the same location sheet as Home's pill, kept in
  `core/` (R14).

No new pub.dev package (`integration_test` comes with the Flutter SDK), no network.

## Technical Context

**Language/Version**: Dart 3.13, Flutter 3.47.5 stable

**Primary Dependencies**: what is already in. flutter_riverpod 3.4.3, drift 2.35.2 +
drift_flutter 0.3.1 (encrypted, milestone 2), go_router 18.1, intl 0.20.3 (`MessageFormat` for
plurals), flutter_screenutil, flutter_svg. Dev: drift_dev, build_runner, and `integration_test`
from the Flutter SDK (approved 2026-10-18).

**Storage**: the milestone 2 encrypted store, schema v2. The design scenario uses an in-memory
store.

**Testing**: flutter_test unit tests (row states, windows, week math, qada order, plurals), drift
migration tests v1 → v2, widget tests for the Prayer tab and the qada list, the architecture test, and one integration test
of the main journey on the design scenario (R16).

**Target Platform**: iOS 15+, Android 8.0+ (minSdk 26)

**Project Type**: mobile app

**Performance Goals**:
- feedback on Mark or unmark within 100 ms (SC-002)
- a year of logs opens and pages with no visible delay (SC-006): one range query per visible
  week, grouped counts for qada

**Constraints**:
- offline only
- the log is keyed by date, never by clock time
- nothing personal in crash reports
- 1 pt match with the PNGs
- text scale 2.0, reduce motion, RTL

**Scale/Scope**: 2 new tables, 1 new column, 1 tab screen, 1 pushed page, 3 sheets, 3 core
widgets, 21 strings in 2 languages

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Result |
| --- | --- | --- |
| I. Structure | log, prayer day and windows in `core/` (Home, notifications and widgets need them). Qada, row states, week and screens in `features/prayer/{data,domain,presentation}`. Tables in `core/database/`, since drift registers them on the one database. The router imports the feature, as allowed. The location sheet Home and Prayer share is in core (R14). No feature imports another | pass |
| II. Design system | weight text widgets, adaptive paddings, `RSizedBox`, `ThemeEnum`, `BmIcon`. Each new size (ring 56 and stroke 4, rows 62 and 44, chips 26 and 32, week cell 68, dot 4) gets a named manager entry. The 21 strings go into `StringsManager` and both arb files. Toast, sheet and compact bar are components from `03 Components.dc.html`, so they sit in `core/widgets/` next to the adaptive ones (R8) | pass |
| III. Faithful | 4.04 and 4.17 built from their specs, Motion 07 and 08 from MOTION.md. The undesigned parts (qada list, passed sheet, method sheet, + count sheet, "In qada" and "Made up" chips) use only existing components and wait for my OK on screenshots (FR-022) | pass |
| IV. Simplicity | no repository interface, no use case classes, the drift data classes are the entities. The domain layer is pure functions. One converter for dates. No new package | pass |
| V. Performance | derived providers that notify only on change (like `periodProvider`), `.select()`, one query per visible week, autoDispose families, const leaves | pass |
| VI. Tests | unit tests at every window boundary (SC-004), qada order, plurals, migration v1 → v2, widget tests for every flow, one integration test of the main journey, architecture test unchanged and green | pass |
| VII. Privacy | log and qada in the encrypted store, the scenario's fake data only in memory, nothing in crash reports | pass |
| VIII. Offline and free | no network | pass |
| Stack | drift only, Riverpod, GoRouter. `intl` was already a direct dependency, `integration_test` is part of the Flutter SDK (approved 2026-10-18) | pass |

**Post-design re-check**: unchanged after Phase 1. No open items.

## Project Structure

### Documentation (this feature)

```text
specs/002-milestone-4-prayer/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── prayer-log.md
├── checklists/requirements.md
└── tasks.md            # /speckit-tasks
```

### Source Code (repository root)

```text
lib/
├── bootstrap.dart                              # scenario opens designScenarioStore()
├── core/
│   ├── app/app_localizations.dart              # keeps the language, ICU plurals (R7)
│   ├── database/
│   │   ├── app_database.dart                   # PrayerLog, QadaEntries, firstUse, v2 migration,
│   │   │                                       # markPrayed, unmarkPrayed, watchSettings(now:)
│   │   ├── civil_date.dart                     # TypeConverter<DateTime, String> yyyy-MM-dd
│   │   └── app_database.steps.dart             # generated by make-migrations, committed
│   ├── prayer_log/prayer_log.dart              # weekLogProvider, prayedProvider
│   ├── prayer_times/
│   │   ├── day_times.dart                      # + endOf(prayer, tomorrow)
│   │   └── prayer_times_providers.dart         # + prayerDayProvider
│   ├── settings/settings.dart                  # settingsProvider passes the clock
│   ├── flavor/design_scenario.dart             # seeded in-memory store, dayTimes per date
│   ├── resources/
│   │   ├── strings_manager.dart                # + 21 keys
│   │   └── dimensions_manager.dart             # + named sizes for the prayer screen
│   ├── router/app_router.dart                  # day/prayer params, /prayer/qada, Routes.prayerAt
│   └── widgets/
│       ├── toast/toast.dart                    # showToast with Undo (R8)
│       ├── sheet/bm_sheet.dart                 # showBmSheet, grabber, scrim
│       ├── sheet/picker_row.dart               # the selected picker row
│       ├── compact_app_bar.dart                # 56 pt bar, back chevron, large title collapse
│       └── (location sheet)                    # from milestone 3, in core (R14)
└── features/prayer/
    ├── domain/
    │   ├── prayer_row_state.dart               # PrayerRowState, rowState(), isOpen (R4)
    │   └── week.dart                           # weekStart, pages from first use, month range
    ├── data/
    │   └── qada_repository.dart                # add, remove, addOlder, makeUpOldest, undo, counts
    └── presentation/
        ├── providers/
        │   ├── selected_day.dart               # selectedDayProvider, null = prayer day (R10)
        │   ├── row_state.dart                  # rowStateProvider, rowState() per day and prayer
        │   └── prayer_actions.dart             # mark/unmark/qada with undo, returns day complete
        └── view/
            ├── prayer_page.dart                # large title, strip, card, rows
            ├── qada_page.dart                  # the qada list
            └── widgets/
                ├── week_strip.dart  day_cell.dart  day_dots.dart
                ├── summary_card.dart  progress_ring.dart
                ├── prayer_row.dart  row_trailing.dart  mark_button.dart
                ├── passed_sheet.dart  method_sheet.dart  add_older_sheet.dart
                ├── day_complete.dart           # Motion 08
                └── qada_row.dart

assets/l10n/app_en.arb, app_ar.arb              # + 21 strings, Arabic plural forms
drift_schemas/app_database/drift_schema_v2.json

test/
├── core/prayer_times/  core/database/  core/app/  core/flavor/
├── features/prayer/domain/  features/prayer/data/  features/prayer/presentation/
└── drift/app_database/                         # generated v2 schema, migration_test.dart

integration_test/prayer_journey_test.dart       # the main journey on the design scenario (R16)
```

**Structure Decision**: one Flutter app. The prayer feature fills its clean layers next to the
existing `presentation/view/prayer_page.dart`. The shared log goes to a new
`core/prayer_log/`, next to milestone 2's `core/prayer_times/`.

## Key Flows

1. **Open the tab**:
   - `selectedDayProvider` is null, so the shown day is `prayerDayProvider`.
   - Rows read `dayTimesProvider(day)`, `dayTimesProvider(day + 1)` for Isha's end,
     `weekLogProvider(weekStart)`, the day's dated qada entries and `nextPrayerProvider`.
   - Each row's state comes from `rowState()` through a provider that notifies only on change.
2. **Mark**:
   - `prayer_actions.mark(day, prayer)` → `markPrayed`.
   - The drift stream updates the strip, the card and the row.
   - It returns true on the day's fifth, and the view plays Motion 08.
3. **Unmark and Undo**: `unmark` → `unmarkPrayed`, then `showToast(prayerUnmarked, onUndo: mark)`.
   The toast lives on the shell's Scaffold, so it survives a tab switch.
4. **Passed prayer**: `addToQada` opens `passed_sheet`. "I prayed it" → mark, with no toast.
   "Add to qada" → the repository adds `(day, prayer)` and shows a toast with Undo.
5. **Qada list**: the summary card → `Routes.qada`. "Made one up" → `makeUpOldest(prayer)` returns
   the id, and Undo clears its `madeUpAt`. + → `add_older_sheet` → `addOlder(prayer, count)`
   returns the new ids, and Undo deletes them (R15).
6. **Other days**:
   - A day cell sets `selectedDayProvider`. The filled cell follows the shown day.
   - The strip pages back to the week of first use.
   - A deep link `/prayer?day=&prayer=` sets the day and scrolls to the row.
7. **Method sheet**: the sliders icon → `showBmSheet(method_sheet)`. A pick goes to
   `updateSettings`, and `Value(null)` means "By country". `dayTimesProvider` recomputes, and so
   does everything that reads it.
8. **Fajr passes with the tab open**: `prayerDayProvider` changes, and the screen follows unless
   another day was picked. A toast still showing keeps its own day and prayer for Undo.
9. **Pin**: opens milestone 3's location sheet from core. A pick changes `locationProvider`, and
   the times follow.

## Decisions (2026-10-17)

Both clarify sessions took every recommendation: Q1 to Q8, the pin change, then the fill, the +
sheet, the "Made up" label and no toast on "I prayed it". The plan adds no new decision for me.
Three things come from reading the code and the other specs:
1. **Milestone 5 depends on this contract**: Mark prayed from a notification has to work without
   the app open, so the log writes are plain `AppDatabase` methods (contracts/prayer-log.md).
2. **The scenario's store moves into memory**, so its fake week never lands in the dev phone's
   real log (R12).
3. **Milestone 3 builds first**: its location sheet, and any sheet, toast or compact bar it
   already put in core, are reused, never built twice (R8, R14).
4. **`integration_test`** from the Flutter SDK is approved as a dev dependency (2026-10-18), for
   one journey test (constitution VI, R16).

## Complexity Tracking

| Addition | Why Needed | Simpler Alternative Rejected Because |
| --- | --- | --- |
| step by step migration v1 → v2 | milestone 2 FR-022: the dev phone's store survives the layout change | a reset on upgrade loses data, which FR-022 rules out |
| ICU plurals in `AppLocalizations` (about 15 lines) | FR-029: Arabic counts are wrong for 1, 2 and 11+ today | a key per form gives the two arb files different keys, which `strings_manager_test` rejects |
| in-memory store for the design scenario | the PNG week has to be seeded without touching the real log | seeding the dev store mixes fake prayers into the developer's own data |
