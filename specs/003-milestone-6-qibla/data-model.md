# Data Model: Milestone 6, Qibla

Nothing is stored. The heading, the fix and the alignment live only while the page is open
(FR-028). Everything below is in memory, in `features/qibla/`.

## CompassReading (model)

One smoothed reading from the compass channel (contracts/compass-channel.md, R5).

| Field | Type | Rule |
| --- | --- | --- |
| heading | double | degrees from true north, 0 ≤ h < 360, magnetic heading + declination (R3) |
| accuracy | `CompassAccuracy` | high (≤ 15°), medium (≤ 30°), low (above, or unknown) (R9) |

The stream gives `null` once when the phone has no compass (R11).

## QiblaPlace (model)

Where the Qibla is worked out from (R10).

| Field | Type | Rule |
| --- | --- | --- |
| latitude, longitude | double | the fresh fix when the location is automatic and allowed, else the saved location |
| name | String | the saved place name in the app's language, never from the fix |

Null when no location is saved.

## QiblaTarget (derived)

| Field | Type | Rule |
| --- | --- | --- |
| bearing | double | `Qibla.qibla` from the place, degrees from true north (R4) |
| distanceKm | double | haversine, mean radius 6371.0088 km (R4) |

Shown: the bearing rounded to the whole degree, the distance rounded by FR-009.

## Difference (derived)

`diff = ((bearing − heading + 540) % 360) − 180`, then 180 when it comes out as −180. So
−180 < diff ≤ 180. Positive is "Turn {deg}° right", negative "left", shown as
`max(1, |diff|.round())` (FR-013).

## QiblaTracker (model, pure)

Turns differences into a phase and events (R6). It holds:

| Field | Type | Meaning |
| --- | --- | --- |
| phase | `QiblaPhase` | turning or aligned |
| insideSince | DateTime? | when the difference came inside ±3°, null outside |
| approachArmed | bool | the approach haptic can fire again |
| lastDiff | double? | null until the first reading after a start or a resume |

Transitions:

| From | On | To | Event |
| --- | --- | --- | --- |
| turning | \|diff\| ≤ 3, insideSince null | turning, insideSince = now | |
| turning | \|diff\| > 3 | turning, insideSince = null | |
| turning | timer at insideSince + 400 ms, still inside | aligned | `aligned` |
| aligned | \|diff\| ≤ 5 | aligned | |
| aligned | \|diff\| > 5 | turning, insideSince = null | |
| any | \|diff\| ≤ 10, approachArmed, lastDiff outside ±10 | same | `approach`, approachArmed = false |
| any | \|diff\| > 15 | same | approachArmed = true |
| any | pause, resume, place change | turning, fresh | |

The first reading only sets `lastDiff`, so opening inside ±10° never fires `approach`.

## QiblaView (view model)

What the page reads, each part through its own provider so it rebuilds alone:

| Part | Source | Rebuilds when |
| --- | --- | --- |
| state | compass + place | no location, no compass, waiting for the first reading, ready |
| heading | compass reading | every reading (dial and needle only) |
| instruction | diff rounded + phase | the whole degree or the phase changes |
| accuracy | compass reading | the level changes |
| target | place | the place moves |

## Design scenario (R12)

| Value | Turning | Aligned |
| --- | --- | --- |
| place | London 51.5074, −0.1278 | same |
| heading | 105° | 119° (tap on the dial) |
| accuracy | high | high |
| shown | "Turn 14° right", "London · Qibla at 119° from north", "4,790 km", "High" | "Facing the Qibla", "Hold steady" |
