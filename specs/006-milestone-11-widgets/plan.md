# Implementation Plan: Milestone 11, Widgets and Live Activity

**Branch**: `feature/milestone-11`, cut when the build starts, after milestone 10 | **Date**:
2026-10-20 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/006-milestone-11-widgets/spec.md`

## Summary

The prayer times outside the app, native code fed by the app:
- **Data**: Dart works out every moment of the next 7 prayer days ahead (entries) and the
  countdown windows, already in the app's language, digits and 12/24 hour setting, with the same
  functions as Home's providers (R3). The native side only picks the entry in force and counts
  minutes and shares. One JSON file, out of every backup, readable while locked (R4).
- **Writes**: launch, resume, any input change, a prayer marked anywhere, the background top-up,
  mark prayed from a notification. Equal data skips the write: the first entry starts at the
  current stretch and nothing holds the write's moment (R5).
- **iOS**: one WidgetKit extension with the small, medium and large widgets, the three
  accessories (a timeline entry per minute) and the Live Activity with the Dynamic Island (system
  timer, stale "Now", iOS 26 scheduled starts) (R6, R7).
- **Android**: an `AppWidgetProvider` drawn in the app's fonts, moved by non wakeup minute alarms,
  and the countdown as an ongoing notification, a Live Update on Android 16 (R8, R9).
- **Plumbing**: one local plugin, `packages/prayer_surfaces`, in every engine (R1, R2). Taps are
  deep links into go_router (R11). The switch in schema 7 (R13). Two dev rows (R14).

No new pub package, no network. Schema 7. Seven platform limits, answered with the recommendations
(Answered).

## Technical Context

**Language/Version**: Dart 3.13, Flutter 3.47.5 stable. Swift 5 with SwiftUI, WidgetKit and
ActivityKit (Xcode 27). Kotlin 2.4, AGP 9.1, compileSdk 36. A one-off Ruby script with the
installed `xcodeproj` gem to add the iOS target.

**Primary Dependencies**: already in: drift 2.35, flutter_riverpod 3.4.3, go_router 18.1,
workmanager 0.10, flutter_local_notifications 22.3.2, timezone, intl, hijri, adhan_dart. New: none
(the local plugin `packages/prayer_surfaces` instead of home_widget and live_activities, Q5). No
new Android or iOS library: plain `AppWidgetProvider`, `Notification.Builder`, WidgetKit,
ActivityKit.

**Storage**: drift, schema 7: `settings.prayerCountdown` (data-model.md). `surfaces.json` in the
iOS app group container and Android's `filesDir` (contracts/surface-data.md).

**Testing**: unit tests for the builder against Home's providers every 5 minutes over 7 days in
three places, the windows, the texts, the key set; the writer; the boot; migration v6 → v7. Widget
tests for the countdown row and the dev rows. The native surfaces are checked on the phones with
quickstart.md (no goldens, no screenshots).

**Target Platform**: iOS 15+ home widgets, iOS 16+ accessories, iOS 16.2+ Live Activity (Q7),
the Dynamic Island where the iPhone has it. Android 8.0+ (minSdk 26) widget and countdown, Android
16+ Live Update.

**Project Type**: mobile app with a widget extension and a local plugin

**Performance Goals**:
- building the JSON (9 days of times, about 50 entries) in a timer callback after a 500 ms
  debounce, never inside a build or a provider, so marking a prayer or a setting never drops a
  frame (SC-007)
- equal data writes nothing and reloads no widget
- iOS: about 4 timeline reloads a day; Android: work only at a minute flip while the screen is on,
  only the countdown picture redrawn

**Constraints**:
- offline, no server, no push (FR-005)
- every surface from its tree in the dark Qiyam Emerald values, both languages, both digit
  settings, 12 and 24 hour, fixed sizes at every text size
- the surface data holds only what the surfaces show and never reaches a backup
- the native code holds the dark values as literals in one file per platform (outside Dart's
  architecture test, as the always dark exception)

**Scale/Scope**: 1 local plugin (about 7 Kotlin files, 1 Swift file), 1 widget extension (about 8
Swift files), 4 Dart files in core and the feature, 1 row and 2 dev rows, schema 7, 12 strings in
2 languages, plus the 4 gallery and picker texts in the native string files

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Result |
| --- | --- | --- |
| I. Structure | `features/surfaces/` clean, as listed ("home widgets and live activity"), with `presentation/surfaces_boot.dart`. The builder, writer and channel in `core/surfaces/` because notifications' background code writes too. The countdown row and dev rows in notifications' page, importing core. Native code that runs in every engine in `packages/prayer_surfaces`. The extension in `ios/PrayerWidgets/` (an Xcode target can't be a plugin). No feature imports another | pass |
| II. Design system | Dart: `ToggleRow` in a `GroupedSection`, `StringsManager` with both arbs, no new sizes. Native: no `ThemeEnum` there, so the dark values (TOKENS.md) and the trees' values in one colors file per platform, the always dark surface exception. Fonts from `assets/fonts/`, icons from `assets/icons/` as vectors | pass |
| III. Faithful | every surface from its tree. Where the platform can't draw the tree as is (the iOS bar's sun, compact h:mm, system drawn digits), Q2 to Q4 have my approval and the spec says so. Q1 keeps the Android widget exact. The large widget's 40 pt rows stay under the 44 pt hit target, approved as a break (spec, analyze session) | pass |
| IV. Simplicity | no package, no Glance, no Compose. The rules in Dart once, three formulas natively. One file, one channel, one plugin for every surface | pass |
| V. Performance | debounced writes, equal check, per minute work only while seen, partial redraws | pass |
| VI. Tests | builder against Home over 7 days (SC-001), windows, key set (SC-006), writer, boot, migration, rows; architecture and strings tests green | pass |
| VII. Privacy | only the shown fields, no coordinates or history, out of iCloud and Android backups, the phone's file protection, the database key untouched | pass |
| VIII. Offline and free | all on the phone, no push, no server | pass |
| Stack | home_widget and live_activities are listed for this milestone and not used (R2), approved (Q5): T001 changes the stack line to the local plugin (MINOR, 3.6.0) | pass with T001 |
| Handoff code | `lib/core/resources/design/` untouched | pass |

**Post-design re-check**: still passes. T001 is a MINOR (3.6.0) for the local plugin.

## Project Structure

### Documentation (this feature)

```text
specs/006-milestone-11-widgets/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── surface-data.md
│   ├── surfaces-channel.md
│   └── native-surfaces.md
├── checklists/requirements.md
└── tasks.md            # /speckit-tasks
```

### Source Code (repository root)

```text
lib/
├── bootstrap.dart                                 # NotificationsBoot(SurfacesBoot(App()))
├── core/
│   ├── database/app_database.dart                 # schema 7, prayerCountdown
│   ├── resources/strings_manager.dart             # + keys
│   └── surfaces/
│       ├── surface_data.dart                      # buildSurfaceData: entries, windows, texts
│       ├── surfaces_channel.dart                  # update, startNow
│       └── write_surfaces.dart                    # store → builder → channel, no riverpod
└── features/
    ├── surfaces/
    │   └── presentation/surfaces_boot.dart        # inputs, prayer_log, resume, window timer
    └── notifications/
        ├── data/background.dart                   # top-up and mark prayed write the surfaces
        └── presentation/view/
            ├── adhan_settings_page.dart           # + the countdown group
            ├── dev_notifications_page.dart        # + Start countdown now, Refresh widgets
            └── widgets/countdown_row.dart         # ToggleRow on prayerCountdown

packages/prayer_surfaces/
├── pubspec.yaml                                   # plugin, android + ios
├── android/src/main/
│   ├── AndroidManifest.xml                        # receivers, POST_PROMOTED_NOTIFICATIONS
│   ├── kotlin/com/elhawary/bettermuslim/surfaces/
│   │   ├── PrayerSurfacesPlugin.kt                # the channel
│   │   ├── SurfaceData.kt                         # file read/write, entry at a moment, counts
│   │   ├── SurfaceTicks.kt                        # minute tick and window alarms, re-arm
│   │   ├── PrayerWidget.kt                        # AppWidgetProvider, sizes, taps
│   │   ├── WidgetPainter.kt                       # 5.8 on a Canvas, the app's fonts
│   │   ├── CountdownNotification.kt               # channel, ongoing, Live Update
│   │   └── SurfacesReceiver.kt                    # ticks, alarms, boot, time and zone changes
│   └── res/                                       # widget layout, appwidget-provider, sun, star,
│                                                  # check vectors, colors, strings (+ values-ar)
└── ios/prayer_surfaces/
    ├── Package.swift
    └── Sources/prayer_surfaces/
        ├── PrayerSurfacesPlugin.swift             # file, backup exclusion, reload, activities
        └── PrayerCountdownAttributes.swift        # the same struct as the extension's

ios/
├── PrayerWidgets/
│   ├── PrayerWidgetsBundle.swift                  # Next prayer, Today's prayers, the lock screen,
│   │                                              # the activity
│   ├── SurfaceData.swift                          # decode, entry at a moment, counts
│   ├── Timeline.swift                             # minute entries, .atEnd
│   ├── SmallWidget.swift  MediumWidget.swift  LargeWidget.swift
│   ├── Accessories.swift                          # circular, rectangular, inline
│   ├── MessageView.swift                          # no place and out of date
│   ├── CountdownActivity.swift                    # 5.3 card, 5.4 island
│   ├── PrayerCountdownAttributes.swift            # the same struct as the plugin's
│   ├── SurfaceColors.swift  SurfaceFonts.swift
│   ├── Assets.xcassets                            # star, check, adhan vectors
│   ├── Info.plist  PrayerWidgets.entitlements
│   └── en.lproj/ ar.lproj/Localizable.strings     # gallery names and descriptions
├── Runner/Info.plist                              # NSSupportsLiveActivities, AppGroup, scheme
├── Runner/Runner.entitlements                     # + app group
├── Runner/Sounds/silence.caf                      # the iOS 26 start alert
└── Runner.xcodeproj                               # + PrayerWidgets target, APP_GROUP per flavor

pubspec.yaml                                       # prayer_surfaces path dependency
assets/l10n/app_en.arb, app_ar.arb
drift_schemas/app_database/drift_schema_v7.json

test/core/surfaces/ surface_data_test.dart  write_surfaces_test.dart
test/features/surfaces/presentation/surfaces_boot_test.dart
test/features/notifications/                       # countdown row, dev rows, background writes
test/drift/app_database/migration_test.dart        # v6 → v7
```

**Structure Decision**: one Flutter app, a local plugin for the code every engine needs, an iOS
app extension for WidgetKit and ActivityKit's views. The Dart side is small and shared from core,
the surfaces feature only holds its boot.

## Key Flows

1. **Launch / resume**: `SurfacesBoot` reads the store, `buildSurfaceData`, `update(json)`. The
   plugin writes the file if it changed, reloads the widgets, syncs the countdowns. The boot sets
   a timer to the next window start or end.
2. **A change** (place, method, digits, reminder, switch, a mark): 500 ms later the same as 1.
3. **App closed**: iOS widgets walk their minute entries and reload at the end of 6 hours.
   Android's tick fires at each minute flip while the phone is awake and redraws the countdown,
   an entry change redraws everything.
4. **A window starts**: Android's wakeup alarm posts the notification, `setTimeoutAfter` ends it
   at the prayer. iOS 26 shows the scheduled activity by itself. iOS 16.2 to 18 waits for the app.
5. **The prayer time**: Android's notification goes. iOS: ended at once if the app runs, else
   "Now" with the full bar until the next sync.
6. **Mark prayed from a notification**: `markFromPayload` marks, then `writeSurfaces`: the ticks,
   the count, "· prayed", and a stale activity ends.
7. **Background top-up**: `writeSurfaces` first (7 days again), then the notifications.
8. **Tap**: `bettermuslim://open/...` → Flutter's deep link → go_router (Home or
   `Routes.prayerAt`).

## Answered (2026-10-20)

Every recommendation taken. The spec carries them (Clarifications, plan session).

| # | Question | Answer |
| --- | --- | --- |
| Q1 | Android widget fonts: Glance and widget layouts can only use system fonts (R8) | the widget drawn on a Canvas in the app's fonts, exact 5.8 |
| Q2 | iOS Live Activity bar: the sun can't move with the app closed (R7) | the system's timer bar in gold, always right, no sun dot |
| Q3 | compact Dynamic Island: no live h:mm in a Live Activity (R7) | h:mm:ss as on the lock screen |
| Q4 | system drawn countdowns use the phone's digits (Android surely, iOS to check) (R7, R9) | accepted, only Arabic with Western digits can differ |
| Q5 | home_widget and live_activities from the constitution (R2) | not used, the local plugin. T001 updates the constitution (3.6.0) |
| Q6 | after Isha the next Fajr isn't in the shown day (R3) | no highlighted cell, every cell past |
| Q7 | iOS 16.1 has no stale date (R7) | Live Activity from iOS 16.2 |

## Decisions (2026-10-20)

The clarify answers are in the spec. The plan adds these:
1. **Dart works out every moment, native counts** (R3): entries at every boundary with final
   strings, tested against Home's providers.
2. **One local plugin** for every surface, in every engine (R1, R2).
3. **A plain file**, excluded from iCloud backup on every write, protected until first unlock
   (R4).
4. **Per minute timeline entries on iOS** for h:mm, the sun and the ring (R6).
5. **Non wakeup exact minute alarms on Android**: right whenever the screen is on, no battery
   with it off (R8).
6. **The surfaces write before the notification permission check** in the top-up (R5).
7. **Deep links for taps** (R11), the scheme registered on iOS.
8. **"Next · {city}" and "{prayer} {time}"** added, the copy table missed them (R15).
9. **The iOS 26 alert** reuses the prayer's name and "Next prayer · {city}", with a silent sound
   (R7).
10. **No third dev row**: the no place state is checked on a fresh install (R14).

## Complexity Tracking

| Addition | Why Needed | Simpler Alternative Rejected Because |
| --- | --- | --- |
| a local plugin with Kotlin and Swift | the channel must exist in the top-up's and mark prayed's engines, and iOS 26 scheduling, the stale date and backup exclusion aren't in the packages | home_widget + live_activities: iCloud backed storage, no scheduled start, no Android countdown |
| entries for every boundary instead of raw times | the prayer rules stay in Dart, tested against Home (FR-003, SC-001) | raw times with the rules again in Swift and Kotlin |
| the Android widget drawn on a Canvas (Q1) | the only way to the design's fonts in a widget | XML layouts: system fonts only |
| non wakeup minute alarms | Android has no live h:mm countdown in a widget | `Chronometer`: always shows seconds, not 5.8's h:mm |
| a Ruby script to add the Xcode target | the target needs 9 flavor configurations and app groups set the same way each time | by hand in Xcode: 9 configurations to get right by clicking |
