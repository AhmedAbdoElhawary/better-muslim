# Research: Milestone 6, Qibla

Checked on 2026-10-18 against the code on `feature/milestone-5`, the package sources in the pub
cache (adhan_dart 2.0.1, geolocator 14.1.1, geolocator_platform_interface 4.4.0), flutter_compass
0.8.1 on GitHub, Apple's CLHeading docs and the handoff (4.05, 4.06, MOTION.md).

## R1. Where the code lives

- **Decision**:
  - `features/qibla/` as MVVM (constitution I lists qibla as MVVM): `model/` for the math, the
    magnetic model and the compass channel, `view_model/` for the providers, `view/` for the page.
  - `core/location/position_source.dart`: `fix()` takes an optional `accuracy`, low by default, so
    the Qibla can ask for a precise fix (R10).
  - `core/widgets/sheet/location_choices.dart`: the "Use my location" and "Choose a city instead"
    buttons move out of Home's `NoLocationCard`, since Qibla needs the same two (constitution IV,
    never two copies).
  - The route sits at the top of the router, next to the shell, so the page covers the tab bar
    (R15).
- **Rationale**: only Qibla uses the compass, the bearing and the magnetic model, so they stay in
  the feature. The location pieces were already in core.
- **Alternatives**: a `core/compass/` (no second user), a copy of Home's buttons (two copies).

## R2. Where the heading comes from

- **Decision**: the app's own event channel `better_muslim/compass`, like the existing
  `better_muslim/power`, `backup` and `adhan` channels. It sends the **magnetic** heading of the
  top of the screen and its accuracy in degrees (contracts/compass-channel.md):
  - iOS: `CLLocationManager.startUpdatingHeading`, `magneticHeading` and `headingAccuracy`, in
    `AppDelegate.swift` next to the other channels, so no Xcode project change.
  - Android: the rotation vector sensor (`TYPE_ROTATION_VECTOR`), in a `CompassStreamHandler.kt`
    next to `MainActivity.kt`.
  - flutter_compass is not added, OK given 2026-10-18. The constitution lists it, T001 amends it
    to 3.1.0.
- **Rationale**:
  - flutter_compass 0.8.1 (last release 23 months ago) sends `trueHeading` on iOS. Apple's
    CLHeading docs say true heading is valid only while the same location manager also gets
    location updates, and the plugin never starts them. So on iPhone it depends on a recent
    location, and with a city picked by hand and location refused it would point wrong.
  - On Android the plugin sends magnetic north with no declination, so it needs a correction
    anyway.
  - With magnetic heading from the phone and declination from R3, both phones share one path,
    and the compass works with a city and no location permission (constitution VII).
  - About 45 lines of Swift and 60 of Kotlin, no package.
- **Alternatives**:
  - flutter_compass + Android's `GeomagneticField` through a 10 line channel: least code, but
    iPhone without a recent location has no valid true heading and needs a "needs location" state
    with new copy.
  - flutter_rotation_sensor or compassx: another package with few users, same true north
    questions.
  - sensors_plus raw magnetometer: iOS gives it uncalibrated, the needle would carry the phone's
    own magnetic bias.
- **To check on a phone**: iPhone with location refused still gets heading events (quickstart
  step 5).

## R3. True north from magnetic north

- **Decision**: the World Magnetic Model 2025 in Dart (`features/qibla/model/declination.dart`),
  with NOAA's WMM2025 coefficients in `wmm2025.dart` (public domain, valid 2025.0 to 2030.0). True
  heading = magnetic heading + declination at the position and today's date, worked out once per
  position.
- **Rationale**: FR-004 asks for a correction that works offline on both phones. The model is a
  fixed formula (spherical harmonics to degree 12) with 90 coefficient rows, about 80 lines.
  NOAA publishes official test values, so the tests prove it.
- **Alternatives**:
  - Android's `GeomagneticField`: Android only, older Androids carry an older model.
  - The geomag package: ships WMM2015 by default, another package for 80 lines.
- **Upkeep**: NOAA releases WMM2030 at the end of 2029. A `TODO(ahmed)` sits on the coefficients.

## R4. Bearing and distance

- **Decision**:
  - Bearing: `Qibla.qibla(Coordinates)` from adhan_dart, already a dependency. Great circle on a
    sphere, the usual Qibla definition.
  - Distance: haversine with the mean Earth radius 6371.0088 km, three lines in
    `qibla_math.dart`.
  - Shown: 10 km steps from 100 km, whole km below 100 km, 10 m steps below 1 km (FR-009).
- **Rationale**: `Geolocator.distanceBetween` uses the equatorial radius (6378.137 km). London
  then comes out at 4,799 km and shows "4,800 km", the PNG says "4,790 km". The mean radius gives
  4,794 km and stays within 0.2% of the WGS84 ellipsoid:

  | From | Qibla | Ellipsoid | Mean radius | Equatorial radius |
  | --- | --- | --- | --- | --- |
  | London | 118.99° | 4,794.8 km | 4,793.8 (−0.02%) | 4,799.1 (+0.09%) |
  | New York | 58.48° | 10,323.9 | 10,306.3 (−0.17%) | 10,317.8 (−0.06%) |
  | Jakarta | 295.15° | 7,922.2 | 7,920.1 (−0.03%) | 7,929.0 (+0.09%) |
  | Makkah city | 318.55° | 5.0 | 5.0 (+0.17%) | 5.0 (+0.28%) |

- **Alternatives**: Vincenty on the ellipsoid (more code, the display rounds it away),
  `Geolocator.distanceBetween` (wrong rounding for the PNG).

## R5. Smoothing the heading

- **Decision**: a low pass on the unit vector (sin, cos) of each reading, weighted by the time
  since the last one: `k = 1 − exp(−dt / 150 ms)`. The angle comes back with `atan2`.
- **Rationale**: averaging angles directly breaks at north (359° and 1° average to 180°). The time
  weight keeps the same feel at 15 Hz on one phone and 60 Hz on another. 150 ms keeps the needle
  still within 1° on a still phone (SC-004) and the dial still feels instant.
- **Alternatives**: a fixed alpha (behaves differently per phone), a median of the last N
  (lags).

## R6. Alignment and haptics

- **Decision**: a pure `QiblaTracker` in `model/` takes each smoothed difference with its time and
  returns the phase and the events:
  - Inside ±3°: a 400 ms timer starts, any reading past ±3° cancels it. When it fires: aligned and
    the `aligned` event.
  - Aligned stays until the difference passes ±5°.
  - Approach: fires when the difference comes inside ±10° and is armed again only past ±15°. It
    doesn't fire when the screen opens already inside.
  - Leaving the screen or the app resets everything to turning.

  The view model owns the timer, because a still phone may send no new reading. The tracker gets
  `now` passed in, so tests need no fake clock.
- **Rationale**: the 3/5 and 10/15 gaps stop ±1° jitter from repeating a haptic (SC-005). A
  timer, not the next reading, ends the 400 ms, since iOS sends nothing while the heading doesn't
  change.
- **Alternatives**: checking the 400 ms on the next reading (never aligns on a still phone).

## R7. Dial, needle and the aligned motion

- **Decision**:
  - Dial: `Transform.rotate` by minus the smoothed heading, kept continuous (unwrapped) so it
    never spins round at north. The letters turn back by the same angle to stay upright, like the
    PNG.
  - Needle: an unbounded `AnimationController` driven by
    `SpringSimulation(BmMotion.needle, value, target, velocity)`. Each reading starts a new
    simulation from the current value and velocity (MOTION: retarget, never queue). The target
    is bearing minus heading, moved by whole turns to the nearest equivalent of the current value
    (shortest path).
  - Reduce motion: `animateTo(target, 300 ms, standardCurve)`, no overshoot.
  - Aligned (MOTION.md `d_align`, the authoritative demo): ring and top tick to accent in 300 ms
    standard, title and subtitle fade in 300 ms, two ring pulses of 900 ms (scale 1 to 1.35,
    opacity .8 to 0, decelerate), the glow breathes opacity .6 to 1 over 3000 ms, the needle
    breathes ±0.8° over 2400 ms (`ndlA`).
  - Reduce motion while aligned: the colors change, no pulses, glow loop or breathe. Haptics
    still fire.
- **Rationale**: the same `SpringSimulation` use as `mark_button.dart` and `day_complete.dart`.
  Only the dial and needle widgets watch the heading, the title watches the rounded difference
  and the phase, so text rebuilds only when a degree changes (constitution V).

## R8. Screen rotation

- **Decision**: the native side gives the heading of the top of the screen. On Android the
  rotation matrix is remapped by the display rotation. On iOS `headingOrientation` follows the
  interface orientation.
- **Rationale**: FR-005. The app doesn't lock orientation, and iPad multitasking ignores locks
  anyway.

## R9. Accuracy levels

- **Decision**: the channel sends the accuracy in degrees. Dart maps ≤ 15° to High, ≤ 30° to
  Medium, and anything above it or unknown to Low:
  - iOS: `headingAccuracy`. A negative value means invalid, sent as −1.
  - Android: `values[4]` of the rotation vector (heading accuracy in radians) when the phone fills
    it. Otherwise the sensor status: high 15, medium 30, low 45, unreliable −1.
  - iOS's own calibration overlay is turned off (`locationManagerShouldDisplayHeadingCalibration`
    returns false), the Low hint says the same in the app's voice.
- **Rationale**: one scale for both phones. 15 and 30 are the steps flutter_compass also uses.

## R10. The position

- **Decision**: `qiblaPlaceProvider` (autoDispose stream in the view model) gives the saved
  location at once. When the location is automatic and allowed, it then asks
  `PositionSource.fix(accuracy: LocationAccuracy.high)` and gives the fix's coordinates with the
  saved place name. A city picked by hand is used as it is. Nothing is saved.
- **Rationale**: FR-008. Coarse accuracy is a kilometre, and from 5 km away in Makkah that turns
  the needle up to about 11°. The fix is taken only while the page listens.
- **Alternatives**: always the saved location (wrong near Makkah, turned down in Q2).

## R11. States around the compass

- **Decision**:
  - Before the first reading (usually under 100 ms): dial north up, no needle, no title, accuracy
    "—".
  - No compass: the channel sends one `null` and closes. Dial still, north up, needle and marker
    at the bearing, the FR-021 copy, no haptics.
  - No location: dial turning, no marker or needle, distance "—", the location choices (R1).
- **Rationale**: the clarify scan left "before the first reading" to the plan. Showing nothing
  for a frame is better than a wrong "Turn 119° right".

## R12. Design scenario

- **Decision**: the Qibla view model checks `isDesignScenario`, like Home's `home_providers.dart`
  already does:
  - The place is `designQiblaPlace` (London, 51.5074, −0.1278) from
    `core/flavor/design_scenario.dart`.
  - The heading comes from `designHeadingProvider`: 105°, High accuracy, no smoothing. A tap on
    the dial switches between 105° and 119°.
  - Outside the scenario the dial has no tap.
- **Rationale**: core can't import the feature, so core can't override a Qibla provider. The
  scenario's data still lives in core/flavor with the rest.

## R13. Screen readers

- **Decision**: the dial is one `Semantics` node, label "Qibla compass", value the instruction,
  bearing, distance and accuracy. On aligning, `SemanticsService.announce` says "Facing the Qibla"
  once. The title is not a live region.
- **Rationale**: FR-026, a live title would read every degree.

## R14. Numbers

- **Decision**: the distance is formatted with `NumberFormat('#,##0')`, then `formatDigitsIn` from
  `core/extensions/time_format.dart`. With Eastern digits the comma becomes the Arabic separator
  "٬". Degrees go through `formatDigitsIn` only.
- **Rationale**: the app's digits setting already lives in `formatDigitsIn`. It doesn't touch the
  separator, and times never had one, so the swap stays in the Qibla formatter.

## R15. Entry, route and gear

- **Decision**:
  - `Routes.qibla = '/qibla'` as a top level `GoRoute` next to the `StatefulShellRoute`, pushed
    with `context.push`, so the page covers the tab bar as designed.
  - The More placeholder gets a temporary `BmButton.secondary(StringsManager.qibla)` with a
    `TODO:` to replace it with the 4.09 tile in milestone 9.
  - The gear calls `showLocationSheet(context)`.
- **Rationale**: the qada page lives inside the shell and keeps the tab bar. Qibla's tree has
  none.

## R16. Battery and lifecycle

- **Decision**: the compass stream is an autoDispose provider. The channel's listen starts the
  sensor and cancel stops it. An `AppLifecycleListener` drops the subscription on pause and starts
  it again on resume, and the tracker starts from turning.
- **Rationale**: FR-006 and SC-007. No sensor runs while the page is closed or the app is in the
  background.
