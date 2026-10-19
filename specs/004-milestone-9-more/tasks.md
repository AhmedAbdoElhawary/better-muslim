---

description: "Tasks for milestone 9, More, theme and Hijri calendar"
---

# Tasks: Milestone 9, More, Theme and Hijri Calendar

**Input**: Design documents from `specs/004-milestone-9-more/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/system-channel.md,
contracts/adhan-recordings.md, quickstart.md

**Tests**: Included. Constitution VI asks for unit tests on logic and widget tests on screens,
SC-003 asks for every month from 1440 to 1460 AH, SC-004 for the Follow sky boundaries.

**Organization**: Grouped by user story, so each story can be built and checked on its own.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an unfinished task)
- **[Story]**: The user story the task belongs to (US1 to US7)

## Before starting

- Built after milestone 8, on `feature/milestone-9` (plan header). Milestone 7 comes after 11, so
  nothing here touches the Quran reader.
- Read `design_handoff_better_muslim/specs/HOW_TO_READ.md`, then the 4.09, 4.13, 4.15 and 4.12
  trees, `design/Theme Snippet.dc.html`, MOTION.md row 15 and the haptics table, and in
  `03 Components.dc.html` the list rows (navigation, with toggle, selected picker), the segmented
  control, the toggle, the slider, the bottom sheet ("Adhan sound"), the dialog ("Reset prayer
  journey?"), the calendar day cells (default, today, selected, white day, event, Sunnah fast) and
  the theme picker.
- Every UI file follows the `adaptive-widgets` rules, and `flutter test test/architecture_test.dart`
  stays green.
- Parallel sessions share `.specify/feature.json`, so speckit commands get this folder passed
  explicitly (`SPECIFY_FEATURE_DIRECTORY=specs/004-milestone-9-more`).

---

## Phase 1: Setup

**Purpose**: The constitution wording, the branch, the folders, the placeholder sounds.

- [X] T001 Amend `.specify/memory/constitution.md` for plan decision 8 (approved in Q3): in principle II change "Arabic shows Eastern Arabic digits." to "Arabic shows Eastern Arabic digits by default, a switch in More turns them Western.", bump the version PATCH (3.4.1, or the next PATCH if another milestone moved it) and the Last Amended date.
- [X] T002 Ask before cutting `feature/milestone-9` from where milestone 8 ends. Then confirm `flutter pub get`, `flutter analyze` and `flutter test` are green before any change.
- [X] T003 Create the folders `lib/core/audio/`, `lib/core/samples/`, `lib/core/system/`, `lib/features/more/{model,view/widgets}/`, `lib/features/theme_picker/{view_model,view/widgets}/`, `lib/features/hijri_calendar/{model,view_model,view/widgets}/`, `test/core/audio/`, `test/core/system/`, `test/features/more/`, `test/features/theme_picker/`, `test/features/hijri_calendar/{model,view}/`.
- [X] T004 Make three placeholder UI sounds in `assets/audio/` (already listed in `pubspec.yaml`): `ui_bead.m4a` (40 ms), `ui_complete.m4a` (600 ms), `ui_aligned.m4a` (300 ms), each a soft sine tone with a fade out, written as wav by a small script in the scratchpad and converted with `afconvert -f m4af -d aac`. Keep them quiet (about −24 LUFS, the Brand board's level).

---

## Phase 2: Foundational

**Purpose**: What every story stands on: the moves to core, schema 5, the theme wiring, the
system channel, the sounds, the strings, the sizes and the four shared widgets.

**⚠️ CRITICAL**: No story work starts before this phase is done

### Tests for the foundation

- [X] T005 [P] Write `test/core/settings/appearance_test.dart` for `themeModeProvider` with a fake clock and Makkah `DayTimes`: dark → dark and light → light at any time; followSky → dark one minute before sunrise, light one minute after, light one minute before Maghrib, dark one minute after, dark at 00:30; followSky with no location → system; a daylight saving day (Europe/London, 29 Mar 2026) and a location change (Makkah → Cairo) move the switch with the new times (SC-004). The provider gives the same value between boundaries.
- [X] T006 [P] Write `test/core/resources/design/bm_theme_test.dart`: `BmPalette.lerp(a, b, 0)` equals a, `1` equals b, `.5` gives each of the 26 colors half way, and `BmColors.lerp` uses it.
- [X] T007 [P] Write `test/core/system/system_channel_test.dart` with a mocked `better_muslim/system` channel: `openNotificationSettings` calls the method, `openUrl` passes https and refuses `http:` and `mailto:` without calling the channel, `version` returns the string.
- [X] T008 [P] Write widget tests in `test/core/widgets/`: `nav_row_test.dart` (icon, title, value, chevron mirrored in Arabic, the whole row is the hit target at least 44 pt, the value goes under the title above text scale 1.4, a screen reader hears "title, value"), `grouped_section_test.dart` (label, dividers between rows, none after the last), `segmented_test.dart` (the selected segment gets the surface pill, a tap calls back once with `BmHaptics.selection`, 44 pt high hits), `bm_dialog_test.dart` (title, body, Cancel returns false, the destructive action returns true).
- [X] T009 [P] Write `test/core/audio/ui_sounds_test.dart` with a fake player: nothing plays when `enabled` is false, when `busy` is true, or (Android) when the ringer mode isn't normal; each of `bead`, `complete`, `aligned` plays its own file once.

### Implementation for the foundation

- [X] T010 [P] Move `lib/features/prayer/presentation/view/widgets/method_sheet.dart` to `lib/core/widgets/sheet/method_sheet.dart` with `git mv` (it only imports core) and update the import in `lib/features/prayer/presentation/view/prayer_page.dart` and its tests.
- [X] T011 [P] Move `lib/features/home/model/home_samples.dart` to `lib/core/samples/home_samples.dart` with `git mv`, update every import in `lib/features/home/` and `test/`.
- [X] T012 Move `lib/features/notifications/data/adhan_recording.dart` to `lib/core/settings/adhan_recording.dart` with `git mv` and give `AdhanRecording` the six values of `contracts/adhan-recordings.md`: makkah, madinah, alAqsa, cairo, istanbul, takbir. Add `lengthLabel` (the Brand board's "3:52", "4:10", "3:31", "3:44", "4:02", "0:12") and `isShort` (takbir only). The five new values use Makkah's four files. One `// TODO(ahmed): ...` above the enum: each recording gets its own files (names in the contract), clips 30 s or less, licensed. Update the imports in `lib/features/notifications/`.
- [X] T013 Schema 5 in `lib/core/database/app_database.dart`: add `fajrRecording`, `dhuhrRecording`, `asrRecording`, `maghribRecording`, `ishaRecording` as `textEnum<AdhanRecording>().withDefault(const Constant('makkah'))`, change the `reminderMinutes` check to `isIn(const [0, 5, 10, 15, 20, 25, 30])`, `schemaVersion => 5`, `from4To5`: add the five columns, then `m.alterTable(TableMigration(schema.settings))` for the new check, every row kept. Add `resetPrayerJourney()`: delete all `prayer_log` and `qada_entries` rows in one transaction (data-model.md). Run `dart run build_runner build` and `dart run drift_dev make-migrations`, commit `drift_schemas/app_database/drift_schema_v5.json`, the steps file and `test/drift/app_database/generated/schema_v5.dart`, and add the v4 → v5 case to `test/drift/app_database/migration_test.dart` (rows kept, the five recordings read makkah, 25 accepted, 7 refused).
- [X] T014 Add `recordingOf(Prayer)` to the `PrayerSoundOf` extension in `lib/core/settings/settings.dart`, the same switch as `soundOf`.
- [X] T015 [P] In `lib/core/resources/design/bm_theme.dart` (with `bm_colors.dart`): add `BmPalette.lerp(a, b, t)` with `Color.lerp` for each color and `lerpDouble` for `starOpacity`, and make `BmColors.lerp` return `BmColors(BmPalette.lerp(p, other.p, t))` instead of the half way snap. No value changes (research R2).
- [X] T016 Write `lib/core/settings/appearance.dart`: `themeIdProvider` (the saved `BmThemeId` by `.select`, Qiyam Emerald while loading) and `themeModeProvider` (`ThemeMode` from the saved `BmThemeMode` with `resolveBrightness`, `todayTimesProvider` and `tickerProvider`, system with no location; data-model.md table). Add `nameKey` to `BmThemeId` in `lib/core/resources/theme_manager.dart` (the eight theme name keys).
- [X] T017 Wire the theme in `lib/core/app/app.dart`: `theme: AppTheme.light(id)`, `darkTheme: AppTheme.dark(id)`, `themeMode: ref.watch(themeModeProvider)`, `themeAnimationDuration: BmMotion.standard`, `themeAnimationCurve: BmMotion.standardCurve`, drop the milestone 9 `TODO:`. In `initState` add a `ref.listenManual` with `fireImmediately` that copies `haptics` into `BmHaptics.enabled` and `uiSounds` into `BmSounds.enabled`.
- [X] T018 [P] In `lib/core/flavor/design_scenario.dart` override `themeModeProvider` so Follow sky gives `ThemeMode.system` (FR-041), Dark and Light stay as saved. Add the case to `test/core/flavor/design_scenario_test.dart`.
- [X] T019 [P] The system channel of `contracts/system-channel.md`: `lib/core/system/system_channel.dart` (`SystemChannel.openNotificationSettings()`, `openUrl(String)` refusing anything not https, `version()`), the handler in `ios/Runner/AppDelegate.swift` (`registerSystem(messenger:)` next to `registerPowerSaving`) and in `android/app/src/main/kotlin/com/elhawary/bettermuslim/MainActivity.kt` next to `better_muslim/power`. One `///` line on the Swift and Kotlin handlers saying why it's the app's own channel.
- [X] T020 Write `lib/core/audio/ui_sounds.dart`: `BmSounds` static like `BmHaptics`, `enabled` (false) and `busy` (false), `bead()`, `complete()`, `aligned()`. Each plays a preloaded `AudioPlayer(handleAudioSessionActivation: false)` on its `assets/audio/ui_*.m4a`. iOS: configure the session as ambient (`AVAudioSessionCategory.ambient`, mix with others) before playing. Android: skip unless `AndroidAudioManager().getRingerMode()` is normal. A `@visibleForTesting` seam for the fake player of T009. `// TODO(ahmed): ` above the file list: the real Bead, Complete and Aligned sounds, Brand board lengths and −24 LUFS.
- [X] T021 Move `ClipPlayer` and `JustAudioClipPlayer` with `clipPlayerProvider` from `lib/features/duas/view_model/dua_player.dart` to `lib/core/audio/clip_player.dart` (the recording preview is the second user). Before `play` configure the session with `AudioSessionConfiguration.music()` like the adhan player, set `BmSounds.busy` true while it plays and false on stop and end. Update the duas imports and tests. In `lib/features/notifications/data/adhan_player.dart` set `BmSounds.busy` while the adhan plays (both players, from their playback state).
- [X] T022 Add every new string to `lib/core/resources/strings_manager.dart` and both `assets/l10n/app_en.arb` and `app_ar.arb` with the wording of spec FR-038, including the credits lines, the eight theme names (`themeQiyamEmerald` … `themeQiyamRose`), the twelve short Hijri months (`hijriShort1` … `hijriShort12`), the six recording names (Makkah keeps `adhanOfMakkah`), "{minutes} min" and "Off". Plurals (`{n, plural, ...}`, the form the app already reads): `minBefore` and the reminder value (Arabic one دقيقة واحدة, two دقيقتان, few {n} دقائق, other {n} دقيقة), the adjustment value with its sign (English "+1 day", "−2 days", "0 days"; Arabic per FR-038). Keep `strings_manager_test.dart` green.
- [X] T023 [P] Add named sizes to `lib/core/resources/dimensions_manager.dart` from the trees: More tiles (height 92, icon box 36, radius 12, gap 10), list row 52 with gap 14 and padding 0 14 0 16, section label letter spacing .12em, swatch height 60, radius 14, check badge 18, preview box 300 high radius 24 with the snippet width 300, segmented 38 high radius 9 inside 12, calendar cell 54 high radius 14, white day dot 4 at 44, COMING UP left column 46, the snippet's font sizes and heights (sky 176, Now 34, Maghrib 28, countdown 22, card overlap 58). Font sizes and letter spacings go into `FontSizeManager` and `LetterSpacingManager` the same way, and `font_manager_test.dart` stays green.
- [X] T024 [P] Write `lib/core/widgets/nav_row.dart`: `NavRow(icon, title, {value, onTap, translateValue = true})`, the components' "Default · navigation" row, 52 pt, icon in text2, value in text2 at 14, chevron `BmUiIcon.forward` 16 in text3 (mirrored in Arabic), the whole row tappable, at least 44 pt. Above text scale 1.4 the value goes under the title. `onTap: null` draws the value without the chevron (Version).
- [X] T025 [P] Write `lib/core/widgets/grouped_section.dart`: `GroupedSection(label?, children)`, the uppercase label (12, letter spacing .12em, text3, padding 0 16) above a `SurfaceCard` whose rows get a 1 px outline divider between them, none after the last.
- [X] T026 [P] Write `lib/core/widgets/segmented.dart`: `Segmented<T>(values, selected, labelOf, onChanged)` from the components and 4.15: track `variant` radius 12 padding 3 gap 2, segments 38 high, the selected one gets the surface pill with the outline ring, `BmHaptics.selection()` on change, each segment a 44 pt hit target.
- [X] T027 [P] Write `lib/core/widgets/bm_dialog.dart`: `showBmDialog(context, title, body, action)` → `Future<bool>`, the components' "Destructive confirmation": title, body, Cancel and the action in `error`, the scrim at 48% light and 64% dark, Motion 15's fade under reduce motion.

**Checkpoint**: schema 5, the theme from the store, the shared widgets and strings ready.

---

## Phase 3: User Story 1 - Change a setting from More (Priority: P1) 🎯 MVP

**Goal**: More from the 4.09 tree, every row showing its value, every toggle working, the tiles,
the method and location rows.

**Independent Test**: In the design scenario More shows 4.09. Haptics off: Mark doesn't vibrate.
Reduce motion on: Home's sky stops drifting. Restart: both stay.

### Tests for User Story 1

- [X] T028 [P] [US1] Write `test/features/more/more_page_test.dart` on the design scenario store: the title, the subtitle, the three tiles push `Routes.qibla`, the Hijri calendar and `Routes.duas`; PRAYER shows "Umm al-Qura", "10 min before", "Makkah · auto"; APPEARANCE shows "Qiyam Emerald", "Follow sky", Reduce motion off; SOUND AND TOUCH Haptics on, UI sounds off. Flipping each toggle writes the store. The digits toggle shows only in Arabic and writes `digits`. The dev row shows in dev only. Arabic, light, text scale 2.0 (nothing overflows, every hit at least 44 x 44).
- [X] T029 [P] [US1] Add to the existing tests: `test/features/azkar/` a tasbih tap calls `BmSounds.bead` and the 33rd `BmSounds.complete`; `test/features/prayer/` the fifth mark calls `BmSounds.complete`; `test/features/qibla/` alignment calls `BmSounds.aligned` once. Each only with `BmSounds.enabled`.

### Implementation for User Story 1

- [X] T030 [P] [US1] Write `lib/features/more/view/widgets/more_tiles.dart`: three equal tiles from the 4.09 tree (surface, radius 20, outline ring, padding 14, the 36 pt `primaryContainer` icon box with `BmUiIcon.compass`, `calendar`, `dua` at 20, the label 14 medium), each a button for screen readers.
- [X] T031 [US1] Rewrite `lib/features/more/view/more_page.dart` from the 4.09 tree: `LargeTitleScrollView` with "More" and "Stored on this device · no account needed", the sky3 glow behind the title like `PrayerHeader`, the tiles, then `GroupedSection`s PRAYER (Calculation method, Adhan and reminders, Location), APPEARANCE (Theme, Light and dark, Reduce motion, the digits toggle in Arabic only), SOUND AND TOUCH (Haptics, UI sounds), with the 4.09 icons. Values by `.select`: the method's name key (by country shows the country's method), "{minutes} min before" or "Off", `autoSuffix` / `manualSuffix` / `noLocationYet`, the theme's `nameKey`, the mode's key. Keep `_DevRow` last in dev builds (FR-004). Replace the two temporary buttons and their `TODO:`s with the tiles.
- [X] T032 [US1] In `more_page.dart` wire Calculation method to `showMethodSheet(context)` (core) and Location to `showLocationSheet(context)` (core). The Adhan and reminders, Theme and Light and dark rows and the Hijri tile get their taps in US6, US2, US3 and US4.
- [X] T033 [US1] Toggles in `more_page.dart` with `ToggleRow`: Reduce motion → `reduceMotion`, Haptics → `haptics`, UI sounds → `uiSounds`, Eastern Arabic digits ١٢٣ → `digits` (on = eastern), each through `updateSettings`, each with `BmHaptics.selection()` (FR-005).
- [X] T034 [US1] Call the sounds next to their haptics: `BmSounds.bead()` and `BmSounds.complete()` beside `BmHaptics.bead()` and `setComplete()` in `lib/features/azkar/view/tasbih_page.dart` and `azkar_set_page.dart`, `BmSounds.complete()` beside `BmHaptics.dayComplete()` in `lib/features/prayer/presentation/view/widgets/day_complete.dart`, `BmSounds.aligned()` beside `BmHaptics.qiblaAligned()` in `lib/features/qibla/view/qibla_page.dart` (FR-008).

**Checkpoint**: More works with every setting it can change on its own.

---

## Phase 4: User Story 2 - Pick a theme (Priority: P1)

**Goal**: The 4.15 page, a live preview under the picked theme, Apply with the crossfade.

**Independent Test**: In the design scenario open Theme and tap Dark: 4.15. Iznik restyles only
the preview. Back: no change. Iznik + Apply: the app crossfades, More says Iznik.

### Tests for User Story 2

- [X] T035 [P] [US2] Write `test/features/theme_picker/theme_page_test.dart`: opens with the saved theme and mode selected; a swatch tap changes the preview's `Theme` and the "Live preview · {name}" chip, not the app's; Dark, Light, Follow sky change the preview mode; Apply writes `theme` and `themeMode` and pops; back writes nothing; the eight swatches in the 4.15 order with their names; Arabic, text scale 2.0 (names wrap), every swatch at least 44 x 44 and announced with its name and "selected".

### Implementation for User Story 2

- [X] T036 [P] [US2] Write `lib/features/theme_picker/view_model/theme_preview.dart`: an `autoDispose` notifier holding `(BmThemeId, BmThemeMode)`, started from the saved pair, with `pickTheme`, `pickMode` and `apply()` (writes both settings).
- [X] T037 [P] [US2] Write `lib/features/theme_picker/view/widgets/theme_swatches.dart`: the 4 x 2 grid (gap 12 10) from 4.15, each swatch two halves: the dark half a gradient sky3 → sky1 at 60% with the dark primary pill, the light half the light `bg` with the light primary pill, colors from `ThemeEnum.x.resolve(bmThemes[id]!.dark/light)`; the selected ring 2.5 `primary` and the check badge; the name 11.5 under it.
- [X] T038 [P] [US2] Write `lib/features/theme_picker/view/widgets/mode_control.dart`: `Segmented` with Dark, Light and Follow sky (Follow sky's label keeps its text2 look from 4.15 while not selected).
- [X] T039 [P] [US2] Write `lib/features/theme_picker/view/widgets/theme_snippet.dart` from `design/Theme Snippet.dc.html` (research R4): 300 wide, radius 30, the base sky gradient sky1/sky2/sky3 176 tall with the still stars and sun, "{place} · {date}" and the Hijri date, NOW and the current prayer (Marcellus 34), the next prayer card overlapping 58 (Arabic name in Reem Kufi, the name 28, the countdown 22 in primary from `tickerProvider`, the 3 pt bar, "at {time}"), the five cell strip with the current one highlighted, the verse card from `HomeSamples`. All values live from core providers, Eastern digits per setting. No ambient loops.
- [X] T040 [US2] Write `lib/features/theme_picker/view/theme_page.dart` from the 4.15 tree: `CompactAppBar(StringsManager.theme)`, the 300 pt preview box (variant, radius 24, outline ring) holding `ThemeSnippet` inside `Theme(data: AppTheme.light|dark(picked))` (Follow sky resolves with `resolveBrightness` now), the bottom fade and the chip, then `ModeControl`, `ThemeSwatches`, the Follow sky note, and Apply theme (`BmButton`, primary) at the bottom. Scrolls when taller than the screen.
- [X] T041 [US2] Add `Routes.theme` as a top level route over the tabs in `lib/core/router/app_router.dart`, and wire More's Theme row to push it.

**Checkpoint**: themes and modes change from the app.

---

## Phase 5: User Story 3 - Light and dark follow the sky (Priority: P2)

**Goal**: The Light and dark sheet. Follow sky itself is in the foundation (T016, T017).

**Independent Test**: Light and dark → Light: the app turns light at once. Follow sky a minute
before Maghrib: dark after it, while open.

- [X] T042 [P] [US3] Write `test/features/more/mode_sheet_test.dart`: the three picker rows with the saved one selected, a pick writes `themeMode` and closes, the note shows, Arabic.
- [X] T043 [US3] Write `lib/features/more/view/widgets/mode_sheet.dart`: `showBmSheet` with `SheetTitle(StringsManager.lightAndDark)`, `PickerRow` for Dark, Light, Follow sky, the Follow sky note under them. A pick writes at once with `BmHaptics.selection()` and closes (FR-016).
- [X] T044 [US3] Wire More's Light and dark row to the sheet in `lib/features/more/view/more_page.dart`.

**Checkpoint**: every way to change light and dark works.

---

## Phase 6: User Story 4 - The Hijri month at a glance (Priority: P2)

**Goal**: The 4.13 calendar: the month grid, the marks, the arrows, COMING UP, the adjustment
row's value.

**Independent Test**: In the design scenario: Jumada I 1448, 4 on 15 Oct highlighted, dots on 13
to 15, COMING UP Ayyam al-Bid, Jumada II begins, Rajab begins. Forward 4: Ramadan with 1 Ramadan
marked. The calendar icon: back.

### Tests for User Story 4

- [X] T045 [P] [US4] Write `test/features/hijri_calendar/model/hijri_month_test.dart`: for every month 1440 to 1460 AH and each adjustment −2 to +2, the first day equals `hijriToGregorian(y, m, 1)` minus the adjustment and every day of the grid gives back the same Hijri date through `HijriDate.of(day, adjust)` (SC-003); 1 Jumada I 1448 is Mon 12 Oct 2026 with 0 blanks + 1 (Sunday first); the header "October – November 2026" and "December 2026 – January 2027" in English, Arabic month names in Arabic; the labels "12 Oct", "13", …, "1 Nov"; the first and last month the table converts, and the step past them refused.
- [X] T046 [P] [US4] Write `test/features/hijri_calendar/model/hijri_events_test.dart` and `coming_up_test.dart`: the look of each FR-020 row, 13 Dhu al-Hijjah is Tashreeq with no white day, FR-019's order (today over selected over Sunnah fast over event over white day); from 15 Oct 2026 COMING UP is Ayyam al-Bid (13 Jum I, "24–26 Oct" without "Estimated"), Jumada II begins ("Estimated 11 Nov · confirmed by moon sighting"), Rajab begins ("Estimated 10 Dec"); from 25 Shaban 1448 Ramadan begins shows once; 1 Shawwal shows as Eid al-Fitr, not "Shawwal begins".
- [X] T047 [P] [US4] Write `test/features/hijri_calendar/view/hijri_calendar_page_test.dart` on the design scenario: the 4.13 values above, arrows move and stop at the ends, the calendar icon returns, the adjustment row shows "0 days", Arabic (Sunday on the right, arrows mirrored, Eastern digits, Western with the setting off), text scale 2.0 (scrolls, nothing cut), every day at least 44 x 44 and read as its full Hijri and Gregorian date with its marks.

### Implementation for User Story 4

- [X] T048 [P] [US4] Write `lib/features/hijri_calendar/model/hijri_month.dart`: `HijriMonth(year, month)` with `first(adjust)`, `length`, `blanks(adjust)` (Sunday = 0), `days(adjust)`, `previous`, `next`, `canGoBack`, `canGoForward` (hijri 3.0.1's range), `of(HijriDate)`; `gregorianLabel(day, isFirst)` and the header span (research R5).
- [X] T049 [P] [US4] Write `lib/features/hijri_calendar/model/hijri_events.dart`: the `DayLook` enum (today, selected, sunnahFast, event, whiteDay, plain), `HijriEvent` and the const list of the ten FR-020 rows with their name and note keys, `eventsOn(HijriDate)` and `lookOf(...)` in FR-019's order.
- [X] T050 [P] [US4] Write `lib/features/hijri_calendar/model/coming_up.dart`: `comingUp(today, adjust)` → three items as data-model.md says (white days one per month with their range, events, month starts unless an event is on them, the date line rule), walking at most 400 days.
- [X] T051 [US4] Write `lib/features/hijri_calendar/view_model/calendar_providers.dart`: `shownMonthProvider` (autoDispose, starts at today's month with the adjustment, `back`, `forward`, `today`), `todayHijriProvider` from `hijriDateProvider`, `comingUpProvider`, `selectedDayProvider` for the day sheet.
- [X] T052 [P] [US4] Write `lib/features/hijri_calendar/view/widgets/month_header.dart` from the 4.13 tree: the 44 pt arrows (`BmUiIcon.back` / `forward`, mirrored in Arabic, disabled at the ends), the month and year in Marcellus 24, the Gregorian span 12.5 text2.
- [X] T053 [P] [US4] Write `lib/features/hijri_calendar/view/widgets/day_cell.dart` and `month_grid.dart`: the 7 column grid with gap 2, the weekday letters (`DateFormat('EEEEE', locale)`, as the Prayer strip), blanks, each cell 54 high radius 14 with the Hijri day 17 medium and the Gregorian label 10.5 text2, the looks of `03 Components` (today primary fill with `onPrimary`, selected, white day accent dot 4 at 44, event, Sunnah fast). Tabular figures, digits per setting.
- [X] T054 [P] [US4] Write `lib/features/hijri_calendar/view/widgets/coming_up_card.dart`: COMING UP label and a `GroupedSection` of the three items, each with the 46 pt left column (day 17 semibold, short month 11 text2) and the title 15 medium with its date line 12.5 text2.
- [X] T055 [US4] Write `lib/features/hijri_calendar/view/hijri_calendar_page.dart` from the 4.13 tree: `CompactAppBar` with the calendar icon action (back to today, "Today" for screen readers), the header, the grid, COMING UP, and the Date adjustment `NavRow` with its value (the sheet comes in US5). One scroll view, the grid never squeezed.
- [X] T056 [US4] Add `Routes.hijriCalendar` as a top level route in `lib/core/router/app_router.dart` and wire More's Hijri calendar tile to it.

**Checkpoint**: the calendar reads and moves through months.

---

## Phase 7: User Story 5 - A day, and my local moon sighting (Priority: P2)

**Goal**: The day sheet and the adjustment sheet.

**Independent Test**: Tap 13 Jumada I: 24 Oct, six times, Ayyam al-Bid. Adjustment +1, Save:
today is 5 here and on Home, the row says "+1 day".

- [X] T057 [P] [US5] Write `test/features/hijri_calendar/view/day_sheet_test.dart` and `adjustment_sheet_test.dart`: the day sheet's dates, six times from `dayTimesProvider` (12 and 24 hour), its events with notes, the selection cleared on close; the stepper stops at −2 and +2, shows today's Hijri date for each step, Save writes `hijriAdjust`, closing without Save writes nothing; Arabic.
- [X] T058 [P] [US5] Write `lib/features/hijri_calendar/view/widgets/day_sheet.dart`: `showBmSheet` with the full Hijri date as title and the Gregorian date under it, a `GroupedSection` of Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha with times by `formatTime`, and EVENTS with each event and its note when the day has any.
- [X] T059 [P] [US5] Write `lib/features/hijri_calendar/view/widgets/adjustment_sheet.dart`: `showBmSheet` with `SheetTitle(dateAdjustment)` and the FR-038 body, a − value + stepper (44 pt buttons, the value with its sign, today's Hijri date under it), Save (`BmButton`) writing `hijriAdjust` (data-model.md: "−2 to 2").
- [X] T060 [US5] Wire a day tap in `month_grid.dart` (select, open the day sheet, clear on close) and the Date adjustment row in `hijri_calendar_page.dart`.

**Checkpoint**: the calendar is complete.

---

## Phase 8: User Story 6 - Adhan and reminders (Priority: P2)

**Goal**: The page that changes milestone 5's choices, a recording per prayer used everywhere, the
reminder slider, the notifications off line.

**Independent Test**: Dhuhr Silent, Fajr Madinah, reminder 15: More says "15 min before", the
pending notifications change, the dev page's test plays the chosen recording.

### Tests for User Story 6

- [X] T061 [P] [US6] Add to `test/features/notifications/`: the channel id for each sound and recording (`adhan_fajr_adhan_madinah`, `adhan_dhuhr_tone`, `adhan_asr_silent`), a recording change creates the new channel and deletes the prayer's others including milestone 5's `adhan_{prayer}_adhan`; `entryOf` carries the prayer's recording asset, channel and name; the iOS clip is the recording's; `buildSchedule` with 25 minutes puts each reminder 25 minutes before; a recording change remakes the schedule (the boot inputs).
- [X] T062 [P] [US6] Write `test/features/notifications/view/adhan_settings_page_test.dart`: the five prayers with today's times and their sounds (Adhan for Fajr and Maghrib), a recording row only under Adhan prayers, a change writes the store; the recording sheet lists six with "Full adhan · 3:52" … "Short · 0:12", a tap plays on a fake `ClipPlayer`, Save writes and stops, closing stops; the reminder sheet's slider gives 0 to 30 in 5s, "Off" at 0, writes on close; the off line shows only when `isAllowed()` is false and calls `openNotificationSettings`; Arabic, text scale 2.0.

### Implementation for User Story 6

- [X] T063 [US6] In `lib/features/notifications/data/notification_scheduler.dart`: `apply` and `_ensureChannels` take `Map<Prayer, AdhanRecording> recordings`; channel ids per `contracts/adhan-recordings.md` (Adhan `adhan_{prayer}_adhan_{recording}`), the sound `recording.clipOf(prayer)`; on each apply delete every other id of the prayer, including the old `adhan_{prayer}_adhan`; `entryOf(alert, texts, recording)` uses the recording's asset, channel and name; the iOS notification sound the recording's clip; drop the `_recording` constant. `testIn1Minute` uses the prayer's recording.
- [X] T064 [US6] In `lib/features/notifications/data/adhan_player.dart`: `NativeAdhanPlayer.length` and `JustAudioAdhanPlayer.play` read the prayer's recording from the settings (passed in or read through the database), drop the `_recording` constant.
- [X] T065 [US6] Pass the recordings along: `lib/features/notifications/data/background.dart` (from `settings.recordingOf`), `lib/features/notifications/presentation/notifications_boot.dart` (`_scheduleInputsProvider` adds the five recordings, so a change remakes the schedule; when the adhan screen opens, `ref.read(clipPlayerProvider).stop()`), and `dev_notifications_page.dart`.
- [X] T066 [P] [US6] Write `lib/features/notifications/presentation/view/widgets/prayer_sound_row.dart`: the 4.12 row (prayer name, today's time, `Segmented` with Adhan, Tone, Silent), and under it, only on Adhan, a `NavRow` with "{recording} · full adhan" (or the takbir's short line) opening the recording sheet.
- [X] T067 [P] [US6] Write `lib/features/notifications/presentation/view/widgets/recording_sheet.dart`: the components' "Adhan sound" sheet, `SheetTitle(adhanSound)` with "For {prayer}", six `PickerRow`s with the length line, a tap selects and plays `recording.fullAsset(prayer)` on `clipPlayerProvider` (another tap stops and plays the new one), Save writes the prayer's recording column and stops, closing stops (FR-027).
- [X] T068 [P] [US6] Write `lib/features/notifications/presentation/view/widgets/reminder_sheet.dart`: `SheetTitle(reminderBefore)` and the components' slider (Flutter `Slider`, 6 divisions, colors from `ThemeEnum`, value label "{minutes} min" or "Off"), `BmHaptics.selection()` on each step, written to `reminderMinutes` when the sheet closes (data-model.md: "0, 5, 10, 15, 20, 25, 30").
- [X] T069 [P] [US6] Write `lib/features/notifications/presentation/view/widgets/notifications_off_line.dart`: the components' offline banner look with "Notifications are off for this app." and an "Open settings" text button calling `SystemChannel.openNotificationSettings()`.
- [X] T070 [US6] Write `lib/features/notifications/presentation/view/adhan_settings_page.dart`: `CompactAppBar(adhanAndReminders)`, the off line when `NotificationScheduler.isAllowed()` is false (checked on open and on resume with `AppLifecycleListener`), a `GroupedSection` of the five `PrayerSoundRow`s, then the reminder `NavRow` with its value. Each sound change writes at once with `BmHaptics.selection()` (FR-026, FR-029, FR-030).
- [X] T071 [US6] Add `Routes.adhanSettings` as a top level route in `lib/core/router/app_router.dart` and wire More's Adhan and reminders row to it.

**Checkpoint**: every notification choice can be changed from More.

---

## Phase 9: User Story 7 - My data and the credits (Priority: P3)

**Goal**: YOUR DATA with Reset prayer journey, ABOUT with Credits, the licenses and the version.

**Independent Test**: Reset → Reset: nothing logged, no qada, settings kept. Credits: GeoNames
with CC BY 4.0. Version "1.0.0 (n)".

- [X] T072 [P] [US7] Write `test/features/more/data_about_test.dart`: Cancel keeps the log; Reset leaves `prayer_log` and `qada_entries` empty, keeps settings, `firstUse`, azkar counts and saved duas, and hides a showing toast (SC-006); Credits lists GeoNames, the five fonts, the azkar and duas source, the adhan recordings, each with its use, license and link through a mocked system channel; the licenses page lists packages from a fake `LicenseRegistry` entry and opens its text; Version shows the mocked string; Arabic.
- [X] T073 [P] [US7] Write `lib/features/more/model/credits.dart`: the const credits of research R14 (source, `useKey`, license, https link). GeoNames `https://www.geonames.org` CC BY 4.0; Marcellus, Schibsted Grotesk, Reem Kufi, Noto Sans Arabic, Amiri SIL OFL 1.1 with their Google Fonts pages; the azkar and duas source and the adhan recordings with `// TODO(ahmed): ` for the real source, license and link.
- [X] T074 [US7] Add YOUR DATA (Reset prayer journey) and ABOUT (Credits, Open source licenses inside Credits, Version) to `lib/features/more/view/more_page.dart` below SOUND AND TOUCH (FR-031). Reset: `showBmDialog` with the FR-038 copy → `resetPrayerJourney()` → `ScaffoldMessenger.of(context).hideCurrentSnackBar()` (FR-032). Version: `NavRow` with no tap and the value from `SystemChannel.version()` (FR-034).
- [X] T075 [P] [US7] Write `lib/features/more/view/credits_page.dart`: `CompactAppBar(credits)`, a `GroupedSection` with one `NavRow` per credit (source as title, "{use} · {license}" as value, the tap opens the link through `SystemChannel.openUrl`), then a `NavRow` "Open source licenses" (FR-033).
- [X] T076 [P] [US7] Write `lib/features/more/view/licenses_page.dart`: reads `LicenseRegistry.licenses` once, groups by package, a `GroupedSection` of package rows, a tap pushes the license paragraphs in `RegularText(translate: false)` (research R14).
- [X] T077 [US7] Add `Routes.credits` and `Routes.licenses` as top level routes in `lib/core/router/app_router.dart` and wire the Credits row.

**Checkpoint**: everything the spec asks for is built.

---

## Phase 10: Polish & Cross-Cutting Concerns

- [X] T078 [P] Add to the More, theme, calendar, sheets, Adhan and reminders and credits tests: Arabic (Eastern digits, chevrons and arrows mirrored, the calendar from Sunday on the right), text scale 2.0, light and dark, reduce motion on and off (sheets fade in place, the theme switch still crossfades), a tablet width (stretched to 480 pt).
- [X] T079 [P] Write `test/core/resources/contrast_test.dart`: text, text2 and primary on bg and surface, onPrimary on primary, for all 8 themes in both modes, at least 4.5:1 (3:1 for 17 pt and up) (SC-007). If a parked theme fails, stop and tell me which pair; never change a palette value.
- [X] T080 [P] Write `integration_test/more_journey_test.dart` on the design scenario: More → Theme → Iznik → Apply → More says Iznik → Light and dark → Light → Hijri calendar → forward 4 → Ramadan marked → back → Reset prayer journey → Reset → Prayer tab shows "0 of 5 prayed today".
- [X] T081 Run the self check from the `adaptive-widgets` skill on every new and changed file, `flutter test test/architecture_test.dart`, and fix every hit.
- [X] T082 Run `dart format --set-exit-if-changed lib test integration_test`, `flutter analyze` and `flutter test`, all clean.
- [X] T083 Run quickstart.md steps 1 and 2 (1 to 10) on a simulator (design scenario, both languages, both modes), and hand me steps 11 to 14 (a phone for notifications, sounds and Follow sky, and the pages with no PNG) to run myself.
- [X] T084 [P] Update the milestone list in `CLAUDE.md`: "9. More, Theme and Hijri calendar: every setting, the 8 themes with Follow sky, the calendar with its events and adjustment, the Adhan and reminders page, Reset prayer journey and Credits. **Done, waiting for my review.**", and the "as in `HANDOFF_CLAUDE.md`" line starts at 10.
- [X] T085 Run `grep -rn "TODO(ahmed)" lib assets ios android pubspec.yaml` and list in the reply what I have to supply: the five adhan recordings, the three UI sounds, the azkar and duas credit, the adhan recordings' credit.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: T001 first, the constitution before any code. Then T002 to T004.
- **Foundational (Phase 2)**: after Setup. Blocks every story.
- **US1 (Phase 3)**: after Phase 2. The MVP. It builds the More page the other stories wire into.
- **US2 (Phase 4)**: after Phase 2. T041's More wiring after T031.
- **US3 (Phase 5)**: after Phase 2. T044 after T031.
- **US4 (Phase 6)**: after Phase 2. T056's tile wiring after T031.
- **US5 (Phase 7)**: after US4 (it acts on the calendar page and grid).
- **US6 (Phase 8)**: after Phase 2. T071's More wiring after T031.
- **US7 (Phase 9)**: after US1 (it adds sections to the More page).
- **Polish (Phase 10)**: after the stories.

### Inside Phase 2

- T005 to T009 (tests) before their code.
- T012 then T013 (the store needs the enum in core), then T014.
- T015 then T016, then T017 and T018.
- T020 then T021 (the clip player sets `BmSounds.busy`).
- T010, T011, T019, T022 to T027 touch different files and run in parallel.

### Parallel Opportunities

- Phase 2: T005 to T009 together. Then T010, T011, T012, T015, T019, T020, T022 to T027 together.
- US1: T028 to T030 together, then T031 to T034.
- US2: T035 to T039 together, then T040, T041.
- US4: T045 to T050 together, then T051, then T052 to T054 together, then T055, T056.
- US5: T057 to T059 together, then T060.
- US6: T061, T062, T066 to T069 together after T063 to T065.
- US7: T072, T073, T075, T076 together, then T074, T077.
- Polish: T078, T079, T080, T084 together.

## Parallel Example: Phase 2

```text
Task: "T010 method sheet to core"
Task: "T011 HomeSamples to core"
Task: "T015 BmPalette.lerp"
Task: "T019 system channel, Dart, Swift, Kotlin"
Task: "T022 strings in strings_manager.dart and both arb files"
Task: "T024 NavRow"  "T025 GroupedSection"  "T026 Segmented"  "T027 BmDialog"
```

## Implementation Strategy

### MVP First (User Story 1)

1. Phase 1 (constitution, branch, sounds), then Phase 2.
2. US1: More with every setting. Stop and check the design scenario (More next to 4.09) and a
   real phone (haptics off, reduce motion on).

### Incremental Delivery

1. US1 → More and its toggles.
2. US2 → the theme page.
3. US3 → the Light and dark sheet.
4. US4 → the calendar.
5. US5 → the day sheet and the adjustment.
6. US6 → Adhan and reminders.
7. US7 → reset and credits.
8. Polish → languages, text scale, contrast, checks, CLAUDE.md. Then stop for my review
   (constitution workflow).
