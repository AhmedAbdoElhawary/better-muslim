---

description: "Tasks for milestone 8, azkar, tasbih and duas"
---

# Tasks: Milestone 8, Azkar, Tasbih and Duas

**Input**: Design documents from `specs/003-milestone-8-azkar/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/content-files.md,
contracts/nudges.md, quickstart.md

**Tests**: Included. Constitution VI asks for unit tests on logic and widget tests on screens,
SC-002 asks for 20 taps in 2 s, SC-004 for the window boundaries, SC-008 for the iOS budget.

**Organization**: Grouped by user story, so each story can be built and checked on its own.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an unfinished task)
- **[Story]**: The user story the task belongs to (US1 to US6)

## Before starting

- Built after milestone 6 is merged, on `feature/milestone-8` (plan header). Milestone 7 comes
  after 11.
- Read `design_handoff_better_muslim/specs/HOW_TO_READ.md`, then the 4.08 and 4.14 trees, MOTION.md
  rows 11 and 12 with `d_tasbih`, the haptics table, and in `03 Components.dc.html` the azkar card
  ("Dua card · source + grading always shown"), the counter, the toast, the empty state, the
  toggle, the nav badge.
- Every UI file follows the `adaptive-widgets` rules, and `flutter test test/architecture_test.dart`
  stays green.
- Parallel sessions share `.specify/feature.json`, so speckit commands get this folder passed
  explicitly (`SPECIFY_FEATURE_DIRECTORY=specs/003-milestone-8-azkar`).

---

## Phase 1: Setup

**Purpose**: The constitution amendment, the branch, the package, the folders.

- [X] T001 Amend `.specify/memory/constitution.md` for research R12 (approved in Q7): in Stack And Constraints add share_plus to the domain package list with "(the share sheet for the dua card)", bump the version MINOR (3.4.0, or the next MINOR if another milestone took it) and the Last Amended date.
- [X] T002 Ask before cutting `feature/milestone-8` from where milestone 6 ends. Then confirm `flutter pub get`, `flutter analyze` and `flutter test` are green before any change.
- [X] T003 Run `flutter pub add share_plus:^13.3.1`, and add `assets/azkar/` and `assets/duas/` to the `flutter: assets:` list in `pubspec.yaml` next to the existing folders.
- [X] T004 Create the folders `lib/core/azkar/`, `lib/features/azkar/{model,view_model,view/widgets}/`, `lib/features/duas/{model,view_model,view/widgets}/`, `assets/azkar/`, `assets/duas/`, `test/core/azkar/`, `test/features/azkar/{model,view}/`, `test/features/duas/{model,view_model,view}/`.

---

## Phase 2: Foundational

**Purpose**: What every story stands on: plurals, the windows, the azkar content, schema 4, the
progress providers, the strings and sizes, the pieces moved to core, the routes, the scenario.

**⚠️ CRITICAL**: No story work starts before this phase is done

### Tests for the foundation

- [X] T005 [P] Add to `test/core/app/app_localizations_test.dart`: a message with two plural placeholders formats both, in English (1 and 24) and Arabic (1, 2, 3 to 10, 11 or more, the counts given in Eastern digits). A message with one plural still works as before.
- [X] T006 [P] Write `test/core/azkar/azkar_window_test.dart` with Makkah `DayTimes` and explicit times:
  - `currentAzkarSet`: Fajr, Duha and Dhuhr periods → morning, Asr, Maghrib, Isha and null → evening
  - `azkarWindowDay` (R4): one minute before and after Fajr and Asr, at 00:30 (evening of the day before), at 10:00 (morning today, evening yesterday), at 16:32 (both today)
  - a daylight saving day (London, last Sunday of October) and a zone change keep the window on its prayer day (SC-004)
- [X] T007 [P] Write `test/core/azkar/azkar_content_test.dart`: `loadAzkarContent()` on the shipped `assets/azkar/azkar.json` follows contracts/content-files.md (both sets, `minutes` ≥ 1, ids unique across the file, `count` ≥ 1, `source.en` and `source.ar` present), morning has 12 items, evening 24, every item has a `note` with `TODO(ahmed)`.

### Implementation for the foundation

- [X] T008 [P] In `lib/core/app/app_localizations.dart` make `tr` format every `{name, plural,` in the message: collect each placeholder's count (Eastern digits turned Western as now) and pass them all to `MessageFormat.format` (R14). Make T005 pass.
- [X] T009 [P] Write `lib/core/azkar/azkar_window.dart`: `enum AzkarSet { morning, evening }` with its title key (`StringsManager.morningAzkar`, `eveningAzkar`) and subtitle key (`morningAzkarSub`, `eveningAzkarSub`), `currentAzkarSet(Period?)`, `azkarWindowDay(AzkarSet set, DateTime prayerDay, Period? period)` (R4), `nudgePrayerOf(set)` (Fajr, Asr). Remove `isMorningAzkar` from `lib/features/home/model/home_moment.dart`, point `morningAzkarProvider` in `home_providers.dart` at `currentAzkarSet`, move its cases from `test/features/home/model/home_moment_test.dart` to T006. Make T006 pass.
- [X] T010 [P] Write `assets/azkar/azkar.json` by contracts/content-files.md and research R3: morning `minutes` 3 with 12 items, evening `minutes` 6 with 24 items, taking turns between the components' zikr ("سُبْحَانَ اللَّهِ وَبِحَمْدِهِ", "Subhan Allahi wa bihamdihi", "Glory be to Allah and praise be to Him.", Sahih Muslim 2692 / صحيح مسلم ٢٦٩٢, grading Sahih / صحيح, count 100) and the 4.14 dua (spec 4.14 text, Abu Dawud 5095 / أبو داود ٥٠٩٥, no grading, count 1), ids `m01`..`m12` and `e01`..`e24`, every item `"note": "TODO(ahmed): sample, replace with the dataset"`. Write `lib/core/azkar/azkar_content.dart`: `Zikr`, `AzkarSetContent` (minutes, items, `total`), `AzkarContent.setOf(AzkarSet)`, `loadAzkarContent()` with `rootBundle` and no Riverpod. Make T007 pass.
- [X] T011 Move to schema 4 in `lib/core/database/app_database.dart` (data-model.md):
  - `Settings`: `tasbihDhikr` int default 0 with "Check 0 to 2", `tasbihCount` int default 0 with a check `>= 0`, `morningOpenedOn` and `eveningOpenedOn` text `CivilDate` nullable, `azkarNudges` bool default true
  - `AzkarCounts`: `setId` `textEnum<AzkarSet>`, `day` `CivilDate`, `zikr` text, `count` int, primary key `(setId, day, zikr)`
  - `SavedDuas`: `dua` text primary key, `savedAt` datetime
  - `schemaVersion` 4, `from3To4` adding the five columns and creating both tables
  - plain methods, no Riverpod, like `markPrayed`: `azkarCounts(AzkarSet set, DateTime day)` → `Map<String, int>`, `setZikrCount(set, day, zikr, count)` (upsert, and on the first row of a new day delete that set's rows of older days)
  - run `dart run build_runner build` and `dart run drift_dev make-migrations`, commit `drift_schemas/app_database/drift_schema_v4.json`, the generated `test/drift/app_database/generated/schema_v4.dart` and the steps file
- [X] T012 Add the v3 → v4 case to `test/drift/app_database/migration_test.dart`: every v3 row kept, the new columns at their defaults, both tables empty. Existing database tests stay green.
- [X] T013 Write `lib/core/azkar/azkar_progress.dart` and `test/core/azkar/azkar_progress_test.dart` with a `ProviderContainer` and an in-memory store:
  - `azkarContentProvider` (FutureProvider, `loadAzkarContent`)
  - `currentAzkarSetProvider` from `periodProvider`
  - `azkarWindowDayProvider(set)` from `prayerDayProvider` and `periodProvider`
  - `azkarCountsProvider(set)` a stream of the latest window's counts
  - `azkarProgressProvider(set)` → `({int done, int total})`, done = items whose count reached their `count`, an id not in the content ignored
  - `azkarBadgeProvider`: a location, and the current set's window ≠ its `morningOpenedOn` or `eveningOpenedOn`
  - tests: 0 of 24 at 16:32, 1 of 24 after one item reaches its count, the evening's counts at 10:00 are last night's, the badge on before opening and off after writing the opened day, no badge without a location
- [X] T014 [P] Add the keys to `lib/core/resources/strings_manager.dart` and both arb files with spec FR-032's wording, plurals in ICU form like `missedToMakeUp`: `setCardHeader` ({set}, {index}, {total}), `duaCount` (plural: one dua, two, 3 to 10, 11+ in Arabic), `chipSaved`, `saved`, `removedFromSaved`, `noSavedTitle`, `noSavedBody`, `noDuasFound`, `noDuasFoundBody`, `countReset`, `resetCount`, `tasbihA11y` ({dhikr}, {count}, {target}), `notifAzkarMorningBody` ({count} and {minutes}, both plural), `azkarReminders`, `azkarRemindersSub` ({minutes}). Change `notifAzkarBody` to "After Asr · {count} remembrances, about {minutes} minutes" with both plurals. `strings_manager_test.dart` passes.
- [X] T015 [P] Add the named values, only those missing, with the trees' numbers, to `lib/core/resources/dimensions_manager.dart`: `SizeManager.tasbihRing` 240, `tasbihRingStroke` 5, `tasbihGlow` 340, `bead` 28, `beadFocus` 36, `beadFocusStroke` 1.5, `chip` 36, `navBadge` 7, `navBadgeRing` 2, `zikrBar` 90 x 3, `shareCard` 360. `SpaceManager.beadGap` 16, `tasbihChipsTop` 12 (the chips at 122, the bar ends at 110), `tasbihDhikrTop` 28 (the dhikr at 186, the chips end at 158), `tasbihStripTop` 280 and `tasbihHintTop` 340 (inside the 390 tap area), `dhikrChipSide` 10, `duaChipSide` 14, `chipGap` 6 and 8, `navBadgeTop` 4 and `navBadgeEnd` 14. In `lib/core/resources/font_manager.dart`: `FontSizeManager.tasbihCount` 80, `dhikrAr` 40, `dhikrName` 16, `dhikrMeaning` 13.5, `dhikrChip` 12.5, `duaChip` 13.5, `zikrAr` 26, `LineHeightManager.dhikrAr` 1.7, `zikrAr` 1.9. `font_manager_test.dart` stays green.
- [X] T016 [P] Move `lib/features/home/view/widgets/home_card.dart` to `lib/core/widgets/surface_card.dart` as `SurfaceCard` and `lib/features/home/view/widgets/shortcut_row.dart` to `lib/core/widgets/shortcut_row.dart` (R15). Update Home's imports, no other change. Home's tests stay green.
- [X] T017 [P] Move `_RingPainter` out of `lib/features/prayer/presentation/view/widgets/progress_ring.dart` into `lib/core/widgets/ring_painter.dart` as `RingPainter` (share, track, arc, stroke, the arc from 12 o'clock), and use it from `ProgressRing`. Prayer's tests stay green.
- [X] T018 [P] Move the text block of `lib/features/notifications/presentation/view/widgets/dua_sheet.dart` into `lib/core/widgets/dua_text.dart` as `DuaText` (R15): a header row (title on the start in `text2`, source on the end in `accent`, both `label` size, the title a key or content with `translate`), the Arabic (`FontEnum.dua`, or `FontEnum.quran` when `quran: true`, RTL, start aligned), then in English only the transliteration (italic, `text2`) and the translation, `SpaceManager.duaGap` between. `DuaSheet` uses it. `dua_sheet_test.dart` stays green.
- [X] T019 [P] Write `lib/core/widgets/toggle_row.dart`: the components' toggle row, a title and an optional subtitle on the start, the switch on the end in `primary` when on, the whole row the hit target (at least 44), `BmHaptics.selection()` on change, `Semantics(toggled:)`. Add a small widget test in `test/core/widgets/toggle_row_test.dart`.
- [X] T020 Add to `lib/core/router/app_router.dart` (R9, R10): `Routes.tasbih` `/azkar/tasbih` and `Routes.azkarSet(AzkarSet set)` `/azkar/morning` and `/azkar/evening` as sub routes of the Azkar branch, `Routes.duas` `/duas` and `Routes.duaCategory(String id)` `/duas/<id>` as top level routes next to Qibla (no tab bar). Create bare `TasbihPage`, `AzkarSetPage(set)`, `DuasPage` and `DuaCategoryPage(id)` in their feature folders so the router compiles. A bad set or category falls back to the Azkar tab or Duas.
- [X] T021 [P] In `designScenarioStore()` of `lib/core/flavor/design_scenario.dart` write `tasbihCount: Value(16)` with the other settings (R16). Add the case to `test/core/flavor/design_scenario_test.dart`.
- [X] T022 [P] Write `test/helpers/azkar.dart`: `pumpAzkar(tester, overrides, {location, locale, brightness, textScale, reduceMotion})` on top of `pumpHome` like `pumpPrayer`, and a fake content override for `azkarContentProvider` with short sets (3 items, counts 1 and 3) for the tests that tap through a set.

**Checkpoint**: T005 to T007, T012 and T013 green, the app runs with every existing screen as before,
the new routes open empty pages.

---

## Phase 3: User Story 1 - Count my tasbih after prayer (Priority: P1) 🎯 MVP

**Goal**: 4.08 from its tree with Motion 11, Motion 12, the haptics, and the count kept.

**Independent Test**: in the design scenario Azkar › Tasbih shows SubhanAllah 16 of 33. 17 taps:
"Set complete", the ring full and glowing. One more: Alhamdulillah 1. A new app start keeps it.

### Tests for User Story 1

- [X] T023 [P] [US1] Write `test/features/azkar/model/tasbih_state_test.dart` on data-model.md's Tasbih machine: tap below the target, at the target (done), after done (next dhikr at 1), after Allahu Akbar (SubhanAllah at 1), chip (from 0), reset, 20 taps from 0 give 20, never past the target.
- [X] T024 [P] [US1] Write `test/features/azkar/view/tasbih_page_test.dart` with `pumpAzkar(location: Routes.tasbih)` and the design scenario's overrides:
  - the 4.08 copy: "Tasbih", "After prayer", the three chips with 33, 33, 34, the Arabic, "SubhanAllah", "Glory be to Allah", "16", "of 33", "Tap anywhere to count", the tab bar with Azkar selected
  - 17 taps in the lower area: "Set complete", the bead haptic on each, the set complete haptic once, the announcement once. One more: Alhamdulillah, "1", "of 33"
  - taps on the chips, the dhikr text and the bar never count. A chip: that dhikr at 0 with the selection haptic
  - reset: 0 on SubhanAllah and the "Count reset" toast. Undo: the dhikr and count from before
  - 20 taps pumped 100 ms apart: exactly 20 more, the beads settled 400 ms after the last (SC-002)
  - a second `ProviderScope` on the same store shows the same dhikr and count (FR-016)
  - reduce motion: no burst, the ring at full

### Implementation for User Story 1

- [X] T025 [P] [US1] Write `lib/features/azkar/model/tasbih_dhikr.dart`: the three dhikr as consts from the 4.08 tree (Arabic with marks, plain Arabic name for the Arabic chip, the English name, the meaning, the target 33, 33, 34), content so `translate: false`.
- [X] T026 [P] [US1] Write `lib/features/azkar/model/tasbih_state.dart`: an immutable `TasbihState(dhikr, count)` with `done`, `tap()`, `select(i)`, `reset()`. Make T023 pass.
- [X] T027 [US1] Write `lib/features/azkar/view_model/tasbih_controller.dart`: a `Notifier<TasbihState?>` that reads `tasbihDhikr` and `tasbihCount` once from the store, then changes the state on each call at once and writes both columns with `updateSettings` without awaiting (R6).
- [X] T028 [P] [US1] Write `lib/features/azkar/view/widgets/dhikr_chips.dart`: the three 36 pt chips centered with a 6 gap (a sideways scroll when they don't fit), `outline` ring, the selected one `primaryContainer` with a `primary` 40% ring, name + target in `text2` with tabular figures, the Arabic names in the Arabic app, each at least 44 tall as a hit.
- [X] T029 [P] [US1] Write `lib/features/azkar/view/widgets/dhikr_text.dart`: the Arabic in `FontEnum.dua` 40 with line height 1.7, then in English only the name (`MediumText` 16) and the meaning (`RegularText` 13.5 `text2`, 2 above), centered.
- [X] T030 [P] [US1] Write `lib/features/azkar/view/widgets/bead_strip.dart`: the line (1 pt `outline2`), 11 beads 28 pt with the radial gradient from `primary` 45% over `raised` at 35% 30% and a 1 pt `outline2` ring, 16 apart, the 36 pt `primary` focus ring in the middle. An unbounded controller: each tap moves the target by −44 (`BmMotion.beadStep`) with `SpringSimulation(BmMotion.snappy, value, target, velocity)`, retargeting from the current value and velocity. Settled, the offset wraps by 44. Reduce motion: no movement. In `Directionality(ltr)` inside a `RepaintBoundary`.
- [X] T031 [P] [US1] Write `lib/features/azkar/view/widgets/tasbih_counter.dart`: the 240 ring with `RingPainter` (`variant` track, `primary` arc, stroke 5, 300 ms standard tween), the count in `FontEnum.display` 80 with tabular figures (scale 1.06 → 1 in 150 ms on each change, not with reduce motion), "of {target}" or "Set complete" in `primary` 500. Done: the 340 radial glow (`glow` 35% to clear at 62%) behind and Motion 12's 8 particle burst (`CustomPainter`, 700 ms decelerate), no burst with reduce motion. The ring and digits in `Directionality(ltr)`, the count's size capped so it stays inside the ring at text scale 2.0.
- [X] T032 [US1] Assemble `lib/features/azkar/view/tasbih_page.dart` (depends on T025 to T031): the 4.08 bar (back, "Tasbih" / "After prayer", reset 44 x 44 with `BmIcon.ui(BmUiIcon.reset)` and the `resetCount` label), the chips, the dhikr block, then the lower area as one `GestureDetector` (opaque) with `Semantics(button, label: tasbihA11y)` holding the counter, the strip and "Tap anywhere to count", gaps from T015 at text scale 1.0 and a column that keeps the lower area the target above it (R7). Each tap: `TasbihController.tap()`, `BmHaptics.bead()`, the strip. Reaching the target: `BmHaptics.setComplete()`, `SemanticsService.announce` "Set complete". Reset: the state before kept for `showToast(context, StringsManager.countReset, icon: BmIconName.tasbih, onUndo: ...)`. Make T024 pass.

**Checkpoint**: Tasbih works on its own from Azkar › Tasbih (the route, the tab page's row comes in
US2).

---

## Phase 4: User Story 2 - Read my evening azkar (Priority: P1)

**Goal**: the Azkar tab, the set page, Home's row with real progress, the badge.

**Independent Test**: in the design scenario the Azkar tab shows Evening azkar 0 of 24 and the
badge. Home's row opens the evening set at card 1 of 24. Counting card 1 to its number and one more
tap goes to card 2, Home shows 1 of 24.

### Tests for User Story 2

- [X] T033 [P] [US2] Write `test/features/azkar/model/set_state_test.dart` on data-model.md's set machine: open at the first card not done (or the last when all are done), tap below the count, at the count, after done (move on), on the last done card (nothing), every card done once.
- [X] T034 [P] [US2] Write `test/features/azkar/view/azkar_page_test.dart`: the large title "Azkar", the three rows with "After Fajr · 0 of 12", "After Asr · 0 of 24", "After prayer", each row opens its route. The badge dot on the Azkar tab in the design scenario, gone after opening the evening set, back when the window changes (move the clock past the next Fajr).
- [X] T035 [P] [US2] Write `test/features/azkar/view/azkar_set_page_test.dart` with the short fake sets from T022: opens at the first card not done, the header "Evening azkar · 1 of 3", the count "0 / 3", a tap counts with the bead haptic, at the count the done look and the set complete haptic, the next tap moves to card 2, a swipe moves without counting, the last card done shows "Set complete" with one haptic. Leaving and opening again continues at the same card. A Quran item uses `FontEnum.quran` and doesn't scale on a tap.
- [X] T036 [P] [US2] Update `test/features/home/view/home_page_test.dart`: the azkar row shows the real progress (0 of 24 in the design scenario, 1 of 24 after a count is written), opens `/azkar/evening`, and still isn't there in Arabic.

### Implementation for User Story 2

- [X] T037 [P] [US2] Write `lib/features/azkar/model/set_state.dart`: `SetState(index, counts)` with `openAt(items, counts)`, `tap(items)` returning the new state and what happened (counted, done, moved, setDone). Make T033 pass.
- [X] T038 [US2] Write `lib/features/azkar/view_model/set_controller.dart`: a `Notifier` per `AzkarSet` that loads the latest window's counts once (`azkarCounts`), opens with `SetState.openAt`, writes `morningOpenedOn` or `eveningOpenedOn` for the window, changes the state at once on a tap and writes `setZikrCount` without awaiting (R6).
- [X] T039 [P] [US2] Write `lib/features/azkar/view/widgets/zikr_card.dart`: the components' azkar card on `raised`, radius 20, a 1 pt `outline` ring, padding 18 x 20: the header "{set} · {index} of {total}" (`setCardHeader`) and "{n} / {count}" in `primary` 500 tabular, then `DuaText` without its header (the Arabic 26 with line height 1.9 centered, the transliteration and translation centered), then the footer above a 1 pt `outline` line: "{source} · {grading}" in `text2` and the 90 x 3 bar (`variant` track, `primary` fill, 300 ms). Done: the bar full, a check (`BmUiIcon.check`) before the count. Arabic: the Arabic and the source only. Its `Semantics` reads the text and "{n} of {count}".
- [X] T040 [US2] Assemble `lib/features/azkar/view/azkar_set_page.dart`: `CompactAppBar` with the set's title key, a `PageView` of `ZikrCard`s opening at the controller's index, each card a `GestureDetector` that calls the controller: counted → `BmHaptics.bead()`, done → `BmHaptics.setComplete()`, moved → `animateToPage` 300 ms standard (a crossfade under reduce motion), setDone → the header reads "Set complete" and one haptic. "Tap anywhere to count" under the card. Make T035 pass.
- [X] T041 [US2] Write `lib/features/azkar/view/azkar_page.dart` (replaces the placeholder): `LargeTitleScrollView` with the "Azkar" large title like More, a `SurfaceCard` with three `ShortcutRow`s: Morning (`BmIconName.sunrise`, `morningAzkarSub` with `azkarProgressProvider(morning)` through `formatDigits`), Evening (`BmIconName.night`, `eveningAzkarSub`), Tasbih (`BmIconName.tasbih`, `afterPrayer`), each pushing its route. Make T034's rows pass.
- [X] T042 [US2] In `lib/features/home/view/widgets/shortcuts_card.dart` make `_AzkarRow` watch `currentAzkarSetProvider` and `azkarProgressProvider(set)` (`.select` on done and total) and go to `Routes.azkarSet(set)`. Remove the azkar values and their `TODO` from `lib/features/home/model/home_samples.dart`. Make T036 pass.
- [X] T043 [US2] The badge: `lib/core/widgets/shell/app_shell.dart` becomes a `ConsumerWidget` watching `azkarBadgeProvider` and passes `badge: 3` (the Azkar index) or null to `NavBar`. In `lib/core/widgets/shell/nav_bar.dart` `_NavItem` draws the components' dot (7 pt `accent`, a 2 pt `surface` ring, 4 from the top and 14 from the end of the pill) when it has the badge, and its semantics value says so. Make T034's badge cases pass.

**Checkpoint**: the Azkar tab, both sets and Home's row work. Tasbih is reached from the tab.

---

## Phase 5: User Story 3 - Find the dua for this moment (Priority: P2)

**Goal**: 4.14 from its tree, the chips, search, the category page, the More entry.

**Independent Test**: in the design scenario More › Duas matches 4.14. "tawakkaltu" and "توكلت"
find Leaving the home, "zzz" shows "No duas found", "Before sleeping" opens a page with 3 duas.

### Tests for User Story 3

- [X] T044 [P] [US3] Write `test/features/duas/model/dua_content_test.dart`: the shipped `assets/duas/duas.json` follows contracts/content-files.md (unique ids, chips from the list, names in both languages, `audio` null or under `assets/duas/audio/`), the five sample categories with 1, 1, 3, 2, 2 duas, every dua with a `TODO(ahmed)` note.
- [X] T045 [P] [US3] Write `test/features/duas/model/dua_search_test.dart`: `normalize` folds case, diacritics, tatweel, أ إ آ ٱ, ة, ى, Eastern digits and the transliteration marks. Matches by Arabic without marks ("توكلت"), transliteration ("tawakkaltu"), translation ("trust"), source ("5095", "٥٠٩٥"), category name ("sleeping"), two words in any order. No match for "zzz".
- [X] T046 [P] [US3] Write `test/features/duas/model/duas_view_test.dart` on FR-019: All → card Leaving the home, rows Waking up, Before sleeping, Entering and leaving the mosque, Before and after eating. Home → card Leaving the home, rows mosque and eating. A first category with 2 duas keeps its row. Travel → nothing.
- [X] T047 [P] [US3] Write `test/features/duas/view/duas_page_test.dart`: the 4.14 copy and order (bar "Duas", the search hint, chips All to Sleep then Saved off screen, the card's "Leaving the home" and "Abu Dawud 5095", the Arabic, transliteration and translation, Listen, Save, Share, the four rows with "1 dua", "3 duas", "2 duas", "2 duas"), no tab bar. A chip filters. Typing shows result cards, clearing returns to the chip. "zzz" shows the empty state. Travel shows "No duas found". A row opens its page with its cards. Arabic: the card shows the Arabic and "أبو داود ٥٠٩٥" only, Arabic plural forms in the rows.

### Implementation for User Story 3

- [X] T048 [P] [US3] Write `assets/duas/duas.json` by contracts/content-files.md and research R3: Leaving the home (`home`, the 4.14 dua), Waking up (`morningEvening`, 1), Before sleeping (`sleep`, 3), Entering and leaving the mosque (`home`, 2), Before and after eating (`home`, 2), in that order, the Arabic names from R3, each dua the 4.14 dua or milestone 5's dua after the adhan (text and source from `dua_after_adhan.dart`), ids `d001`.., `audio` null, every dua `"note": "TODO(ahmed): sample, replace with the dataset"`.
- [X] T049 [P] [US3] Write `lib/features/duas/model/dua.dart`: `Dua`, `DuaCategory`, `enum DuaChip { all, morningEvening, home, travel, sleep, saved }` with its label key (`catAll`, `catMorningEvening`, `catHome`, `catTravel`, `catSleep`, `chipSaved`), and `loadDuas()` reading the file with `rootBundle`, with `// TODO(ahmed): dua clips go in assets/duas/audio/ and their paths in duas.json.` above it. Make T044 pass.
- [X] T050 [P] [US3] Write `lib/features/duas/model/dua_search.dart` (`normalize`, `searchDuas(query, categories)`) and `lib/features/duas/model/duas_view.dart` (`duasViewFor(chip, categories)` → card dua and its category, rows). Make T045 and T046 pass.
- [X] T051 [US3] Write `lib/features/duas/view_model/duas_providers.dart`: `duasContentProvider` (FutureProvider), `duaChipProvider` (the selected chip, All), `duaQueryProvider`, `duasViewProvider` and `duaResultsProvider` from the pure functions.
- [X] T052 [P] [US3] Write `lib/features/duas/view/widgets/dua_chips.dart`: the 4.14 chips, 36 pt, padding 14, gap 8, a sideways scroll from the start edge, selected `primary` with `on` text 500, others an `outline2` ring with `text`, every hit at least 44 tall, the selection haptic.
- [X] T053 [P] [US3] Write `lib/features/duas/view/widgets/dua_card.dart` and `dua_actions.dart`: `SurfaceCard`, padding 16 18 6, `DuaText` with the category name and the source (· grading when present), then the actions row above a 1 pt `outline` line: Listen (`BmIconName.listen`), Save (`BmIconName.bookmark`), Share (`BmUiIcon.share`), each 48 tall with an 18 icon and `caption` text in `text2`, callbacks given by the page.
- [X] T054 [P] [US3] Write `lib/features/duas/view/widgets/category_rows.dart`: a `SurfaceCard` with 56 pt rows, the name 15 on the start, `duaCount` in `text2` with `formatDigits`, the forward chevron (flipped in Arabic) in `text3`, an `outline` line between rows, each row a 44+ hit that pushes `Routes.duaCategory(id)`.
- [X] T055 [US3] Assemble `lib/features/duas/view/duas_page.dart`: `CompactAppBar(StringsManager.duas)` (no tab bar, the route is outside the shell), `SearchField(hint: StringsManager.searchDuas)`, the chips, then the card and rows from `duasViewProvider`, or the result cards while the query has text, or the components' empty state (the octagon from `03 Components.dc.html` with `noDuasFound` and `noDuasFoundBody`, only the title for an empty chip). The gaps from the 4.14 tree, a scroll view so text scale 2.0 never cuts.
- [X] T056 [US3] Write `lib/features/duas/view/dua_category_page.dart`: `CompactAppBar` with the category's name (content, `translate: false`) and its duas as `DuaCard`s with the same callbacks. Make T047 pass.
- [X] T057 [P] [US3] In `lib/features/more/view/more_page.dart` add `BmButton.secondary(StringsManager.duas)` under the Qibla one that calls `context.push(Routes.duas)`, with `// TODO: replaced by the 4.09 Duas tile in milestone 9.` above it.

**Checkpoint**: More › Duas works with search and the category pages. Save, Listen and Share don't
act yet.

---

## Phase 6: User Story 4 - Keep the duas I use (Priority: P3)

**Goal**: Save, remove with Undo, the Saved chip and its empty state.

**Independent Test**: Save the 4.14 card: "Saved", filled. The Saved chip lists it. Tap "Saved":
removed, a toast, Undo brings it back. Nothing saved: "No duas saved yet".

### Tests for User Story 4

- [X] T058 [P] [US4] Add to `test/features/duas/view/duas_page_test.dart` (save): Save fills the bookmark and reads "Saved", the Saved chip lists it, newest first with two saved, tapping "Saved" removes it at once with the "Removed from saved" toast, Undo brings it back in the same place. Nothing saved: the empty state with `noSavedTitle` and `noSavedBody`. A save from a category page shows on Duas. A second `ProviderScope` on the same store keeps it.

### Implementation for User Story 4

- [X] T059 [US4] Add to `lib/core/database/app_database.dart` the plain `saveDua(id, {DateTime? at})` and `unsaveDua(id)`, and to `lib/features/duas/view_model/duas_providers.dart` `savedDuasProvider` (a stream of `saved_duas` newest first, ids not in the content skipped) and `isSavedProvider(id)`.
- [X] T060 [US4] Wire Save in `dua_actions.dart`: saved → filled `bookmark` and `saved` in `primary`, `Semantics` with the label. Unsave keeps the row's `savedAt` for Undo: `showToast(context, StringsManager.removedFromSaved, icon: BmIconName.bookmark, onUndo: () => saveDua(id, at: savedAt))`.
- [X] T061 [US4] Add the Saved chip to `duas_page.dart`: the saved duas as `DuaCard`s, or the components' empty state with `noSavedTitle` and `noSavedBody`. Make T058 pass.

**Checkpoint**: saving works everywhere a dua card shows.

---

## Phase 7: User Story 5 - Listen to a dua and share it (Priority: P3)

**Goal**: Listen ready for clips, Share as an image card.

**Independent Test**: Listen on a dua without a clip does nothing. With a fake player and a clip
it plays, "Stop", a second dua stops the first, leaving stops it. Share opens the share sheet with
a PNG.

### Tests for User Story 5

- [X] T062 [P] [US5] Write `test/features/duas/view_model/dua_player_test.dart` with a fake `AudioPlayer` seam: play a clip, stop the same, a second dua stops the first and plays its own, `stop()` when nothing plays is fine, a dua without a clip never reaches the player.
- [X] T063 [P] [US5] Add to `test/features/duas/view/duas_page_test.dart` (listen and share): without a clip Listen changes nothing. With an override giving a clip, Listen reads "Stop", pushing another route over Duas stops it, popping the page stops it. Share with a fake share function gets one PNG file with a width of 360 × 3, in English and Arabic.

### Implementation for User Story 5

- [X] T064 [US5] Write `lib/features/duas/view_model/dua_player.dart`: `duaPlayerProvider` holding one just_audio `AudioPlayer` behind a small seam the tests replace, the playing dua id as state, `toggle(Dua dua)` (no clip → nothing, the playing one → stop, another → stop and play `setAsset`), `stop()`, the player disposed with the provider (R11). Make T062 pass.
- [X] T065 [US5] Wire Listen in `dua_actions.dart` (playing → `BmUiIcon.stop` and `stop`) and stop the player in `duas_page.dart` and `dua_category_page.dart` on dispose and when `ModalRoute.of(context)!.isCurrent` turns false (R11).
- [X] T066 [P] [US5] Write `lib/features/duas/view/widgets/share_card.dart`: 360 pt wide, the app's theme and mode, `bg` with the arch frame (`assets/ornaments/frame_arch.svg` in `primary`), `DuaText` with the category and source, the wordmark (`assets/brand/wordmark_en_qiyam_dark.svg` or `_light`, the Arabic PNG wordmark in Arabic) at the bottom. In Arabic the Arabic and the source only. Grows with the text, nothing cut. No design: I check it in the app (FR-027).
- [X] T067 [US5] Write `lib/features/duas/view/share_dua.dart`: put `ShareCard` in an `OverlayEntry` off screen inside a `RepaintBoundary`, wait for the end of the frame, `toImage(pixelRatio: 3)`, encode PNG, remove the entry, then `SharePlus.instance.share(ShareParams(files: [XFile.fromData(png, mimeType: 'image/png', name: 'dua.png')], sharePositionOrigin: <the Share button's rect>))` through a provider the tests replace. Wire Share in `dua_actions.dart`. Make T063 pass.
- [X] T068 [P] [US5] Add `NSPhotoLibraryAddUsageDescription` to `ios/Runner/Info.plist` and its text to `ios/Runner/en.lproj/InfoPlist.strings` ("Lets you save a dua card you share to your photos.") and `ios/Runner/ar.lproj/InfoPlist.strings` ("لحفظ بطاقة الدعاء التي تشاركها في الصور."), since the share sheet's "Save Image" crashes without it.

**Checkpoint**: Share works on both phones, Listen waits for the clips.

---

## Phase 8: User Story 6 - A quiet nudge for my azkar (Priority: P3)

**Goal**: the morning and evening nudges in milestone 5's schedule, the switch on the Azkar tab.

**Independent Test**: `buildNudges` at 16:32 gives tomorrow's morning, tomorrow's evening and the
day after's morning (today's evening at 15:47 has passed). A done window is skipped. The switch
off gives none.

### Tests for User Story 6

- [X] T069 [P] [US6] Add to `test/features/notifications/domain/schedule_test.dart`: `buildNudges` gives the next 3 windows after now at Fajr and Asr + 20 min, none for a window in the done set, none on a day with no Fajr or Asr time. With `buildSchedule`'s 60 the total is 63 (SC-008). Add to `alert_test.dart`: the azkar ids from 2,000,000, `alertFromId` returns null for them, the payload round trips with kind `azkar`.
- [X] T070 [P] [US6] Add to `test/features/notifications/domain/tap_target_test.dart` (an azkar payload gives `AzkarTarget(AzkarSet.evening)`), `test/features/notifications/data/alert_texts_test.dart` (the title "Evening azkar" and the body "After Asr · 24 remembrances, about 6 minutes" in English, the Arabic plural forms) and `test/features/notifications/data/background_test.dart` (`topUp` with `azkarNudges` on schedules 3 nudges with the `azkar` channel and no sound, a done evening window skips tonight's, off schedules none).
- [X] T071 [P] [US6] Add to `test/features/notifications/presentation/notifications_boot_test.dart`: flipping `azkarNudges` and finishing the current set each reschedule once after the debounce, a tap on an azkar notification goes to `/azkar/evening`, the design scenario never schedules. Add to `azkar_page_test.dart`: the switch shows on, flipping writes `azkarNudges` with the selection haptic.

### Implementation for User Story 6

- [X] T072 [P] [US6] In `lib/features/notifications/domain/alert.dart` add `AlertKind.azkar`, `azkarAlertId(day, set)` = 2,000,000 + days since 2020 × 2 + set index, and use it in `Alert.id` for the azkar kind (contracts/nudges.md).
- [X] T073 [P] [US6] In `lib/features/notifications/domain/schedule.dart` add `nudgeDelay` (20 min), `nudgeCount` (3) and `buildNudges({now, days, done})` with a one line why comment on the budget. Make T069 pass.
- [X] T074 [P] [US6] In `lib/features/notifications/domain/tap_target.dart` add `AzkarTarget(AzkarSet set)` for the azkar kind.
- [X] T075 [US6] In `lib/features/notifications/data/alert_texts.dart` give `AlertTexts` the `AzkarContent` (loaded in `load`) and the azkar title and body (`count` = the set's total, `minutes`, both through `formatDigitsIn`). In `lib/features/notifications/data/notification_scheduler.dart` add the `azkar` channel (name `tabAzkar`, default importance, no sound, no vibration) to `_ensureChannels` and its details (iOS passive, no sound, banner and list).
- [X] T076 [US6] In `lib/features/notifications/data/background.dart` make `topUp` read `azkarNudges`, load `loadAzkarContent()`, build the done set from `db.azkarCounts` for the latest morning and evening windows, and add `buildNudges(...)` to the alerts when on. Make T070 pass.
- [X] T077 [US6] In `lib/features/notifications/presentation/notifications_boot.dart` add `azkarNudges` and both sets' done (from `azkarProgressProvider`) to `_scheduleInputsProvider`, and route `AzkarTarget` to `Routes.azkarSet(set)` in `_open`.
- [X] T078 [US6] Add the switch to `lib/features/azkar/view/azkar_page.dart`: a second `SurfaceCard` under the rows with `ToggleRow(azkarReminders, subtitle: azkarRemindersSub with 20)` bound to `azkarNudges` through `updateSettings`. Make T071 pass.

**Checkpoint**: nudges come on a phone with the app closed, quietly, and open the set.

---

## Phase 9: Polish & Cross-Cutting Concerns

- [X] T079 [P] Add to the Azkar, Tasbih, set, Duas and category page tests: Arabic (Eastern digits, the ring and beads not mirrored, the back arrows flipped), text scale 2.0 (nothing overflows, the chips scroll, every hit at least 44 x 44), light and dark, reduce motion on and off, a tablet width (stretched to 480 pt).
- [X] T080 [P] Write `integration_test/azkar_journey_test.dart` on the design scenario: Home's azkar row → the evening set, count card 1 → card 2, back → Azkar › Tasbih, 17 taps → "Set complete" → More › Duas, search "tawakkaltu", Save, back.
- [X] T081 Run the self check from the `adaptive-widgets` skill on every new and changed file, `flutter test test/architecture_test.dart`, and fix every hit.
- [X] T082 Run `dart format --set-exit-if-changed lib test integration_test`, `flutter analyze` and `flutter test`, all clean.
- [X] T083 Run quickstart.md steps 1 and 2 on a simulator (design scenario, both languages, both modes), and hand me steps 3 and 4 (a phone for the nudges and the share sheet, the undesigned pages) to run myself.
- [X] T084 [P] Update the milestone list in `CLAUDE.md`: "8. Azkar, Tasbih and Duas: the Azkar tab, both sets, Tasbih, Duas with save, share and Listen ready for clips, the azkar nudges. **Done, waiting for my review.**", and the "as in `HANDOFF_CLAUDE.md`" line starts at 9.
- [X] T085 Run `grep -rn "TODO(ahmed)" lib assets ios android` and list in the reply what I have to supply: the azkar and duas dataset (every `note`), the dua clips, the set minutes.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: T001 first, the constitution before any code. Then T002 to T004.
- **Foundational (Phase 2)**: after Setup. Blocks every story.
- **US1 (Phase 3)**: after Phase 2. The MVP.
- **US2 (Phase 4)**: after Phase 2. Independent of US1 except the Tasbih row, which only pushes the
  route.
- **US3 (Phase 5)**: after Phase 2, independent of US1 and US2.
- **US4 (Phase 6)** and **US5 (Phase 7)**: after US3, they act on its cards. Both touch
  `dua_actions.dart` and `duas_page.dart`, so one after the other.
- **US6 (Phase 8)**: after US2 (the progress and the Azkar tab page).
- **Polish (Phase 9)**: after the stories.

### Inside Phase 2

- T005 to T007 (tests) before T008 to T010.
- T011 then T012 and T013 (they need schema 4).
- T014 to T019 and T021, T022 touch different files and run in parallel.
- T020 after T009 (it needs `AzkarSet`).

### Parallel Opportunities

- Phase 2: T005, T006, T007 together. Then T008, T009, T010, T014 to T019 together.
- US1: T023 to T026 and T028 to T031 together, then T027, then T032.
- US2: T033 to T037 and T039 together, then T038, T040 to T043.
- US3: T044 to T050 and T052 to T054 together, then T051, T055, T056. T057 any time.
- US6: T069 to T074 together, then T075 to T078.
- Polish: T079, T080 and T084 together.

## Parallel Example: Phase 2

```text
Task: "T008 every plural in AppLocalizations.tr"
Task: "T009 azkar_window.dart"
Task: "T010 azkar.json + azkar_content.dart"
Task: "T014 strings in strings_manager.dart and both arb files"
Task: "T016 SurfaceCard and ShortcutRow to core"
Task: "T018 DuaText to core"
```

## Implementation Strategy

### MVP First (User Story 1)

1. Phase 1 (constitution, branch, share_plus), then Phase 2.
2. US1: Tasbih. Stop and check the design scenario and a real phone (taps, haptics, beads).

### Incremental Delivery

1. US1 → Tasbih counts and keeps its count.
2. US2 → the Azkar tab, the sets, Home's row, the badge.
3. US3 → Duas with chips, search and the category pages.
4. US4 → Save.
5. US5 → Share, Listen ready.
6. US6 → the nudges.
7. Polish → languages, text scale, checks, CLAUDE.md. Then stop for my review (constitution
   workflow).
