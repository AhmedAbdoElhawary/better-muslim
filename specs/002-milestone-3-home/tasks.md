---

description: "Tasks for milestone 3, Home"
---

# Tasks: Milestone 3, Home

**Input**: Design documents from `specs/002-milestone-3-home/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/core-additions.md,
quickstart.md

**Tests**: Included. Constitution VI asks for unit tests on logic and widget tests on screens.
Integration tests wait for milestone 10 (plan decision 6).

**Organization**: Grouped by user story, so each story can be built and checked on its own.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an unfinished task)
- **[Story]**: The user story the task belongs to (US1 to US5)

## Before starting

- Milestone 2 is committed and `feature/milestone-3` is cut from it.
- `.specify/feature.json` is shared with other sessions. Run speckit commands for this folder with
  `SPECIFY_FEATURE_DIRECTORY=specs/002-milestone-3-home`.
- Decided 2026-10-17:
  - `useAuto()` asks and reports back (R12)
  - power saving is a method channel, no package (R7)
  - `prayerDayProvider` and `prayedProvider` are built here with milestone 4's contract (R2)
- Decided 2026-10-18:
  - `MediaQuery.of` is allowed in `lib/core/app/app.dart` only, for the reduce motion flag (R4)
  - the no-location card uses a new core button (R12)
  - integration tests wait for milestone 10 (R17)
- Every UI file follows the `adaptive-widgets` rules and the spec-to-code table in `CLAUDE.md`.
  `flutter test test/architecture_test.dart` stays green.
- Layout values come from `design_handoff_better_muslim/specs/screens/4.01-home.md`,
  `4.02-home-light.md` and `4.16-home-ar.md`. Motion values come from `MOTION.md`.

---

## Phase 1: Setup

**Purpose**: Strings and design system entries that every story uses

- [X] T001 [P] Add the 15 keys from `contracts/core-additions.md` § Strings to
  `lib/core/resources/strings_manager.dart`, `assets/l10n/app_en.arb` and `assets/l10n/app_ar.arb`
  (`fajrAr` … `ishaAr`, `ishaLabel`, `fajrLabel`, `morningAzkar`, `morningAzkarSub`,
  `timeLeftSemantics`, `searchCity`, `noPlacesFound`, `locationFailed`, `noLocationBody`), with
  `@` placeholder entries for `{time}`, `{done}`, `{total}`, `{hours}`, `{minutes}`, `{prayer}`.
  `test/core/resources/strings_manager_test.dart` must pass.
- [X] T002 [P] In `lib/core/resources/theme_manager.dart`:
  - add to `ThemeEnum`, resolved to constants:
    - `onSkyBright` → `Color(0xEBFFFFFF)`
    - `skyScrim` → `Color(0x47000000)`
    - `glass` → `Color(0x6607100D)`
    - `glassHighlight` → `Color(0x1AFFFFFF)`
  - add `double get starOpacity => bm.starOpacity;` to `ThemeExtension`

  The values are from `bm_sky.dart`'s notes and the 4.01 pill.
- [X] T003 [P] In `lib/core/resources/font_manager.dart`:
  - add `FontEnum.quran(latin: FontFamilyManager.quran, arabic: FontFamilyManager.quran)` with a
    `TODO(ahmed)` above it: production needs KFGQPC Hafs once licensed
  - add the Home values that have no entry:
    - `FontSizeManager.skyLabel` 11 (arc labels)
    - `FontSizeManager.cardNote` 12.5 (adhan line)
    - `FontSizeManager.nextPrayerAr` 16 (the Arabic name on the card)
    - `LineHeightManager.cardTitleAr` 1.2 (4.16 card title)
    - `LineHeightManager.verseTranslation` 1.5

  Reuse the rest: `overline` 11.5 with `LetterSpacingManager.overline` (NOW), `hero` / `heroAr`,
  `accentAr` 22, `cardTitle`, `countdown`, `quranAr` 26 / 2.2, `caption`, `label`.
  `font_manager_test.dart` must stay green.
- [X] T004 [P] Add a named entry to `lib/core/resources/dimensions_manager.dart` for every Home
  number from the three trees that `SpaceManager`, `RadiusManager` and `SizeManager` don't already
  hold. These include:
  - `homeCardOverlap` 60, `homeGlowInset` 18, `homeGlowBlur` 6
  - `locationPillHeight` 32, `prayerBarHeight` 3
  - `shortcutIconBox` 40, `stripCellGap` 4, `skyTextTop` 62, `nowTop` 22 / 18 (Arabic)
  - the card paddings 16 / 18 and 14 / 18
  - the arc label offsets 94 / 14 / 100

  Reuse the existing entries: radius 20 = `RadiusManager.lg`, 14 = `md`, row 64 =
  `SizeManager.linkRow`, sky 380 = `homeSkyHeight`, button 52 = `buttonLarge`.
- [X] T005 [P] Add `bool tabularFigures = false` to the weight text widgets in
  `lib/core/widgets/adaptive/text/*.dart`. It passes `FontFeature.tabularFigures()` through
  `_AdaptiveText` into `GetTextStyle` (R10). Add `fontFeatures` to `GetTextStyle` in
  `lib/core/resources/styles_manager.dart` if it lacks it.
- [X] T006 [P] Add `bool get isLargeText => MediaQuery.textScalerOf(this).scale(1) > 1.4;` to
  `lib/core/extensions/window_size.dart`, with a one-line `///` saying the countdown and the prayer
  rows stack above it (R15).

---

## Phase 2: Foundational

**Purpose**: Core changes and the Home samples that every story stands on

**⚠️ CRITICAL**: No story work starts before this phase is done

- [X] T007 Write `test/core/clock/clock_test.dart`:
  - with a fake clock at 10:00:00.700 the first tick after the initial value comes at 10:00:01.000
  - later ticks land on whole seconds with no drift over 5 minutes of `fakeAsync`
- [X] T008 Change `tickerProvider` in `lib/core/clock/clock.dart` to tick on the wall clock's
  whole second. It yields `clock()` first, then re-arms a `Timer` for `1000 - now.millisecond` ms
  after every tick, and cancels it in `ref.onDispose` (R5). T007 passes.
- [X] T009 [P] Write `test/core/prayer_times/prayer_day_test.dart` for `prayerDayProvider`:
  - 03:00 before today's Fajr gives yesterday
  - Fajr and later give today
  - 23:59 gives today
  - it notifies once at Fajr, not every second
  - with no location it is the location-free local date
- [X] T010 Add `prayerDayProvider` (`Provider<DateTime>`) to
  `lib/core/prayer_times/prayer_times_providers.dart`, exactly as milestone 4's
  `contracts/prayer-log.md` describes. It is the location's date, or yesterday before today's
  Fajr (a null Fajr counts as no Fajr yet). It follows `tickerProvider` and notifies only on a
  change. T009 passes.
- [X] T011 [P] Create `lib/core/prayer_log/prayer_log.dart` with
  `prayedProvider = Provider.autoDispose.family<Set<Prayer>, DateTime>((ref, day) => const {})`,
  and a plain `TODO:` that milestone 4 fills it from the store.
- [X] T012 [P] Add `final String nameArKey` to `Prayer` and `Period` in
  `lib/core/prayer_times/day_times.dart`, set to the `fajrAr` … `ishaAr` keys (R13).
- [X] T013 Update the design scenario (R3):
  - in `lib/core/prayer_times/prayer_times_providers.dart`, move `dayTimesProvider`'s body into a
    top-level `DayTimes? computeDayTimes(Ref ref, DateTime date)` that the provider calls
  - in `lib/core/flavor/design_scenario.dart`, replace the `todayTimesProvider` override with
    `dayTimesProvider.overrideWith((ref, date) => ...)`: the handoff's six times for
    15 Oct 2026, `computeDayTimes(ref, date)` for every other date
  - add a `prayedProvider` override giving `{Prayer.fajr, Prayer.dhuhr}` for 15 Oct 2026

  Update `test/core/flavor/` so it checks that `todayTimesProvider`,
  `dayTimesProvider(prayerDay)` and `prayedProvider(prayerDay)` give the handoff's values, and that
  16 Oct 2026 is computed.
- [X] T014 Make the in-app reduce motion switch reach every widget (R4):
  - in `lib/core/app/app.dart`, wrap the router child in
    `MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: ...))`, where the value
    is `MediaQuery.disableAnimationsOf(context) || reduceMotion` and `reduceMotion` comes from
    `settingsProvider.select((settings) => settings.value?.reduceMotion ?? false)`
  - add `allowedIn: ['lib/core/app/app.dart']` to the `MediaQuery.of` rule in
    `test/architecture_test.dart`, with a one-line `///` above the path constant: the app root
    copies the data once, nothing below it rebuilds for it
  - remove the reduce motion `TODO:` in `lib/core/widgets/shell/tab_switcher.dart`
  - add a case to `test/app_test.dart`: the setting on gives `disableAnimations` true below the
    router
- [X] T015 [P] Create `lib/features/home/model/home_samples.dart` (R14) with:
  - the verse: reference `Al-Fatiha 1:5` / `الفاتحة ٥`, the Arabic text, the English translation,
    with a `TODO(ahmed)` above it: replace with the Quran dataset in milestone 7, the text must
    match the licensed mushaf
  - continue reading `Al-Fatiha` / `الفاتحة`, ayah 3 of 7 (`TODO:` milestone 7)
  - azkar 0 of 24 evening, 0 of 12 morning (`TODO:` milestone 8)
  - reminder 10 minutes (`TODO:` milestone 5)

**Checkpoint**: core is ready, `flutter test` green, the dev readout still works.

---

## Phase 3: User Story 1 - Where am I in the day (Priority: P1) 🎯 MVP

**Goal**: Home shows NOW, the next prayer with a live countdown, the bar, the glow and the
strip, in English and Arabic, matching 4.01, 4.02 and 4.16 in the design scenario

**Independent Test**: Run "Dev · design scenario", put Home next to the three PNGs: same within 1
pt, countdown at 1:24:00. In a normal dev run the countdown ticks with the phone clock.

### Tests for User Story 1

- [X] T016 [P] [US1] Write `test/features/home/model/home_moment_test.dart` for the US1 functions:
  - **bar share** at 16:32 on the scenario day is 0.436 (Asr 15:27 → Maghrib 17:56), from
    sunrise during Duha, and from yesterday's Isha before Fajr
  - **countdown parts**: 1:24:00, 10:05:09, and rounding of 1:23:58.997 to 1:23:59
  - **glow window**: on at 9:59 and 10:00 left, off at 10:01 and at 0
  - **strip cell state**: logged, current with dot, current logged, plain, no current during Duha
  - **a polar day**: a null time gives no bar share for that period
- [X] T017 [P] [US1] Write `test/features/home/view/home_page_test.dart` (design scenario
  overrides, 393 x 852, 24 hour):
  - **English**: shows NOW, "Asr", "العصر", "Until Maghrib at 17:56", "Next prayer", "Maghrib",
    "1:24:00", "Adhan at 17:56 · reminder 10 min before", the five times, checks on Fajr and
    Dhuhr only, Asr highlighted
  - **Arabic**: the same in Arabic with Eastern digits, no "العصر" second name
  - **a ticking clock override**: the countdown drops by one per second, and at 17:56:00 NOW
    becomes Maghrib and the next prayer Isha
  - **Duha** (09:00): NOW is Duha and no cell is highlighted
  - **after Isha** (21:00): the next prayer is Fajr
  - **a polar day** with a null Isha: the Isha cell shows "—"
  - **settings and location changes** (FR-007): changing the location, the method, the Hijri
    adjustment or the digits setting updates the times, the date line and the digits without
    leaving Home
  - **dark and light** both build without errors

### Implementation for User Story 1

- [X] T018 [US1] Add to `lib/features/home/model/home_moment.dart` the pure functions from
  `data-model.md`: `barShare`, `periodStart`, `countdownParts`, `glowBreathing`, `stripCellState`
  (enum `StripCell { plain, current, logged }` plus the dot flag). T016 passes.
- [X] T019 [US1] Create `lib/features/home/view_model/home_providers.dart`. Each slice notifies
  only on a change (data-model "Home view state"):
  - `timeLeftProvider`: Duration, every second
  - `glowBreathingProvider`: bool
  - `stripProvider`: five records of prayer, time (null when not available), `StripCell` and dot,
    from `dayTimesProvider(prayerDay)`, `prayedProvider(prayerDay)` and `periodProvider`
- [X] T020 [US1] Delete `lib/features/home/view/widgets/dev_readout.dart` and
  `test/features/home/dev_readout_test.dart` (spec FR-002). Remove `isDev` from `home_page.dart`.
- [X] T021 [P] [US1] Create `lib/features/home/view/widgets/sky_header.dart`. It paints
  `SkyHeaderPainter` still: theme base stops from `ThemeEnum.sky1/2/3`, drift 0, stars at
  `context.starOpacity`, twinkle 1, the sun from `BmSunArc.fraction`. It sits inside a
  `RepaintBoundary`, in `Directionality(ltr)`, with `rtl` taken from the app's direction.
- [X] T022 [P] [US1] Create `lib/features/home/view/widgets/date_line.dart`:
  - English: "Thu 15 Oct · 4 Jumada I 1448", from `DateFormat('EEE d MMM')`
  - Arabic: "الخميس · ٤ جمادى الأولى ١٤٤٨", from the full weekday
  - Hijri from `hijriDateProvider(todayProvider)` and its month key, digits through
    `context.formatDigits`, 13 pt, `translate: false`
- [X] T023 [P] [US1] Create `lib/features/home/view/widgets/location_pill.dart`, showing only (the
  tap comes in US4):
  - the glass pill: height 32, `ThemeEnum.glass`, blur `BmGlass.blurSigma`, a 1 px
    `glassHighlight` top line
  - `BmIcon(BmIconName.location)` at 18
  - the place name in the app's language (`placeNameAr` in Arabic when set)
  - padding 0 10 0 6, mirrored in Arabic
  - the pill sits centered in a hit area at least `SizeManager.hit` (44) tall, so the 32 pt
    drawing keeps its place and the tap target meets 44 x 44
- [X] T024 [P] [US1] Create `lib/features/home/view/widgets/now_block.dart`:
  - English: "NOW" overline 11.5 with letter spacing .14em at 85%, then the period name in
    Marcellus 52 / 1.1, the Arabic name (`nameArKey`) in Reem Kufi 22 at 85% with a 12 gap on
    the baseline, then "Until {prayer} at {time}" 13 at 85%
  - Arabic, as in 4.16: "الآن" 13, the name 52 / 1.35, then the "until" line with the time in an
    LTR span
- [X] T025 [P] [US1] Create `lib/features/home/view/widgets/countdown.dart` and
  `countdown_digit.dart` (Motion 04, R10):
  - `h:mm:ss` from `timeLeftProvider`, 26 / 500, `primary`, `tabularFigures`
  - each digit an `AnimatedSwitcher` + `SlideTransition` upwards in a `ClipRect`, 300 ms
    `BmMotion.standardCurve`
  - zero duration when `MediaQuery.disableAnimationsOf`
  - wrapped in `Directionality(ltr)`, Eastern digits in Arabic
- [X] T026 [P] [US1] Create `lib/features/home/view/widgets/prayer_bar.dart`: 3 pt,
  radius 2, `variant` track, `primary` fill at `barShare`, never mirrored.
- [X] T027 [P] [US1] Create `lib/features/home/view/widgets/card_glow.dart` (R11):
  - always: a radial `glow` 55% → transparent at 72%, inset −18, radius 36, blur 6
  - while `glowBreathingProvider` is true: opacity .45 → 1 and scale .98 → 1.03, an
    `AnimationController` with `BmMotion.glowLoop` and `repeat(reverse: true)` on
    `BmMotion.breathe`
  - with reduce motion: still
- [X] T028 [US1] Create `lib/features/home/view/widgets/next_prayer_card.dart` from the 4.01 and
  4.16 trees:
  - glow behind
  - `surface`, radius 20, 1 px `outline`, padding 16 18, gap 9 (Arabic 14 18 16, gap 8)
  - row 1: "Next prayer" 12 text2 + the Arabic name in Reem Kufi 16 (English only)
  - row 2: the name in Marcellus 32 / 1 + the countdown
  - the bar
  - the adhan line: `BmIcon(BmIconName.adhan)` 16 + "Adhan at {time} · reminder {minutes} min
    before", 12.5 text2, minutes from `home_samples.dart`, the time in an LTR span in Arabic
- [X] T029 [US1] Rewrite `lib/features/home/view/home_page.dart`:
  - `AnnotatedRegion` with light status bar icons
  - one vertical scroll view holding:
    - the 380 pt sky area with `SkyHeader` (T021) and the header text block
    - the next-prayer card pulled up by `homeCardOverlap`
    - the strip
    - a slot for the verse and shortcuts (US3)
  - bottom padding so the content clears the nav bar
- [X] T030 [P] [US1] Create `lib/features/home/view/widgets/strip_cell.dart` and
  `prayer_strip.dart`:
  - 5 equal columns, gap 4, margin 16 14 0
  - each cell: padding 10 0 8, radius 14, name 12 text2, time 15 / 500 `tabularFigures`
    (text2 when logged or past, "—" when the time is null), a 12 pt slot with the success check
    `BmIcon.ui(BmUiIcon.check)` 12 or the 5 pt `onPrimaryContainer` dot
  - the current cell: `primaryContainer` with an inset 1 px `primary` at 35%, name 600
    `onPrimaryContainer`
  - times are LTR in Arabic
- [X] T031 [US1] Put the pieces into `home_page.dart`: sky with the pill, date line and NOW block
  (top 62, sides 14 / 20, mirrored in Arabic), card, strip. T017 passes for everything except the
  verse and shortcuts.

**Checkpoint**: US1 matches the PNGs above the verse card in the scenario, and ticks in a dev run.

---

## Phase 4: User Story 2 - The sky follows the real sun (Priority: P1)

**Goal**: the Living Sky with live states, the sun, stars by night, the sky change and the
ambient loop, paused when it should be

**Independent Test**: Set the clock to a time in each of the six periods. The sky shows the
matching state and the sun sits at its share of the day. The loop stops with reduce motion,
another tab or power saving.

### Tests for User Story 2

- [X] T032 [P] [US2] Add to `test/features/home/model/home_moment_test.dart`:
  - sky state for each period
  - stars on for fajr, maghrib and isha only (and always in theme base)
  - sun share at sunrise 0, at Maghrib 1, null at night, rounded to 0.001
  - arc labels Sunrise / Maghrib by day, Isha / Fajr by night with the prayer day's Isha after
    midnight, and no label for a time that is null
- [X] T033 [P] [US2] Write `test/features/home/view/sky_contrast_test.dart` (SC-006, FR-012). For
  each of the six `bmSkyQiyamEmerald` states, and the theme base sky in dark and light, the header
  text color must reach WCAG AA (4.5:1) against the darkest and lightest point behind the text
  block. That is `onSkyBright` over the `skyScrim` on bright states and `onSky` elsewhere. The
  contrast math stays in the test file.
- [X] T034 [P] [US2] Write `test/features/home/view/sky_header_test.dart`:
  - in a live run at 16:32 the painter gets the asr stops and no stars, at 21:00 the isha stops
    with stars and no sun
  - passing 17:56 starts a 1800 ms change (300 ms with reduce motion)
  - with reduce motion, with `powerSavingProvider` true, or under `TickerMode(enabled: false)`
    no ticker is active (`tester.binding.hasScheduledFrame` stays false)
  - the design scenario uses the theme base stops
- [X] T035 [P] [US2] Write `test/core/power/power_saving_test.dart`: a mocked
  `better_muslim/power` channel returns true or false, a missing handler returns false.

### Implementation for User Story 2

- [X] T036 [US2] Add `skyState`, `starsOn`, `sunShare` and `arcLabels` to
  `lib/features/home/model/home_moment.dart` (data-model, R8). T032 passes.
- [X] T037 [P] [US2] Create `lib/core/power/power_saving.dart` (R7):
  - a `MethodChannel('better_muslim/power')` call `isPowerSaving`
  - `powerSavingProvider`, a `FutureProvider<bool>` that falls back to false on a
    `MissingPluginException` or `PlatformException`
  - re-read on resume with an `AppLifecycleListener` that invalidates it

  T035 passes.
- [X] T038 [P] [US2] Add the `better_muslim/power` handler to `ios/Runner/AppDelegate.swift`, next
  to `registerBackupExclusion`. It returns `ProcessInfo.processInfo.isLowPowerModeEnabled`.
- [X] T039 [P] [US2] Add the `better_muslim/power` handler to
  `android/app/src/main/kotlin/com/elhawary/bettermuslim/MainActivity.kt` in
  `configureFlutterEngine`. It returns `getSystemService(PowerManager::class.java).isPowerSaveMode`.
- [X] T040 [US2] Add `skyStateProvider` (null without a location), `starsOnProvider` and
  `sunShareProvider` to `lib/features/home/view_model/home_providers.dart`. Each notifies only on
  a change.
- [X] T041 [US2] Extend `lib/features/home/view/widgets/sky_header_painter.dart` (R6):
  - the RTL star list from 4.16 (10 stars) next to the LTR one (9)
  - a `starsStrength` 0..1
  - twinkle, drift and sun pulse worked out from an elapsed `Duration` with MOTION.md's numbers
    and `BmMotion.breathe`
  - `repaint` from a `ValueListenable<Duration>`
  - `shouldRepaint` true only when an input changed
- [X] T042 [US2] Make `lib/features/home/view/widgets/sky_header.dart` live (R6, R8):
  - **Ticker**: one `Ticker` that writes elapsed time into a `ValueNotifier` at most every
    33 ms. It is not started under reduce motion or with `powerSavingProvider` true.
    `TickerMode` already stops it on other tabs.
  - **Fade back**: a 300 ms strength 0 → 1 when the loop starts again.
  - **Sky change**: a `TweenAnimationBuilder<BmSkyStops>` over `bmSkyQiyamEmerald[state]`,
    `BmMotion.skyChange` with `BmMotion.sacred`, or 300 ms linear with reduce motion. The stars'
    strength rides on the same animation.
  - **Theme base** when `flavorProvider.select((config) => config.isDesignScenario)` is true.

  T034 passes.
- [X] T043 [P] [US2] Create `lib/features/home/view/widgets/sky_labels.dart`:
  - positions from `sky_header_painter.dart`'s notes: LTR at top 306, start 94 and end 14; RTL at
    top 300 with line height 1.2, left 14 and right 100
  - 11 pt at 85%, `tabularFigures`
  - by day "Sunrise {time}" / "Maghrib {time}", by night "Isha {time}" / "Fajr {time}"
  - no label without a location or for a time that is null
- [X] T044 [US2] Use the sky state for the header text in `location_pill.dart`, `date_line.dart`,
  `now_block.dart` and `sky_labels.dart` (R9). With `bmSkyIsBright(state)` the text is
  `onSkyBright` with a `skyScrim` gradient (0 → 28%) behind the text block, otherwise `onSky`.
  T033 passes.
- [X] T045 [US2] In `home_page.dart`, fill the top overscroll with the sky's top color, so iOS
  bounce never shows the page background above the sky (R16).

**Checkpoint**: the sky follows the time in a dev run, the scenario still matches the PNGs.

---

## Phase 5: User Story 3 - One tap to what I need (Priority: P2)

**Goal**: the verse card, the shortcuts with the morning or evening row, and the tab taps

**Independent Test**: Tap every card and row and check the tab. At 08:00 the row says morning, at
16:32 evening. In Arabic only Continue reading shows.

### Tests for User Story 3

- [X] T046 [P] [US3] Add the azkar window to `home_moment_test.dart`: morning for fajr, duha and
  dhuhr, evening for asr, maghrib, isha and null.
- [X] T047 [P] [US3] Add to `home_page_test.dart`:
  - the verse card in English (reference, Arabic text, translation) and in Arabic (no
    translation)
  - "Continue reading" with "Al-Fatiha · ayah 3 of 7"
  - "Evening azkar · After Asr · 0 of 24" at 16:32, "Morning azkar · After Fajr · 0 of 12" at
    08:00
  - no azkar row in Arabic
  - taps on the card, a strip cell, the verse, Continue reading and the azkar row land on
    `Routes.prayer`, `prayer`, `quran`, `quran`, `azkar`

### Implementation for User Story 3

- [X] T048 [US3] Add `azkarWindow` to `home_moment.dart` and `azkarWindowProvider` to
  `home_providers.dart`. T046 passes.
- [X] T049 [P] [US3] Create `lib/features/home/view/widgets/verse_card.dart` from the trees:
  - `surface`, radius 20, outline
  - padding 14 18 16 (Arabic 12 18 10)
  - "Verse of the day" 12 text2 and the reference 12 / 500 `accent`
  - the verse in `FontEnum.quran` 26 / 2.2, centered, RTL, `translate: false`, never animated
  - the translation 13 / 1.5 text2, English only
- [X] T050 [P] [US3] Create `lib/features/home/view/widgets/shortcut_row.dart` and
  `shortcuts_card.dart`:
  - each row: 64 pt, gap 14, padding 0 16, a 40 pt `primaryContainer` box radius 12 with the
    `onPrimaryContainer` icon at 20, a title 15 / 500 over a subtitle 13 text2, and the forward
    chevron at 18 `text3`
  - mirrored in Arabic
  - the card holds Continue reading (`BmIconName.quran`) and the azkar row (`BmIconName.azkar`,
    morning or evening from `azkarWindowProvider`)
  - Arabic shows only Continue reading
- [X] T051 [US3] Add the taps with `context.go`:
  - the card and every strip cell → `Routes.prayer`
  - the verse and Continue reading → `Routes.quran`
  - the azkar row → `Routes.azkar`

  Add each tap area of at least 44 x 44. Put the verse and shortcuts into `home_page.dart`.
  T047 passes.

**Checkpoint**: the whole of 4.01, 4.02 and 4.16 matches in the scenario.

---

## Phase 6: User Story 4 - Set or change my location from Home (Priority: P2)

**Goal**: the location sheet, `useAuto()` that asks and reports, and the no-location state

**Independent Test**: Deny location, open Home: no times, "No location yet", the card with both
choices. In airplane mode search "Tanta" and pick it: Home shows Tanta.

### Tests for User Story 4

- [X] T052 [P] [US4] Add to `test/core/location/location_controller_test.dart` for `useAuto()`:
  - denied with a saved manual place: it asks; allowed with a fix → true, auto, the new place
  - denied after asking → false, mode and place unchanged
  - denied forever → false without asking
  - no fix → false, unchanged
  - `refresh()` still never asks with a saved location
- [X] T053 [P] [US4] Write `test/features/home/view/location_sheet_test.dart` with a fake place
  list and position source:
  - the pill opens the sheet, and its tap area is at least 44 x 44
  - "tanta" and "طنطا" list Tanta with its region and country
  - "zzz" shows "No places found"
  - picking a result calls `choose` and closes the sheet
  - "Use my location" returning false shows `locationFailed` and keeps the sheet open
  - returning true closes it
- [X] T054 [P] [US4] Add to `home_page_test.dart` with no location: the sky has no sun and no
  labels, the pill says "No location yet", the date line shows, the no-location card has both
  choices, there is no NOW block and no strip, and the verse and shortcuts still show.

### Implementation for User Story 4

- [X] T055 [US4] Change `useAuto()` in `lib/core/location/location_controller.dart` to
  `Future<bool>` (R12, contract):
  - it reads the permission and asks when it is `denied`, whatever is saved
  - it returns false for anything but `whileInUse` / `always`, or when `fix()` is null, with
    nothing written
  - on success it saves the place as auto (`_save(..., LocationMode.auto)`)

  Keep `refresh()` as it is. T052 passes.
- [X] T056 [P] [US4] Create `lib/core/widgets/sheet/bm_sheet.dart`:
  - `showBmSheet<T>(BuildContext context, {required WidgetBuilder builder})` over
    `showModalBottomSheet`
  - `sheetAnimationStyle` from `BmMotion` (in: spring gentle ≈520 ms, out: 300 ms accelerate,
    reduce motion: 150 ms)
  - the scrim at `BmOpacity.scrimDark` or `scrimLight`
  - a `RadiusManager.sheet` top, a grabber, `BmHaptics.selection()` on a detent
  - a one-line `///` naming Motion 15
- [X] T057 [P] [US4] Create `lib/core/widgets/search_field.dart` from 4.14's field:
  - 46 pt, radius 14, `surface`, 1 px `outline`
  - `BmIcon.ui(BmUiIcon.search)` 20 `text2`, gap 10
  - a borderless `TextField` styled with `GetTextStyle(...)` from `styles_manager.dart` (15,
    `text`; hint 15 `text2`), with `contentPadding: EdgeInsets.zero`, inside a
    `SymmetricPadding(horizontal: SpaceManager.fieldSide)`
  - new manager entries for its own numbers: `SizeManager.searchField` 46, `SpaceManager.fieldSide`
    14, `SpaceManager.fieldIconGap` 10 (radius 14 is `RadiusManager.md`)
  - it takes `hint` (a StringsManager key, translated with `context.tr`) and `onChanged`, and is
    RTL aware

  This stays inside the architecture test's rules with no allow-list change.
- [X] T058 [P] [US4] Create `lib/core/widgets/bm_button.dart` (R12) from 4.11's two buttons:
  - `BmButton.primary`: 52 pt (`SizeManager.buttonLarge`), radius 14, `primary` fill,
    `onPrimary` 15 / 500
  - `BmButton.secondary`: the same with no fill, an inset 1 px `outlineStrong` border and `text`
    15 / 500
  - full width, a StringsManager key for the label, `onPressed`
  - a pressed overlay at `BmOpacity.pressed`
  - a `busy` flag that ignores taps and dims the label

  The adhan screen (5) and onboarding (10) use it too.
- [X] T059 [US4] Create `lib/features/home/view/widgets/location_sheet.dart`:
  - "Location" title 17 / 600
  - a "Use my location" row (`BmIconName.location`, 52 pt list row)
  - `SearchField(hint: StringsManager.searchCity)`
  - results from `placeListProvider` → `search(query)`, each row the name (Arabic in Arabic
    when set) over "region · country" 13 text2, at least 52 pt tall
  - "No places found" when empty
  - `locationFailed` 13 `error` under the use row when `useAuto()` returned false
  - while `useAuto` runs, the row shows it is busy and ignores taps
- [X] T060 [P] [US4] Create `lib/features/home/view/widgets/no_location_card.dart`: a `surface`
  card, radius 20, with `noLocationBody`, then
  `BmButton.primary(StringsManager.useMyLocation)` and
  `BmButton.secondary(StringsManager.chooseCity)`, gap 12. Both open the location sheet, the first
  also starts `useAuto()`.
- [X] T061 [US4] Wire it up in `home_page.dart` and `location_pill.dart`:
  - the pill opens `showBmSheet` with the location sheet
  - with `locationProvider` null the page shows the no-location layout, and the pill shows
    `noLocationYet`

  T053 and T054 pass.

**Checkpoint**: the city can be changed offline from Home, and a denied phone gets a clear way in.

---

## Phase 7: User Story 5 - Readable for everyone (Priority: P3)

**Goal**: stacked layouts above 1.4, 12 hour times that fit, the screen reader label, nothing
clipped at 2.0

**Independent Test**: Home at text scale 1.0, 1.5 and 2.0, on a 12 hour phone, with VoiceOver or
TalkBack, and with reduce motion on.

### Tests for User Story 5

- [X] T062 [P] [US5] Add to `home_page_test.dart` (scenario, English and Arabic):
  - at text scales 1.5 and 2.0 there are no overflow errors, the countdown sits under the prayer
    name, and the strip is five rows
  - 12 hour at 1.0 has no overflow in the strip, the card or the arc labels, and the strip is
    rows at 1.1
  - the countdown's semantics label is "1 h 24 min until Maghrib" and is not a live region
  - with reduce motion the digits change with no running animation

### Implementation for User Story 5

- [X] T063 [US5] In `next_prayer_card.dart`, stack row 2 when `context.isLargeText`: the name,
  then the countdown under it, start-aligned.
- [X] T064 [US5] Create `lib/features/home/view/widgets/strip_row.dart`:
  - a full-width row with the name at the start, the time (or "—") at the end, then the check or
    dot
  - the same current highlight, at least 44 pt tall

  In `prayer_strip.dart`, show five rows when `context.isLargeText`, or when the phone is 12 hour
  and the text scale is above 1.0 (R15).
- [X] T065 [US5] Wrap the countdown in `Semantics(label: timeLeftSemantics, excludeSemantics:
  true)`, with hours and minutes from `countdownParts` and the next prayer's name.
- [X] T066 [US5] Let the sky area grow at large text in `home_page.dart` and `sky_header.dart`:
  - at least `homeSkyHeight`, taller when the header text block needs it
  - the horizon and arc keep their distance from the top
  - the card overlap stays 60

  T062 passes.

**Checkpoint**: every look from the definition of done works.

---

## Phase 8: Polish & Cross-Cutting Concerns

- [X] T067 Run `flutter test test/architecture_test.dart` and the adaptive-widgets greps on
  `lib/features/home/` and the new core files, and fix every hit.
- [X] T068 Run `dart format --set-exit-if-changed lib test`, `flutter analyze` and `flutter test`,
  and fix everything.
- [ ] T069 Run `specs/002-milestone-3-home/quickstart.md` on the iOS simulator and an Android
  emulator: the PNG comparison and every live check. Take screenshots of Home on phone and tablet,
  dark and light, English and Arabic, in the design scenario (constitution workflow).
- [ ] T070 Measure, and write in the milestone reply:
  - start to times on screen with a saved location (SC-004)
  - frame times while scrolling and with the sky running, on a mid-range phone, including the
    pill's blur over the moving sky (SC-007)
  - the sky's CPU when on another tab or in the background
- [ ] T071 [P] Mark milestone 3 as "Done, waiting for my review." in `CLAUDE.md`.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: none. T001 to T006 touch different files.
- **Foundational (Phase 2)**: after Setup, and it blocks every story.
  - T008 needs T007, and T010 needs T009 and T008.
  - T013 needs T010 and T011.
  - T014 and T015 stand alone.
- **US1 (Phase 3)**: after Foundational.
  - T029 needs T021.
  - T031 needs T021 to T030.
- **US2 (Phase 4)**: after US1, since it makes US1's still sky live and colors US1's header text.
  T035 and T037 to T039 can start right after Foundational.
- **US3 (Phase 5)**: after US1, because it adds the taps to US1's card and strip. The verse and
  shortcut widgets (T049, T050) can be built after Foundational.
- **US4 (Phase 6)**: after US1. T052, T055, T056, T057 and T058 can start after Foundational.
  T060 needs T058.
- **US5 (Phase 7)**: after US1 and US3, which build the widgets it reshapes.
- **Polish (Phase 8)**: after all stories.

### Within Each Story

Tests first and failing, then the model, the providers, the widgets, and the page wiring last.

## Parallel Examples

```text
# Setup, all together:
T001 strings | T002 theme_manager | T003 font_manager | T004 dimensions | T005 text widgets | T006 window_size

# Foundational:
T007 → T008 | T009 → T010 | T011 prayer_log | T012 day_times | T014 app | T015 samples

# US1 widgets together, after T018 and T019:
T021 sky_header | T022 date_line | T023 location_pill | T024 now_block | T025 countdown | T026 prayer_bar | T027 card_glow | T030 strip

# US2 next to US1:
T035 → T037 power_saving | T038 AppDelegate | T039 MainActivity | T033 contrast test

# US4 core pieces next to US1:
T052 → T055 useAuto | T056 bm_sheet | T057 search_field | T058 bm_button
```

## Implementation Strategy

### MVP First (User Story 1)

1. Phase 1 and Phase 2.
2. Phase 3 (US1): Home with live values on a still sky. It matches the PNGs above the verse card.
3. Stop and check against 4.01, 4.02 and 4.16.

### Incremental Delivery

US1 (live values) → US2 (Living Sky) → US3 (verse, shortcuts, taps) → US4 (location sheet, no
location) → US5 (large text, 12 hour, screen readers) → Polish. Each step keeps the earlier ones
green.
