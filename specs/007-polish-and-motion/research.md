# Research: Milestone 12, Polish and Motion

Checked on 2026-10-20 against the code on `feature/milestone-11` (milestones 2 to 6 and 8 to 10
built, 11 in progress), the handoff (4.04, 4.08, 4.09, 4.13, MOTION.md, TOKENS.md, OVERVIEW.md,
`bm_motion.dart`, `bm_sky.dart`, `bm_tokens.dart`), Flutter 3.47.5's `page.dart`, `route.dart`
(cupertino) and `heroes.dart`, go_router 18.1.0's `builder.dart` and hijri 3.0.1.

## R1. Where the code lives

- **Decision**:
  - `features/hijri_calendar/` stays MVVM: the two month kinds, the views, the selected day, the
    tabs and Coming up. The day sheet goes, the adjustment sheet leaves.
  - `features/more/` gets the adjustment sheet (its only user now), Acknowledgements (the old
    licenses page with the credits on top) and the CONTACT section.
  - `features/azkar/` keeps the auto move and the tasbih round in its own model and view.
  - New in core, each used by two features or more (constitution IV):
    - `core/resources/theme_sky.dart`: the six sky states of each theme (R5).
    - `core/router/page_transitions.dart`: the push every page uses (R8).
    - `core/widgets/title_hero.dart`: the text flight between a row and a bar title (R9).
    - `core/widgets/bm_switcher.dart`: the content swap with its size change (R11).
    - `core/widgets/sliding_selection.dart`: the highlight that slides to the picked item (R11).
    - `core/widgets/rolling_digits.dart`: home's countdown digit moved to core, the azkar counter
      rolls with it too (R11).
  - Changed in core: `compact_app_bar.dart` (the title into the bar, R10), `title_glow.dart`
    (pinned, with the switch, R12), `segmented.dart` (the sliding highlight, the dimmed segment
    with its x), `bm_dialog.dart` (R13), `system_channel.dart` (mail and device, R14),
    `settings.dart` and the store (R4).
- **Rationale**: no feature imports another, everything two features use is in core once.
- **Alternatives**: the adjustment sheet in core (only More opens it now), a page scaffold that
  adds the glow and the bar to every page (one more layer for what a `Stack` child does).

## R2. Two kinds of month

- **Decision**: `sealed class CalendarMonth` with `HijriMonth` (as now) and `GregorianMonth`. Both
  give `days(adjust)`, `blanks(adjust)`, `previous`, `next`, `canGoBack`, `canGoForward` and an
  order to compare (for the slide's direction). `CalendarMonth.of(day, mode, adjust)` finds the
  month holding a day.
- Gregorian ends: hijri 3.0.1 converts 14 Mar 1937 to 16 Nov 2077 only (it throws outside). With
  the adjustment from −2 to +2, every day of a month must stay inside after the shift, so Gregorian
  mode runs **April 1937 to October 2077**. Hijri mode keeps 1356 to 1500.
- The grid stays the same widget for both: the big number and the small label come from the mode.
  In Gregorian mode the small label is the Hijri day, with the short Hijri month on the first cell
  and on each Hijri 1 (FR-003). The header's second line is the Hijri span, "Rabi II – Jumada I
  1448" or "Dhu al-Hijjah 1447 – Muharram 1448", with the existing `monthSpan` strings fed Hijri
  month names.
- **Rationale**: one grid, two small classes with the same five methods. A sealed class is the
  smallest thing that lets the providers and the grid not care which mode they show.
- **Alternatives**: one class with a mode field and switches in every method (each method reads
  twice as long), a second grid widget (two copies of the cell layout).

## R3. The calendar's state

- **Decision**, in `view_model/calendar_providers.dart`, all `autoDispose` except the mode:
  - `calendarModeProvider`: reads `settings.calendarMode`, the title tap writes it.
  - `selectedDayProvider`: a `DateTime`, never null, starts on today (read once, so midnight never
    moves it, like the shown month).
  - `calendarPageProvider`: `(view: days | months | years, month: CalendarMonth)`. The years view
    shows the page of 12 holding `month`'s year, pages start at the first year of the range
    (1356 + 12k, 1937 + 12k). Arrows step a month, a year or 12 years by view. A mode switch maps
    the month holding the selected day.
  - `dayTabProvider`: `prayerTimes | comingUp | events`, Prayer times on open.
  - `comingUpProvider`: from the selected day, today, the adjustment and the mode (R6).
  - `todayEnabledProvider`: false only when the selected day is today, the view is days and the
    shown month holds today.
- A Coming up tap writes the page (days view, the event's month), the selected day and the tab
  together.
- **Rationale**: each widget reads only its part with `.select()`, a selection rebuilds two cells
  and the area under the grid, not the page.
- **Alternatives**: one big calendar state object (every change rebuilds every reader).

## R4. Stored settings, schema 8

- **Decision**: one migration, v7 → v8 (milestone 11 is v7):
  - `calendarMode` (text enum `CalendarMode`, default `hijri`).
  - `topGlow` (bool, default true). It lands in part 1 with the others, so part 2 needs no second
    migration.
  - `subhanallahCount`, `alhamdulillahCount`, `allahuAkbarCount` (int ≥ 0, default 0) replace
    `tasbihCount`. `tasbihDhikr` stays.
  - drift's `TableMigration` remakes `settings` (as v5 did): the old count goes to the column of
    the saved dhikr, the other two start at 0, `tasbihCount` is dropped.
- Backups: `readBackup` opens a backup's store, which upgrades it to this schema before
  `copyTables` copies the settings row typed, so an older backup gets the same migration. The new columns are the user's, so
  a backup carries them.
- **Rationale**: the same path as every earlier schema change, tested by drift's generated schema
  test.
- **Alternatives**: the three counts as one text column ("10,0,0", a string to parse on every
  tap), keeping `tasbihCount` as SubhanAllah's (a name that lies).

## R5. A sky for every theme

- **Decision**: in `core/resources/theme_sky.dart`, `themeSky(BmThemeId) → Map<BmSkyState,
  BmSkyStops>`, worked out once per theme and kept:
  - Qiyam Emerald: `bmSkyQiyamEmerald` as it is, no math, so its 18 colors never move (SC-004).
  - Isha: the theme's dark `sky1`, `sky2`, `sky3`.
  - Fajr to Maghrib: Qiyam Emerald's state with its hue turned by the theme's offset, in OKLCH
    (lightness, chroma, hue). The offset is the hue of the theme's dark `sky3` minus the hue of
    Emerald's dark `sky3` (the most colored stop, the black top has no hue). The chroma is scaled
    by the same two colors' chroma ratio, kept between 0.5 and 1.5. A color pushed out of sRGB
    loses chroma until it fits, so its lightness and hue stay.
  - Light and dark mode use the same sky (`bm_sky.dart`: "the sky is the sky").
- OKLCH and not HSL: HSL keeps a "lightness" that isn't what the eye sees (a yellow and a blue at
  the same HSL lightness are far apart), so the turned skies would change the text contrast. OKLCH
  keeps the perceived lightness, so each state keeps Emerald's light and dark profile, the one the
  text and scrim were tuned on. The conversion is about 30 lines (sRGB ↔ linear ↔ OKLab).
- Used by: Home's `SkyHeader`, the welcome's `WelcomeSky`, the theme preview's `SnippetSky`. The
  adhan screen and the system surfaces keep `bmSkyQiyamEmerald` (TOKENS.md).
- `bmSkyIsBright` stays per state, so the bright states keep the white text and the scrim.
- Test (FR-021, before any motion work): `sky_contrast_test.dart` loops the 8 themes × 6 states ×
  dark and light over the still sky, the same checks it runs for Emerald today. The drift check
  stays skipped with its existing `TODO(ahmed)`.
- **Rationale**: each theme keeps its own hue, the readable lightness carries over, no 48 hand-made
  gradients.
- **Alternatives**: hand-picked gradients (declined in the spec), HSL turning (breaks contrast),
  blending each state toward the theme's light sky (the light skies are lighter than the day states
  and not designed as day skies).

## R6. Coming up

- **Decision**: `comingUp(selected, today, adjust, mode)` in `model/coming_up.dart` returns
  `ComingUp(year, next: bool, groups)`. Each group is `(month, items)`, each item is
  `(event, first day, days away, estimated)`.
  - The days walked: from the day after the selected day to the last day of its year (the last day
    of Dhu al-Hijjah in Hijri mode, 31 December in Gregorian mode), never past the table's end.
  - An item is an event from `hijriEvents` whose first day (`from`) falls on a walked day. So an
    event already running on the selected day isn't listed (FR-014), the white days come back each
    month, Islamic New Year is 1 Muharram's event like the others.
  - Nothing found: the same walk over the next year, with `next: true`. Still nothing (past 1500 or
    2077): an empty list, the tab shows "No more events".
  - Groups: the selected day's month first as "This month", then each later month with an item, in
    the mode's months. Empty months don't show.
  - Days away: whole days from the selected day to the first day.
  - Estimated: the event's Hijri month is after today's Hijri month (today, not the selected day,
    because it's about what is known now).
- About 385 conversions at most, under a millisecond. The provider recomputes only when the selected
  day, the adjustment or the mode change.
- **Rationale**: one walk for both modes, the events table stays the only source.
- **Alternatives**: computing each event's next date with month math (fails on the white days and
  on Gregorian years that hold 13 Hijri month starts).

## R7. The auto move (azkar sets and Tasbih)

- **Decision**:
  - A new `BmMotion.completionPause = standard + burst` (1000 ms), the time the ring fill and the
    burst take (Motion 12). The azkar card uses it too, its check is shorter but the same pause
    keeps the two places alike.
  - Azkar set page: on `SetTap.done` a `Timer(completionPause)` calls `moveNext`. A tap in the wait
    goes through `tap()`, which already returns `moved` for a done card, so the timer is cancelled
    and the move happens at once without counting. A page change (swipe) cancels it. Disposing the
    page cancels it.
  - Tasbih: `TasbihState` becomes `(dhikr, counts[3])` with pure methods, unit tested:
    - `tap()`: round complete → a new round (all 0, SubhanAllah at 1). Shown dhikr done → the next
      one not done at 1. Else +1.
    - `advance()`: the next not done in order (around), or the same state when all are done.
    - `select(i)`, `reset()`, `complete`.
  - The page starts the timer when a tap finishes a dhikr while another isn't done, `advance()` on
    expiry. A tap in the wait cancels it and taps (`tap()` already moves and counts 1). A chip tap
    cancels it and selects. Leaving the page cancels it, the counts are already saved.
- **Rationale**: the existing tap paths already do the "move at once" part, only a timer is new.
- **Alternatives**: moving at the very moment of completion (declined), an animation status
  listener on the burst (the azkar card has no burst, and reduce motion has none either).

## R8. The push on every page

- **Decision**: `BmPageTransitionsBuilder` in `core/router/page_transitions.dart`, set for iOS and
  Android in `AppTheme._build` with `pageTransitionsTheme`. Every `GoRoute` with a plain `builder`
  makes a `MaterialPage`, whose route reads the theme's builder, so no route changes.
  - Reduce motion off: it hands over to Flutter's `CupertinoPageTransitionsBuilder` (the slide, the
    page under moving a third and dimming, the edge swipe back following the finger), including its
    `delegatedTransition` and its 500 ms. Arabic mirrors by itself (it reads the text direction).
  - Reduce motion on: a fade on `Interval(0, .3)` of the same 500 ms, so it reads as 150 ms (the
    route's length can't depend on context), and nothing on the page under.
  - Android's back button and gesture pop the route, which plays the same transition in reverse.
    The app doesn't opt into predictive back (`enableOnBackInvokedCallback` isn't set).
  - Flutter's edge swipe back has no platform check, so Android gets it too. Kept: with gesture
    navigation the system takes the edge first, with three buttons it works like on iOS, and
    blocking it is code for nothing.
- Kept as they are: the onboarding steps, the adhan reveal and the shell's fade in
  (`CustomTransitionPage`, they don't read the theme's builder), the tab switch (`TabSwitcher`),
  the sheets (`showBmSheet`).
- **Rationale**: Flutter's own iOS transition, not a rebuilt one, set in one place.
- **Alternatives**: `CupertinoPage` on each route (twenty edits for the same result), a hand-made
  slide (loses the edge swipe and the parallax).

## R9. Hero flights

- **Decision**: `TitleHero(tag, child)` in core: a `Hero` whose shuttle lerps the text style (size,
  weight, color) from the source's to the bar's and crossfades the two texts, so "Hijri calendar"
  can land as "Gregorian calendar". `transitionOnUserGestures: true`, so the edge swipe flies it
  back too. Under reduce motion it sits in `HeroMode(enabled: false)`.
- Tags are the destination's route path. The bars take a `heroTag`: `CompactAppBar`, `QiblaBar`,
  Tasbih's `_TasbihBar`.
  | Source | Tag | Target |
  | --- | --- | --- |
  | More tiles: Qibla, Hijri calendar, Duas | `Routes.qibla`, `Routes.hijriCalendar`, `Routes.duas` | Qibla's bar, the calendar's bar, Duas's bar |
  | More rows: Theme, Adhan and reminders | `Routes.theme`, `Routes.adhanSettings` | their bars |
  | Azkar tab rows: Morning, Evening, Tasbih | `Routes.azkarSet(set)`, `Routes.tasbih` | the set's bar, Tasbih's bar |
  | A dua category row | `Routes.duaCategory(id)` | the category's bar |
- Why it works across navigators: More's page lives in the shell's branch navigator, Qibla is
  pushed on the root one. Flutter's hero controller also invites a hero inside a nested navigator
  when its route is that navigator's current `PageRoute` (`heroes.dart`), and go_router 18 gives
  every navigator a `HeroControllerScope` (`builder.dart`).
- **Home's azkar shortcuts are dropped** (the spec's condition): `context.go` switches to the Azkar
  branch and pushes the set there. Home's branch is a sibling of the Azkar branch, not inside the
  route that transitions, so no controller ever sees both heroes. Making it fly needs an overlay
  of my own, which is the workaround the spec rules out.
- **Rationale**: Flutter's own `Hero`, one shuttle for all pairs.
- **Alternatives**: tags from the text keys (two pages with the same title would clash).

## R10. The large title moving into the bar

- **Decision**: `LargeTitleScrollView` (in `compact_app_bar.dart`) keeps its API and gets a
  `ScrollController`, a `ValueNotifier<double>` progress and a scope its headers read:
  - `LargeTitle(title, fontSize, height)`: the header's large title. It lays out as now but paints
    nothing, its `GlobalKey` tells the view where it rests.
  - The view paints the moving title in its own layer: from the resting rect at progress 0 (moving
    with the content while overscrolled) to the bar's center at 1, scaled by the bar size over the
    large size. Between 0.7 and 1 it crossfades into the bar's own semibold title. Transform and
    opacity only, rebuilt by a `ValueListenableBuilder` on the progress, the page doesn't rebuild.
  - Progress = scroll offset over the old collapse point (the button row plus the large title).
  - The subtitle (Prayer's place and method, More's "Stored on this device") reads the progress and
    fades out by 0.5.
  - The bar's glass stays a 150 ms fade at the point the title enters the bar, not tied to the
    finger: animating a blur every frame costs too much on older phones (design craft: crossfade a
    static blurred layer).
  - Snap: a user scroll that ends between 0 and 1 animates to the nearer end (300 ms, standard).
  - Reduce motion: no moving layer, the large title scrolls with the content and the bar fades in
    as today.
- **Rationale**: scroll-linked like iOS, cheap frames, the three pages keep their headers.
- **Alternatives**: `CupertinoSliverNavigationBar` (its own bar, font and sizes, not 4.04 and
  4.09), a header that resizes its text every frame (relayout on each scroll frame).

## R11. Nothing jumps

- **Decision**: three small core widgets, the rest uses Flutter's implicit animations:
  - `BmSwitcher(child, from)`: an `AnimatedSwitcher` (300 ms standard, the old child out on the
    same path) with a fade and a slide of `BmMotion.shift` (a new 8 pt token) from `from`, inside an
    `AnimatedSize` for the height. Reduce motion: a 150 ms fade, no slide, the size snaps.
  - `SlidingSelection`: a `Stack` whose highlight moves to the picked child's rect (measured after
    layout), on the snappy spring, retargeted from where it is when the pick changes again. Used by
    the segmented control (both sizes), the dhikr and dua chips, the theme swatches and the
    calendar's selected day. Reduce motion: it jumps.
  - `RollingDigits`: home's `CountdownDigit` moved to core, the azkar card's counter uses it too.
- FR-036's list maps to these: content swaps → `BmSwitcher`; selections → `SlidingSelection`;
  rows opening and lines appearing → `AnimatedSize` with the content faded in; list items → slide
  and fade in and out with `AnimatedList` where the list changes in place (Qada) and `BmSwitcher`
  where it is replaced (search results); on, off and enabled → `AnimatedOpacity` and color tweens
  (micro).
- Toasts: the floating `SnackBar` already fades. `_Toast` in `toast.dart` adds a slide of `BmMotion.shift` on the
  way in, the fade only with reduce motion.
- The calendar's tab content uses `BmSwitcher` with `from` toward the tapped tab. The design craft
  says tabs never slide, but those are the app's bottom tabs (100+ a day). These segments are seen
  far less and the spec asks for the slide, which stays 8 pt.
- Every motion has a purpose: state (swaps, selections), spatial (pushes, month slides, flights),
  feedback (counter).
- Quran text (Ayat al-Kursi on an azkar card, a Quranic dua) only moves with its whole card, as the
  azkar pager already does, never on its own (constitution III).
- Reduce motion turned on mid animation: what runs finishes, the next change reads the fallback.
  Stopping every running animation at the flip is code for a moment nobody sees. Durations stay in the Responsive tier, exits on the same path.
- **Rationale**: three widgets cover every row of FR-036 without a pattern per screen.
- **Alternatives**: the `animations` package (a new package for `FadeThroughTransition`, which
  `TabSwitcher` already does by hand).

## R12. The top glow on every page

- **Decision**:
  - `TitleGlow` moves out of Prayer's and More's headers into each page's background: the first
    child of a page-level `Stack`, at the top, so it doesn't scroll. Same size and gradient as now.
  - It watches `settingsProvider.select((settings) => settings.value?.topGlow ?? true)` and fades
    in or out (`AnimatedOpacity`, 300 ms) when the switch changes.
  - `CompactAppBar` uses `BmGlass.surfaceOpacity` (.55, the handoff's glass on the sky) when the
    glow is on and the current .8 when it's off. The blur stays.
  - Pages: Prayer, Azkar, More, the azkar sets, Tasbih, Duas, a category, the calendar, Theme,
    Adhan and reminders, Qada, Qibla, Acknowledgements, a license, Quran's placeholder, the dev page.
    The last two have a title and no bar, the glow sits behind the title the same way.
  - A contrast test checks the bar title over the glow in the 8 themes, dark and light.
- **Rationale**: one widget, one place for the switch, the bar uses a token the handoff already has.
- **Alternatives**: the glow inside `CompactAppBar` (it is taller than the bar and must sit behind
  the large title pages too).

## R13. Dialogs

- **Decision**: `showBmDialog`'s transition becomes a `ScaleTransition` from `BmMotion.dialogFrom`
  (a new 1.08 token) to 1 with the fade, both on the decelerate curve, 300 ms in, a 150 ms fade out.
  Reduce motion: the 150 ms fade only. The barrier fades with it (it already does).
- **Rationale**: Apple's alert, two transforms, centered.

## R14. Contact and the system channel

- **Decision**:
  - `SystemChannel.mail(to, subject, body) → bool`: iOS opens the `mailto:` link with
    `UIApplication.open`, Android starts `ACTION_SENDTO`. False when no app takes it, the row shows
    the "No mail app" toast with the address. `openUrl` stays https only.
  - `SystemChannel.device() → (model, os)`: iOS `utsname` machine ("iPhone15,2") and
    `UIDevice.current.systemVersion`, Android `Build.MANUFACTURER` + `Build.MODEL` and
    `Build.VERSION.RELEASE`. Only written into the mail draft, which I see before sending.
  - `features/more/model/contact.dart`: `email`, `developerName`, `website`, `appStoreUrl`,
    `playStoreUrl`, each `null` with a `TODO(ahmed)` until set. A row whose value is null isn't
    shown, the section is hidden when all four rows are.
  - Rate opens the platform's store link with `openUrl`. Share uses `share_plus` (already in) with
    the share line and the link.
- **Rationale**: two small native calls next to the existing ones, no package.
- **Alternatives**: url_launcher and device_info_plus (two packages for two calls the channel
  already has the shape for).

## R15. New motion tokens

- **Decision**: five new entries at the end of `BmMotion`, the handoff's values unchanged:
  `completionPause` (1000 ms), `shift` (8.0 design points), `dialogFrom` (1.08), `zoomNear` (1.1)
  and `zoomFar` (.9) for the calendar's views. The page push
  uses Cupertino's own 500 ms.
- **Rationale**: the project's one motion file, no parallel set (design craft).
