# Implementation Plan: Milestone 8, Azkar, Tasbih and Duas

**Branch**: `feature/milestone-8`, made when the build starts, after milestone 6 is merged |
**Date**: 2026-10-19 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/003-milestone-8-azkar/spec.md`

## Summary

The Azkar tab, Tasbih (4.08), the morning and evening sets, Duas (4.14) and the azkar nudges:
- **Sets**: content from `assets/azkar/azkar.json` (R2), the samples repeated up to 12 and 24
  (R3). A window per set and prayer day, morning Fajr to Asr, evening Asr to the next Fajr (R4).
  One card at a time, the tap after done moves on (R8). Shared by Home, the tab, the badge and the
  nudges from `core/azkar/` (R1).
- **Tasbih**: from the 4.08 tree, Motion 11 and 12 (R7), the state kept on the settings row (R5),
  felt on the tap's frame (R6).
- **Duas**: from the 4.14 tree, content from `assets/duas/duas.json`, FR-019's card and rows from
  one pure function, search folding Arabic marks and letter forms (R10). Save in the store, Listen
  through just_audio with no clips yet (R11), Share as an image card through share_plus (R12).
- **Nudges**: a third alert kind in milestone 5's schedule, the next 3 only, 20 minutes after Fajr
  and Asr, quiet, skipped when the set is done (R13).
- **Core moves**: Home's card and row, the ring painter, the dua text block (R15). Plurals for two
  counts in one message (R14).

One new pub.dev package, share_plus 13.3.1 (approved in Q7). Schema 3 → 4. No network.

## Technical Context

**Language/Version**: Dart 3.13, Flutter 3.47.5 stable.

**Primary Dependencies**: what is already in: flutter_riverpod 3.4.3, go_router 18.1, drift 2.35
(drift_dev, build_runner), just_audio 0.10.6, flutter_local_notifications 22.3.2, flutter_svg,
flutter_screenutil, intl 0.20.3 (`MessageFormat`). New: share_plus 13.3.1.

**Storage**: the encrypted drift store, schema 4: five settings columns, `azkar_counts`,
`saved_duas` (data-model.md). Content is read only JSON in the app bundle.

**Testing**: unit tests for the windows, the progress, the tasbih and set state machines, the
duas view and search, the nudges, the two plural message. A test that the shipped JSON follows the
contract. Widget tests for the Azkar tab, Tasbih, the set page, Duas and the category page. The v3
→ v4 migration test. One integration test: Home's row → the evening set → Tasbih → Duas.

**Target Platform**: iOS 15+, Android 8.0+ (minSdk 26)

**Project Type**: mobile app

**Performance Goals**:
- each tasbih or zikr tap: haptic and motion on the next frame, 20 taps in 2 s count 20 (SC-002)
- search results while typing with no visible delay (SC-005)
- only the counter, the ring and the beads rebuild on a tap

**Constraints**:
- offline, nothing leaves the phone, nothing in crash reports
- built from the 4.08 and 4.14 trees, the undesigned pages only from components
- text scale 2.0, reduce motion, RTL with the ring, beads and digits never mirrored
- iOS keeps at most 64 pending notifications (63 used)
- Quran items in the sets follow the Quran text rules

**Scale/Scope**: 5 pages (Azkar tab, Tasbih, set, Duas, category), 1 share card, 2 JSON files
(36 zikr, 9 duas in the samples), 3 tables touched, 1 alert kind, about 14 new strings in 2
languages, 5 pieces moved to core.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Result |
| --- | --- | --- |
| I. Structure | `features/azkar/{model,view_model,view}` and `features/duas/{model,view_model,view}`, MVVM as listed. The sets, windows and progress are read by Home, the shell, the tab and the notifications, so `core/azkar/`. The nudges stay in `features/notifications/` and read core. The router imports the pages, as allowed. No feature imports another (R1) | pass |
| II. Design system | weight text widgets with `FontEnum.dua`, `FontEnum.quran` and `FontEnum.display`, adaptive paddings, `RSizedBox`, `ThemeEnum` roles (`primaryContainer`, `primary`, `outline2`, `glow`, `accent`), `BmIcon` for every icon. The tree's sizes (ring 240, stroke 5, beads 28 and 16 gap, chips 36, card paddings) get named manager entries. Every string is a key in both arb files, content passes `translate: false` | pass |
| III. Faithful | 4.08 and 4.14 from their trees, Motion 11 and 12 and the haptics table from MOTION.md. The Azkar tab, the set page, the category page, the empty states and the share card only from `03 Components.dc.html` and Brand, I check them in the app | pass |
| IV. Simplicity | five pieces move to core instead of being copied (R15). One pure function for the duas view, one for the nudges. No interface except the audio player seam the tests need. share_plus added in the milestone that needs it | pass |
| V. Performance | tap state in a notifier, written through (R6). `.select()` on the count and dhikr, `RepaintBoundary` around the ring and beads, `const` leaves. Content loaded once. Search in memory | pass |
| VI. Tests | unit, widget, migration and integration tests as above. Architecture and strings tests green | pass |
| VII. Privacy | counts, tasbih and saved duas only in the encrypted store, never in crash reports. The nudge payload carries no place. The share card is made only when I tap Share | pass |
| VIII. Offline and free | content and clips in the bundle. share_plus uses the phone's share sheet, no service | pass |
| Stack | share_plus is not on the constitution's list. Checked on pub.dev (R12) and approved in Q7. T001 adds it to the list | pass, T001 amends the constitution to 3.4.0 |

**Post-design re-check**: data-model.md and the contracts keep every table in the store, the
nudge inside milestone 5's scheduler and its budget, and the moved pieces in core. No open items.

## Project Structure

### Documentation (this feature)

```text
specs/003-milestone-8-azkar/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── content-files.md
│   └── nudges.md
├── checklists/requirements.md
└── tasks.md            # /speckit-tasks
```

### Source Code (repository root)

```text
assets/
├── azkar/azkar.json                              # the morning and evening sets (samples)
├── duas/duas.json                                # the categories and duas (samples)
└── l10n/app_en.arb, app_ar.arb                   # + the FR-032 strings, the nudge bodies

lib/
├── core/
│   ├── app/app_localizations.dart                # every plural in a message (R14)
│   ├── azkar/
│   │   ├── azkar_content.dart                    # Zikr, AzkarContent, loadAzkarContent()
│   │   ├── azkar_window.dart                     # AzkarSet, currentAzkarSet, azkarWindowDay
│   │   └── azkar_progress.dart                   # content, counts, progress, badge providers
│   ├── database/app_database.dart                # schema 4, azkar counts, saved duas
│   ├── flavor/design_scenario.dart               # tasbih at 16
│   ├── resources/
│   │   ├── strings_manager.dart                  # + keys
│   │   └── dimensions_manager.dart               # + named tasbih, chip, card and badge sizes
│   ├── router/app_router.dart                    # azkar sub routes, duas routes
│   └── widgets/
│       ├── dua_text.dart                         # out of milestone 5's DuaSheet
│       ├── ring_painter.dart                     # out of the prayer ring
│       ├── shortcut_row.dart                     # out of Home
│       ├── surface_card.dart                     # Home's HomeCard
│       ├── toggle_row.dart                       # the components' toggle row
│       └── shell/ app_shell.dart nav_bar.dart    # the azkar badge
└── features/
    ├── home/                                     # imports the moved pieces, real progress
    ├── prayer/presentation/view/widgets/progress_ring.dart   # uses RingPainter
    ├── notifications/
    │   ├── domain/ alert.dart schedule.dart tap_target.dart  # AlertKind.azkar, buildNudges
    │   ├── data/ background.dart alert_texts.dart notification_scheduler.dart
    │   └── presentation/ notifications_boot.dart view/widgets/dua_sheet.dart
    ├── more/view/more_page.dart                  # temporary Duas button, TODO: milestone 9
    ├── azkar/
    │   ├── model/
    │   │   ├── tasbih_dhikr.dart                 # the three dhikr and targets
    │   │   ├── tasbih_state.dart                 # tap, chip, reset (pure)
    │   │   └── set_state.dart                    # open, tap, done (pure)
    │   ├── view_model/
    │   │   ├── tasbih_controller.dart            # notifier, written through
    │   │   └── set_controller.dart               # notifier per set, opened day
    │   └── view/
    │       ├── azkar_page.dart                   # large title, rows, switch
    │       ├── tasbih_page.dart
    │       ├── azkar_set_page.dart
    │       └── widgets/
    │           ├── dhikr_chips.dart  dhikr_text.dart
    │           ├── tasbih_counter.dart           # ring, count, glow, Motion 12 burst
    │           ├── bead_strip.dart               # Motion 11
    │           └── zikr_card.dart
    └── duas/
        ├── model/
        │   ├── dua.dart                          # Dua, DuaCategory, DuaChip, loader
        │   ├── duas_view.dart                    # FR-019 card and rows (pure)
        │   └── dua_search.dart                   # normalize, match (pure)
        ├── view_model/
        │   ├── duas_providers.dart               # content, chip, query, saved, results
        │   └── dua_player.dart                   # one clip at a time
        └── view/
            ├── duas_page.dart
            ├── dua_category_page.dart
            ├── share_dua.dart                    # render the card, share it
            └── widgets/
                ├── dua_chips.dart  category_rows.dart
                ├── dua_card.dart  dua_actions.dart
                └── share_card.dart               # arch frame, text, wordmark

drift_schemas/drift_schema_v4.json
test/
├── core/azkar/ azkar_window_test.dart azkar_progress_test.dart azkar_content_test.dart
├── core/app/app_localizations_test.dart          # two plurals
├── drift/app_database/                           # schema_v4, migration 3 → 4
├── features/azkar/ model/ view/
├── features/duas/ model/ view_model/ view/
├── features/notifications/domain/ schedule_test.dart tap_target_test.dart
└── helpers/azkar.dart
integration_test/azkar_journey_test.dart
```

**Structure Decision**: one Flutter app. Two new MVVM features, a new `core/azkar/`, five pieces
moved to core. No native code.

## Key Flows

1. **Tasbih tap**: the counter area's `GestureDetector` → `TasbihController.tap()` changes the
   state at once (R6), `BmHaptics.bead()`, the bead strip retargets its spring, the ring tweens,
   the store gets the new dhikr and count. At the target: `setComplete()`, Motion 12, the
   announcement.
2. **Opening a set**: from the Azkar tab, Home's row or a nudge → `Routes.azkarSet(set)`. The set
   controller reads the latest window's counts, opens at the first card not done, and writes the
   opened day (the badge goes).
3. **A zikr tap**: count + 1 or move on (data-model.md), written through. When the set is done,
   the boot's inputs change and the nudge for that window is taken back.
4. **Duas**: the content loads once. The chip and the query pick between `duasViewFor` and the
   search results. Save writes `saved_duas`. Listen goes to `DuaPlayer`. Share renders the card
   and opens the share sheet.
5. **Nudges**: `topUp` loads `azkar.json`, reads the latest windows' counts, adds
   `buildNudges(...)` to the prayer alerts, `apply` schedules them with the azkar channel.
6. **Design scenario**: tasbih at 16, nothing counted, the evening set current, nothing scheduled.

## Decisions (2026-10-19)

The clarify answers (Q1 to Q10, then the two nudge questions, all recommendations) are in the spec.
The plan adds these:
1. **Content as JSON assets** with a `note` field carrying the `TODO(ahmed)` (R2), so my dataset
   drops in with no code change.
2. **The samples**: the components' zikr (100 times) and the 4.14 dua (once) take turns in the
   sets. The dua categories repeat the 4.14 dua and the dua after the adhan. Travel stays empty
   and shows "No duas found" (R3, spec edge case).
3. **Tasbih state on the settings row**, counts and saved duas in two tables (R5).
4. **The toggle row goes to core now**, More's settings in milestone 9 use the same component (R9).
5. **Duas outside the shell**, like Qibla, since 4.14 has no tab bar. The sets and Tasbih stay in
   the Azkar tab, since 4.08 has it (R9, R10).
6. **The Azkar tab's icons**: sunrise for the morning, night for the evening, tasbih for Tasbih.
   No design, I check them in the app.
7. **The share card uses the app's current theme and mode** (R12). No design, I check it.
8. **A zikr's done look**: the bar full and the count in primary with the check icon (R8).

## Complexity Tracking

| Addition | Why Needed | Simpler Alternative Rejected Because |
| --- | --- | --- |
| share_plus | the phone's share sheet for the image card (FR-027, Q7) | no package: needs a channel per platform for the share sheet |
| off screen render of the share card | an image of a widget with the app's fonts (R12) | a screenshot package: another dependency for 15 lines |
| `AppLocalizations.tr` with every plural | the nudge body has two counts (R14) | two keys glued in code: Arabic word order |
