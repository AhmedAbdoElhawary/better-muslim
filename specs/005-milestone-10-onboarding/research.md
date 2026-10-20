# Research: Milestone 10, Onboarding and Backup

Checked on 2026-10-19 against the code on `feature/milestone-9` (milestones 2 to 6, 8 and 9 built),
the handoff (4.10, 4.11, 4.12, 4.15, `03 Components.dc.html`, MOTION.md, SCREENS.md), my
`liquid_glass_onboarding` project (`lib/src/onboarding_page.dart`, `choreography.dart`,
`glass/liquid_glass.dart`, `shaders/liquid_glass.frag`), pub.dev for file_picker (13.1.0, 160
points) and the file_picker 8.3.7 podspec in the pub cache.

## R1. Where the code lives

- **Decision**:
  - `features/onboarding/` (MVVM, as the constitution lists it): the first screen and 4.10 as one
    page (R4), the glass (R5), the welcome sky and stars (R7), 4.11 (R9), the reset notice (R16).
    `model/` holds the stage enum and the choreography math (pure, tested), `view/` the pages and
    widgets. The sun's moment to moment state lives in the page's `State`, as in the reference.
  - `features/notifications/presentation/view/notifications_step_page.dart`: 4.12, next to the
    Adhan and reminders page whose `PrayerSoundRow`, `showReminderSheet` and the scheduler's
    permission calls it uses (R10). Same reason milestone 9 kept Adhan and reminders there.
  - `features/theme_picker/`: the theme step is `ThemePage(onboarding: true)` (R11).
  - New in core because two features or more use them (constitution IV):
    - `core/settings/onboarding.dart`: finished or not, replay, finish (R2). Router, onboarding,
      theme step and the dev page read it.
    - `core/widgets/step/step_scope.dart`, `step_reveal.dart`, `step_dots.dart`: the step build
      and the dots (R8). 4.11, 4.12 and the theme step use them.
    - `core/backup/backup_file.dart`, `core/backup/restore.dart`: the file and the copy (R12, R13).
      More and onboarding use them.
    - `core/widgets/backup/`: the back up sheet, the restore sheet and `pickAndRestore` (R15).
    - `core/widgets/text_field.dart`: the 03 Inputs text field (R15).
  - Moved to core because onboarding now needs them: home's `skyState`, `starsOn` (model) and
    `skyStateProvider` (view_model) → `core/prayer_times/sky_state.dart` (R7).
- **Rationale**: no feature imports another, the router composes the flow (it may import
  features), everything shared is in core once.
- **Alternatives**: 4.12 inside `features/onboarding/` (would need the scheduler and the rows from
  notifications, a feature import), the whole flow as one widget with a step index (the theme step
  is a `theme_picker` page, only the router can reach it).

## R2. Who sees onboarding

- **Decision**:
  - Schema 6 adds `settings.onboarded` (bool, default false). The 5 → 6 step sets it to true where
    `latitude is not null` (FR-001: an older install with a place counts as finished).
  - `bootstrap.dart` reads the settings row once before `runApp` and overrides
    `onboardingProvider` with it, so the first frame already knows where to go. The design
    scenario store seeds `onboarded = true` (FR-004).
  - `onboardingProvider` (a `Notifier`) holds `(done, replay)`. `finish()` writes `onboarded`,
    clears replay. `replay()` sets replay, nothing is cleared (FR-004).
  - The router's `redirect`: not done or replaying → anything but `/onboarding…` and `/adhan` goes
    to `/onboarding`. Done and not replaying → `/onboarding…` goes to `/`. The router listens to
    the provider and calls `refresh()`.
- **Rationale**: one bool per phone, read before the first frame, so a finished install never
  flashes the welcome and a new one never flashes Home.
- **Alternatives**: redirect on the settings stream (Home shows for a frame before the stream's
  first value), "finished" = "has a place" (a place picked in onboarding would end it before the
  sounds and theme).

## R3. No more permission dialogs at launch (FR-002)

- **Decision**:
  - `LocationController._locateOnce` stops calling `source.request()`. It still uses a granted
    permission. Asking is left to `useAuto()` (4.11, Home's no location card, Qibla).
  - `NotificationsBoot._start` drops the first ask and the wait on `firstLocate`. `firstLocate`
    has no other user and goes.
- **Rationale**: the primers ask now. After onboarding there is always a place, so launch never
  needs to ask.

## R4. The first screen and 4.10 are one page

- **Decision**: `WelcomePage` at `/onboarding` ports the reference's `_OnboardingPageState`: the
  stages (`intro` = first screen, `main` = 4.10), the finger following ball with its catch up
  (180 pt), the rest spot spring (k 170, c 20, two sub steps), the flick rules (1200 pt/s up, 900
  pt/s down), the commit line (45% into the bottom zone), the ticker that stops when everything
  has settled, and the build controller `b` (0 → 1 in 1800 ms linear, back in 900 ms).
  - `model/sun_choreography.dart` is the reference's `Choreography` with 4.10's geometry: the rest
    spot is 4.10's sun (centre on the horizon, 452 of 852, radius 22), the dome is 0.55 widths in
    radius with its top at 0.745 of the height, the start line is the horizon. Positions are the
    tree's design points times `ScreenUtil` like every screen, the buttons hang from the bottom
    (46). Every size is a named entry in the managers, the physics constants stay in the model.
  - The build order of FR-013 maps onto `b`, overlapping, in order of start: title travel 0 to
    0.45 with opacity 0 to 0.2, horizon 0.05 to 0.35, mark 0.10 to 0.40, sun fill 0.30 to 0.75,
    stars from 0.35 (R7), tagline 0.35 to 0.55 and ink 0.50 to 0.75, Get started 0.60 to 0.85,
    Restore 0.70 to 1.
  - A tap anywhere during the build jumps `b` to 1 (FR-013). Grabbing the sun stops the build where
    it is, as the reference does.
  - The drag follows the first finger only. Flutter's drag recognizer hands a drag to the newest
    finger by default (`MultitouchDragStrategy.latestPointer`, none of its strategies keeps the
    first), so the grab area is a `Listener` that keeps the first pointer's id, ignores the others
    until it lifts, and measures the release speed with a `VelocityTracker`.
  - A cancelled pointer (the app going to the background, a system gesture) ends the drag as a
    release with no speed, so the sun springs to its rest spot.
  - Back on 4.10 (FR-018): a `PopScope` that can pop only on the first screen. On 4.10 the back
    runs `commitBackward`, the same as a drag past the line.
- **Rationale**: the sun has to move between the two stages without a route change. The reference
  already solves the drag, the springs and the reverse.
- **Alternatives**: two routes with a hero (a hero can't follow a finger), the reference's code
  as is (its layout is a 390 pt blush screen, its colors and copy are literal).

## R5. The glass

- **Decision**: `shaders/liquid_glass.frag` and `view/widgets/glass/liquid_glass.dart` come from
  the reference (render object feeding a backdrop `ImageFilter.shader`, `FallbackGlass`).
  `LensSpec` is plain data and goes to `model/lens_spec.dart`, since the choreography in `model/`
  returns it and a model can't import a view. Changes:
  - the reference's `FallbackGlass` paints with literal colors (white at 8, 3, 30 and 80% for the
    frost, rim and highlight, a blue to cyan gradient for the arc). They become `onSkyBright` at
    the same alphas and the theme's `glow` toward `sun`, so the file passes the color rule;
  - the blue, cyan and lavender of the glow arc become one `uGlow` color (theme `glow`) mixed
    toward `sun` for the light end, no literal colors in Dart or GLSL;
  - `uFill` (0 to 1) and `uFillColor` (theme `sun`) tint the glass: it warms as it rises (FR-008)
    and fills on settling (FR-013);
  - `uClipY` hides the lens below the horizon once settled, like the tree's `overflow:hidden` box.
  - The layer is only in the tree while the lens shows. At rest on 4.10 the designed sun (R6) is
    drawn instead, so 4.10 at rest runs no shader.
  - `ImageFilter.isShaderFilterSupported` false (Skia, widget tests) → `FallbackGlass`.
  - `pubspec.yaml` gets `flutter: shaders: - shaders/liquid_glass.frag`. The bubble shader and
    the bubble field are not copied (R7).
- **Rationale**: FR-007 asks for the reference's lens. A blur can't bend and flip.
- **Alternatives**: `BackdropFilter` blur (no refraction), the `liquid_glass_renderer` package (a
  new package for one lens, and it isn't the reference).

## R6. The sun at rest on 4.10

- **Decision**: a `WelcomeSun` widget draws 4.10's sun (44 pt, `sun` color, the 40/14 pt glow at
  45%, clipped at the horizon, the `sun` breathe 1 → 1.12 over 3000 ms). Its opacity is the fill;
  the lens's opacity is `1 - fill`. Grabbing the sun animates fill to 0 (glass again, FR-014),
  settling animates it back to 1.
- **Rationale**: the end state is the tree exactly, and the breathe is the handoff's ambient.

## R7. The sky and the stars

- **Decision**:
  - `WelcomeSkyPainter` paints 4.10's sky: the three stop gradient (`bmSkyGradient`) from
    `bmSkyQiyamEmerald[state]` at the current hour, or the theme's `sky1..3` when the state is
    null (design scenario, FR-012). Stars in `onSkyBright` at `starOpacity` like the theme
    snippet, so no literal color and no allow list entry. The horizon, the dotted arc and the
    mark draw from the tree.
  - The state comes from `skyStateProvider`, moved from home to `core/prayer_times/sky_state.dart`
    with `skyState` and `starsOn` (R1). Home imports it from there.
  - The ten stars (4.10's coordinates, the same list as Home's `starsRtl`) are tweens: from the
    sun's centre to their place, scale 0 → 1, staggered from `b` = 0.35 to 0.75 with
    `decelerate`, landing at the state's star strength (FR edge: a day sky fades them as they
    land). After landing they twinkle (1800 + (i % 7) × 410 ms, delay −(i % 5) × 600 ms).
  - On 4.10 going back, the stars fade over 1.4 s (the reference's `dismissDuration`).
  - Ambient (twinkle, breathe, the sky's drift) runs on one ticker at 30 fps in a
    `RepaintBoundary`, paused in the background and in power saving like Home
    (`powerSavingProvider`), and off with reduce motion: stars still at their strength, the sun
    at scale 1, the gradient at drift 0 (MOTION.md "No loops").
- **Rationale**: ten known points don't need the reference's particle field.

## R8. Moving between steps

- **Decision**:
  - Each step route is a `CustomTransitionPage` with `transitionDuration` 900 ms and
    `reverseTransitionDuration` 150 ms. Its `transitionsBuilder` wraps the page in
    `StepScope(animation, secondaryAnimation)`.
  - `StepReveal(index:, child:)` reads the nearest `StepScope` and gives its child the FR-017
    interval: the background fades in over 0 to 0.33 (300 ms), then the title (with 4.11's icon
    tile above it in the same slot), body, cards and buttons each get a slot after it (rise 14
    pt, fade). Without a scope (the theme page from More) it returns the child as it is.
  - A step page being covered fades its content out over the first 150 ms of the new route
    (`secondaryAnimation` 0 to 0.17), and fades back in when the route on top pops.
  - The welcome is covered differently (FR-015): its parts fade out over secondary 0 to 0.33
    (300 ms), in reverse build order (buttons, tagline, title, stars, mark and horizon), while
    4.11's background fades in over the same 300 ms. Popping 4.11 plays it the other way.
  - `StepDots(step:)` lerps the wide dot from the previous step to this one on the route's
    animation. "Step 1 of 3" for screen readers.
  - Reduce motion: the route is 300 ms, every slot is a plain fade over the whole of it (FR-037).
  - System back and the edge swipe are the routes' own pops (FR-018).
- **Rationale**: the route's animation already is a 0 → 1 timeline with a reverse. No controller
  per page.

## R9. Location step (4.11)

- **Decision**: `LocationStepPage` from the 4.11 tree. Use my location → `busy` on the button →
  `locationControllerProvider.useAuto()`. True → push 4.12. False → `showLocationSheet(context,
  failed: true)`, which opens with the existing `locationFailed` line showing. When the sheet
  closes, a place in `locationProvider` → push 4.12, none → stay. Choose a city instead →
  `showLocationSheet(context)`, same check.
- `showLocationSheet` gets the `failed` parameter. Nothing else in the sheet changes.

## R10. Notifications step (4.12)

- **Decision**:
  - `NotificationsStepPage` from the 4.12 tree, with `StepDots(step: 2)`, `PrayerSoundRow` × 5 and
    the reminder row opening `showReminderSheet` (milestone 9).
  - Allow notifications → always `askPermission()` (it returns at once with no dialog when
    notifications are already allowed, as on Android 12 and older), then `askExactAlarms()` when
    granted (milestone 5, it checks `canScheduleExactNotifications` itself and opens the page only
    when needed), then `notificationsAsked = true`, then push the theme step. No `isAllowed()`
    check before, or Android 12 would skip its alarms page.
  - Not now → push the theme step, nothing written.
  - `notificationsAsked` joins the boot's `_scheduleInputsProvider`, so writing it after the answer
    makes the schedule at once (otherwise nothing changes the inputs until a resume).
  - The "off" line on Adhan and reminders (FR-026): `notificationsAsked` false → ask as above,
    true → `SystemChannel.openNotificationSettings()` as now.
- **Rationale**: iOS shows no notification switch for an app that never asked, so "Open settings"
  alone would lead nowhere after Not now.

## R11. Theme step and finishing

- **Decision**: `ThemePage({this.onboarding = false})`. Onboarding: no back chevron, the parts
  wrapped in `StepReveal`, Apply → `apply()` then `onboardingProvider.finish()` then
  `context.go(Routes.home)`. The shell route gets a `pageBuilder` with a 300 ms fade
  (`CustomTransitionPage`), so Home fades in while the theme crossfades through `AnimatedTheme`
  (milestone 9). go_router's transition delegate drops the onboarding routes under it.
- **Rationale**: FR-027's 300 ms. On a normal cold start the shell is the first route and nothing
  animates.
- **Alternatives**: swapping the whole `MaterialApp.router` child on `done` (rebuilds the
  navigator, the step can't be painted under Home anyway).

## R12. The backup file

- **Decision**: the file is a small header plus a second store encrypted with the password.
  - The payload is a schema 6 store made by drift (`AppDatabase.backup(file, password)`), keyed by
    `pragma cipher = 'chacha20'`, `pragma kdf_iter = 600000`, `pragma hexkey = '<utf-8 bytes of
    the password as hex>'`. Hex, so no quoting problem with any password.
  - The header says what the file is before any password: magic, format, schema version, payload
    length (contracts/backup-file.md).
  - Writing: make the payload in the temporary folder, copy every table with typed drift reads and
    a batch insert, reset the phone's own columns in the copy (`notificationsAsked`,
    `storeResetPending`, `onboarded`), close, prepend the header, share it, delete both temp files.
  - The name: `better-muslim-YYYY-MM-DD.bmbackup`, Western digits always.
- **Rationale**: sqlite3mc already encrypts the store (ChaCha20-Poly1305 with a key derived from
  the passphrase), so the file is locked with no crypto package and no hand made format. A drift
  store migrates itself, which is FR-034's "upgraded the same way".
- **Alternatives**: JSON encrypted with AES-GCM (needs the `cryptography` package and a schema per
  version), a plain copy of the store (locked with the phone's key, useless on a new phone),
  `VACUUM INTO` (unclear which key the copy gets).
- **To verify in the first backup task**: `kdf_iter` is taken by sqlite3mc's chacha20 cipher (a
  round trip test with a wrong iteration count must fail). If it isn't, the default iterations
  stay and the header's format number marks it.

## R13. Restoring

- **Decision**:
  - Read the header: no magic → not a backup. Length short → damaged. Schema version above the
    app's → newer. All checked before the password.
  - Write the payload to a temp file, open it with the password: the first query fails (SQLite
    26) → wrong password. `pragma quick_check` not ok → damaged. Drift migrates an older one on
    open.
  - Copy into the app's store in one transaction: delete every table's rows, insert the backup's,
    keep this phone's own settings columns. Drift's typed batch notifies every stream, so every
    screen updates and the boot remakes the notifications (its inputs change).
  - A test fails when a table is added to the store without being in the copy (`allTables`).
  - Unexpected errors are reported with the reason only, like the store reset.
- **Rationale**: all or nothing (FR-032), nothing changes on any error (FR-031).

## R14. Picking and sharing the file

- **Decision**:
  - `file_picker` (13.1.0 on pub.dev, 160 points, 4.5 M downloads, approved in the spec):
    `pickFiles(type: FileType.any)`, the first file's path. Any type, since a custom extension on
    iOS needs a declared document type.
  - iOS `Podfile`: `Pod::PICKER_MEDIA = false` and `Pod::PICKER_AUDIO = false` before the pods, so
    file_picker leaves out its photo picker pod (DKImagePickerController) and the app needs no
    photo library wording. Checked in the 8.3.7 podspec, to check again in 13.x.
  - Sharing: `share_plus` (already in) with the file, so iOS offers Save to Files and Android the
    share sheet.
- **Alternatives**: `file_selector` (flutter.dev, lighter, but not the package I approved), a
  native document picker on the system channel (more native code than the package saves).

## R15. Sheets, field and dialogs

- **Decision**:
  - `BmTextField` in core from 03 Inputs: label above, the field on `surface`, focused outline in
    `primary`, the error line in `error` under it, `obscureText` for passwords. Inputs sit on the
    sheet's background, never on the sky (03 Inputs).
  - `showBackupSheet(context)`: two fields, the line, Save backup enabled at 6 characters and a
    match, `busy` while the file is made.
  - `pickAndRestore(context, {required bool confirm})`: picks, checks the header, opens the restore
    sheet (header problems show their line at once and leave Restore off), restores, returns
    whether it did. From More `confirm: true` shows the dialog first (FR-032) and a toast after.
  - `showBmDialog` gets `cancel` (default Cancel) and `destructive` (default true), so the reset
    notice can show Start fresh and a plain Restore from backup.
- **Rationale**: one restore path for 4.10, More and the notice.

## R16. Store reset notice

- **Decision**: when the welcome's build completes and `storeResetPending` is true, show the
  dialog (FR-036). Either answer writes `storeResetPending = false` first. Restore from backup
  runs `pickAndRestore(confirm: false)` and pushes 4.11 when it restored.

## R17. Motion, haptics, access

- **Decision**:
  - Reduce motion (`MediaQuery.disableAnimationsOf`, already joined with the app's switch in
    `App`): the sun still follows the finger, `LensSpec.velocity` zero (no squash), releases
    animate 300 ms with `standardCurve` instead of the spring, the build is 300 ms with the stars
    fading in place, steps per R8. The first screen's entrance is a 300 ms fade with the dome
    already in place. Twinkle, breathe and drift are off (R7).
  - `BmHaptics.sunLetGo()` (light) when the welcome starts or the sun sinks back, `selection()`
    when the sun crosses the horizon or the commit line. Nothing during builds.
  - Semantics: the grab area is a button with the FR-042 label and an `onTap` that starts the
    welcome (first screen) or does nothing but read (4.10). "Swipe up to begin" is a button too.
    The ready hint is a live region.
- **Rationale**: MOTION.md "meaning stays", FR-011, FR-037, FR-038.

## R18. Notifications while onboarding

- **Decision**: the redirect lets `/adhan` through, so the in-app adhan still covers onboarding
  (MOTION.md: the adhan wins over everything) and closing it comes back to the step. The boot's
  other taps (`PrayerTarget`, `AzkarTarget`) are skipped while onboarding isn't done, since a `go`
  would drop the steps.

## R19. Tests

- **Decision**:
  - Unit: `sun_choreography_test` (size by height, lift, the build intervals at known `b`),
    backup round trip on host sqlite3mc (every table and value back, phone columns kept), wrong
    password, foreign file, cut file, newer schema, older schema migrates, no plaintext in the
    file (SC-006), every table covered, the v5 → v6 migration, the onboarding redirect.
  - Widget: the first screen (drag below and above the horizon with `timedDrag`, a flick, a tap,
    the semantics tap, reduce motion, a second finger, a cancelled pointer, back on 4.10), 4.10's
    end state and the reset notice, 4.11 (granted,
    refused, city), 4.12 (defaults, segments, Allow, Not now), the theme step, More's backup rows
    and the sheets, in both languages, both modes and text scale 2.0. The glass is the fallback
    in tests (no shader filter).
  - Integration: `integration_test/onboarding_journey_test.dart` on the design scenario: More →
    dev page → Replay onboarding → tap the sun → Get started → Choose a city → Makkah → Not now →
    Apply → Home. No system dialog on the way.
