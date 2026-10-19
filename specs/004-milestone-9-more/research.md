# Research: Milestone 9, More, Theme and Hijri Calendar

Checked on 2026-10-19 against the code on `feature/milestone-8` (milestones 2 to 6 and 8 built),
the handoff (4.09, 4.12, 4.13, 4.15, `03 Components.dc.html`, `01 Brand.dc.html`,
`Theme Snippet.dc.html`, MOTION.md, OVERVIEW.md), the hijri 3.0.1, just_audio 0.10.6 and
audio_session 0.2.4 sources in the pub cache.

## R1. Where the code lives

- **Decision**:
  - `features/more/` (MVVM, as listed): the More tab, its tiles and rows, the light and dark
    sheet, the reset dialog, Credits and the licenses page.
  - `features/theme_picker/` (MVVM, as listed): the theme page, the snippet, the swatches.
  - `features/hijri_calendar/` (MVVM, as listed): the calendar page, the month math, the events,
    COMING UP, the day sheet and the adjustment sheet.
  - `features/notifications/`: the Adhan and reminders page with its sheets, next to the
    scheduler it feeds.
  - New in core because two features or more use them (constitution IV):
    - `core/widgets/nav_row.dart`: the 52 pt list row with icon, title, value and chevron (More,
      calendar, Adhan and reminders, Credits).
    - `core/widgets/grouped_section.dart`: the uppercase label over a surface card with divided
      rows (More, Adhan and reminders, Credits, the day sheet).
    - `core/widgets/segmented.dart`: the components' segmented control (theme page, Adhan and
      reminders, onboarding later).
    - `core/widgets/bm_dialog.dart`: the components' destructive dialog (reset now, the downloads
      in milestone 7).
    - `core/settings/appearance.dart`: the theme id and the resolved light or dark mode (R3).
    - `core/audio/ui_sounds.dart`: `BmSounds`, the UI sounds (R11).
    - `core/system/system_channel.dart`: open the notification settings, open a link, the
      version (R10).
  - Moved to core because a second feature now uses them:
    - prayer's `method_sheet.dart` → `core/widgets/sheet/` (More opens it).
    - duas' `ClipPlayer` → `core/audio/clip_player.dart` (the recording preview).
    - notifications' `AdhanRecording` → `core/settings/adhan_recording.dart` (the store keeps a
      recording per prayer).
    - Home's `HomeSamples` → `core/samples/home_samples.dart` (the theme snippet's verse).
- **Rationale**: no feature imports another, everything shared is in core once.
- **Alternatives**: theme and calendar inside `features/more/` (the constitution lists them on
  their own), the Adhan and reminders page in More (it would need the scheduler's channel ids and
  the preview, both notifications').

## R2. Applying the theme and the 300 ms crossfade

- **Decision**: `App` reads the theme id and the mode from `core/settings/appearance.dart`:
  `theme: AppTheme.light(id)`, `darkTheme: AppTheme.dark(id)`, `themeMode` from R3,
  `themeAnimationDuration: BmMotion.standard` with `BmMotion.standardCurve`. `BmColors.lerp`
  today snaps at half way (`t < .5 ? this : other`), so the switch is a cut. It becomes a real
  lerp of the palette (`BmPalette.lerp`, each of the 26 colors with `Color.lerp`), so the whole
  app crossfades in 300 ms. The values stay unchanged (constitution II).
- **Rationale**: one `AnimatedTheme` the framework already runs, no overlay, no rebuild of the
  navigator, so pages keep their state.
- **Alternatives**: an `AnimatedSwitcher` keyed by theme around the app (rebuilds the router and
  loses state), a screenshot crossfade (a frame grab and an overlay for something the theme lerp
  does).

## R3. Follow sky

- **Decision**: `themeModeProvider` in `core/settings/appearance.dart`:
  - Dark → `ThemeMode.dark`, Light → `ThemeMode.light`.
  - Follow sky with today's times → `resolveBrightness` (already in `bm_theme.dart`) with
    `todayTimesProvider`'s sunrise and Maghrib and `tickerProvider`'s now. The provider returns the
    same value for hours, so `MaterialApp` only rebuilds at sunrise and Maghrib.
  - Follow sky with no location → `ThemeMode.system`.
  - The design scenario overrides it to `ThemeMode.system` for Follow sky (FR-041), so each PNG is
    looked at in the phone's mode as in milestone 3.
- **Rationale**: the times are always there with a location, the high latitude rule of milestone
  2 gives a sunrise and a Maghrib every day, so the spec's polar edge case never reaches here.
- **Alternatives**: a timer to the next boundary (the ticker already exists and `.select` keeps it
  cheap), the phone's mode for Follow sky (not what Follow sky means).

## R4. The theme preview

- **Decision**: the preview is its own widget, `ThemeSnippet`, built from
  `design/Theme Snippet.dc.html` (300 pt wide, sky 176 tall, Now 34, Maghrib 28, countdown 22,
  strip, verse card), not Home scaled down. It sits in
  `Theme(data: AppTheme.light|dark(picked))`, so every `context.getColor` inside it reads the
  picked palette. Values are live from core: place and date, the Hijri date, Now, the next prayer
  with its time, the countdown from `tickerProvider`, today's five times, the verse from
  `HomeSamples`. The sky is the theme's base sky (sky1, sky2, sky3) as the snippet draws it
  (FR-014). The snippet is static: no sky drift, twinkle or glow loop inside the preview, the
  countdown ticks. Swatches read each theme's colors with
  `ThemeEnum.x.resolve(bmThemes[id]!.dark/light)`.
- **Rationale**: the snippet has its own sizes, Home's widgets don't fit it, and the theme feature
  can't import Home.
- **Alternatives**: Home's widgets moved to core and scaled with `Transform.scale` (most of Home
  in core for one preview, and the sizes still wouldn't match the snippet), the snippet with its
  ambient loops (five more animations in a preview the PNG shows still).

## R5. The Hijri month

- **Decision**: pure functions in `features/hijri_calendar/model/hijri_month.dart`:
  - The table is hijri 3.0.1's Umm al-Qura array, 1356 AH (14 Mar 1937) to 1500 AH (16 Nov 2077).
  - A month `(year, month)` starts on `hijriToGregorian(year, month, 1)` minus the adjustment, so
    it agrees with `HijriDate.of(date, adjust)`, which converts `date + adjust`. Its length is
    `getDaysInMonth(year, month)`.
  - The grid: blanks for the weekday of the first day (Sunday first), then the days. 5 or 6 rows.
  - The Gregorian label: the short month on the first cell and on every Gregorian 1st, the day
    number elsewhere. The header: "{first} – {last} {year}", or both years when they differ.
  - The arrows stop at the first and last month the table can convert, checked in a test.
  - 4.13's "Verify 1 Jumada I 1448 = 12 Oct 2026": the table gives it (15 Oct is 4 Jumada I in
    milestone 2's test).
- **Rationale**: the same table and the same adjustment rule as Home and the notifications, so
  every Hijri date in the app agrees.
- **Alternatives**: a calendar package (a second table that could disagree with Home's).

## R6. Events and COMING UP

- **Decision**: `features/hijri_calendar/model/hijri_events.dart` holds the FR-020 table as a
  const list: Hijri month, first and last day, the look (event, Sunnah fast, white day), the name
  key and the note key. Ayyam al-Bid is one entry for every month (13 to 15, 14 and 15 in Dhu
  al-Hijjah). A day's look follows FR-019's order, with today and selected from the page.
  COMING UP walks the days from today, at most 400, and keeps the first three items: the white
  days as one item per month (with their range), the events, and each month's first day as
  "{month} begins" unless an event falls on it. The date line: the item's Gregorian date alone
  inside the current Hijri month, "Estimated {date} · confirmed by moon sighting" for the first
  month start in the list, "Estimated {date}" for the rest.
- **Rationale**: a fixed list, the same every year (spec, Key Entities). No content file, the list
  is ten rows and decided in the spec.
- **Alternatives**: a JSON asset like the azkar (a file and a loader for ten fixed rows).

## R7. One recording per prayer

- **Decision**:
  - `AdhanRecording` moves to core and gets the six recordings of `01 Brand.dc.html`, each with
    its name key and its length from the board (3:52, 4:10, 3:31, 3:44, 4:02, 0:12) for the sheet.
    The five new ones point at the Makkah placeholder files until I supply theirs, one
    `TODO(ahmed)` above the enum, so no extra placeholder audio ships.
  - The store gets one recording column per prayer, like the sounds (data-model.md).
  - The scheduler's `apply` takes the recordings next to the sounds. Android channel ids become
    `adhan_{prayer}_adhan_{recording}` for Adhan, the others stay `adhan_{prayer}_{tone|silent}`.
    A prayer's other channels are deleted, as today. Android fixes a channel's sound when it is
    made, so a new recording needs a new channel id (`contracts/adhan-recordings.md`).
  - The full adhan (Android service, iOS in app) and the iOS clip use the prayer's recording.
    `NativeAdhanPlayer.length` and `JustAudioAdhanPlayer` read it from the settings instead of the
    `makkah` constant. The notification payload stays as it is.
  - The schedule inputs (`_scheduleInputsProvider`, the background top-up) add the five
    recordings, so a change remakes the schedule.
- **Rationale**: the sheet in `03 Components.dc.html` is per prayer ("For Asr"). The payload
  staying the same keeps pending notifications from before the update working.
- **Alternatives**: the recording inside the payload (a format change for pending alerts), five
  copies of the placeholder files (30 files, about 3 MB of placeholders).

## R8. The preview in the Adhan sound sheet

- **Decision**: the sheet plays `recording.fullAsset(prayer)` on the `ClipPlayer` moved to core
  (`core/audio/clip_player.dart`), so Fajr previews the Fajr variant. Another tap stops and plays
  the new one, Save and closing the sheet stop it. When the adhan screen opens, the notifications
  boot stops the clip player. Before it plays, the clip player configures the audio session as
  music, like the adhan player, so the preview is heard with the silent switch on, like the adhan.
- **Rationale**: one small player already exists for dua clips, the second user moves it to core.
- **Alternatives**: the adhan player (built for one alert at a time with its notification texts).

## R9. Reminder minutes: the slider and 25

- **Decision**: the store's check becomes `0, 5, 10, 15, 20, 25, 30` (migration v4 → v5 remakes
  the settings table with the new check, rows kept). The reminder sheet holds the components'
  slider: Flutter's `Slider` with 6 divisions, colored from `ThemeEnum`, the value label
  ("15 min", "Off" at 0) and `BmHaptics.selection()` on each step. Saved when the sheet closes, so
  dragging doesn't remake the schedule six times.
- **Rationale**: the components board's slider is 0 to 30 in 5 minute steps (spec Q5).
- **Alternatives**: picker rows (keeps the old list, not the board's control).

## R10. Opening settings, links and the version

- **Decision**: one app channel, `better_muslim/system`, in `AppDelegate.swift` and
  `MainActivity.kt`, next to `better_muslim/power`: `openNotificationSettings`, `openUrl(url)`,
  `version` ("1.0.0 (12)"). `contracts/system-channel.md`. No package.
- **Rationale**: about 20 lines on each side, the app already has its own channels (power, backup,
  compass). The constitution asks before any new package.
- **Alternatives**: url_launcher, package_info_plus and app_settings (three packages for three
  calls, each needing my OK).

## R11. UI sounds

- **Decision**: `BmSounds` in `core/audio/ui_sounds.dart`, static like `BmHaptics`:
  `enabled` (from the setting) and `busy` (set while the adhan or a clip plays). `bead()`,
  `complete()`, `aligned()` play a preloaded `AudioPlayer` each:
  - iOS: the session is set to ambient before a UI sound, so the silent switch mutes it and it
    mixes with other apps' audio. The adhan and clip players set music again before they play.
  - Android: the players are made with `handleAudioSessionActivation: false`, so a tap never takes
    audio focus from the user's music, and nothing plays unless the ringer mode is normal
    (audio_session's `AndroidAudioManager().getRingerMode()`).
  - Called next to the haptics: tasbih bead, set complete, day complete, Qibla aligned. Page comes
    with milestone 7.
  - Files: `assets/audio/ui_bead.m4a`, `ui_complete.m4a`, `ui_aligned.m4a`, short soft tones made
    as placeholders, `TODO(ahmed)` in `ui_sounds.dart` (Brand: −24 LUFS, 40 ms, 600 ms, 300 ms).
- **Rationale**: the haptics table pairs each sound with a haptic, so the call sites are already
  there. Static flags match `BmHaptics`.
- **Alternatives**: `SystemSound` (no custom sounds), a native sound pool (native code for three
  short files).

## R12. Haptics and Reduce motion

- **Decision**: `App` listens to the settings and sets `BmHaptics.enabled` and `BmSounds.enabled`
  (a `ref.listenManual` with `fireImmediately` in `initState`). Reduce motion is already joined to
  the phone's flag in `App.builder` (milestone 3), only the toggle is new.
- **Rationale**: every haptic already goes through `BmHaptics`, one flag turns them all off.

## R13. Reset prayer journey

- **Decision**: `AppDatabase.resetPrayerJourney()` deletes every `prayer_log` and `qada_entries`
  row in one transaction. Settings, `firstUse`, azkar counts and saved duas stay. After it the
  page hides the current toast, so an Undo from the Prayer tab can't bring a row back. Every
  screen updates from the store's streams.

## R14. Credits and the open source licenses

- **Decision**: `features/more/model/credits.dart`, a const list: the source's name (not
  translated), what the app uses it for (a key), the license and the link. GeoNames (place names,
  CC BY 4.0), the five font families (SIL OFL 1.1), the azkar and duas source and the adhan
  recordings (both `TODO(ahmed)` until final). "Open source licenses" pushes the app's own list
  from `LicenseRegistry`: one row per package, a tap shows its license text.
- **Rationale**: the license list from Flutter covers every package without a hand kept list.
  Built from the grouped rows, as FR-036 asks.
- **Alternatives**: Flutter's `showLicensePage` (Material's own page, outside the components).

## R15. The More tab

- **Decision**: `LargeTitleScrollView` (core, milestone 4) with the sky3 glow behind the title
  like the Prayer header. The three tiles, the sections from `GroupedSection` and `NavRow` /
  `ToggleRow`. Above text scale 1.4 a row's value goes under its title (the project's stacking
  rule). The dev row stays last in dev builds (FR-004). The digits toggle shows only when the
  locale is Arabic (FR-035).

## R16. Strings and plurals

- **Decision**: the FR-038 copy plus the credits lines, the theme names and the short Hijri months
  go into `StringsManager` and both arb files. Plurals use the ICU plural form the app already
  reads (`{n, plural, ...}`): `minBefore` and the reminder value (Arabic: 3 to 10 take دقائق,
  11 and up دقيقة), the signed adjustment. `BmThemeId` gets a `nameKey` next to `AppTheme`.
