# Contract: the compass channel

Between Dart (`features/qibla/model/compass_source.dart`) and the phone:
- iOS: `AppDelegate.swift`, registered like the backup and power channels.
- Android: `CompassStreamHandler.kt`, registered in `MainActivity.configureFlutterEngine`.

## Event channel `better_muslim/compass`

Listening starts the sensor, cancelling stops it. No arguments.

| Event | Meaning |
| --- | --- |
| `{"heading": double, "accuracy": double}` | `heading`: degrees from **magnetic** north of the top of the screen as it is shown now, 0 ≤ h < 360. `accuracy`: degrees, −1 when unknown or invalid |
| `null` | the phone has no compass. Sent once, then nothing more |

No errors are sent. A sensor that stops sending simply sends nothing.

## iOS

- `CLLocationManager.headingAvailable()` false → `null`.
- `headingFilter = 0.5`, `headingOrientation` from the window scene's interface orientation,
  updated on `UIDevice.orientationDidChangeNotification` (R8).
- `heading` = `magneticHeading`, `accuracy` = `headingAccuracy` (negative → −1).
- `locationManagerShouldDisplayHeadingCalibration` returns false (R9).
- Never asks for location permission and never starts location updates.

## Android

- `getDefaultSensor(TYPE_ROTATION_VECTOR)` null → `null`.
- `SENSOR_DELAY_UI`. `getRotationMatrixFromVector`, then `remapCoordinateSystem` by
  `display.rotation`, then `getOrientation`. Azimuth to degrees, normalized to 0..360 (R8).
- `accuracy` = `values[4]` in degrees when present and ≥ 0, else the sensor status: high 15,
  medium 30, low 45, unreliable −1 (R9).

## Dart side

`CompassSource.readings()` maps each event to a raw `(magnetic, accuracyDegrees)` record or `null`.
Off iOS and Android it gives a single `null`, so the page shows the no compass state. A missing
plugin is reported by `EventChannel` as a Flutter error, never on the stream, so it can't be caught
there, and tests give a fake `CompassSource`. Smoothing and the declination are done in the view
model (R3, R5).
