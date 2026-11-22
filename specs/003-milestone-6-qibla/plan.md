# Implementation Plan: Milestone 6, Qibla

**Branch**: `feature/milestone-6`, cut from where milestone 5 ends | **Date**: 2026-10-18 |
**Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/003-milestone-6-qibla/spec.md`

## Summary

The Qibla page (4.05, 4.06) on top of milestone 2's location:
- **Heading**: the app's own `better_muslim/compass` channel sends the magnetic heading and its
  accuracy (R2). The World Magnetic Model 2025 in Dart turns it to true north (R3). Smoothed on
  the unit circle (R5).
- **Target**: bearing from adhan_dart's `Qibla.qibla`, distance by haversine with the mean radius,
  so London shows 119° and 4,790 km (R4). From a fresh precise fix in auto mode, never saved
  (R10).
- **Alignment**: a pure tracker for ±3° for 400 ms, out past ±5°, approach at ±10° re-armed past
  ±15° (R6). Motion 09 and 10 from MOTION.md (R7).
- **States**: weak compass, no compass, no location, before the first reading (R9, R11).
- **Entry**: a top level route that covers the tab bar, a temporary button on the More
  placeholder, the gear opens milestone 3's location sheet (R15).
- **Checking it**: the design scenario shows London at 105°, a tap on the dial switches to 119°
  (R12).

No new pub.dev package, no network. flutter_compass, listed in the constitution, is not added
(R2, OK given 2026-10-18, T001 amends the constitution).

## Technical Context

**Language/Version**: Dart 3.13, Flutter 3.47.5 stable. Swift (iOS 15+) and Kotlin (JVM 17) for
the compass channel.

**Primary Dependencies**: what is already in. adhan_dart 2.0.1 (`Qibla.qibla`), geolocator 14.1.1
(the fix, through `PositionSource`), flutter_riverpod 3.4.3, go_router 18.1, intl 0.20.3
(`NumberFormat`), flutter_screenutil. Dev: `integration_test` from the SDK.

**Storage**: none. Nothing about the Qibla is stored (FR-028).

**Testing**: unit tests for the bearing, distance and rounding (20 places against WGS84 reference
values), the magnetic model (NOAA's WMM2025 test values), the tracker (every threshold, jitter)
and the smoothing. Widget tests for every state of the page. The architecture test. One
integration test on the design scenario.

**Target Platform**: iOS 15+, Android 8.0+ (minSdk 26)

**Project Type**: mobile app

**Performance Goals**:
- the dial follows each reading in the same frame, the needle settles in about 1 s (SC-004)
- text rebuilds only when the whole degree or the phase changes (R7)
- the needle still within 1° on a still phone (SC-004)

**Constraints**:
- offline, no location permission needed for the compass itself
- the heading and the fix never stored or reported
- the sensor runs only while the page is visible (SC-007)
- built from the 4.05 and 4.06 trees, text scale 2.0, reduce motion, RTL with the dial never
  mirrored

**Scale/Scope**: 1 pushed page, 2 native channel handlers (about 45 lines of Swift and 60 of
Kotlin), 1 magnetic model (about 80 lines and 90 coefficient rows), 1 core widget moved out of
Home, 14 strings in 2 languages, about 25 named sizes and gaps

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Result |
| --- | --- | --- |
| I. Structure | `features/qibla/{model,view_model,view}` (MVVM as listed). The compass channel, the magnetic model, the tracker and the math are only Qibla's, so they stay in the feature. `PositionSource` and the location sheet are already core. The two location buttons Home and Qibla share move to `core/widgets/sheet/` (R1). The router imports the page, as allowed. No feature imports another | pass |
| II. Design system | weight text widgets, also for the dial letters (placed as widgets, never painted, so no `TextStyle` in the feature), adaptive paddings, `RSizedBox`, `ThemeEnum` (success, warning and error for the accuracy dot, accent and accentContainer roles for aligned), `BmIcon.ui(back)`, `BmIcon(settings)`. The dial sizes (300, ticks, needle 2 x 106, head 12, hub 10, top tick 2 x 16, marker 16, glow 420) get named manager entries. 14 strings go into `StringsManager` and both arb files | pass |
| III. Faithful | 4.05 and 4.06 built from their trees, Motion 09 and 10 from MOTION.md's demo (R7), haptics through `BmHaptics.qiblaApproach` and `qiblaAligned`. The weak compass, no compass and no location states use only existing parts, I check them in the app (FR-023) | pass |
| IV. Simplicity | no interface for the compass, one small `CompassSource` class like `PositionSource`. The tracker is one pure class. No package | pass |
| V. Performance | only the dial and needle watch the heading, `.select()` on the rounded difference and the phase, `RepaintBoundary` around the dial, const leaves, autoDispose streams | pass |
| VI. Tests | unit tests for the math, the model, the tracker, the smoothing. Widget tests for every state. One integration test. Architecture and strings tests green | pass |
| VII. Privacy | the fix is never saved. Heading and position are never logged, never in crash reports. The compass needs no location permission (R2) | pass |
| VIII. Offline and free | the magnetic model is in the app, no network | pass |
| Stack | flutter_compass from the constitution's list is **not** added, the app's own channel replaces it (R2). No other package | pass, OK given 2026-10-18, T001 amends the constitution to 3.1.0 before any code |

**Post-design re-check**: after `/speckit-analyze` the dial letters moved out of the painter into
text widgets (principle II), and the dial and needle sit in `Directionality(ltr)`. No open items.
T001 gives the constitution a MINOR bump (3.1.0): flutter_compass leaves the domain package list,
and a line says the compass is the app's own channel with WMM2025.

## Project Structure

### Documentation (this feature)

```text
specs/003-milestone-6-qibla/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── compass-channel.md
├── checklists/requirements.md
└── tasks.md            # /speckit-tasks
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── flavor/design_scenario.dart             # + designQiblaPlace (London)
│   ├── location/position_source.dart           # fix({accuracy = low})
│   ├── resources/
│   │   ├── strings_manager.dart                # + 14 keys
│   │   └── dimensions_manager.dart             # + named Qibla sizes
│   ├── router/app_router.dart                  # Routes.qibla, top level route over the shell
│   └── widgets/sheet/location_choices.dart     # the two buttons, out of Home's NoLocationCard
└── features/
    ├── home/view/widgets/no_location_card.dart # uses LocationChoices
    ├── more/view/more_page.dart                # temporary Qibla button, TODO: milestone 9
    └── qibla/
        ├── model/
        │   ├── compass_source.dart             # the event channel, raw readings or null
        │   ├── declination.dart                # WMM2025 declination(lat, lon, date)
        │   ├── wmm2025.dart                    # NOAA's coefficients, TODO(ahmed): WMM2030
        │   ├── qibla_math.dart                 # bearing, distance, difference, rounding
        │   └── qibla_tracker.dart              # phase, approach and aligned events
        ├── view_model/
        │   └── qibla_providers.dart            # compass, smoothed heading, place, target,
        │                                       # tracker notifier, design heading
        └── view/
            ├── qibla_page.dart
            └── widgets/
                ├── qibla_bar.dart              # back, "Qibla", gear, no surface or border
                ├── qibla_title.dart            # instruction or "Facing the Qibla" + subtitle
                ├── qibla_dial.dart             # ring, ticks, marker painted, letters as text
                │                               # widgets, top tick, in Directionality(ltr)
                ├── qibla_needle.dart           # Motion 09, ndlA breathe
                ├── aligned_pulse.dart          # Motion 10 pulses and glow
                ├── qibla_cards.dart            # distance and accuracy cards
                └── qibla_hint.dart             # hint, calibration hint or location choices

ios/Runner/AppDelegate.swift                    # + registerCompass, CLLocationManager delegate
android/app/src/main/kotlin/com/elhawary/bettermuslim/
├── MainActivity.kt                             # + the compass event channel
└── CompassStreamHandler.kt                     # rotation vector, remap, accuracy

assets/l10n/app_en.arb, app_ar.arb              # + 14 strings

test/features/qibla/
├── model/ qibla_math_test.dart  declination_test.dart  qibla_tracker_test.dart
├── view_model/ qibla_providers_test.dart
└── view/ qibla_page_test.dart
test/fixtures/wmm2025_test_values.txt           # NOAA's official test values
integration_test/qibla_journey_test.dart
```

**Structure Decision**: one Flutter app. The Qibla feature is new and MVVM, like Home. Native code
sits next to the existing channels, in `AppDelegate.swift` (no Xcode project change) and next to
`MainActivity.kt`.

## Key Flows

1. **Open**: More › Qibla → `context.push(Routes.qibla)`. The page listens to
   `qiblaPlaceProvider` (saved location, then the precise fix in auto mode) and
   `compassProvider` (the channel). Before the first reading the dial sits north up with no
   needle (R11).
2. **Each reading**: magnetic + declination(place, today) → true heading → smoothed (R5) →
   `headingProvider`. The dial turns at once, the needle retargets its spring (R7). The difference
   goes to the tracker notifier.
3. **Tracker**: inside ±3° starts a 400 ms timer. On `approach` → `BmHaptics.qiblaApproach`. On
   `aligned` → `BmHaptics.qiblaAligned`, the announcement, Motion 10 (R6, R13).
4. **Accuracy**: Medium and Low change the dot, Low swaps the hint for the calibration hint (R9).
5. **No compass**: the channel sends `null`. The dial stays north up, the needle and marker sit at
   the bearing, the FR-021 copy. **No location**: no marker or needle, the location choices open
   the sheet. A saved place shows everything at once.
6. **Gear**: `showLocationSheet(context)`. A new place → `qiblaPlaceProvider` → new target, the
   needle springs to it.
7. **Pause and resume**: the subscription is dropped on pause, the tracker resets, a new
   subscription on resume (R16). Leaving the page disposes it all.
8. **Design scenario**: London, 105°, High. A tap on the dial → 119° → aligned after 400 ms.
   Again → 105° (R12).

## Decisions (2026-10-18)

The clarify answers (Q1 to Q7, all recommendations) are in the spec. The plan adds these:
1. **Own compass channel instead of flutter_compass** (R2), OK given 2026-10-18. flutter_compass
   gives true north on iPhone only with a recent location, and magnetic north with no correction
   on Android. The own channel plus WMM2025 is one path for both phones and needs no location
   permission. Turned down: flutter_compass + Android's `GeomagneticField`, less code, but iPhone
   without a recent location would need a new "needs location" state and copy.
2. **The distance uses the mean Earth radius**, not `Geolocator.distanceBetween`. Its equatorial
   radius makes London "4,800 km" (R4).
3. **The precise fix**: `PositionSource.fix` gets an accuracy, high only for Qibla, since a
   kilometre off in Makkah turns the needle by up to 11° (R10).
4. **Home's two location buttons move to core**, now that Qibla uses them too (R1).
5. **Before the first reading** the page shows no needle and no title for that frame (R11), the
   item clarify left to the plan.

## Complexity Tracking

| Addition | Why Needed | Simpler Alternative Rejected Because |
| --- | --- | --- |
| own compass channel, about 105 native lines | true north on both phones without location permission (FR-004, constitution VII) | flutter_compass: iPhone true heading needs a recent location, Android has no correction |
| WMM2025 in Dart, about 80 lines + coefficients | magnetic to true north offline on both phones (FR-004) | Android's `GeomagneticField` covers Android only, iOS has no public declination |
| tracker with a timer | a still phone sends no readings, the 400 ms has to end anyway (FR-015) | checking on the next reading never aligns a still phone |
