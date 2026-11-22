---

description: "Tasks for milestone 10, onboarding and backup"
---

# Tasks: Milestone 10, Onboarding and Backup

**Input**: Design documents from `specs/005-milestone-10-onboarding/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/backup-file.md,
contracts/onboarding-routes.md, contracts/liquid-glass-shader.md, quickstart.md

**Tests**: Included. Constitution VI asks for unit tests on logic, widget tests on screens and
integration tests on main journeys. SC-004 to SC-006 ask for the backup round trip, the errors and
no plaintext in tests.

**Organization**: Grouped by user story, so each story can be built and checked on its own.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an unfinished task)
- **[Story]**: The user story the task belongs to (US1 to US4)

## Before starting

- Built after milestone 9, on `feature/milestone-10` (plan header). Milestone 7 comes after 11, so
  nothing here touches the Quran reader. Motion 01 stays out (spec clarification).
- Read `design_handoff_better_muslim/specs/HOW_TO_READ.md`, then the 4.10, 4.11, 4.12 and 4.15
  trees, MOTION.md (tiers, haptics, reduce motion, the `sun`, `tw` and `sky` ambient rows), and in
  `03 Components.dc.html` 03 Inputs (text field: label 13 `text2`, box 52 high, radius 14, `bg`,
  inset 1 `outline2`, focused inset 2 `primary`, error inset 2 `error` with a 12.5 `error` line,
  padding 0 16, text 15, placeholder `text3`), 01 Actions (primary, secondary, text buttons) and
  08 Overlays (sheet, dialog, toast).
- Read the reference: `liquid_glass_onboarding/lib/src/onboarding_page.dart`, `choreography.dart`,
  `glass/liquid_glass.dart`, `shaders/liquid_glass.frag`. Port, don't redesign.
- Every UI file follows the `adaptive-widgets` rules, and `flutter test test/architecture_test.dart`
  stays green.
- Parallel sessions share `.specify/feature.json`, so speckit commands get this folder passed
  explicitly (`SPECIFY_FEATURE_DIRECTORY=specs/005-milestone-10-onboarding`).

---

## Phase 1: Setup

**Purpose**: The constitution, the branch, the package, the shader asset, the folders.

- [X] T001 Amend `.specify/memory/constitution.md` for plan decision 5 (approved in the spec's clarifications): in Stack And Constraints add file_picker to the domain packages after share_plus as "file_picker (picking a backup file to restore)", bump the version MINOR (3.5.0, or the next MINOR if another milestone moved it) and the Last Amended date.
- [X] T002 Ask before cutting `feature/milestone-10`: milestone 9 is still uncommitted on `feature/milestone-9`. Then confirm `flutter pub get`, `flutter analyze` and `flutter test` are green before any change.
- [X] T003 Run `flutter pub add file_picker` (13.1.0 or the latest), add `shaders:` with `- shaders/liquid_glass.frag` under `flutter:` in `pubspec.yaml`, and in `ios/Podfile` above `target 'Runner'` add `Pod::PICKER_MEDIA = false` and `Pod::PICKER_AUDIO = false` (research R14). First read the installed `file_picker` podspec in the pub cache and confirm it still reads those two constants; if it moved to other flags, use those and say so. Run `cd ios && pod install`. (Built: iOS uses Swift Package Manager and has no Podfile, and file_picker 13 is federated with no media pods, so the Podfile part didn't apply.)
- [X] T004 Create the folders `shaders/`, `lib/core/backup/`, `lib/core/widgets/backup/`, `lib/core/widgets/step/`, `lib/features/onboarding/model/`, `lib/features/onboarding/view/widgets/glass/`, `test/core/backup/`, `test/core/router/`, `test/features/onboarding/model/`, `test/features/onboarding/view/`.

---

## Phase 2: Foundational

**Purpose**: What every story stands on: schema 6, the onboarding gate, no launch dialogs, the sky
state in core, the step widgets, the shared field, button and dialog changes, strings and sizes.

**⚠️ CRITICAL**: No story work starts before this phase is done

### Tests for the foundation

- [X] T005 [P] Write `test/core/settings/onboarding_test.dart`: `OnboardingNotifier(done: false)` starts not done and not replaying; `finish()` writes `settings.onboarded = true` to an in-memory store and gives `(done: true, replay: false)`; `replay()` on a done state gives `(done: true, replay: true)` and writes nothing.
- [X] T006 [P] Write `test/core/router/onboarding_redirect_test.dart` for the pure `onboardingRedirect(Onboarding, String location)` against every row of the table in `contracts/onboarding-routes.md`: not done → `/prayer` goes to `/onboarding`, `/onboarding/location` and `/adhan?prayer=asr` stay; replaying behaves the same; done → `/onboarding` and `/onboarding/theme` go to `/`, `/more` stays.
- [X] T007 [P] Write `test/core/widgets/step_test.dart`: `StepReveal` without a `StepScope` returns its child untouched; with a scope at animation 0, 0.33, 0.6 and 1 each slot's opacity and 14 pt offset follow the intervals in `contracts/onboarding-routes.md`; a covered page (secondary 0 → 0.17) fades its slots out; with `disableAnimations` every slot is a plain fade over the whole animation; `StepDots(step: 2)` shows a small `primary` dot, a wide `primary` dot and a small `outline2` dot, and a screen reader hears "Step 2 of 3".
- [X] T008 [P] Write `test/core/widgets/text_field_test.dart` and extend `test/core/widgets/bm_dialog_test.dart`: the field shows its label, obscures when asked, shows the error line and the 2 pt `error` outline when given an error key, the 2 pt `primary` outline when focused, is at least 44 pt high; `showBmDialog(cancel: StringsManager.startFresh, destructive: false)` shows Start fresh and an action with no `error` tint, the defaults stay as before. Add `BmButton.text` cases to the existing button test or a new `test/core/widgets/bm_button_test.dart`: text only, the given color, 44 pt hit, busy.
- [X] T009 [P] Update `test/core/location/location_controller_test.dart` and `test/features/notifications/presentation/notifications_boot_test.dart`: `refresh()` with no place and permission denied never calls `request()` (FR-002); the boot never asks for notifications at start; writing `notificationsAsked` remakes the schedule (R10); a `PrayerTarget` tap while onboarding isn't finished doesn't navigate, an adhan tap still opens the adhan screen (R18).

### Implementation for the foundation

- [X] T010 Schema 6 in `lib/core/database/app_database.dart`: add `onboarded` as `boolean().withDefault(const Constant(false))()` with a one-line `///` saying it belongs to the phone and never goes into a backup, `schemaVersion => 6`, `from5To6`: `addColumn(schema.settings, schema.settings.onboarded)` then `customStatement('update settings set onboarded = 1 where latitude is not null')` (data-model.md: "an older install with a place counts as finished"). Run `dart run build_runner build` and `dart run drift_dev make-migrations`, commit `drift_schemas/app_database/drift_schema_v6.json`, the steps file and `test/drift/app_database/generated/schema_v6.dart`, and add the v5 → v6 case to `test/drift/app_database/migration_test.dart` (rows kept, a row with a place reads onboarded, one without reads not).
- [X] T011 Write `lib/core/settings/onboarding.dart`: `typedef Onboarding = ({bool done, bool replay})`, `OnboardingNotifier extends Notifier<Onboarding>` taking `done` in its constructor, `finish()` (writes `onboarded`, then `(done: true, replay: false)`), `replay()`, and `onboardingProvider`. Add the pure `String? onboardingRedirect(Onboarding onboarding, String location)` per `contracts/onboarding-routes.md` in `lib/core/router/app_router.dart`.
- [X] T012 Read the settings row in `lib/bootstrap.dart` before `runApp` (`await db.watchSettings().first`) and override `onboardingProvider` with `OnboardingNotifier(done: settings.onboarded)`. In `lib/core/flavor/design_scenario.dart` seed `onboarded: true` (FR-004). In `test/helpers/providers.dart` add `onboardingProvider` done to `testOverrides` and `designOverrides`, so existing tests keep landing on Home.
- [X] T013 Wire the gate in `lib/core/router/app_router.dart`: `redirect: (context, state) => onboardingRedirect(ref.read(onboardingProvider), state.uri.toString())`, `ref.listen(onboardingProvider, (_, _) => router.refresh())`, the route constants `Routes.onboarding`, `onboardingLocation`, `onboardingNotifications`, `onboardingTheme`, a `_stepPage(state, child)` helper (`CustomTransitionPage`, 900 ms in, 150 ms out, 300 ms with reduce motion, `transitionsBuilder` wraps the child in `StepScope`), and a `pageBuilder` on the `StatefulShellRoute` with a 300 ms `FadeTransition` (research R11). The `/onboarding…` `GoRoute`s come in US1 and US2.
- [X] T014 [P] Move `skyState` and `starsOn` from `lib/features/home/model/home_moment.dart` and `skyStateProvider` from `lib/features/home/view_model/home_providers.dart` to `lib/core/prayer_times/sky_state.dart` (research R7), update every import in `lib/features/home/` and `test/`, and move their test cases from `test/features/home/model/home_moment_test.dart` to `test/core/prayer_times/sky_state_test.dart`.
- [X] T015 [P] Remove the launch dialogs (research R3): in `lib/core/location/location_controller.dart` `_locateOnce` no longer calls `source.request()` (keep using a granted permission, fix its comment), and drop `firstLocate` with its completer. In `lib/features/notifications/presentation/notifications_boot.dart` drop the first ask and the `firstLocate` wait in `_start`, add `row?.notificationsAsked` to `_scheduleInputsProvider`, and in `_open` skip `PrayerTarget` and `AzkarTarget` while `onboardingProvider` isn't done or is replaying (R18).
- [X] T016 [P] Write `lib/core/widgets/step/step_scope.dart` (an `InheritedWidget` with `animation` and `secondaryAnimation`, `maybeOf`), `step_reveal.dart` (`StepReveal(slot:, child:)` with the slots of `contracts/onboarding-routes.md`: background, title, body, cards, buttons; rise 14 pt from `SpaceManager`, fade; plain fade with reduce motion; untouched without a scope) and `step_dots.dart` (`StepDots(step:)`, total 3: dots before the current small `primary`, the current wide `primary`, after small `outline2`, sizes from the 4.11 and 4.12 trees through named entries, the wide dot lerps from the previous step on the route's animation, `Semantics(label: "Step {step} of {total}")`).
- [X] T017 [P] Write `lib/core/widgets/text_field.dart`: `BmTextField(label:, hint:, obscure:, error:, enabled:, onChanged:, textInputAction:, onSubmitted:)` from 03 Inputs (values in "Before starting"), label and error are `StringsManager` keys, the error line is text only (the icon set has no alert icon). Style through `GetRegularStyle` like `search_field.dart`.
- [X] T018 [P] Add `BmButton.text(label, {required onPressed, color = ThemeEnum.primary, busy})` to `lib/core/widgets/bm_button.dart` (01 Actions text button: 52 high, no fill, no border, 15 pt medium). 4.10's Restore uses `onSky`, 4.12's Not now `primary`.
- [X] T019 [P] Add `cancel` (default `StringsManager.cancel`) and `destructive` (default true) to `showBmDialog` in `lib/core/widgets/bm_dialog.dart`; `destructive: false` drops the `error` tint (research R15).
- [X] T020 [P] Add `static Future<void> sunLetGo() => _run(HapticFeedback.lightImpact);` to `lib/core/resources/design/bm_haptics.dart` with a trailing comment in the file's style ("the sun let go on the first screen, or sunk back on 4.10").
- [X] T021 [P] Add every FR-042 string to `lib/core/resources/strings_manager.dart` and both `assets/l10n/app_en.arb` and `assets/l10n/app_ar.arb` with the exact wording of the table: `firstHeadline`, `swipeToBegin`, `letGoToBegin`, `sunHint`, `sunBackHint`, `stepOf` ({step}, {total}), `backUp`, `password`, `confirmPassword`, `passwordNote`, `passwordTooShort` ({count}, so Arabic shows ٦), `passwordsDontMatch`, `saveBackup`, `restorePasswordNote`, `restore`, `wrongPassword`, `notABackup`, `damagedBackup`, `newerBackup`, `restoreTitle`, `restoreBody`, `backupRestored`, `resetNoticeTitle`, `resetNoticeBody`, `startFresh`. Reuse `restoreBackup`, `cancel`, `getStarted`, `locationFailed`. `strings_manager_test.dart` stays green.
- [X] T022 [P] Add the named sizes to `lib/core/resources/dimensions_manager.dart` and `lib/core/resources/font_manager.dart`, values from the trees, names saying where they're used: 4.10 (horizon 452, sun 44, sun glow blur 40 and spread 14, mark top 248 and size 88, arc radius 100.5, title top 500, title to tagline 12, tagline max width 300, buttons bottom 46 and gap 8, the grab margin 22), the first screen (dome radius share, ready hint), the step pages (dots top 66, wide dot 22, dot 6, dot gap 6, content top 118, the 4.11 icon tile 64 and radius 20, the 4.11 card top 372, the 4.12 card top 288, rows and gaps), the text field (52, radius 14, side 16). Text roles: `wordmark` for "Better Muslim", `bodyLarge` for the tagline, `onboardingTitle` for 4.11 and 4.12, `font_manager_test.dart` stays equal to `BmText`.

**Checkpoint**: tests T005 to T009 green, a fresh store redirects to `/onboarding` (no page yet), an
older store with a place opens Home, no dialog shows at launch.

---

## Phase 3: User Story 1 - Raise the sun to begin (Priority: P1) 🎯 MVP

**Goal**: The first screen with the glass sun, the sunrise gesture, 4.10 building out of it, and
the way back.

**Independent Test**: Replay onboarding from the dev page. Drag the sun halfway: it sinks back.
Past the horizon: "Let go to begin" with a tick. Let go: 4.10 builds and ends as its tree. Drag it
down past the line: the first screen again. Reduce motion on: tap the hint, 4.10 crossfades.

### Tests for User Story 1

- [X] T023 [P] [US1] Write `test/features/onboarding/model/sun_choreography_test.dart` on a 393 x 852 size: the rest spot is (196.5, 452) with radius 22; the dome's top is at 0.745 of the height; `liftAt` is 0 at the dome and 1 at the horizon and above; the lens radius grows monotonically from 22 at the horizon to the dome radius at the dome; the build intervals of research R4 at b = 0, 0.35, 0.6, 1 (title travel 0 at b ≥ 0.45, Get started fully in at 0.85, Restore at 1); `startLine` is the horizon.
- [X] T024 [P] [US1] Write `test/features/onboarding/view/welcome_page_test.dart` (the fallback glass, haptics counted through `SystemChannels.platform` like `test/core/widgets/segmented_test.dart`): the first screen shows the headline, "Swipe up to begin" and the dome, no stars; a `timedDrag` from the dome to just below the horizon and release → still the first screen; a drag above the horizon shows "Let go to begin" with one selection haptic, release → `sunLetGo` and after 1800 ms the 4.10 end state (title, tagline, Get started, Restore, the mark, ten stars, the designed sun); a flick up over 1200 pt/s from just above the dome → 4.10; a tap on the hint → 4.10; the sun's semantics tap → 4.10; a tap during the build ends it at once; on 4.10 a drag to the bottom and release → the first screen, a short drag → 4.10 again; a second finger put down mid drag doesn't move the sun, only the first does (FR edge); a pointer cancelled mid drag springs the sun to its rest spot with no commit; the system back on 4.10 → the first screen, on the first screen it isn't blocked (FR-018); Get started → by 150 ms of the push the buttons have faded while the title still shows, by 300 ms the welcome's content is gone (FR-015); with `disableAnimations` the entrance is a fade with the dome already in place, the hint tap gives 4.10 in 300 ms, the stars don't fly or twinkle and the sun doesn't breathe (FR-037). Arabic, text scale 2.0, dark and light.

### Implementation for User Story 1

- [X] T025 [P] [US1] Write `lib/features/onboarding/model/lens_spec.dart` (the reference's `LensSpec` with `fill` and `clipY` added, `hidden`, `lerp`) and `lib/features/onboarding/model/sun_choreography.dart`: `enum SunStage { intro, main }` and `SunChoreography(size, padding)` per research R4: the geometry from the managers in design points, `domeRadius`, `domeCenter`, `restRadius`, `restCenter`, `startLine`, `readyHintTop`, `reverseZoneTop`, `reverseZoneLength`, `liftAt`, `lensAt(center, {glow, velocity, fill})` (radius in log space as in the reference, magnify, refraction, chroma, shadow, specular, rim from the reference's ranges), `glowForLift`, `headlineOpacity`, `headlineBlur`, `hintOpacity`, the build intervals and title travel, the fill as it rises. Physics constants (spring 170 and 20, catch up 180, flicks 1200 and 900, commit 0.45, build 1800 and 900 ms) as named `static const` with the reference's values. Pure Dart, no widgets.
- [X] T026 [P] [US1] Write `shaders/liquid_glass.frag` from the reference with the uniform layout of `contracts/liquid-glass-shader.md`: the glow arc from `uGlowColor` toward `mix(uGlowColor, uFillColor, 0.5)` instead of the literal blue, cyan and lavender, the glass tinted by `uFill` toward `uFillColor`, nothing drawn below `uClipY`.
- [X] T027 [US1] Write `lib/features/onboarding/view/widgets/glass/liquid_glass.dart` from the reference's `liquid_glass.dart`: `LiquidGlassLayer` (the render object feeding the shader each frame, uniforms in the contract's order, `glow` and `sun` from `context.getColor`), `FallbackGlass` (frosted, same size, rim and motion, the fill and clip too; the reference paints it with literal colors, use `onSkyBright` at the same alphas, 8, 3, 30 and 80%, for frost, rim and highlight, and `glow` toward `sun` for the arc, research R5), and a loader that reads `FragmentProgram.fromAsset('shaders/liquid_glass.frag')` once when `ImageFilter.isShaderFilterSupported`, reports a failure with the reason only through `CrashReporter` and falls back.
- [X] T028 [P] [US1] Write `lib/features/onboarding/view/widgets/welcome_sky.dart`: a painter for 4.10's sky (`bmSkyGradient` with `bmSkyQiyamEmerald[state]` from `skyStateProvider`, or the theme's `sky1..3` when the state is null, drifting with the `sky` ambient row, drift 0 with reduce motion), the horizon line drawn out from the middle by a progress value, the dotted sun arc and the 8 point mark in `primary` from the tree's polygon, each faded and scaled by the build. Bright states put the bm_sky.dart scrim behind the text block.
- [X] T029 [P] [US1] Write `lib/features/onboarding/view/widgets/welcome_stars.dart`: 4.10's ten stars (x, y, size from the tree, a const list), each flying from the sun's centre to its place with scale 0 → 1 between b = 0.35 and 0.75 staggered with `BmMotion.decelerate`, landing at the state's star strength (`starsOn`, `starOpacity`), then twinkling (1800 + (i % 7) × 410 ms, delay −(i % 5) × 600 ms, `breathe`), fading over 1.4 s when going back, a 300 ms fade in place with reduce motion. Color `onSkyBright`. Twinkle on one ticker at 30 fps in a `RepaintBoundary`, paused in the background and with `powerSavingProvider`, off with reduce motion (still at their strength, FR-037).
- [X] T030 [P] [US1] Write `lib/features/onboarding/view/widgets/welcome_sun.dart`: 4.10's sun (44 pt `sun` disc, the 40 / 14 glow at 45%, clipped at the horizon), breathing 1 → 1.12 over 3000 ms (`sun` ambient row) on the same ambient ticker as the stars (paused in the background and power saving, scale 1 with reduce motion, FR-039), its opacity the fill (research R6).
- [X] T031 [P] [US1] Write `lib/features/onboarding/view/widgets/intro_layer.dart` (headline in the display font centred above the middle, blurred and faded by the choreography; "Let go to begin" under the middle with a 300 ms slide and fade and a live region; "Swipe up to begin" near the bottom as a button whose tap starts the welcome) and `welcome_layer.dart` (title with `wordmark`, starting inside the sun and sliding to its place; tagline with `bodyLarge`, max width 300, going from faint to `onSky` at 0.85; Get started `BmButton.primary`; Restore from backup `BmButton.text(color: ThemeEnum.onSky)`; `onSkyBright` text on bright states; every value from the choreography at `b`). Restore's `onPressed` is wired in US3.
- [X] T032 [US1] Write `lib/features/onboarding/view/welcome_page.dart` porting the reference's page state (research R4): the ticker, the finger catch up, the rest spot spring with two sub steps (300 ms `standardCurve` with no overshoot under reduce motion), the flicks, `commitForward` (`BmHaptics.sunLetGo`, home = horizon, build 0 → 1 over 1800 ms, 300 ms with reduce motion), the 4.10 drag down (`b` follows the finger, a `BmHaptics.selection` at the commit line, `commitBackward` with the glow flash), `BmHaptics.selection` when the held sun crosses the horizon, the fill (0 while held, 1 when settled on 4.10), a tap anywhere while building jumps `b` to 1, a grab stops the build. Layers: sky, stars, intro layer, welcome layer, glass (only while the lens shows), the designed sun, the grab area (rest radius + the grab margin, `Semantics` button with `sunHint` or `sunBackHint` and `onTap`). The grab area is a `Listener` that follows the first pointer only and ignores others until it lifts, with a `VelocityTracker` for the release speed (Flutter's drag recognizer would hand the drag to the newest finger); a cancelled pointer is a release with no speed (research R4). A `PopScope` lets back leave the app only on the first screen; on 4.10 back runs `commitBackward` (FR-018). The first screen's entrance (FR-006): sky fade, dome rising from below the edge, headline and hint fade, within 1200 ms; with reduce motion a 300 ms fade with the dome already in place (FR-037). Read the `StepScope` around it: fade the welcome's content out over secondary 0 to 0.33 in reverse build order (buttons, tagline, title, stars, mark and horizon) and back in when 4.11 pops (FR-015, FR-018, contracts/onboarding-routes.md). Status bar icons follow `onSky`. Get started → `context.push(Routes.onboardingLocation)`.
- [X] T033 [US1] Add `GoRoute(path: Routes.onboarding)` with `WelcomePage` to `lib/core/router/app_router.dart`, its page a `CustomTransitionPage` with no transition of its own that wraps it in `StepScope` (contracts/onboarding-routes.md).
- [X] T034 [US1] Add "Replay onboarding" to `lib/features/notifications/presentation/view/dev_notifications_page.dart` as a `_Row` with an English `static const` label like the others: `ref.read(onboardingProvider.notifier).replay()` then `context.go(Routes.onboarding)` (FR-004). It shows in the design scenario too.

**Checkpoint**: the sunrise works end to end and is reviewable through Replay.

---

## Phase 4: User Story 2 - Set up where I am and how prayers reach me (Priority: P1)

**Goal**: 4.11, 4.12 and the theme step, each building on its route, and the finish into Home.

**Independent Test**: Fresh install, raise the sun, Get started → 4.11. Use my location (or a
city) → 4.12 with today's times. Dhuhr Silent, reminder 15, Allow → theme step. Iznik, Apply →
Home in Iznik. Restart: Home directly.

### Tests for User Story 2

- [X] T035 [P] [US2] Write `test/features/onboarding/view/location_step_page_test.dart` with a fake `PositionSource`: the 4.11 tree's content and the first dot wide; Use my location granted → the button is busy, then the route is `/onboarding/notifications`; refused → the location sheet opens with the `locationFailed` line; a city picked there → `/onboarding/notifications`; the sheet closed without a city → still `/onboarding/location`; Choose a city instead → the sheet without the line. Arabic, text scale 2.0.
- [X] T036 [P] [US2] Write `test/features/notifications/presentation/notifications_step_page_test.dart` with a fake scheduler, on the design scenario: five rows with 04:58, 12:05, 15:27, 17:56, 19:26 and Adhan, Tone, Tone, Adhan, Tone; the reminder row says "10 min"; a segment tap writes the store with one selection haptic; the reminder row opens the reminder sheet; Allow → `askPermission`, then `askExactAlarms` when granted, then `notificationsAsked` true, then `/onboarding/theme`; already allowed → `askPermission` still called (the fake returns true with no dialog) and `askExactAlarms` still called, so Android 12 gets its alarms page (FR-024); Not now → no ask, `notificationsAsked` stays false, `/onboarding/theme`; with Dhuhr already Silent and 15 minutes in the store from an earlier run, 4.12 shows them picked (FR-003). Arabic (Eastern digits), 12 hour, text scale 2.0 (rows stack above 1.4).
- [X] T037 [P] [US2] Write `test/features/theme_picker/theme_step_test.dart`: `ThemePage(onboarding: true)` has no back chevron; Apply saves the picked theme and mode, `onboarded` is true, the route is `/`; `ThemePage()` from More keeps the chevron and Apply pops as before.
- [X] T038 [P] [US2] Extend `test/features/notifications/presentation/view/adhan_settings_page_test.dart` (where the "off" line is tested): `notificationsAsked` false → the button asks (and writes it), true → it opens the notification settings through the mocked system channel (FR-026).

### Implementation for User Story 2

- [X] T039 [US2] Add `failed` to `showLocationSheet` and `LocationSheet` in `lib/core/widgets/sheet/location_sheet.dart`: true shows the `locationFailed` line from the start (research R9). Nothing else changes.
- [X] T040 [P] [US2] Write `lib/features/onboarding/view/location_step_page.dart` from the 4.11 tree: `StepDots(step: 1)`, the icon tile (`primaryContainer`, `onPrimaryContainer`, `BmIcon(BmIconName.location)` 30), title (`onboardingTitle`), body (`text2`), the card with three rows (`BmUiIcon.sun`, `compass`, `lock` in 40 pt tiles), Use my location (`BmButton.primary`, busy while looking), Choose a city instead (`BmButton.secondary`), the footnote; each part in its `StepReveal` slot, the icon tile in the title's; the flow of research R9 (push `Routes.onboardingNotifications` when `locationProvider` has a place).
- [X] T041 [P] [US2] Write `lib/features/notifications/presentation/view/notifications_step_page.dart` from the 4.12 tree: `StepDots(step: 2)`, title, body, the card of five `PrayerSoundRow`s, the reminder card (`BmIcon(BmIconName.adhan)`, "Reminder before each prayer", the value `reminderValue` or `reminderOff`, the forward chevron, opens `showReminderSheet`), Allow notifications (`BmButton.primary`) and Not now (`BmButton.text`); `StepReveal` slots; the flow of research R10: Allow always calls `askPermission` (no `isAllowed()` check first), then `askExactAlarms` when granted, then writes `notificationsAsked`, then pushes `Routes.onboardingTheme`.
- [X] T042 [US2] Change `lib/features/notifications/presentation/view/widgets/notifications_off_line.dart`: `notificationsAsked` false → ask as on 4.12 and write it, true → `SystemChannel.openNotificationSettings()` (FR-026).
- [X] T043 [US2] Add `onboarding` to `ThemePage` in `lib/features/theme_picker/view/theme_page.dart`: `CompactAppBar(StringsManager.theme, back: !onboarding)`, the preview, mode control, swatches and Apply in `StepReveal` slots (plain from More), Apply in onboarding → `apply()`, `ref.read(onboardingProvider.notifier).finish()`, `context.go(Routes.home)` (research R11).
- [X] T044 [US2] Add the three step routes to `lib/core/router/app_router.dart` under `/onboarding` with `_stepPage`: `location` → `LocationStepPage`, `notifications` → `NotificationsStepPage`, `theme` → `ThemePage(onboarding: true)` (contracts/onboarding-routes.md).

**Checkpoint**: a new install goes from the first screen to Home with a place, sounds and a theme,
and never sees a dialog it wasn't primed for.

---

## Phase 5: User Story 3 - Move my data to a new phone (Priority: P2)

**Goal**: Back up from More, restore from More and from 4.10, locked with a password.

**Independent Test**: Log, add qada, save a dua, Iznik. Back up with "test1234", save it. Delete,
reinstall, raise the sun, Restore: wrong password → its line; right → the steps with Iznik, Home
with the log.

### Tests for User Story 3

- [X] T045 [P] [US3] Write `test/core/backup/backup_file_test.dart` on host SQLite3MultipleCiphers with temp files: the header bytes of `contracts/backup-file.md`; a round trip opens with the password and holds every table; the file has no `Makkah`, no `2026-10-15` and no `SQLite format 3` in it (SC-006); the payload's `onboarded`, `notificationsAsked`, `storeResetPending` are false; wrong password → `BackupError.wrongPassword`; the magic changed → `notABackup`; the file cut short → `damaged`; schema 99 in the header → `newer`; a flipped byte deep in the payload → `damaged`; the same payload opened with sqlite3mc's default `kdf_iter` and the right password fails (research R12 check; if it opens, stop and tell me). Temp files are gone after each call.
- [X] T046 [P] [US3] Write `test/core/backup/restore_test.dart`: every row of every table comes back equal (SC-004), this phone's `onboarded`, `notificationsAsked`, `storeResetPending` stay as they were; an error in the middle leaves the store as it was; `backupTables` names every table in `AppDatabase.allTables` (fails when a table is added without it); a backup store at schema 5 (made from `test/drift/app_database/generated/schema_v5.dart`) migrates and restores.
- [X] T047 [P] [US3] Write `test/core/widgets/backup_sheets_test.dart` with a fake picker and a mocked share_plus platform: Save backup is off until both fields match with 6 characters, each error line shows at the right time, busy while making, the share gets one `better-muslim-YYYY-MM-DD.bmbackup` file; `pickAndRestore` with a non backup file opens the sheet with `notABackup` shown and Restore off; a wrong password shows `wrongPassword` and nothing changes; `confirm: true` shows the "Restore this backup?" dialog, Cancel changes nothing, Restore restores; a cancelled picker returns false. Arabic, text scale 2.0.
- [X] T048 [P] [US3] Extend `test/features/more/data_about_test.dart`: YOUR DATA shows Back up, Restore from backup, Reset prayer journey in that order; Back up opens the sheet; a restore from More ends with the `backupRestored` toast.

### Implementation for User Story 3

- [X] T049 [US3] Add `static Future<AppDatabase> backup(File file, String password)` to `lib/core/database/app_database.dart`: a `NativeDatabase` on the file with `setup` running `pragma cipher = 'chacha20'`, `pragma kdf_iter = 600000`, `pragma hexkey = '<utf-8 bytes of the password as hex>'` (contracts/backup-file.md), not shared across isolates. A one-line `///` on why hex (any password, no quoting).
- [X] T050 [US3] Write `lib/core/backup/backup_file.dart`: `enum BackupError { notABackup, damaged, newer, wrongPassword }` with each one's `StringsManager` key; `Future<File> writeBackup(AppDatabase from, String password)` (payload in `getTemporaryDirectory()`, typed copy of every table in `backupTables`, the phone's own columns false, close, the 19 byte header + payload into `better-muslim-YYYY-MM-DD.bmbackup` with Western digits, the payload temp deleted); `Future<(AppDatabase?, BackupError?)> readBackup(File file, String password)` doing the checks of the contract in order (magic, length, schema, first read SQLite 26, `pragma quick_check`), deleting the temp payload on every failure. Unexpected errors go to `CrashReporter` with the reason only.
- [X] T051 [US3] Write `lib/core/backup/restore.dart`: `const backupTables` (the five table names, a one-line `///` that a new table must be added here, the test checks it) and `Future<void> restore(AppDatabase into, AppDatabase from)`: one `transaction`, delete every table's rows, insert the backup's with a drift batch, write the settings row with this phone's `onboarded`, `notificationsAsked` and `storeResetPending` put back (data-model.md).
- [X] T052 [US3] Write `lib/core/widgets/backup/backup_sheet.dart` (`showBackupSheet(context)`: title `backUp`, two `BmTextField`s obscured, `passwordNote`, `passwordTooShort` and `passwordsDontMatch` lines, `saveBackup` enabled at 6 characters and a match, busy while `writeBackup` runs, then `SharePlus` with the file, temp file deleted when the share ends), `restore_sheet.dart` (title `restoreBackup`, `restorePasswordNote`, one field, a header error shown at once with Restore off, `wrongPassword` and `damagedBackup` under the field after Restore) and `pick_and_restore.dart` (`Future<bool> pickAndRestore(BuildContext context, {required bool confirm})`: `FilePicker` any type, the header check, the sheet, `readBackup`, with `confirm` the `showBmDialog` of `restoreTitle` / `restoreBody` / `restore`, then `restore`, closing the backup store and its temp file in every case).
- [X] T053 [US3] Add Back up and Restore from backup to YOUR DATA in `lib/features/more/view/more_page.dart` above Reset prayer journey with `NavRow` (FR-028): Back up → `showBackupSheet`, Restore → `pickAndRestore(confirm: true)` and `showToast(StringsManager.backupRestored)` when it restored.
- [X] T054 [US3] Wire 4.10's Restore from backup in `lib/features/onboarding/view/widgets/welcome_layer.dart` (through `welcome_page.dart`): `pickAndRestore(context, confirm: false)`, then `context.push(Routes.onboardingLocation)` when it restored (FR-033).

**Checkpoint**: a backup made on one phone restores on another, and every failure changes nothing.

---

## Phase 6: User Story 4 - Told once when my data was lost (Priority: P3)

**Goal**: The store reset notice over 4.10.

**Independent Test**: A reset store, raise the sun: the notice once 4.10 has built. Start fresh:
never again.

- [X] T055 [P] [US4] Write `test/features/onboarding/view/reset_notice_test.dart`: with `storeResetPending` true, once the welcome's build ends the dialog shows `resetNoticeTitle`, `resetNoticeBody`, Start fresh and Restore from backup (not tinted as destructive); Start fresh writes false and the dialog never shows again (replay); Restore from backup writes false first, then runs the fake picker; with the flag false nothing shows.
- [X] T056 [US4] Write `lib/features/onboarding/view/widgets/reset_notice.dart` (`showResetNotice(context)`: `showBmDialog(title: resetNoticeTitle, body: resetNoticeBody, action: restoreBackup, cancel: startFresh, destructive: false)`, `storeResetPending = false` before acting, Restore → `pickAndRestore(confirm: false)` → push 4.11 when restored) and call it from `welcome_page.dart` when the build completes and the setting is true (FR-036).

**Checkpoint**: everything the spec asks for is built.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [X] T057 [P] Add to the welcome, step, theme step, sheet and More tests: Arabic (mirrored steps, Eastern digits, the sun's gesture unchanged), text scale 2.0 (nothing cut, steps scroll with buttons at the bottom, the horizon doesn't move), light and dark, reduce motion on and off, a tablet width (stretched to 480 pt), every action at least 44 x 44 (FR-040, the text scale and Arabic edge cases, SC-003, SC-008).
- [X] T058 [P] Add the welcome's text over all six sky states and the theme base to `test/core/resources/contrast_test.dart`: the title and tagline color the welcome uses (with the scrim on bright states) at least 3:1 for the 42 pt title and 4.5:1 for the tagline. If a state fails, stop and tell me which; never change a palette value.
- [X] T059 [P] Write `integration_test/onboarding_journey_test.dart` on the design scenario: More → Notifications (dev) → Replay onboarding → tap the sun's semantics → Get started → Choose a city instead → Makkah → 4.12 shows 17:56 for Maghrib → Not now → Iznik → Apply → Home, and no system dialog on the way.
- [X] T060 Run the self check from the `adaptive-widgets` skill on every new and changed file, `flutter test test/architecture_test.dart`, and fix every hit.
- [ ] T061 Run `dart format --set-exit-if-changed lib test integration_test`, `flutter analyze` and `flutter test`, all clean.
- [X] T062 Run `integration_test/onboarding_journey_test.dart` on a simulator, then hand me quickstart.md section 2 (the design scenario steps 1 to 9 and the phone steps 10 to 16) to run myself. No simulator walk through beyond the journey test.
- [X] T063 Hand me quickstart.md step 16 for SC-002 to run myself: `flutter run --profile --flavor dev -t lib/main_dev.dart --dart-define-from-file=dart_define/dev.json` on a 2021 mid range Android (Galaxy A52 class), the performance overlay on, replay onboarding, drag the sun up and down and let the welcome build: no frame over 16 ms. If some are, note which part (the shader, the stars, the text blur) for a follow up, don't tune it blind.
- [X] T064 [P] Update the milestone list in `CLAUDE.md`: "10. Onboarding and backup: the sunrise first screen in liquid glass, the welcome, location, notifications and theme steps, the backup file with Back up and Restore, the store reset notice. **Done, waiting for my review.**", and "11. as in `HANDOFF_CLAUDE.md`."
- [X] T065 Run `grep -rn "TODO(ahmed)" lib assets ios android pubspec.yaml shaders` and list in the reply what I still have to supply, plus anything new from this milestone.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: T001 first, the constitution before any code. Then T002 to T004.
- **Foundational (Phase 2)**: after Setup. Blocks every story.
- **US1 (Phase 3)**: after Phase 2. The MVP: the sunrise and the welcome.
- **US2 (Phase 4)**: after Phase 2. Get started (T032) pushes the route T044 adds; the steps can
  be built alongside US1 and reached by URL in tests.
- **US3 (Phase 5)**: after Phase 2. T054 after T031 and T032.
- **US4 (Phase 6)**: after US1 (the welcome) and US3 (`pickAndRestore`).
- **Polish (Phase 7)**: after the stories.

### Inside Phase 2

- T005 to T009 (tests) before their code.
- T010 then T011 (finish writes the new column), then T012 and T013.
- T014 to T022 touch different files and run in parallel.

### Inside the stories

- US1: T023, T024 first. T025 and T026 before T027. T028 to T031 in parallel. T032 after them,
  then T033 and T034.
- US2: T035 to T038 first. T039 before T040. T040, T041 in parallel, then T042 to T044.
- US3: T045 to T048 first. T049 then T050, T051, then T052, then T053 and T054.

### Parallel Opportunities

- Phase 2: T005 to T009 together. Then T014 to T022 together, beside T010 to T013.
- US1: T023, T024, T025, T026 together, then T028 to T031 together.
- US2: T035 to T038 together, then T040 and T041.
- US3: T045 to T048 together.
- Polish: T057, T058, T059, T064 together.

## Parallel Example: Phase 2

```text
Task: "T014 sky state to core"
Task: "T015 no launch dialogs"
Task: "T016 StepScope, StepReveal, StepDots"
Task: "T017 BmTextField"   "T018 BmButton.text"   "T019 showBmDialog cancel, destructive"
Task: "T020 BmHaptics.sunLetGo"
Task: "T021 strings"   "T022 sizes"
```

## Parallel Example: User Story 1

```text
Task: "T028 welcome sky"
Task: "T029 welcome stars"
Task: "T030 welcome sun"
Task: "T031 intro and welcome layers"
```

## Implementation Strategy

### MVP First (User Story 1)

1. Phase 1 (constitution, branch, package, shader asset), then Phase 2.
2. US1: the first screen and the sunrise into 4.10. Stop and check it through Replay on the design
   scenario and on a real phone (the glass needs the phone's shader support).

### Incremental Delivery

1. US1 → the sunrise.
2. US2 → the three steps and the finish into Home. A new install works end to end.
3. US3 → back up and restore.
4. US4 → the reset notice.
5. Polish → languages, text scale, contrast, the journey test, checks, CLAUDE.md. Then stop for my
   review (constitution workflow).
