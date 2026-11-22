---

description: "Tasks for milestone 6, qibla"
---

# Tasks: Milestone 6, Qibla

**Input**: Design documents from `specs/003-milestone-6-qibla/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/compass-channel.md,
quickstart.md

**Tests**: Included. Constitution VI asks for unit tests on logic and widget tests on screens,
SC-002 asks for 20 places against reference values, SC-005 for a jitter run of the haptics.

**Organization**: Grouped by user story, so each story can be built and checked on its own.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an unfinished task)
- **[Story]**: The user story the task belongs to (US1 to US4)

## Before starting

- Built after milestone 5, on `feature/milestone-6` cut from where milestone 5 ends (Q7).
- Research R2 replaces flutter_compass, OK given 2026-10-18. T001 amends the constitution first.
- Read `design_handoff_better_muslim/specs/HOW_TO_READ.md`, then the 4.05 and 4.06 trees in
  `design_handoff_better_muslim/specs/screens/`, and MOTION.md's `d_needle` and `d_align`.
- Every UI file follows the `adaptive-widgets` rules, and `flutter test test/architecture_test.dart`
  stays green.
- Parallel sessions share `.specify/feature.json`, so speckit commands get this folder passed
  explicitly (`SPECIFY_FEATURE_DIRECTORY=specs/003-milestone-6-qibla`).

---

## Phase 1: Setup

**Purpose**: The constitution amendment, the branch and the folders. No new pub.dev package.

- [X] T001 Amend `.specify/memory/constitution.md` for research R2 and R3 (OK given 2026-10-18): in Stack And Constraints drop flutter_compass from the domain package list and add "The compass is the app's own `better_muslim/compass` channel, true north from the World Magnetic Model in Dart", bump the version to 3.2.0 (MINOR, milestone 5 already took 3.1.0) and the Last Amended date.
- [X] T002 Ask before cutting `feature/milestone-6` from where milestone 5 ends. Then confirm `flutter pub get`, `flutter analyze` and `flutter test` are green before any change.
- [X] T003 Create the folders `lib/features/qibla/model/`, `lib/features/qibla/view_model/`, `lib/features/qibla/view/widgets/`, `test/features/qibla/model/`, `test/features/qibla/view_model/` and `test/features/qibla/view/`.

---

## Phase 2: Foundational

**Purpose**: What every story stands on: the math, the magnetic model, the tracker, the compass
channel, the precise fix, the strings and sizes, the view model, the route and the entry.

**⚠️ CRITICAL**: No story work starts before this phase is done

### Tests for the foundation

- [X] T004 [P] Write `test/fixtures/qibla_places.csv` (name, latitude, longitude, bearing, km) with the WGS84 ellipsoid reference values below, and `test/features/qibla/model/qibla_math_test.dart`:
  - every place: `qiblaBearing` within 0.5° and `kaabaDistanceKm` within 0.5% of the file (SC-002)
  - London (51.5074, −0.1278): bearing rounds to 119, `formatDistance` gives `distanceKm` with "4,790" in English and with "٤٬٧٩٠" in Arabic with Eastern digits
  - rounding (FR-009), the unit picked after rounding: 99.6 km → 100 km, 100.4 km → 100 km, 104.9 km → 100 km, 105 km → 110 km, 12.4 km → 12 km, 0.999 km → 1 km, 0.994 km → 990 m, 0.0004 km → 0 m
  - `qiblaDiff(bearing, heading)`: 119/105 → +14, 105/119 → −14, 10/350 → +20, 350/10 → −20, 0/180 → +180, never −180
  - `turnDegrees(diff)`: 0.3 → 1, 14.4 → 14, 179.6 → 180

  | name | lat | lon | bearing | km |
  | --- | --- | --- | --- | --- |
  | London | 51.5074 | −0.1278 | 118.87 | 4794.8 |
  | New York | 40.7128 | −74.0060 | 58.40 | 10323.9 |
  | Los Angeles | 34.0522 | −118.2437 | 23.77 | 13443.1 |
  | Toronto | 43.6532 | −79.3832 | 54.49 | 10513.8 |
  | Mexico City | 19.4326 | −99.1332 | 46.47 | 13663.9 |
  | Sao Paulo | −23.5505 | −46.6333 | 69.09 | 10601.0 |
  | Lima | −12.0464 | −77.0428 | 72.10 | 13262.6 |
  | Reykjavik | 64.1466 | −21.9426 | 106.03 | 6522.8 |
  | Cairo | 30.0444 | 31.2357 | 135.98 | 1285.6 |
  | Lagos | 6.5244 | 3.3792 | 63.46 | 4253.1 |
  | Cape Town | −33.9249 | 18.4241 | 23.47 | 6532.0 |
  | Istanbul | 41.0082 | 28.9784 | 151.51 | 2400.3 |
  | Moscow | 55.7558 | 37.6173 | 176.35 | 3815.9 |
  | Karachi | 24.8607 | 67.0011 | 267.79 | 2804.3 |
  | Jakarta | −6.2088 | 106.8456 | 295.02 | 7922.2 |
  | Tokyo | 35.6762 | 139.6503 | 293.07 | 9487.9 |
  | Sydney | −33.8688 | 151.2093 | 277.32 | 13237.0 |
  | Auckland | −36.8485 | 174.7633 | 260.95 | 15368.8 |
  | Suva | −18.1416 | 178.4419 | 281.83 | 15693.2 |
  | Makkah Aziziyah | 21.4110 | 39.8930 | 280.45 | 7.0 |

- [X] T005 [P] Download NOAA's official WMM2025 test values (the test values table that comes with the WMM2025 coefficient download and report on NCEI's World Magnetic Model page, ncei.noaa.gov/products/world-magnetic-model) into `test/fixtures/wmm2025_test_values.txt`, one row per line with date, altitude, latitude, longitude and declination, and write `test/features/qibla/model/declination_test.dart`: every row's declination within 0.01° of `declination(latitude, longitude, altitudeKm, decimalYear)`, plus `decimalYear(DateTime(2027, 7, 2))` ≈ 2027.5.
- [X] T006 [P] Write `test/features/qibla/model/qibla_tracker_test.dart` on the rules in data-model.md (QiblaTracker), passing explicit times:
  - diff 3 held: `check` at 399 ms stays turning, at 400 ms gives aligned and one `aligned` event
  - a reading at 3.1 between them restarts the 400 ms
  - aligned: diff 4.9 stays aligned with no event, 5.1 turns back
  - approach: from 12 to 9.9 one `approach`, back to 12 and to 9.9 again no event, past 15.1 and back to 9.9 one more
  - the first reading at 8 gives no `approach`. The first reading at 2 aligns after 400 ms
  - a scripted run with ±1° noise around 3°, 5°, 10° and 15° gives exactly one `approach` and one `aligned` per pass (SC-005)
  - `reset()` returns to turning, armed, no `lastDiff`

### Implementation for the foundation

- [X] T007 [P] Write `lib/features/qibla/model/qibla_math.dart`: `qiblaBearing(lat, lon)` through adhan_dart's `Qibla.qibla(Coordinates(lat, lon))`, `kaabaDistanceKm(lat, lon)` by haversine with `6371.0088` km to `Qibla.makkah` (R4), `qiblaDiff(bearing, heading)` in (−180, 180], `turnDegrees(diff)` = `max(1, diff.abs().round())`, and `formatDistance(km, {language, digits})` that rounds by FR-009 (metres to the nearest 10 first, under 1,000 m stays in metres, else whole km, from 100 km to the nearest 10 km), formats with `NumberFormat('#,##0')`, runs `formatDigitsIn`, swaps "," for "٬" when Eastern digits are on, and returns the `StringsManager.distanceKm` or `distanceM` key with its argument (R14). Make T004 pass.
- [X] T008 [P] Copy the `WMM.COF` file from NOAA's WMM2025 coefficient zip (same NCEI page) into `lib/features/qibla/model/wmm2025.dart` as a const list of (n, m, g, h, gDot, hDot) rows with the epoch 2025.0, with `// TODO(ahmed): swap in the WMM2030 coefficients from NOAA before 2030, the model is valid until then.` above it. Write `lib/features/qibla/model/declination.dart`: `declination(latitude, longitude, {altitudeKm = 0, required double decimalYear})` in degrees east, the standard WMM algorithm (geodetic to geocentric on WGS84, Schmidt semi-normalized Legendre functions to degree 12, secular change from the epoch), and `decimalYear(DateTime)`. Make T005 pass.
- [X] T009 [P] Write `lib/features/qibla/model/qibla_tracker.dart`: `QiblaPhase { turning, aligned }`, `QiblaEvent { approach, aligned }`, and a pure `QiblaTracker` with `List<QiblaEvent> update(double diff, DateTime now)`, `List<QiblaEvent> check(DateTime now)` for the timer, `DateTime? get alignAt` (when the view model should call `check`) and `reset()`, by the thresholds 3, 5, 10, 15 and 400 ms in data-model.md. Make T006 pass.
- [X] T010 [P] Write `lib/features/qibla/model/compass_source.dart` from contracts/compass-channel.md: `compassSourceProvider` and a small `CompassSource` class like `PositionSource`, with `Stream<RawHeading?> readings()` over `EventChannel('better_muslim/compass')`, `typedef RawHeading = ({double magnetic, double accuracy})`, `null` for a `null` event, and a single `null` on `MissingPluginException`.
- [X] T011 [P] Add the iOS side to `ios/Runner/AppDelegate.swift`: `registerCompass(messenger:)` from `didInitializeImplicitFlutterEngine` with its own registrar ("Compass"), a `FlutterEventChannel` named `better_muslim/compass` and a small `FlutterStreamHandler` + `CLLocationManagerDelegate` class in the same file. On listen: `CLLocationManager.headingAvailable()` false → send `nil` and stop. Else `headingFilter = 0.5`, `headingOrientation` from the window scene's interface orientation (updated on `UIDevice.orientationDidChangeNotification`), `startUpdatingHeading()`. Each heading sends `["heading": magneticHeading, "accuracy": headingAccuracy < 0 ? -1 : headingAccuracy]`. `locationManagerShouldDisplayHeadingCalibration` returns false. On cancel: `stopUpdatingHeading()`. Never asks for permission or starts location updates. Add `import CoreLocation`.
- [X] T012 [P] Add the Android side in `android/app/src/main/kotlin/com/elhawary/bettermuslim/CompassStreamHandler.kt`: an `EventChannel.StreamHandler` + `SensorEventListener` on `Sensor.TYPE_ROTATION_VECTOR` with `SENSOR_DELAY_UI`. No sensor → `events.success(null)`. Each event: `getRotationMatrixFromVector`, `remapCoordinateSystem` by the activity display's rotation (0, 90, 180, 270), `getOrientation`, azimuth to degrees normalized to 0..360. Accuracy: `values[4]` in degrees when `values.size > 4` and ≥ 0, else the event status (high 15, medium 30, low 45, unreliable −1). Send `mapOf("heading" to h, "accuracy" to a)`. On cancel unregister. Register it in `MainActivity.configureFlutterEngine` on the shared `messenger`, next to the other channels: `EventChannel(messenger, "better_muslim/compass").setStreamHandler(CompassStreamHandler(this))`.
- [X] T013 [P] Give `fix()` in `lib/core/location/position_source.dart` an optional `{LocationAccuracy accuracy = LocationAccuracy.low}` used in its `LocationSettings`, and update every `PositionSource` fake (`_NoPosition` in `lib/core/flavor/design_scenario.dart`, the fakes in `test/helpers/`) to the new signature. Existing tests stay green.
- [X] T014 [P] Add the 14 keys to `lib/core/resources/strings_manager.dart` and both `assets/l10n/app_en.arb` and `assets/l10n/app_ar.arb` with spec FR-025's wording, `{distance}` placeholders written like the existing ones: `distanceKm`, `distanceM`, `accuracyMedium`, `accuracyLow`, `calibrateHint`, `noCompass`, `accuracyNone`, `noCompassHint`, `qiblaNeedsLocation`, `compassN`, `compassE`, `compassS`, `compassW`, `qiblaCompass`. `strings_manager_test.dart` passes.
- [X] T015 [P] Add the named Qibla values, only those missing, with the tree's numbers: in `lib/core/resources/dimensions_manager.dart` `SizeManager.qiblaDial` 300, `qiblaTickOuter` 146, `qiblaTickMajor` 18, `qiblaTickMinor` 8, `qiblaLetterRadius` 108, `qiblaMarker` 16, `qiblaNeedle` 106, `qiblaNeedleWidth` 2, `qiblaNeedleHead` 12, `qiblaHub` 10, `qiblaTopTick` 16, `qiblaTopTickGap` 6, `qiblaGlow` 420, `accuracyDot` 8, `RadiusManager.qiblaMarker` 3 and `qiblaCard` 20 (if the 20 card radius doesn't exist yet), `SpaceManager.qiblaTitleTop` 26, `qiblaDialTop` (gap from the subtitle to the dial), `qiblaCardsTop` 50, `qiblaHintTop`, `qiblaHintSide` 24, `qiblaCardGap` 10, `qiblaCardV` 14, `qiblaCardH` 16; in `lib/core/resources/font_manager.dart` `FontSizeManager.qiblaValue` 20 and `LineHeightManager.qiblaHint` 1.5. The gaps come from the tree's absolute tops (title 136, dial 270, cards 620, hint 722) measured from the bottom of the element before.
- [X] T016 [P] Add `const designQiblaPlace = (latitude: 51.5074, longitude: -0.1278, name: 'London', nameAr: 'لندن')` to `lib/core/flavor/design_scenario.dart` with a one-line why comment (the PNGs show London, from Makkah the Qibla is a few metres away).
- [X] T017 [P] Move the two buttons of `lib/features/home/view/widgets/no_location_card.dart` into `lib/core/widgets/sheet/location_choices.dart` (`LocationChoices`: "Use my location" primary → `showLocationSheet(context, useMyLocation: true)`, "Choose a city instead" secondary → `showLocationSheet(context)`, the same gap), and use it from `NoLocationCard`. Home's tests stay green.
- [X] T018 Write `test/features/qibla/view_model/qibla_providers_test.dart` with a `ProviderContainer`, a fake `CompassSource` and a fake `PositionSource`:
  - smoothing: 359° then 1° stays near 0°, never near 180°. 100 readings at 120° ± 0.5° noise over 2 s keep the smoothed heading within 1° (SC-004)
  - true heading = magnetic + `declination` at the place and today
  - place: manual mode gives the saved coordinates with no fix call. Auto mode with permission gives the saved place, then the fix's coordinates with the saved name, and calls `fix(accuracy: LocationAccuracy.high)`. Auto mode without permission gives the saved place only. No location gives null. Nothing is written to the store
  - design scenario: London, 105°, High. `toggle()` gives 119°, again 105°
  - the tracker notifier calls `check` when `alignAt` passes even with no new reading, and resets on pause
  - the fake `CompassSource` stream is cancelled when the last listener goes (page left) and when the app pauses, and listened to again on resume (FR-006, SC-007)
- [X] T019 Write `lib/features/qibla/view_model/qibla_providers.dart` (depends on T007 to T010, T013, T016). Make T018 pass:
  - `compassProvider`: autoDispose stream of `CompassReading?` from `compassSourceProvider`: magnetic + declination (R3), the time-weighted unit circle low pass with 150 ms (R5), accuracy mapped ≤ 15 high, ≤ 30 medium, else low (R9). An `AppLifecycleListener` drops the channel subscription on pause and listens again on resume (R16)
  - `qiblaPlaceProvider`: autoDispose stream, the saved location from `locationProvider` at once, then the precise fix in auto mode with permission, never saved (R10)
  - `qiblaTargetProvider`: bearing and distance from the place
  - `qiblaDiffProvider`, `turnDegreesProvider` (rounded, so text rebuilds per degree)
  - `qiblaTrackerProvider`: a Notifier holding `QiblaTracker`, feeding it each diff with the clock's now, a `Timer` to `alignAt` that calls `check`, exposing the phase and a stream or callback of events, reset on pause and on a place change
  - `designHeadingProvider`: 105 or 119 with `toggle()`. When `flavorProvider` says `isDesignScenario`, `compassProvider` gives that heading with High and no smoothing, and the place is `designQiblaPlace` (R12)
- [X] T020 Create `lib/features/qibla/view/qibla_page.dart` as a bare page and add `Routes.qibla = '/qibla'` to `lib/core/router/app_router.dart` as a top level `GoRoute` next to the `StatefulShellRoute`, so the page covers the tab bar (R15).
- [X] T021 [P] Add the temporary Qibla entry, a plain `BmButton.secondary(StringsManager.qibla)`, under the title in `lib/features/more/view/more_page.dart` that calls `context.push(Routes.qibla)`, with `// TODO: replaced by the 4.09 Qibla tile in milestone 9.` above it.

**Checkpoint**: tests T004 to T006 and T018 green, More › Qibla pushes an empty page with no tab bar.

---

## Phase 3: User Story 1 - Find the Qibla (Priority: P1) 🎯 MVP

**Goal**: the turning state of 4.05: title, subtitle, a dial that turns with the phone, a needle
that springs to the Kaaba marker, the two cards, the hint, the approach haptic.

**Independent Test**: in the design scenario, "Turn 14° right", "London · Qibla at 119° from
north", "4,790 km", "High", the needle 14° right of the top tick on the marker.

### Tests for User Story 1

- [X] T022 [P] [US1] Write `test/features/qibla/view/qibla_page_test.dart` (turning) with the design scenario's overrides and a fake compass:
  - the copy above, in English and in Arabic (Eastern digits, "٤٬٧٩٠ كم", ش ق ج غ)
  - the dial's rotation is −105°, the needle's angle settles at 14°, the letters stay upright, the dial isn't mirrored in Arabic and the back arrow is
  - heading 350° then 10° turns the dial by +20° the short way, never −340°
  - reduce motion: the needle reaches its target in 300 ms with no overshoot
  - the approach haptic (`HapticFeedback.vibrate` on `SystemChannels.platform`) fires once going from 20° off to 9° off
  - the gear opens the location sheet, back pops the page
  - the dial's semantics label is "Qibla compass" with the instruction, bearing, distance and accuracy as value
  - every action is at least 44 x 44

### Implementation for User Story 1

- [X] T023 [P] [US1] Write `lib/features/qibla/view/widgets/qibla_bar.dart`: the tree's 56 pt bar with no surface and no border: back 44 x 44 (`BmIcon.ui(BmUiIcon.back)` size 22, pops), "Qibla" `SemiBoldText` 17 centered, gear 44 x 44 (`BmIcon(BmIconName.settings)` size 22) → `showLocationSheet(context)` (FR-024). Reuse `CompactAppBar` instead if it can draw without its surface and border without a new flag.
- [X] T024 [P] [US1] Write `lib/features/qibla/view/widgets/qibla_title.dart`: a `ConsumerWidget` that watches only `turnDegreesProvider`, the diff's sign and the phase. Turning: `RegularText(StringsManager.turnRight or turnLeft, font: FontEnum.display, fontSize: FontSizeManager.qiblaTitle, height: LineHeightManager.qiblaTitle, args: {deg})` with the degrees through `formatDigits`, and the subtitle `RegularText(StringsManager.qiblaFrom, fontSize: FontSizeManager.secondary, color: ThemeEnum.text2, args: {city, deg})`, centered, gap 6.
- [X] T025 [P] [US1] Write `lib/features/qibla/view/widgets/qibla_dial.dart`: a `RepaintBoundary` inside `Directionality(textDirection: TextDirection.ltr)` (handoff rule 5, FR-012) with the 300 x 300 ring (radial gradient `surface` to `bg` at 72%, a 1 pt `outline` ring) and a `Stack` turned by minus the continuous heading:
  - a `CustomPainter` for the shapes only: 72 ticks every 5° from radius 146 inwards. 0/90/180/270 length 18, 1.5 wide, `text2`. Other multiples of 30° length 18, 1.5 wide, `outlineStrong`. The rest length 8, 1 wide, `outlineStrong`. The Kaaba marker at radius 146 at the bearing: a 16 x 16 square with radius 3 in `accent` and a 1.5 `primary` line across 3 above its center, turned by the bearing
  - the letters as widgets, never painted (a painter needs a `TextStyle`, which principle II and the architecture test forbid outside core): `SemiBoldText(StringsManager.compassN, fontSize: FontSizeManager.secondary, color: ThemeEnum.primary)` and `RegularText` for `compassE`, `compassS`, `compassW` in `text2`, each placed at radius 108 in the `Stack` and turned back by the heading to stay upright
  - the hub (10, `text`) in the middle and the top tick (2 x 16, `text`, 6 above the ring) outside the turning part
  - the heading kept continuous across north (R7). In the design scenario only, a tap calls `designHeadingProvider.toggle()`
  - colors through `context.getColor` passed into the painter. Sizes from T015, scaled with `.r` inside the painter and the `Stack` positions, since they don't go through the adaptive widgets
- [X] T026 [P] [US1] Write `lib/features/qibla/view/widgets/qibla_needle.dart`: a `ConsumerStatefulWidget` inside the dial's `Directionality(ltr)`, with an unbounded `AnimationController`. On each new target (bearing − heading moved by whole turns to the nearest equivalent of the current value) it runs `SpringSimulation(BmMotion.needle, value, target, velocity)`. Reduce motion (`context.reduceMotion(settings.reduceMotion)`): `animateTo(target, duration: BmMotion.standard, curve: BmMotion.standardCurve)`. The needle is 2 x 106 from the center up, a gradient from `primary` to `primary` at 10%, with a 12 pt `primary` head at its tip.
- [X] T027 [P] [US1] Write `lib/features/qibla/view/widgets/qibla_cards.dart`: two cards in a row with a 10 gap, `surface`, radius 20, a 1 pt `outline` border, padding 14 x 16. Distance: `MediumText(key, fontSize: FontSizeManager.qiblaValue, args: {'distance': value})` with the key and value `formatDistance` returns (tabular figures), and `RegularText(StringsManager.toTheKaaba, fontSize: FontSizeManager.cardNote, color: ThemeEnum.text2)`. Accuracy: an 8 pt dot (high `success`, medium `warning`, low `error`), the level key (`accuracyHigh`, `accuracyMedium`, `accuracyLow`) and `compassAccuracy` under it.
- [X] T028 [P] [US1] Write `lib/features/qibla/view/widgets/qibla_hint.dart`: `RegularText(StringsManager.holdFlat, fontSize: FontSizeManager.caption, height: LineHeightManager.qiblaHint, color: ThemeEnum.text2)` centered with 24 at the sides.
- [X] T029 [US1] Assemble `lib/features/qibla/view/qibla_page.dart`: `bg`, a scroll view so text scale 2.0 never cuts (FR-027), the bar, the title block, the dial with the needle stacked on it, the cards, the hint, with the T015 gaps, the layout stretched to at most 480 pt on tablets like the other pages. The dial's `Semantics` (R13). Listen to the tracker's events: `approach` → `BmHaptics.qiblaApproach()`. Before the first reading: dial north up, no needle, no title, accuracy "—" (R11). Make T022 pass.

**Checkpoint**: More › Qibla in the design scenario shows the turning state. On a phone the dial
and needle follow the compass.

---

## Phase 4: User Story 2 - Know that I'm facing it (Priority: P1)

**Goal**: the aligned state of 4.06 with Motion 10, the success haptic and the announcement.

**Independent Test**: in the design scenario, tap the dial: after 400 ms "Facing the Qibla",
"Hold steady", the accent ring and tick, two pulses. Tap again: back to turning.

### Tests for User Story 2

- [X] T030 [P] [US2] Add to `test/features/qibla/view/qibla_page_test.dart` (aligned): tap the dial, pump 399 ms still turning, 400 ms aligned with the copy, `onAccentContainer` title, `accent` ring and tick. The aligned haptic fires once, `SemanticsService.announce` gets "Facing the Qibla" once. A fake compass at 123.9° stays aligned, 124.1° turns back to "Turn 5° left". Reduce motion: no pulse or glow widget animates, the ring is still accent, the haptic still fires.
- [X] T031 [P] [US2] Write `integration_test/qibla_journey_test.dart` on the design scenario: Home → More → Qibla, "Turn 14° right", tap the dial, "Facing the Qibla", back.

### Implementation for User Story 2

- [X] T032 [P] [US2] Write `lib/features/qibla/view/widgets/aligned_pulse.dart`: on aligning, two pulses of `BmMotion.alignPulse` (scale 1 to 1.35, opacity .8 to 0, `BmMotion.decelerate`) of a 1.5 `accent` ring the dial's size, and the 420 pt glow (radial `accent` at 30% to clear at 62%) breathing opacity .6 to 1 over 3000 ms with `BmMotion.breathe` while aligned (MOTION `d_align`, R7). Neither under reduce motion.
- [X] T033 [US2] Aligned in the existing widgets: `qibla_dial.dart` animates the ring (1 to 1.5, `outline` to `accent`) and the top tick (`text` to `accent`) in 300 ms standard, instantly under reduce motion. `qibla_needle.dart` breathes ±0.8° over 2400 ms while aligned (`ndlA`), not under reduce motion. `qibla_title.dart` shows `facingQibla` in `onAccentContainer` and `holdSteady`, faded in over 300 ms.
- [X] T034 [US2] In `lib/features/qibla/view/qibla_page.dart` handle `aligned`: `BmHaptics.qiblaAligned()` and `SemanticsService.announce(context.tr(StringsManager.facingQibla), Directionality.of(context))`. Make T030 and T031 pass.

**Checkpoint**: both PNG states can be seen in the design scenario, alignment works on a phone.

---

## Phase 5: User Story 3 - When the compass can't be trusted (Priority: P2)

**Goal**: Medium and Low with their dots, the calibration hint at Low.

**Independent Test**: feed accuracies 10, 25, 40 and −1 to the fake compass: High, Medium, Low
with the calibration hint, Low with the calibration hint. Back to 10: the designed hint.

### Tests for User Story 3

- [X] T035 [P] [US3] Add to `test/features/qibla/view/qibla_page_test.dart` (accuracy): the four accuracies above give the right level text and dot color, Low swaps `holdFlat` for `calibrateHint`, going back to High brings `holdFlat` back. The level change doesn't rebuild the dial (a build counter on the painter).

### Implementation for User Story 3

- [X] T036 [US3] In `lib/features/qibla/view/widgets/qibla_hint.dart` watch only the accuracy level and show `calibrateHint` at Low (FR-020). Check `qibla_cards.dart` selects only the level. Make T035 pass.

**Checkpoint**: the accuracy card and hint follow the compass.

---

## Phase 6: User Story 4 - No compass, or no location (Priority: P2)

**Goal**: the two states the design doesn't show, from existing parts only (FR-023).

**Independent Test**: a fake compass sending `null` shows the still dial with the marker and
needle at 119°, "No compass on this phone". No saved location shows "No location yet", no marker
or needle, the two buttons.

### Tests for User Story 4

- [X] T037 [P] [US4] Add to `test/features/qibla/view/qibla_page_test.dart`:
  - no compass: the dial at 0°, the needle and marker at the bearing, title `noCompass`, subtitle as usual, distance as usual, accuracy `accuracyNone` with no dot, hint `noCompassHint`, no haptics, the dial still after pumping 2 s
  - no location: the dial turns with the fake compass, no marker, no needle, title `noLocationYet`, subtitle `qiblaNeedsLocation`, distance "—", `LocationChoices` in place of the hint. "Use my location" opens the sheet in its locating mode, "Choose a city instead" opens it with the search
  - a location saved while the page is open shows the marker, needle, subtitle and distance at once

### Implementation for User Story 4

- [X] T038 [US4] Add the two states to `qibla_title.dart`, `qibla_dial.dart` (no marker without a target, still at 0° without a compass), `qibla_needle.dart` (none without a target, at the bearing without a compass), `qibla_cards.dart` ("—" distance with `translate: false`, `accuracyNone` with no dot) and `qibla_hint.dart` (`noCompassHint`, or `LocationChoices` from T017). No tracker, no haptics without a compass. Make T037 pass.

**Checkpoint**: every state of the page works.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [X] T039 [P] Add to `test/features/qibla/view/qibla_page_test.dart`: Arabic turning and aligned, text scale 2.0 (title wraps, the page scrolls, nothing overflows), light and dark, reduce motion on and off, a tablet width (stretched to 480 pt).
- [X] T040 Run the self check from the `adaptive-widgets` skill on every new and changed file, `flutter test test/architecture_test.dart`, and fix every hit.
- [X] T041 Run `dart format --set-exit-if-changed lib test integration_test`, `flutter analyze` and `flutter test`, all clean.
- [X] T042 Run quickstart.md steps 1 and 2 on a simulator (design scenario, both languages, both modes), and hand me steps 3 to 5 (real phone outdoors, no location, iPhone with location refused) to run myself.
- [X] T043 [P] Update the milestone list in `CLAUDE.md`: add "6. Qibla: compass, alignment, haptics. **Done, waiting for my review.**" and move the "as in `HANDOFF_CLAUDE.md`" line to start at 7.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: T001 first, the constitution before any code. Then T002, T003.
- **Foundational (Phase 2)**: after Setup. Blocks every story.
- **US1 (Phase 3)**: after Phase 2. The MVP.
- **US2 (Phase 4)**: after US1, it changes US1's widgets.
- **US3 (Phase 5)** and **US4 (Phase 6)**: after US1, independent of US2 and of each other, but
  both touch `qibla_hint.dart` and `qibla_cards.dart`, so one after the other.
- **Polish (Phase 7)**: after the stories.

### Inside Phase 2

- T004 to T006 (tests) before T007 to T009.
- T007 to T017 touch different files and run in parallel.
- T018 then T019 (needs T007 to T010, T013, T016).
- T020 then T021.

### Parallel Opportunities

- Phase 2: T004, T005, T006 together. Then T007 to T017 together (the Swift, Kotlin and Dart
  sides of the channel at the same time).
- US1: T022 to T028 together, then T029.
- US2: T030, T031, T032 together, then T033, T034.
- Polish: T039 and T043 together.

## Parallel Example: Phase 2

```text
Task: "T007 qibla_math.dart"
Task: "T008 wmm2025.dart + declination.dart"
Task: "T009 qibla_tracker.dart"
Task: "T011 iOS compass in AppDelegate.swift"
Task: "T012 Android CompassStreamHandler.kt"
Task: "T014 strings in strings_manager.dart and both arb files"
```

## Implementation Strategy

### MVP First (User Story 1)

1. Phase 1 (constitution 3.1.0, branch), then Phase 2.
2. US1: the turning state. Stop and check the design scenario and a real phone.

### Incremental Delivery

1. US1 → turning works, the needle points the right way.
2. US2 → aligned with Motion 10 and the haptic.
3. US3 → accuracy levels and the calibration hint.
4. US4 → no compass and no location.
5. Polish → languages, text scale, checks, CLAUDE.md. Then stop for my review (constitution
   workflow).
