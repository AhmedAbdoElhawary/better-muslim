# Implementation Plan: Milestone 3, Home

**Branch**: `feature/milestone-3`, cut from `feature/milestone-2` once milestone 2 is committed |
**Date**: 2026-10-17 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/002-milestone-3-home/spec.md`

## Summary

Home (4.01, 4.02, 4.16) on top of milestone 2's data, in place of the dev readout:
- **Living Sky**: the handoff's painter on one ticker at 30 fps, following the prayer period, the
  sun at its real place, the sky change on each prayer time (R6, R8).
- **Live values**: NOW, next prayer, a countdown on the wall clock's second with sliding digits,
  the bar, the glow that breathes in the last 10 minutes (R5, R10, R11).
- **Strip**: the prayer day's five times with the log marks, through milestone 4's
  `prayerDayProvider` and `prayedProvider`, built here first (R2).
- **Location sheet**: "Use my location" and the offline city search, plus the no-location state.
  `useAuto()` now asks and reports back (R12).
- **Core pieces later screens need**: the bottom sheet, the search field, the reduce motion flag
  in one place, the power saving check, tabular figures, the large text rule (R4, R7, R10, R15).

No new package, no network, no store change.

## Technical Context

**Language/Version**: Dart 3.13, Flutter 3.47.5 stable

**Primary Dependencies**: what is already in. flutter_riverpod 3.4.3, go_router 18.1,
flutter_screenutil 5.9, flutter_svg 2.3, intl 0.20.3, geolocator 14.1 (through milestone 2's
`PositionSource`).

**Storage**: none new. Reads milestone 2's encrypted store.

**Testing**:
- flutter_test unit tests for `features/home/model/`, `prayerDayProvider`, the ticker and
  `useAuto()`
- widget tests for Home and the location sheet
- the architecture test

**Target Platform**: iOS 15+, Android 8.0+ (minSdk 26)

**Project Type**: mobile app

**Performance Goals**:
- times on screen within 1 s of start (SC-004)
- the sky at 30 fps in its own repaint layer, the rest of the page rebuilds only the countdown
  leaf each second (SC-007)
- the city search under 100 ms per key (milestone 2's SC-004)

**Constraints**:
- offline
- the sky does no work while hidden, in the background, with reduce motion, or in Low Power Mode
  or Battery Saver
- nothing about the location leaves the phone

**Scale/Scope**: 1 screen in 3 looks (dark, light, Arabic), 1 sheet, about 15 widgets, 15 new
strings

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Checked against constitution 2.2.0.

| Principle | Check | Result |
| --- | --- | --- |
| I. Structure | Home stays MVVM (`model/`, `view_model/`, `view/`). The prayer day and log seams, the sheet, the search field and the power check go in `core/` because other features use them. The scenario reads no Home code, Home reads `flavorProvider`. No feature imports another | pass |
| II. Design system | weight text widgets, adaptive paddings, `RSizedBox`, `ThemeEnum`, `BmIcon`. Every Home-only number gets a named manager entry. The sky's white text and scrim are `ThemeEnum` entries resolved in core (R9). The painter keeps its allow-list entry for the white stars. 15 strings go into `StringsManager` and both arb files. Buttons, the sheet and the search field are core components (R12) | pass |
| III. Faithful | built from 4.01, 4.02 and 4.16. The undrawn parts (sheet, no location, stacking) use existing components only and were decided in the spec. Every animation follows MOTION.md with its reduce motion fallback | pass |
| IV. Simplicity | no new package. Two providers that milestone 4 needs anyway. The sky lives in Home until a second screen needs it. One method channel call instead of battery_plus (R7) | pass |
| V. Performance | the countdown leaf alone ticks each second. Derived providers notify only on a change. The sky paints in a `RepaintBoundary` from one notifier, with no rebuilds (R6). `const` leaves. One `MediaQuery.of` in `app.dart`, approved (decision 4) | pass, approved exception |
| VI. Tests | unit tests for every model function and the changed core calls, a contrast test for the sky text. Widget tests for the looks, text scale 2.0, 12 hour, no location, the sheet and reduce motion. Integration tests wait for milestone 10 (decision 6) | pass, approved deferral |
| VII. Privacy | the city search is on the phone. `useAuto` asks only "while using". No position or place name is logged or reported | pass |
| VIII. Offline and free | nothing touches the network | pass |
| Workflow | spec, plan and tasks per constitution 2.2.0 | pass |

**Post-design re-check**: unchanged after Phase 1. No open items.

## Project Structure

### Documentation (this feature)

```text
specs/002-milestone-3-home/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── core-additions.md
├── checklists/requirements.md
└── tasks.md            # /speckit-tasks
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── app/app.dart                            # disableAnimations = OS or settings (R4)
│   ├── clock/clock.dart                        # ticker on the wall clock's second (R5)
│   ├── extensions/window_size.dart             # + isLargeText (R15)
│   ├── flavor/design_scenario.dart             # dayTimes for the date, Fajr and Dhuhr logged (R3)
│   ├── location/location_controller.dart       # useAuto() → Future<bool> (R12)
│   ├── power/power_saving.dart                 # powerSavingProvider, better_muslim/power (R7)
│   ├── prayer_log/prayer_log.dart              # prayedProvider, {} until milestone 4 (R2)
│   ├── prayer_times/
│   │   ├── day_times.dart                      # + nameArKey on Prayer and Period (R13)
│   │   └── prayer_times_providers.dart         # + prayerDayProvider (R2), computeDayTimes (R3)
│   ├── resources/
│   │   ├── theme_manager.dart                  # + onSkyBright, skyScrim, glass, starOpacity (R9)
│   │   ├── font_manager.dart                   # + FontEnum.quran, Home font roles
│   │   ├── dimensions_manager.dart             # + named Home sizes
│   │   └── strings_manager.dart                # + 15 keys
│   └── widgets/
│       ├── adaptive/text/adaptive_text.dart    # + tabularFigures (R10)
│       ├── shell/tab_switcher.dart             # drops the reduce motion TODO (R4)
│       ├── sheet/bm_sheet.dart                 # showBmSheet, Motion 15 (R12)
│       ├── search_field.dart                   # 4.14's search field (R12)
│       └── bm_button.dart                      # 4.11's primary and secondary buttons (R12)
└── features/home/
    ├── model/
    │   ├── home_moment.dart                    # bar share, sky state, sun share, labels,
    │   │                                       # azkar and glow windows, countdown parts
    │   └── home_samples.dart                   # sample content with its TODOs (R14)
    ├── view_model/
    │   └── home_providers.dart                 # slices that notify only on a change
    └── view/
        ├── home_page.dart                      # scroll, layers, AnnotatedRegion light
        └── widgets/
            ├── sky_header.dart                 # ticker, RepaintBoundary, sky change (R6, R8)
            ├── sky_header_painter.dart         # + stars on/off, RTL stars, pulse, twinkle
            ├── sky_labels.dart                 # Sunrise / Maghrib or Isha / Fajr
            ├── location_pill.dart  date_line.dart  now_block.dart
            ├── next_prayer_card.dart           # title row, countdown, bar, adhan line
            ├── countdown.dart  countdown_digit.dart
            ├── prayer_bar.dart  card_glow.dart
            ├── prayer_strip.dart  strip_cell.dart  strip_row.dart
            ├── verse_card.dart
            ├── shortcuts_card.dart  shortcut_row.dart
            ├── no_location_card.dart
            └── location_sheet.dart             # use my location, search, results

ios/Runner/AppDelegate.swift                    # + better_muslim/power
android/app/src/main/kotlin/.../MainActivity.kt # + better_muslim/power
assets/l10n/app_en.arb, app_ar.arb              # + 15 strings

test/
├── architecture_test.dart                      # MediaQuery.of allowed in app.dart only (R4)
├── core/clock/  core/prayer_times/  core/location/  core/flavor/  core/power/
├── features/home/model/home_moment_test.dart
├── features/home/view/sky_contrast_test.dart   # WCAG AA on every sky (SC-006)
├── features/home/view/sky_header_test.dart
├── features/home/view/home_page_test.dart      # looks, scale 2.0, 12 h, no location, taps
├── features/home/view/location_sheet_test.dart
└── features/home/dev_readout_test.dart         # deleted with the readout
```

**Structure Decision**: one Flutter app. Home fills its MVVM folders. The pieces other
milestones already plan to use go to `core/`, next to their milestone 1 and 2 neighbours. The dev
readout and its test go away (spec FR-002).

## Key Flows

1. **Open Home**:
   - The saved location gives the times at once.
   - The sky picks its state from `periodProvider`, with no change animation on first build.
   - The countdown subscribes to the ticker.
   - The sky ticker starts unless reduce motion is on or the phone is power saving.
2. **Every second**: the ticker fires on the whole second. Only the countdown digits, the bar
   and the screen reader label read it. A digit that changed slides.
3. **A prayer time passes**:
   - `periodProvider` and `nextPrayerProvider` change.
   - NOW, the card, the strip highlight and the azkar window update.
   - The sky lerps to the new state over 1.8 s.
4. **Fajr**: `prayerDayProvider` changes. The strip reads the new day's times and log.
5. **Midnight**: `todayProvider` changes, so the date line and the Hijri date update.
6. **Location pill**: `showBmSheet` → the location sheet.
   - Picking a result calls `choose`, closes the sheet and Home follows.
   - "Use my location" calls `useAuto()`. True closes the sheet. False shows the message and
     keeps the search open.
7. **No location**: the page shows the sky with no sun and no labels, the pill "No location yet",
   the date line, the no-location card (both choices open the same sheet), the verse and the
   shortcuts.
8. **Leaving Home**:
   - another tab: `TickerMode` stops the sky
   - background: no frames
   - resume: the power check is read again, and the loop fades back in over 300 ms

## Decisions (2026-10-17)

1. **useAuto()** changes to ask and report back (R12). It was built for app start, the sheet is a
   user's request.
2. **Power saving** is a two-line method channel, not battery_plus (R7). If I'd rather have the
   package, that needs my OK under the stack rules.
3. **Milestone 4 seams**: `prayerDayProvider` and `prayedProvider` are built here with milestone
   4's contract (R2). Milestone 4's tasks for them become "fill in the log".

## Decisions (2026-10-18)

4. **`MediaQuery.of` in `app.dart`**: allowed in that one file, for the reduce motion copy (R4).
   The architecture test lists it as the rule's only exception.
5. **Core buttons**: `BmButton.primary` and `.secondary` from 4.11 go into `core/widgets/` now,
   for the no-location card (R12).
6. **Integration tests**: they wait for milestone 10, when onboarding into Home is the first main
   journey (R17).

## Complexity Tracking

| Addition | Why Needed | Simpler Alternative Rejected Because |
| --- | --- | --- |
| `better_muslim/power` channel (about 10 lines Swift, 10 Kotlin) | MOTION.md pauses ambient motion in Low Power Mode and Battery Saver | battery_plus is a package for one bool, skipping breaks MOTION.md |
| `prayedProvider` returning `{}` | the strip and the scenario need the log's shape now, milestone 4 fills it | a Home-only list would be rewired in milestone 4 |
| `MediaQuery.of` in `app.dart` | the in-app reduce motion switch has to reach `MediaQuery.disableAnimationsOf` for every widget | a core inherited widget means a second flag every widget has to read |
