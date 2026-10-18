# Quickstart: checking milestone 6

## Before

```bash
flutter pub get
```

No new package, no code generation.

## 1. Tests (all offline)

```bash
dart format --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
```

Expected, among the rest:
- `test/features/qibla/model/qibla_math_test.dart`: 20 places on every continent, both
  hemispheres, near the date line and inside Makkah. Bearing within 0.5° and distance within 0.5%
  of reference values worked out on the WGS84 ellipsoid (SC-002). London gives 119° and
  "4,790 km". Distance rounding at 99.9 km, 100 km, 999 m and 1 km. The difference is never −180
  and never shows "0°".
- `test/features/qibla/model/declination_test.dart`: every row of NOAA's WMM2025 test values
  within 0.01° (R3).
- `test/features/qibla/model/qibla_tracker_test.dart`: 116° held 399 ms stays turning, 400 ms
  aligns. 123.9° stays aligned, 124.1° turns back. A scripted run with ±1° jitter on 3°, 5°, 10°
  and 15° gives one approach and one aligned per pass (SC-005). Opening inside ±10° gives no
  approach.
- `test/features/qibla/view_model/`: smoothing across north (359° then 1° stays near 0°), a still
  phone moves the smoothed heading under 1° (SC-004), the fix replaces the saved coordinates only
  in auto mode and keeps the saved name.
- `test/features/qibla/view/qibla_page_test.dart`: turning, aligned, Medium and Low (calibration
  hint), no compass, no location (both buttons open the location sheet), the gear opens the
  location sheet, Arabic (ش ق ج غ, Eastern digits, "٤٬٧٩٠ كم", the dial not mirrored), text scale
  2.0 scrolls with nothing cut, reduce motion (no pulses, colors still change), every action at
  least 44 x 44.
- `test/architecture_test.dart` and `strings_manager_test.dart` pass.

Journey test, on a simulator or a phone:

```bash
flutter test integration_test/qibla_journey_test.dart --flavor dev -d <device id> \
  --dart-define-from-file=dart_define/dev.json --dart-define=SCENARIO=design
```

It opens More, taps Qibla, sees "Turn 14° right", taps the dial and sees "Facing the Qibla".

## 2. The design scenario

Run "Dev · design scenario" (VS Code or Android Studio). More › Qibla:
- London, "Turn 14° right", "London · Qibla at 119° from north", "4,790 km", "High", the needle
  14° right of the top tick, on the Kaaba marker (4.05).
- Tap the dial: "Facing the Qibla", "Hold steady", accent ring and tick, two pulses, the success
  haptic (4.06). Tap again: back to turning.
- Dark and light, English and Arabic, text scale 2.0, reduce motion on and off.

## 3. A real phone, outdoors, away from metal

Run Dev, More › Qibla:
- The needle points within 5° of a reference compass app set to true north (SC-003).
- Turn slowly into the Qibla: one tick near 10°, then aligned with one success haptic after a
  moment within 3°. Drift past 5°: back to turning. Come back: aligned and the haptic again.
- Lay the phone still: the needle doesn't wander (SC-004).
- Put it next to a laptop: accuracy drops, at Low the hint asks for a figure 8.
- Airplane mode: everything still works (SC-006).
- Leave the page or the app: the compass stops (SC-007, the battery stays quiet).
- Turn the phone to landscape on a table: the needle still points the same way.

## 4. Without a location

On a fresh install, skip location, open More › Qibla: "No location yet", both buttons. Pick a city
in the sheet: the marker, needle, subtitle and distance appear.

## 5. iPhone with location refused

Settings › Privacy › Location › Better Muslim › Never. Pick a city in the app. Qibla still turns
with the phone and points the right way (R2, heading needs no location permission).
