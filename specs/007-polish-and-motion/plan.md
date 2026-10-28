# Implementation Plan: Milestone 12, Polish and Motion

**Branch**: `feature/milestone-12`, cut when the build starts, after milestone 11 is reviewed |
**Date**: 2026-10-20 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/007-polish-and-motion/spec.md`

## Summary

A polish pass in two parts, each stopping for my review:
- **Part 1, behaviour** (US1 to US5, US8):
  - **Calendar**: two month kinds behind one grid (R2), months and years views in place of the
    days, the selected day always set, the day sheet becomes the area under the grid with Prayer
    times, Coming up and Events (R3). Coming up walks the days to the year's end (R6).
  - **Sky**: each theme's six states turned from Qiyam Emerald's in OKLCH, Emerald untouched, the
    48 skies tested for contrast before anything else (R5).
  - **Azkar and Tasbih**: a timer after the completion moment does the move (R7). Tasbih keeps
    three counts and a finite 99 bead string.
  - **More**: Acknowledgements in place of Credits, a CONTACT section (R14), the adjustment row
    and the Top glow switch.
  - **Store**: schema 8 with every new column, so part 2 needs no migration (R4).
- **Part 2, motion** (US6, US7):
  - Apple's push from the theme for every page (R8), five hero pairs minus Home's shortcuts (R9),
    dialogs scaling in (R13).
  - The large title moving into the bar with the finger (R10), the glow pinned on every page (R12).
  - Every sudden change in FR-036 through three small core widgets (R11).

No new pub package. Schema 8. Two native calls on the existing system channel.

## Technical Context

**Language/Version**: Dart 3.13, Flutter 3.47.5 stable. Swift 5 and Kotlin 2.4 for the two system
channel calls.

**Primary Dependencies**: already in: flutter_riverpod 3.4.3, go_router 18.1, drift 2.35, hijri
3.0.1, share_plus 13.3.1, flutter_screenutil. Flutter's own `CupertinoPageTransitionsBuilder`,
`Hero`, `AnimatedSwitcher`, `AnimatedSize`. New: none.

**Storage**: drift, schema 8 (data-model.md): `calendarMode`, `topGlow`, three tasbih counts,
`tasbihCount` dropped.

**Testing**:
- Unit: theme skies (Emerald equal, each Isha the theme's, every state in the theme's hue), the
  months of both kinds and their ends, Coming up (groups, pills, estimated, next year, the end),
  the Tasbih round (100 taps, chips, reset), migration v7 → v8, the system channel's two calls.
- Contrast: the text over all 48 skies (FR-021), the bar title over the glow in 8 themes × 2 modes.
- Widget: the calendar (modes, views, Today, tabs, a Coming up tap), the azkar and Tasbih
  automatic moves with fake time, More's new rows, the push builder, dialogs, the segmented
  control, the title flight, the title moving into the bar.
- No goldens and no screenshots. Feel, flights and 120 Hz are checked on the phones with
  quickstart.md.

**Target Platform**: iOS 15+, Android 8.0+ (minSdk 26), the same as before.

**Project Type**: mobile app

**Performance Goals**:
- every frame of a push, a flight, the title move and the month slide inside the phone's budget
  (SC-008), checked in profile mode on an older phone
- only transform and opacity animate. The title moves through a `ValueListenableBuilder`, the
  page never rebuilds per frame. No blur animates (the bar's glass is a static layer that fades)
- theme skies worked out once per theme and kept, Coming up under a millisecond, recomputed only
  when the day, the adjustment or the mode change

**Constraints**:
- offline, no package, nothing leaves the phone (the mail draft is mine to send)
- every new motion from `BmMotion`, with its reduce motion fallback through
  `MediaQuery.disableAnimationsOf` (the app already joins the phone's setting and the switch)
- every animation interruptible, input never blocked
- English and Arabic, mirrored except the bead string, text scale 1.0 and 2.0, 8 themes, both
  modes

**Scale/Scope**: about 12 new Dart files and 45 changed, 1 removed page (Credits) and 3 removed
calendar widgets, schema 8, about 35 strings in 2 languages, 2 native calls per platform

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Result |
| --- | --- | --- |
| I. Structure | the calendar stays MVVM. The adjustment sheet moves into `features/more` (its only user). The theme sky, the push builder, the title flight, the switcher, the sliding selection and the rolling digits go into core, each used by two features or more. `CountdownDigit` leaves Home for core because Azkar uses it too. No feature imports another | pass |
| II. Design system | colors from `getColor`, the theme skies from `BmPalette` inside core. New sizes in the managers, new strings in `StringsManager` and both arbs, icons from `BmIcon` (`close` for the dimmed Events tab, `forward` turned for the title's chevron). Five new `BmMotion` entries appended, the handoff's values unchanged (R15) | pass |
| III. Faithful | every break of the handoff is in the spec's Approved breaks. What has no design (the Gregorian header, the months and years views, the area under the grid, the marker and head beads, CONTACT) is built from the existing components and checked by me in the app. Home's azkar shortcut flight is dropped as the spec allows (R9) | pass with the approved breaks |
| IV. Simplicity | no package. Three small motion widgets for every FR-036 row, Flutter's own Cupertino push and `Hero`. One migration with every new column | pass |
| V. Performance | transform and opacity only, scroll-linked through a notifier, `.select()` on every read, the skies and Coming up computed once | pass |
| VI. Tests | the 48 skies before any sky or motion code (T012), the bar over the glow (T069), migration, Coming up, Tasbih, the calendar and the motion widgets. The architecture test gains one rule: no feature reads `bmSkyQiyamEmerald` except the adhan screen | pass |
| VII. Privacy | Send feedback only opens a draft, I send it. The phone model and OS only go into that draft. `openUrl` stays https only, `mail` is its own call | pass |
| VIII. Offline and free | everything on the phone, store links open only on tap | pass |
| Stack | no new package (share_plus already in) | pass |
| Handoff code | `bm_sky.dart` untouched, `bm_motion.dart` only appended | pass |

**Post-design re-check**: still passes. The breaks are the spec's own list, nothing new was added
by the design.

## Project Structure

### Documentation (this feature)

```text
specs/007-polish-and-motion/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── system-channel.md       # + mail, device
│   └── routes.md               # acknowledgements in place of credits, the hero tags
├── checklists/requirements.md
└── tasks.md                    # /speckit-tasks
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── database/app_database.dart                  # schema 8
│   ├── settings/settings.dart                      # + CalendarMode
│   ├── resources/
│   │   ├── design/bm_motion.dart                   # + completionPause, shift, dialogFrom, zoom
│   │   ├── theme_sky.dart                          # themeSky(id): the six states, OKLCH
│   │   ├── theme_manager.dart                      # pageTransitionsTheme
│   │   ├── dimensions_manager.dart                 # bead marker, head bead, tassel, pill, ...
│   │   └── strings_manager.dart                    # + keys, - credits, comingUp, monthBegins, ...
│   ├── router/
│   │   ├── app_router.dart                         # /acknowledgements, - /credits
│   │   └── page_transitions.dart                   # BmPageTransitionsBuilder
│   ├── system/system_channel.dart                  # + mail, device
│   └── widgets/
│       ├── compact_app_bar.dart                    # heroTag, glass over the glow, the title move
│       ├── title_glow.dart                         # pinned page layer, the Top glow switch
│       ├── title_hero.dart                         # text flight shuttle
│       ├── bm_switcher.dart                        # content swap + size
│       ├── sliding_selection.dart                  # the highlight that slides
│       ├── rolling_digits.dart                     # from home's countdown_digit.dart
│       ├── segmented.dart                          # sliding highlight, dimmed segment with x
│       ├── bm_dialog.dart                          # scale 1.08 → 1
│       ├── nav_row.dart                            # the value crossfades
│       ├── toast/toast.dart                        # slides in
│       ├── sheet/location_sheet.dart, method_sheet.dart
│       └── backup/                                 # working → done
└── features/
    ├── hijri_calendar/
    │   ├── model/
    │   │   ├── calendar_month.dart                 # sealed: HijriMonth, GregorianMonth (was hijri_month.dart)
    │   │   ├── coming_up.dart                      # the year walk
    │   │   └── hijri_events.dart
    │   ├── view_model/calendar_providers.dart      # mode, selected day, page, tab, coming up
    │   └── view/
    │       ├── hijri_calendar_page.dart            # title switch, Today, glow, day area
    │       └── widgets/
    │           ├── calendar_title.dart             # the title with its chevron
    │           ├── month_header.dart               # cycles the views, arrows by view
    │           ├── month_grid.dart                 # slides, the selection
    │           ├── day_cell.dart                   # both modes
    │           ├── picker_grid.dart                # months and years
    │           ├── day_details.dart                # date line, segmented, the tab
    │           ├── day_times.dart                  # Prayer times
    │           ├── coming_up_list.dart             # was coming_up_card.dart
    │           ├── day_events.dart                 # Events
    │           └── calendar_format.dart            # + Gregorian strings
    │           # removed: day_sheet.dart, adjustment_sheet.dart (to more)
    ├── home/view/widgets/                          # sky_header (theme sky), FR-036 Home rows
    ├── onboarding/view/widgets/welcome_sky.dart    # theme sky
    ├── theme_picker/view/widgets/                  # snippet_sky, swatches ring, mode control
    ├── azkar/
    │   ├── model/tasbih_state.dart                 # three counts, advance, round
    │   ├── view_model/tasbih_controller.dart       # three columns
    │   └── view/
    │       ├── azkar_page.dart                     # hero sources
    │       ├── azkar_set_page.dart                 # the timer
    │       ├── tasbih_page.dart                    # the timer, reset all, the bar's hero
    │       └── widgets/bead_strip.dart, dhikr_chips.dart, dhikr_text.dart, zikr_card.dart
    ├── duas/view/                                  # category hero source, chips, results
    ├── more/
    │   ├── model/contact.dart                      # TODO(ahmed) values
    │   └── view/
    │       ├── more_page.dart                      # adjustment row, Top glow, CONTACT
    │       ├── acknowledgements_page.dart          # credits + licenses (was licenses_page.dart)
    │       └── widgets/about_section.dart, contact_section.dart, adjustment_sheet.dart, more_tiles.dart
    │       # removed: credits_page.dart
    ├── prayer/presentation/view/                   # FR-036 Prayer rows, glow
    ├── notifications/presentation/view/            # FR-036 Adhan and reminders rows, glow
    ├── qibla/view/widgets/qibla_bar.dart           # heroTag, glow
    └── quran/presentation/view/quran_page.dart     # glow

ios/Runner/AppDelegate.swift                        # mail, device
android/app/src/main/kotlin/com/elhawary/bettermuslim/MainActivity.kt   # mail, device
assets/l10n/app_en.arb, app_ar.arb
drift_schemas/app_database/drift_schema_v8.json

test/
├── core/resources/theme_sky_test.dart
├── features/home/view/sky_contrast_test.dart       # 48 skies
├── core/resources/contrast_test.dart               # bar title over the glow
├── drift/app_database/migration_test.dart          # v7 → v8
├── core/backup/backup_file_test.dart               # a v7 backup restores its tasbih count
├── features/hijri_calendar/                        # calendar_month, coming_up, the page
├── features/azkar/                                 # tasbih_state, tasbih and set pages
├── features/more/                                  # contact, acknowledgements, new rows
├── core/system/system_channel_test.dart            # mail, device
├── core/router/page_transitions_test.dart
├── core/widgets/                                   # dialog, segmented, title hero, switcher,
│                                                   # sliding selection, the title move
└── architecture_test.dart                          # bmSkyQiyamEmerald rule
```

**Structure Decision**: the same single Flutter app. Shared motion and the theme sky go into core,
each feature changes only its own files.

## Key Flows

1. **Calendar open**: mode from the settings, the selected day today, the page the days view of
   today's month, Prayer times open.
2. **Day tap**: the selected day changes, the selection slides, the date line and the open tab
   crossfade, Coming up recomputes.
3. **Header tap**: days → months → years → days. A year opens its months, a month its days.
4. **Coming up tap**: page (days, that month) + selected day + Events, one write each, the grid
   slides.
5. **Title tap**: the mode is saved, the page maps to the month holding the selected day, the grid
   crossfades.
6. **Azkar card done**: haptic and check, the 1 s timer, the next card slides. A tap in the wait
   moves at once, a swipe or leaving cancels.
7. **Tasbih**: a tap counts and saves the three counts. Done with another left: the timer, then
   `advance()`. All done: "Set complete", the next tap starts a new round.
8. **Push**: `context.push` → `MaterialPage` → the theme's `BmPageTransitionsBuilder` → Cupertino
   or the fade. A `TitleHero` with the same tag on both sides flies.
9. **Scroll on Prayer, Azkar, More**: offset → progress → the title layer's transform, the
   subtitle's opacity, the bar's glass at the end. Scroll end between 0 and 1 → snap.
10. **Top glow switch**: one setting, every page's glow fades, the bars change tint.

## Answered (2026-10-20)

Nothing new was asked in the plan. One spec condition was settled, and the analyze findings were
answered with the recommendations:

| # | Question | Answer |
| --- | --- | --- |
| P1 | Can Home's azkar shortcuts fly into the set's title? (spec, conditional) | No: `context.go` switches branch navigators, no hero controller sees both ends (R9). The pair is dropped as the spec allows, FR-033 updated |
| A1 | The dimmed Events label is still tappable, so it must meet AA (analyze) | the segmented control's muted text2 look with the x icon, FR-018 updated |
| A2 | The calendar's zoom used raw scales (analyze) | `BmMotion.zoomNear` and `zoomFar` (R15) |
| A3 | Reduce motion turned on mid animation (analyze) | what runs finishes, the next change uses the fallback, the edge case updated |
| A4 | Android gets Flutter's edge swipe back too (analyze) | kept (R8) |

## Decisions (2026-10-20)

1. **One sealed month type** for both modes, the grid doesn't know which (R2).
2. **Gregorian mode from April 1937 to October 2077**, the months the table covers with the ±2
   adjustment (R2).
3. **The selected day is never null**, today on open (R3).
4. **Schema 8 in part 1 with `topGlow`**, one migration for the whole milestone (R4).
5. **Theme skies turned in OKLCH** from Emerald's, offset from the dark sky3 hues (R5).
6. **Coming up as a walk over the days**, so the white days and Gregorian years work (R6).
7. **`completionPause` 1000 ms** for both the azkar cards and Tasbih (R7, R15).
8. **Flutter's Cupertino push from the theme** on both platforms, a fade interval for reduce
   motion (R8).
9. **A text morph shuttle** for every flight, tags are the destination routes (R9).
10. **The title drawn in an overlay layer**, the header's own title kept for layout (R10).
11. **The bar's glass fades, it isn't scroll-linked** (R10), cheaper on older phones.
12. **`BmGlass.surfaceOpacity` (.55)** for the bar over the glow, .8 without (R12).
13. **`mail` and `device` on the system channel**, no url_launcher, no device_info_plus (R14).

## Complexity Tracking

| Addition | Why Needed | Simpler Alternative Rejected Because |
| --- | --- | --- |
| a sealed month type with two kinds | one grid and one set of providers for both modes (FR-002, FR-003) | a mode switch in every method, or a second grid |
| OKLCH conversion (about 30 lines) | turned skies must keep Emerald's perceived lightness, so the text stays readable (FR-021) | HSL turning changes contrast per hue, hand-made skies were declined |
| an overlay layer for the moving title | the move follows the finger without relayout or a rebuild per frame (FR-039, SC-008) | `CupertinoSliverNavigationBar`: not 4.04 and 4.09's bar, fonts or sizes |
| a text morph hero shuttle | the default flight scales a picture of the text, the weight and size jump at the end (FR-033) | Flutter's default shuttle |
| two native calls | a mail draft and the phone model need the platform (FR-044) | url_launcher and device_info_plus: two packages for two calls |
