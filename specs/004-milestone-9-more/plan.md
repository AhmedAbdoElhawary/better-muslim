# Implementation Plan: Milestone 9, More, Theme and Hijri Calendar

**Branch**: `feature/milestone-9`, cut when the build starts, after milestone 8 | **Date**:
2026-10-19 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/004-milestone-9-more/spec.md`

## Summary

More (4.09), the theme picker (4.15) and the Hijri calendar (4.13), plus the pages More opens:
- **More**: the large title page with the three tiles, PRAYER, APPEARANCE, SOUND AND TOUCH, YOUR
  DATA and ABOUT. Rows open milestone 4's method sheet (moved to core), milestone 3's location
  sheet, the theme page, the light and dark sheet and the Adhan and reminders page (R1, R15).
- **Theme**: `App` reads the theme and the mode from the store. Follow sky resolves from today's
  sunrise and Maghrib (R3). `BmColors.lerp` becomes a real lerp, so Apply is a 300 ms crossfade
  (R2). The preview is its own snippet from `Theme Snippet.dc.html` under the picked theme (R4).
- **Calendar**: the month from hijri's Umm al-Qura table minus the adjustment, the same rule as
  Home (R5). Ten fixed events and COMING UP (R6). The day sheet and the adjustment sheet.
- **Adhan and reminders**: the 4.12 rows, a recording per prayer stored and used by the adhan,
  the clip and the Android channel (R7), a preview on the clip player moved to core (R8), the
  reminder slider with 25 (R9), the notifications off line.
- **Toggles**: Haptics and UI sounds through static flags like `BmHaptics` (R11, R12). UI sounds
  play three placeholder files with a `TODO(ahmed)`.
- **Data and about**: Reset prayer journey (R13), Credits and the open source licenses (R14), the
  version from a small system channel that also opens settings and links (R10).

No new package, no network. Schema 5.

## Technical Context

**Language/Version**: Dart 3.13, Flutter 3.47.5 stable. Swift (iOS 15+) and Kotlin for the
system channel.

**Primary Dependencies**: what is already in. hijri 3.0.1 (Umm al-Qura array), just_audio 0.10.6
and audio_session 0.2.4 (preview, UI sounds, ringer mode), flutter_local_notifications 22.3.2
(channels, permission check), drift 2.35 (schema 5), flutter_riverpod 3.4.3, go_router 18.1,
intl 0.20.3, flutter_screenutil.

**Storage**: drift, schema 5: five recording columns, the reminder check takes 25
(data-model.md).

**Testing**: unit tests for the month math (SC-003), events and COMING UP, the resolved mode, the
palette lerp, the channel ids and the alarm entry, the migration. Widget tests for More, the theme
page, the calendar, the sheets, the Adhan and reminders page and Credits, in both languages, both
modes and text scale 2.0. One integration test for the More journey on the design scenario.

**Target Platform**: iOS 15+, Android 8.0+ (minSdk 26)

**Project Type**: mobile app

**Performance Goals**:
- a toggle, a swatch or a mode tap shows within 100 ms, Apply in one 300 ms crossfade (SC-002)
- `MaterialApp` rebuilds only when the theme or the resolved mode changes, not every second (R3)
- a month is 30 cells of plain dates, built at once, no loading

**Constraints**:
- offline, nothing leaves the phone, settings in the encrypted store
- built from the 4.09, 4.13 and 4.15 trees; the pages with no PNG only from `03 Components`
- RTL, Eastern digits per setting, text scale 2.0, reduce motion, 44 x 44, AA in 8 themes x 2 modes

**Scale/Scope**: 6 pages (More, Theme, Calendar, Adhan and reminders, Credits, Licenses), 5 sheets,
1 dialog, 4 new core widgets, 4 files moved to core, 1 native channel (about 20 lines each side),
schema 5, about 75 strings in 2 languages, about 30 named sizes

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Result |
| --- | --- | --- |
| I. Structure | `features/more/`, `features/theme_picker/`, `features/hijri_calendar/` as MVVM (listed). The Adhan and reminders page in `features/notifications/presentation/`. Shared parts go to core once: `NavRow`, `GroupedSection`, `Segmented`, `BmDialog`, appearance, `BmSounds`, the system channel. Moved: the method sheet, `ClipPlayer`, `AdhanRecording`, `HomeSamples` (R1). The router imports the pages. No feature imports another | pass |
| II. Design system | weight text widgets, adaptive paddings, `RSizedBox`, `ThemeEnum` (swatches resolve each theme's palette through `ThemeEnum.resolve`), `BmIcon`, named sizes for tiles, swatches, cells, the snippet. About 75 strings in `StringsManager` and both arbs. The digits switch is the handoff's own ("setting to switch", OVERVIEW) and defaults to Eastern: T001 makes the constitution's line say "by default" (PATCH) | pass, with T001 |
| III. Faithful | the three screens from their trees, the snippet from `Theme Snippet.dc.html`, the sheets, rows, dialog, slider and segmented control from `03 Components`. Apply's 300 ms crossfade, sheet Motion 15, toggle haptics. Pages with no PNG checked by me in the app (FR-036) | pass |
| IV. Simplicity | events and credits as const lists, no content files. Static flags for haptics and sounds like the existing `BmHaptics`. Placeholder recordings point at Makkah's files instead of 30 copies. No package | pass |
| V. Performance | `.select()` on each setting, the resolved mode changes twice a day, the snippet's countdown is the only ticking widget on the theme page, const leaves | pass |
| VI. Tests | unit, widget and one integration test as above. Migration test v4 → v5. Architecture and strings tests green | pass |
| VII. Privacy | nothing new leaves the phone. Links open only https (system channel). Reset touches only the log and qada | pass |
| VIII. Offline and free | the calendar, events, themes and sounds are all on the phone. Credits gives GeoNames its CC BY credit | pass |
| Stack | no new package. The system channel replaces url_launcher, package_info_plus and app_settings (R10) | pass |
| Handoff code | `BmColors.lerp` changes from a snap to a lerp, every value stays (R2) | pass |

**Post-design re-check**: still passes. T001 is a PATCH (3.4.1) of principle II's digits line.

## Project Structure

### Documentation (this feature)

```text
specs/004-milestone-9-more/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── system-channel.md
│   └── adhan-recordings.md
├── checklists/requirements.md
└── tasks.md            # /speckit-tasks
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── app/app.dart                              # theme id, themeMode, 300 ms, haptics and
│   │                                             # sounds flags
│   ├── audio/
│   │   ├── clip_player.dart                      # moved from duas, music session, busy flag
│   │   └── ui_sounds.dart                        # BmSounds, TODO(ahmed): the three files
│   ├── database/app_database.dart                # schema 5, resetPrayerJourney()
│   ├── flavor/design_scenario.dart               # themeModeProvider override for Follow sky
│   ├── resources/
│   │   ├── design/bm_theme.dart                  # BmColors.lerp, BmPalette.lerp
│   │   ├── dimensions_manager.dart               # + named sizes
│   │   ├── strings_manager.dart                  # + keys
│   │   └── theme_manager.dart                    # BmThemeId.nameKey
│   ├── router/app_router.dart                    # theme, hijri calendar, adhan settings,
│   │                                             # credits, licenses (top level, over the tabs)
│   ├── samples/home_samples.dart                 # moved from home
│   ├── settings/
│   │   ├── adhan_recording.dart                  # moved from notifications, six recordings
│   │   ├── appearance.dart                       # themeIdProvider, themeModeProvider
│   │   └── settings.dart                         # recordingOf(prayer)
│   ├── system/system_channel.dart                # openNotificationSettings, openUrl, version
│   └── widgets/
│       ├── bm_dialog.dart                        # destructive confirmation
│       ├── grouped_section.dart                  # label + card + dividers
│       ├── nav_row.dart                          # icon, title, value, chevron, stacks > 1.4
│       ├── segmented.dart                        # 03 Components segmented control
│       └── sheet/method_sheet.dart               # moved from prayer
└── features/
    ├── more/
    │   ├── model/credits.dart                    # const list, TODO(ahmed) where not final
    │   └── view/
    │       ├── more_page.dart                    # 4.09 + YOUR DATA + ABOUT + dev row
    │       ├── credits_page.dart
    │       ├── licenses_page.dart                # LicenseRegistry, one row per package
    │       └── widgets/ more_tiles.dart  mode_sheet.dart  reset_row.dart
    ├── theme_picker/
    │   ├── view_model/theme_preview.dart         # picked theme + mode, autoDispose
    │   └── view/
    │       ├── theme_page.dart                   # 4.15
    │       └── widgets/ theme_snippet.dart  theme_swatches.dart  mode_control.dart
    ├── hijri_calendar/
    │   ├── model/ hijri_month.dart  hijri_events.dart  coming_up.dart
    │   ├── view_model/calendar_providers.dart    # shown month, today's month, coming up
    │   └── view/
    │       ├── hijri_calendar_page.dart          # 4.13
    │       └── widgets/ month_header.dart  month_grid.dart  day_cell.dart
    │                    coming_up_card.dart  day_sheet.dart  adjustment_sheet.dart
    ├── notifications/
    │   ├── data/ notification_scheduler.dart (recordings, channel ids)  adhan_player.dart
    │   │         background.dart
    │   └── presentation/
    │       ├── notifications_boot.dart           # recordings in the inputs, stop the preview
    │       └── view/
    │           ├── adhan_settings_page.dart      # FR-026 to FR-030
    │           └── widgets/ prayer_sound_row.dart  recording_sheet.dart  reminder_sheet.dart
    │                        notifications_off_line.dart
    ├── prayer/                                   # method sheet import, day complete sound
    ├── azkar/                                    # bead and set complete sounds
    ├── qibla/                                    # aligned sound
    ├── duas/                                     # ClipPlayer import
    └── home/                                     # HomeSamples import

ios/Runner/AppDelegate.swift                      # + better_muslim/system
android/app/src/main/kotlin/com/elhawary/bettermuslim/MainActivity.kt   # + better_muslim/system
assets/audio/ ui_bead.m4a  ui_complete.m4a  ui_aligned.m4a           # placeholders
assets/l10n/app_en.arb, app_ar.arb
drift_schemas/app_database/drift_schema_v5.json

test/core/settings/appearance_test.dart
test/core/resources/design/bm_theme_test.dart
test/core/system/system_channel_test.dart
test/drift/app_database/migration_test.dart       # v4 → v5
test/features/more/ hijri_calendar/ theme_picker/ notifications/
integration_test/more_journey_test.dart
```

**Structure Decision**: one Flutter app. Three new MVVM features as the constitution lists them,
the Adhan and reminders page inside notifications. Native code next to the existing channels in
`AppDelegate.swift` and `MainActivity.kt`.

## Key Flows

1. **Theme**: `App` watches `themeIdProvider` and `themeModeProvider`. The mode provider reads the
   saved mode, today's sunrise and Maghrib and the ticker, and returns the same `ThemeMode` until a
   boundary (R3). `AnimatedTheme` lerps the palettes in 300 ms (R2).
2. **Theme page**: `themePreviewProvider` starts from the saved pair. Swatches and segments write
   to it. `ThemeSnippet` sits in `Theme(AppTheme.x(picked))`. Apply writes both settings and pops;
   back drops the preview (FR-010 to FR-012).
3. **Calendar**: `shownMonthProvider` starts at today's Hijri month (with the adjustment). Arrows
   step it, the calendar icon resets it. The grid reads `hijriMonth(shown, adjust)` and each cell's
   look. COMING UP reads today and the adjustment only. A tap opens the day sheet with
   `dayTimesProvider(date)` and the day's events.
4. **Adjustment**: the sheet keeps a local value, shows `HijriDate.of(today, value)`, Save writes
   `hijriAdjust`. Home, the calendar, Ramadan's Isha and the notification inputs already watch it.
5. **Adhan and reminders**: the page reads the five sounds, the five recordings and the reminder
   minutes. Each change writes the store, the notifications boot's inputs change, the schedule is
   remade with the new channel ids (R7). The recording sheet previews on `clipPlayerProvider` (R8).
6. **Permission line**: `NotificationScheduler.isAllowed()` on open and on resume. "Open settings"
   → `SystemChannel.openNotificationSettings()`.
7. **Toggles**: written to the store. `App` copies haptics and UI sounds into `BmHaptics.enabled`
   and `BmSounds.enabled`. Reduce motion is already joined in `App.builder`.
8. **Reset**: `BmDialog` → `resetPrayerJourney()` → hide the current toast (R13).
9. **Design scenario**: the store's defaults are the 4.09 values, `themeModeProvider` gives the
   phone's mode for Follow sky (FR-041).

## Decisions (2026-10-19)

The clarify answers (Q1 to Q8, all recommendations) are in the spec. The plan adds these:
1. **Quran rows wait for milestone 7**, which moved after 11: Page turn haptic, Downloaded
   recitations, the Quran credits and the Page sound (spec FR-031, FR-033, FR-008).
2. **The Location row opens milestone 3's location sheet**, built since the spec was drafted.
3. **A system channel instead of three packages** (R10): url_launcher, package_info_plus and
   app_settings would each need my OK for one call each.
4. **The preview is the snippet, not Home** (R4), and it's still: the countdown ticks, the sky
   doesn't drift.
5. **Placeholder recordings reuse Makkah's files** (R7), one `TODO(ahmed)` above the enum.
6. **The reminder saves when its sheet closes** (R9), not on each slider step.
7. **The credits page's own lines** ("Place names", "Fonts", "Azkar and duas", "Adhan
   recordings") join the FR-038 copy table.
8. **The constitution's digits line** becomes "by default" (T001, PATCH 3.4.1), since I chose the
   switch in Q3.

## Complexity Tracking

| Addition | Why Needed | Simpler Alternative Rejected Because |
| --- | --- | --- |
| `better_muslim/system` channel, about 20 native lines each side | notification settings, links and the version without three new packages (FR-030, FR-033, FR-034) | url_launcher + package_info_plus + app_settings: three packages to approve for three calls |
| `BmPalette.lerp` over 26 colors | the 300 ms crossfade on Apply (FR-012) | an app wide `AnimatedSwitcher` rebuilds the router and loses every page's state |
| `ThemeSnippet` as its own widget | the snippet's sizes differ from Home and a feature can't import Home (FR-011) | Home's widgets in core, scaled, still wrong sizes and most of Home moved for one preview |
| a recording column per prayer + channel ids with the recording | Android fixes a channel's sound at creation (FR-027, FR-029) | one recording for all prayers: the board's sheet is per prayer |
