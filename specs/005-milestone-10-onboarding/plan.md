# Implementation Plan: Milestone 10, Onboarding and Backup

**Branch**: `feature/milestone-10`, cut when the build starts, after milestone 9 | **Date**:
2026-10-19 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/005-milestone-10-onboarding/spec.md`

## Summary

The first launch (4.10, 4.11, 4.12, the theme step) with the sunrise from my
`liquid_glass_onboarding` project, and the app's backup file:
- **Gate**: `settings.onboarded` (schema 6), read in bootstrap, a router redirect, a dev replay
  (R2). The launch dialogs from milestones 2 and 5 go, the primers ask (R3).
- **Sunrise**: one `WelcomePage` for the first screen and 4.10, the reference's drag, springs and
  build ported with 4.10's geometry (R4), its glass shader with theme colors, a fill and a clip
  (R5), the designed sun at rest (R6), the welcome sky and ten flying stars (R7).
- **Steps**: each step route's 900 ms transition is its build, through `StepScope` and
  `StepReveal` (R8). 4.11 on the location controller and sheet (R9), 4.12 in notifications with
  the permission written after the answer (R10), the theme page with an onboarding flag and a fade
  into Home (R11).
- **Backup**: a header plus a second drift store locked with the password by sqlite3mc, typed copy
  both ways, all or nothing (R12, R13), picked with file_picker and shared with share_plus (R14),
  sheets on a new 03 Inputs field (R15), the reset notice over 4.10 (R16).

One new package (file_picker, approved). No network. Schema 6.

## Technical Context

**Language/Version**: Dart 3.13, Flutter 3.47.5 stable. GLSL for the fragment shader. A few lines
of Ruby in the iOS Podfile.

**Primary Dependencies**: already in: drift 2.35 with sqlite3 3.5.2 built as SQLite3MultipleCiphers,
flutter_riverpod 3.4.3, go_router 18.1, geolocator 14.1, flutter_local_notifications 22.3.2,
share_plus 13.3.1, flutter_screenutil. New: file_picker 13.1.0 (approved in the spec).

**Storage**: drift, schema 6: `settings.onboarded` (data-model.md). The backup file is a second
store of the same schema, encrypted with the password (contracts/backup-file.md).

**Testing**: unit tests for the choreography, the backup (round trip, errors, no plaintext, every
table), the redirect and the v5 → v6 migration. Widget tests for the first screen, 4.10, 4.11,
4.12, the theme step, the reset notice and the backup sheets and rows, in both languages, both
modes, text scale 2.0 and reduce motion. One integration test through Replay on the design
scenario.

**Target Platform**: iOS 15+, Android 8.0+ (minSdk 26). The refracting glass where the shader
filter is supported (Impeller), the frosted glass elsewhere.

**Project Type**: mobile app

**Performance Goals**:
- the drag and the builds at the phone's frame rate on a 2021 mid range Android (SC-002)
- the shader only while the lens shows, the ticker stops once everything settles, 4.10 at rest is
  the designed sun and the 30 fps ambient in a `RepaintBoundary`
- a backup of a few thousand rows made and restored in well under a second, plus the key
  derivation

**Constraints**:
- offline, the place stays on the phone, the backup leaves only through the share sheet
- 4.10, 4.11, 4.12, 4.15 from their trees; the first screen only from 4.10's parts
- RTL, Eastern digits per setting, text scale 2.0, reduce motion, 44 x 44, AA in 8 themes x 2 modes
- no literal colors in Dart or GLSL, every size from the managers

**Scale/Scope**: 4 onboarding routes (1 new page with 2 stages, 2 step pages, 1 flag on the theme
page), 1 shader port (about 300 lines with its render object), 2 sheets, 1 dialog variant, 1 text
field, 3 step widgets, 2 More rows, schema 6, about 30 strings in 2 languages, about 25 named
sizes

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Result |
| --- | --- | --- |
| I. Structure | `features/onboarding/` MVVM (listed): `model/sun_choreography.dart` and `view/`. The sun's stage lives in the page's state like in the reference, so no `view_model/` (the shape test takes a subset). 4.12 in `features/notifications/presentation/` like Adhan and reminders. The theme step is `theme_picker`'s page with a flag. Shared in core once: onboarding state, step scope, reveal and dots, the backup, the backup sheets, the text field, the sky state (moved from home). The router composes the flow. No feature imports another | pass |
| II. Design system | weight text widgets, adaptive paddings, `RSizedBox`, `ThemeEnum` (the shader gets `glow` and `sun` as uniforms, the stars `onSkyBright`), `BmIcon`, named sizes for 4.10's geometry, `StringsManager` with both arbs, `BmHaptics.sunLetGo()` added next to the others | pass |
| III. Faithful | 4.10, 4.11, 4.12 and 4.15 from their trees, end states exact. The first screen and the sunrise motion are new, by my explicit instruction in this spec's clarifications (governance: my instruction overrides). The headline isn't Quran text. Ceremonial build 1800 ms (the tier's top), taps finish a build, reduce motion fallbacks for all of it | pass |
| IV. Simplicity | one shader from the reference, not its bubble field (ten tweens instead), the route animation is the step build, the backup is a second store with no crypto package, one restore path for three entry points, no scheduled backups | pass |
| V. Performance | `.select()`, the ticker stops at rest, no shader at rest, ambient at 30 fps paused in background and power saving, const leaves | pass |
| VI. Tests | unit, widget and one integration test as above, migration v5 → v6, architecture and strings tests green | pass |
| VII. Privacy | the backup is encrypted with the password (ChaCha20-Poly1305, 600 000 key derivation rounds), the password is never stored, the phone's own columns aren't in it, temp files deleted, errors reported with the reason only | pass |
| VIII. Offline and free | everything on the phone, the file goes where I share it | pass |
| Stack | + file_picker, approved in the spec: T001 adds it to the constitution's package list (MINOR, 3.5.0) | pass, with T001 |
| Handoff code | `BmHaptics` gets one entry, `showBmDialog` two optional parameters, every existing value stays | pass |

**Post-design re-check**: still passes. T001 is a MINOR (3.5.0) for file_picker.

## Project Structure

### Documentation (this feature)

```text
specs/005-milestone-10-onboarding/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── backup-file.md
│   ├── onboarding-routes.md
│   └── liquid-glass-shader.md
├── checklists/requirements.md
└── tasks.md            # /speckit-tasks
```

### Source Code (repository root)

```text
shaders/liquid_glass.frag                          # from the reference, contracts/liquid-glass-shader.md

lib/
├── bootstrap.dart                                 # reads onboarded before runApp
├── core/
│   ├── backup/
│   │   ├── backup_file.dart                       # header, write, read, BackupError
│   │   └── restore.dart                           # one transaction, phone columns kept
│   ├── database/app_database.dart                 # schema 6, AppDatabase.backup(file, password)
│   ├── flavor/design_scenario.dart                # onboarded = true
│   ├── location/location_controller.dart          # no request at launch, firstLocate gone
│   ├── prayer_times/sky_state.dart                # moved from home: skyState, starsOn, provider
│   ├── resources/
│   │   ├── design/bm_haptics.dart                 # + sunLetGo
│   │   ├── dimensions_manager.dart                # + 4.10 geometry, step, field sizes
│   │   └── strings_manager.dart                   # + keys
│   ├── router/app_router.dart                     # onboarding routes, redirect, shell fade
│   ├── settings/onboarding.dart                   # Onboarding(done, replay), finish, replay
│   └── widgets/
│       ├── backup/ backup_sheet.dart  restore_sheet.dart  pick_and_restore.dart
│       ├── bm_dialog.dart                         # + cancel, destructive
│       ├── sheet/location_sheet.dart              # + failed
│       ├── step/ step_scope.dart  step_reveal.dart  step_dots.dart
│       └── text_field.dart                        # 03 Inputs
└── features/
    ├── onboarding/
    │   ├── model/
    │   │   ├── lens_spec.dart                     # LensSpec, plain data the choreography returns
    │   │   └── sun_choreography.dart              # SunStage, geometry, size by height, build
    │   │                                          # intervals
    │   └── view/
    │       ├── welcome_page.dart                  # first screen + 4.10, drag, springs, build
    │       ├── location_step_page.dart            # 4.11
    │       └── widgets/
    │           ├── glass/liquid_glass.dart        # LiquidGlassLayer, FallbackGlass
    │           ├── welcome_sky.dart               # gradient, horizon, arc, mark
    │           ├── welcome_stars.dart             # flight and twinkle
    │           ├── welcome_sun.dart               # the designed sun at rest
    │           ├── intro_layer.dart               # headline, hints
    │           ├── welcome_layer.dart             # title, tagline, buttons
    │           └── reset_notice.dart              # FR-036
    ├── notifications/
    │   └── presentation/
    │       ├── notifications_boot.dart            # no first ask, notificationsAsked in inputs,
    │       │                                      # taps skipped while onboarding
    │       └── view/
    │           ├── notifications_step_page.dart   # 4.12
    │           ├── dev_notifications_page.dart    # + Replay onboarding
    │           └── widgets/notifications_off_line.dart   # asks first when never asked
    ├── theme_picker/view/theme_page.dart          # onboarding flag
    ├── more/view/more_page.dart                   # Back up, Restore from backup
    └── home/                                      # sky state import from core

ios/Podfile                                        # PICKER_MEDIA, PICKER_AUDIO false
pubspec.yaml                                       # file_picker, shaders
assets/l10n/app_en.arb, app_ar.arb
drift_schemas/app_database/drift_schema_v6.json

test/core/backup/ backup_file_test.dart  restore_test.dart
test/core/settings/onboarding_test.dart
test/core/router/onboarding_redirect_test.dart
test/drift/app_database/migration_test.dart        # v5 → v6
test/features/onboarding/ model/  view/
test/features/notifications/presentation/notifications_step_page_test.dart
test/features/theme_picker/ test/features/more/
integration_test/onboarding_journey_test.dart
```

**Structure Decision**: one Flutter app. Onboarding is the MVVM feature the constitution lists,
4.12 sits in notifications and the theme step in theme_picker, the router puts them in order.
The shader lives at the repo root in `shaders/`, outside `lib/`, as Flutter expects.

## Key Flows

1. **Launch**: bootstrap opens the store, reads `onboarded`, overrides `onboardingProvider`. The
   router's redirect sends a new install to `/onboarding`, everyone else to `/`.
2. **First screen**: the sky at the current hour without stars, the headline, the dome, the hint.
   It enters over 1200 ms (FR-006). A pan inside the grab area starts a drag: the ticker moves the
   sun toward the finger, the choreography gives size, glow and the headline's blur from its
   height. Crossing the horizon shows the ready hint with a selection haptic.
3. **Let go**: above the horizon or a flick up → `sunLetGo` haptic, home = horizon, `b` 0 → 1 over
   1800 ms, overlapping in this order: title out of the sun, horizon, mark, fill, stars, tagline,
   buttons. Below → spring back into the dome. Only the first finger moves the sun, a cancelled
   pointer springs it home.
4. **On 4.10**: a grab clears the fill, a drag toward the bottom drives `b` down, past the commit
   line (or the system back) → sink into the dome, glow flash, stars fade, stage back to intro. When the build ends and
   `storeResetPending` is set, the reset notice shows.
5. **Get started**: push `/onboarding/location`. The welcome's content fades out in reverse build
   order over the first 300 ms of the secondary animation while 4.11's background fades in, then
   4.11's slots build.
6. **4.11**: `useAuto()` → push 4.12, or the city search (with the failed line after a refusal) →
   a place → push 4.12.
7. **4.12**: rows write the store at once. Allow → always ask (no dialog when already allowed),
   alarms when needed, `notificationsAsked`, push theme. Not now → push theme.
8. **Theme step**: Apply → save, `finish()`, `go('/')`, the shell fades in over 300 ms.
9. **Back up**: More → sheet → `writeBackup` → share sheet → temp files deleted.
10. **Restore**: 4.10, More or the notice → `pickAndRestore` → header checks → password sheet →
    `readBackup` → (More: dialog) → `restore` in one transaction → toast (More) or push 4.11
    (4.10, notice).
11. **Replay**: the dev page sets replay and goes to `/onboarding`. Apply clears it.

## Decisions (2026-10-19)

The clarify answers (all recommendations, and Motion 01 left out) are in the spec. The plan adds
these:
1. **4.12 lives in notifications**, next to the rows, the reminder sheet and the permission calls
   it uses (R1, R10).
2. **The step build is the route's transition** (R8): 900 ms in, 150 ms out, no controller per
   page.
3. **The backup is a second encrypted store** with a 19 byte header, copied with typed drift
   reads both ways (R12, R13). No crypto package.
4. **`notificationsAsked` is written after the answer** and joins the schedule inputs, so a grant
   on 4.12 schedules at once (R10). It also decides whether the "off" line asks or opens settings.
5. **file_picker without its media pods** through the Podfile flags (R14). `file_selector` would
   be lighter still, file_picker is the approved one.
6. **The in-app adhan still covers onboarding**, other notification taps wait until it's finished
   (R18).
7. **Home's sky state moves to core**, the welcome reads the same current sky (R7).

## Complexity Tracking

| Addition | Why Needed | Simpler Alternative Rejected Because |
| --- | --- | --- |
| a fragment shader and its render object (about 300 lines from the reference) | the refracting, flipping, squashing lens of FR-007 | a blur doesn't bend; a package for one lens isn't the reference |
| a 19 byte header in front of the backup store | not a backup, damaged and newer tell apart before the password (FR-031, FR-034) | only the store: every failure looks like a wrong password |
| reading `onboarded` in bootstrap | the first frame already on the right route (FR-001) | redirect on the settings stream: Home or the welcome flashes for a frame |
| `StepScope` and `StepReveal` in core | 4.11, 4.12 (another feature) and the theme step build the same way (FR-017) | a copy per feature, or 4.12 moved out of notifications and a feature import |
