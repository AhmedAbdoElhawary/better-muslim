# Research: Milestone 3, Home

Checked on 2026-10-17 against the code from milestones 1 and 2, the handoff, and the milestone 4,
5, 7 and 8 specs written the same day, so Home leaves the right seams for them.

## R1. Where Home's code lives

- **Decision**: Home is MVVM (constitution I):
  - `model/`: pure functions with no Flutter, like the bar share, the azkar window and the glow
    window.
  - `view_model/`: Riverpod providers built from core's providers.
  - `view/`: the widgets.

  The sky painter and the location sheet stay in `features/home/` until a second feature needs
  them (Welcome in 10, Theme preview in 9, More › Location in 9). Then they move to `core/`.
- **Rationale**: one user today. A move later is cheap, a shared component nobody else uses yet is
  a guess.
- **Alternatives**: the sky in `core/widgets/` now (rejected, no second user yet).

## R2. Prayer day and log seams for milestone 4

- **Decision**: milestone 3 adds two of milestone 4's core providers, with the exact names and
  types from `specs/002-milestone-4-prayer/contracts/prayer-log.md`:
  - `prayerDayProvider` (`Provider<DateTime>`, in `core/prayer_times/prayer_times_providers.dart`):
    the location's date, or yesterday before today's Fajr. Built here in full.
  - `prayedProvider` (`Provider.autoDispose.family<Set<Prayer>, DateTime>`, in
    `core/prayer_log/prayer_log.dart`): returns `{}` until milestone 4 gives it the store query.

  The strip reads `dayTimesProvider(prayerDay)` and `prayedProvider(prayerDay)`.
- **Rationale**: the strip follows the prayer day (spec clarification), and milestone 4's plan
  already names these providers. Built first here, milestone 4 fills the log body instead of making
  them again.
- **Alternatives**: a Home-only "logged" list (milestone 4 would have to rewire Home), the
  calendar day (marks would vanish at midnight while Isha is still open).
- **Note for milestone 4**: its tasks that create `prayerDayProvider` and the `prayer_log.dart`
  file become "fill in", and its design scenario drops milestone 3's `prayedProvider` override
  once the seeded store exists.

## R3. Design scenario

- **Decision**:
  - The scenario's fixed times move from `todayTimesProvider` to `dayTimesProvider` for
    15 Oct 2026, so every reader (today, the prayer day, the strip) gets the handoff's times.
  - It adds `prayedProvider(15 Oct 2026) = {fajr, dhuhr}`.
  - The sky reads `flavorProvider.select((config) => config.isDesignScenario)` and paints
    `BmSkyMode.themeBase` when it is true. That needs no new provider, and core never imports
    Home.
- **Rationale**: the strip reads `dayTimesProvider(prayerDay)` directly. With the override still
  on `todayTimesProvider`, the strip would show the real 05:00 / 06:16 / 12:06. Milestone 4's plan
  makes the same move ("dayTimes per date").
- **How**: a family override replaces the whole builder, so `dayTimesProvider`'s body moves into
  a top-level `computeDayTimes(ref, date)`. The provider and the override both call it, so the
  override computes every date except 15 Oct 2026.
- **Alternatives**: overriding `todayTimesProvider` and the strip separately (two sources for one
  day).

## R4. One reduce motion flag

- **Decision**: the `MaterialApp.router` builder in `App` sets `disableAnimations` to
  `MediaQuery.disableAnimationsOf(context) || settings.reduceMotion`. Every widget then reads
  `MediaQuery.disableAnimationsOf(context)`, and `TabSwitcher`'s milestone 2 TODO goes away.
- **Rationale**: MOTION.md's flag is "OS setting or the in-app switch". One override covers Home,
  the tab switch, the sheet and every later screen, and no widget has to read settings for it.
- **Alternatives**: each widget reads `settingsProvider` and calls `context.reduceMotion(...)`
  (the same two lines in a dozen widgets). A small core inherited widget with its own
  `context.reduceMotion` (more code, and every widget reads two flags).
- **Approved 2026-10-18**: copying the data needs `MediaQuery.of`, which constitution V and the
  architecture test ban. `lib/core/app/app.dart` is the only file allowed it, for this one copy.
  At the app root nothing rebuilds because of it.

## R5. A ticker on the wall clock's second

- **Decision**: `tickerProvider` fires on each whole second of the wall clock. The timer is
  re-armed every tick for `1000 - now.millisecond` ms, instead of `Stream.periodic` from whenever
  it was first listened to. The time left is rounded to the nearest second.
- **Rationale**: MOTION 04 says "Timer aligned to the wall clock", and SC-002 needs the countdown
  to match the phone clock's seconds. `Stream.periodic` ticks at a random offset inside the second
  and can drift. Rounding keeps a tick that lands at .003 s past the second from showing one
  second too few.
- **Alternatives**: `Stream.periodic` (off by up to a second), a ticker per countdown widget (a
  second clock beside core's).

## R6. Living Sky animation

- **Decision**:
  - **One ticker, no rebuilds**: one `Ticker` in the sky widget drives a `ValueNotifier<Duration>`
    used as the painter's `repaint`. The widget tree never rebuilds for the loop.
  - **Every effect from elapsed time**: the painter works out drift, twinkle and sun pulse from
    the elapsed time with MOTION.md's numbers:
    - drift: 12 s alternate, breathe curve
    - twinkle: `1800 + (i % 7) × 410` ms, delay `−(i % 5) × 600` ms
    - sun pulse: 1 → 1.12 over 3 s alternate
  - **30 fps**: frames closer than 33 ms to the last paint are skipped.
  - **Stops**: `TickerMode` (TabSwitcher already turns it off for hidden tabs), the app in the
    background (no frames), reduce motion (stopped at elapsed 0, which is the still state), and
    Low Power Mode or Battery Saver (R7).
  - **Fade back**: when the loop starts again, its strength fades from 0 to 1 over 300 ms.
- **Rationale**: MOTION.md asks for a CustomPainter on a Ticker inside a RepaintBoundary at 30
  fps, paused off-screen. One notifier keeps the cost to one layer's repaint.
- **Alternatives**: an `AnimationController` per effect (a dozen controllers for 10 stars), a
  rebuild per frame.

## R7. Low Power Mode and Battery Saver

- **Decision**: a method channel `better_muslim/power` with one call, `isPowerSaving`:
  - iOS: `ProcessInfo.processInfo.isLowPowerModeEnabled`, in `AppDelegate.swift` next to the
    backup channel.
  - Android: `PowerManager.isPowerSaveMode`, in `MainActivity.kt`.

  It is read when Home's sky starts and on every app resume. Switching it on while Home is open
  takes effect at the next resume or tab return.
- **Rationale**: one flag, about 10 lines on each side, the same pattern as milestone 2's backup
  channel. No package to approve.
- **Alternatives**: battery_plus (a whole package for one bool, would need my approval), an
  event channel that follows changes live (more native code for a rare case), skipping it (breaks
  MOTION.md).

## R8. Sky change and sky colors

- **Decision**:
  - **Motion 03**: a `TweenAnimationBuilder` on `BmSkyStops.lerp`, 1800 ms sacred, or 300 ms
    linear with reduce motion. The stars' strength (0 by day, 1 at night) lerps with it. It
    animates whenever the state changes while Home is mounted, so the first build shows the
    current state with no animation.
  - **Live** (`BmSkyMode.live`): `bmSkyQiyamEmerald[state]`, where Period maps to the state as
    fajr → fajr, duha → sunrise, dhuhr → dhuhr, asr → asr, maghrib → maghrib, isha → isha.
  - **Theme base** (the scenario): `ThemeEnum.sky1/2/3`.
  - **Star opacity**: the palette's `starOpacity` (0.8 dark, 0.6 light), through a new
    `context.starOpacity` in `theme_manager.dart`. Features never read `context.bm`.
- **Rationale**: `periodProvider` already holds the polar cases and notifies only on a change, so
  the sky follows it instead of calling `bmSkyStateAt` with six maybe-null times.

## R9. Text on bright skies

- **Decision**: `bm_sky.dart` says header text is `#FFFFFF` at 92% on the sunrise, Dhuhr and Asr
  states, with a 0 → 28% black scrim behind the header text. That gives two new `ThemeEnum`
  entries resolved in core: `onSkyBright` (`0xEBFFFFFF`) and `skyScrim` (`0x47000000`). The
  header picks `onSkyBright` or `onSky` with `bmSkyIsBright(state)`. The status bar icons are
  light on Home in every state, because the top of every sky is dark.
- **Rationale**: the architecture test allows literal colors only in `core/resources/`, and these
  are the handoff's numbers.

## R10. Countdown

- **Decision**:
  - **Digits**: `h:mm:ss`, each character in its own slot. A changed digit slides up in a
    `ClipRect` with `AnimatedSwitcher` + `SlideTransition`, 300 ms standard. With reduce motion
    it swaps at once. The colons don't move.
  - **Widths**: times and the countdown use tabular figures. The text widgets get a
    `tabularFigures` flag (default off), since `font-variant-numeric: tabular-nums` is on every
    time in the specs.
  - **Screen readers**: one `Semantics` label, "{hours} h {minutes} min until {prayer}", with the
    digits excluded. The label only changes once a minute and the node is not a live region, so
    nothing is announced every second.
- **Alternatives**: one `Text` swapped whole (the whole number jumps, not Motion 04).

## R11. Glow

- **Decision**: a still radial glow behind the card, as the 4.01 layout tree draws it (inset −18,
  radial `glow` 55% → 0 at 72%, blur 6), always on. In the final 10 minutes before the next
  prayer it breathes: opacity .45 → 1 and scale .98 → 1.03, 3 s each way, breathe curve. With
  reduce motion it stays still at the PNG's look. `glowBreathingProvider` notifies only when the
  10-minute window opens or closes.

## R12. Location sheet, search field and sheet shell

- **Decision**:
  - **Sheet shell**: `core/widgets/sheet/bm_sheet.dart` with `showBmSheet`, using the name and
    file from milestone 4's plan, built first here:
    - in: spring gentle, ≈520 ms
    - out: 300 ms accelerate
    - reduce motion: a 150 ms fade
    - plus the grabber, the 64% scrim and the detent haptic
  - **Search field**: `core/widgets/search_field.dart` styled like 4.14's search field (46 pt,
    radius 14, surface, outline, search icon 20, 15 text2). Duas (milestone 8) uses the same one.
    It uses `GetTextStyle`, `EdgeInsets.zero` and an adaptive padding, so the architecture test
    needs no change.
  - **Buttons** (approved 2026-10-18): `core/widgets/bm_button.dart` with `BmButton.primary` and
    `BmButton.secondary`, from 4.11's "Use my location" and "Choose a city instead" (52 pt,
    radius 14, primary fill or a 1 px `outlineStrong` border, 15 / 500). The no-location card
    uses both. The adhan screen (5) and onboarding (10) need the same buttons.
  - **Sheet content**: `features/home/view/widgets/location_sheet.dart`:
    - "Location" title
    - a "Use my location" row
    - the search field
    - results from milestone 2's `PlaceList.search`, each as name, then region · country in the
      app's language
  - **Actions**: picking a result calls `LocationController.choose`, "Use my location" calls
    `useAuto`. A failed `useAuto` shows "Couldn't get your location…" in the sheet and keeps the
    search open.
- **Change to milestone 2**: today `useAuto()`:
  - switches the mode to auto before it knows the permission
  - never asks again once a location is saved (the "never nags" rule for app start)

  From the sheet the user asked, so `useAuto()` becomes `Future<bool>`:
  - it asks for "while using" when the permission is denied, even with a location saved
  - it saves auto only once a fix and a place are found
  - it returns false on denied, denied forever, location services off or no fix, with the
    mode and place left as they were

  `refresh()` keeps the never-nag rule.
- **Rationale**: milestone 2's controller already holds every other rule (manual stays manual,
  auto names the position, only "while using"). The sheet only calls it.

## R13. Arabic name beside the English one

- **Decision**: six arb keys (`fajrAr`, `duhaAr`, `dhuhrAr`, `asrAr`, `maghribAr`, `ishaAr`) hold
  the Arabic name in both files. `Period` and `Prayer` get a `nameArKey`. They show only in
  English, since 4.16 has no second name. The text is `font: FontEnum.display`, so Reem Kufi comes
  in through the Arabic fallback.
- **Alternatives**: loading the Arabic arb a second time at runtime (async loading for six words).

## R14. Sample content until later milestones

- **Decision**: `features/home/model/home_samples.dart` holds:
  - verse: Al-Fatiha 1:5, the Arabic text, the Sahih International translation, the reference in
    both languages
  - continue reading: Al-Fatiha · ayah 3 of 7
  - azkar: 0 of 24 evening, 0 of 12 morning (milestone 8's spec totals)
  - reminder: 10 minutes

  Markers:
  - the verse text gets `TODO(ahmed)`, because the Quran dataset is content I provide
  - the reading position, azkar count and reminder get a plain `TODO:` naming milestone 7, 8 or 5,
    since that is code still to write
- **Rationale**: the constitution's "sample content and a TODO(ahmed)" rule for content I have to
  source, and the global split between `TODO(ahmed)` and `TODO`.

## R15. Large text, 12 hour clock, tablets

- **Decision**:
  - **Stacking**: `context.isLargeText` (text scale above 1.4) goes in
    `core/extensions/window_size.dart`, since milestone 4's rows use the same rule. Above it, the
    card stacks and the strip turns into five rows.
  - **12 hour**: a strip cell is about 69 pt wide. "12:05 PM" at 15 pt fits at scale 1.0 but
    not much above it, so on a 12 hour phone the strip switches to rows as soon as the text scale
    is above 1.0. A widget test at 12 hour and 1.0 guards the cell.
  - **Tablets**: they already get the 480 pt cap in `App`.
- **Alternatives**: shrinking text to fit (breaks the type scale and the user's text size).

## R16. Navigation and scrolling

- **Decision**:
  - **Taps**: `context.go(Routes.prayer | quran | azkar)` switches the tab through the
    `StatefulShellRoute`. Milestone 4 adds `Routes.prayerAt` and milestone 7 the reader route,
    and they change these calls.
  - **Scrolling**: the whole page scrolls, the sky included. On iOS the overscroll above the sky
    shows sky, not the page background: the sky's top color fills the space behind the scroll
    view.

## R17. Tests

- **Decision**:
  - **Unit tests** for `model/`: bar share, azkar window, glow window, sky state from the period,
    sun share, night labels, countdown parts.
  - **Unit tests** for core: `prayerDayProvider` around Fajr and midnight, the ticker's alignment.
  - **Widget tests** for Home in the scenario:
    - English and Arabic, dark and light, text scale 1.0 and 2.0, 12 and 24 hour, with no
      overflow
    - the no-location state
    - the sheet with a fake position source and place list
    - the tab taps
    - reduce motion leaves no ticker running
  - **Contrast**: a test computes WCAG contrast for the header text on all six skies and the
    theme base in both modes (SC-006).
  - **Matching the PNGs** is the screenshot check at the end of the milestone.
- **Integration tests** (approved 2026-10-18): none in this milestone. The project has no
  `integration_test` setup yet. The first main journey that needs one, onboarding into Home, comes
  in milestone 10, and the setup comes with it.
