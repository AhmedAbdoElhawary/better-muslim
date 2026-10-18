# Data Model: Milestone 5, Notifications and Adhan

Builds on milestone 2 (`specs/001-milestone-2-data/data-model.md`) and milestone 4
(`specs/002-milestone-4-prayer/data-model.md`, schema v2).

## Stored: `settings`, schema v3

Seven new columns on the one settings row, added by a step v2 → v3 (`addColumn` each, defaults
fill the existing row):

| Column | Type | Default | Rule |
| --- | --- | --- | --- |
| `fajr_sound` | text enum `PrayerSound` | `adhan` | adhan, tone or silent |
| `dhuhr_sound` | text enum `PrayerSound` | `tone` | |
| `asr_sound` | text enum `PrayerSound` | `tone` | |
| `maghrib_sound` | text enum `PrayerSound` | `adhan` | |
| `isha_sound` | text enum `PrayerSound` | `tone` | |
| `reminder_minutes` | int | `10` | check: one of 0, 5, 10, 15, 20, 30. 0 is off |
| `notifications_asked` | bool | `false` | true once the first launch asked for notifications (and alarms on Android) |

`PrayerSound { adhan, tone, silent }` sits in `core/settings/settings.dart` next to `Digits`.
`AppSettings.soundOf(Prayer)` returns the matching column.

Nothing else is stored. The schedule is rebuilt from these columns, the location and the day
times every time (research R6).

## Not stored in the database

### Alert (domain, pure)

One notification to schedule.

| Field | Type | Notes |
| --- | --- | --- |
| `id` | int | `dayNumber × 10 + slot` (R6) |
| `day` | `DateTime` (date only) | the prayer day it belongs to |
| `prayer` | `Prayer` | fajr to isha, never sunrise |
| `kind` | `AlertKind { adhan, reminder }` | |
| `at` | `TZDateTime` | the prayer time, or the prayer time minus the reminder minutes |
| `sound` | `PrayerSound` | the prayer's sound. Reminders ignore it |

- `alertId(day, prayer, kind)` and `alertFromId(id)` turn one into the other. `alertFromId` gives
  null for the test id 1,000,000.
- Rules: `at` is after now, the prayer has a time that day, `day` is one of the 6 prayer days.

### Payload

The string each notification carries, the same on both platforms and in the native entries:
`yyyy-MM-dd|prayer|kind|sound|atMillis`, for example `2026-10-15|maghrib|adhan|adhan|1792076160000`.
Pipe separated, so Kotlin reads it with one `split`. It holds no place and no name.

### Alarm entry (Android native, `AdhanAlarms`)

What Dart hands to Kotlin for each Adhan prayer when exact alarms are allowed, kept in the app's
private preferences until it fires or the next `apply` replaces it:

| Field | Example |
| --- | --- |
| `id` | 24793 (day 2479 × 10 + slot 3, Maghrib) |
| `atMillis` | 1792076160000 |
| `payload` | see above |
| `asset` | `assets/audio/adhan_makkah.m4a` |
| `channel` | `adhan_maghrib_adhan` |
| `title` | `Maghrib · 17:56` |
| `body` | `It is time for Maghrib in Makkah. Tap to mark it prayed.` |
| `mediaTitle` | `Maghrib · 17:56` |
| `mediaSubtitle` | `Adhan of Makkah` |
| `subText` | `Adhan`, Android draws the app name before it ("Better Muslim · Adhan") |
| `actions` | localized "Mark prayed", "Stop", "Pause", "Play" |

### AdhanRecording

`AdhanRecording { makkah }` in `data/adhan_recording.dart`, with the full asset, the Fajr full
asset, and the clip names for iOS and Android. One value in this milestone, the picker of
milestone 9 adds the rest.

### Playback state (from the player)

| Field | Type |
| --- | --- |
| `id` | int, the alert id being played, null when idle |
| `playing` | bool |
| `position` | `Duration` |
| `duration` | `Duration` |
| `ended` | bool |

The Android player streams it from the service every 500 ms while playing. The iOS player maps
just_audio's position and state streams.

### TapTarget (domain, pure)

`AdhanTarget(prayer, day, from)` or `PrayerTarget(day, prayer)` or `NoTarget`, from
`tapTarget(payload, now, length)` (R9).

## State transitions

```text
alert scheduled ──(prayer time, app closed)──▶ delivered
  Android Adhan + exact + ringer on ─▶ playing (media notification)
       ├─ Pause ⇄ Play
       ├─ Mark prayed ─▶ logged, keeps playing, action gone
       ├─ Stop ─▶ notification removed
       └─ ends ─▶ plain notification with Mark prayed
  everything else ─▶ plain notification
       ├─ Mark prayed ─▶ logged, notification removed
       ├─ tap ─▶ adhan screen (Adhan, within the length) or Prayer tab
       └─ prayer logged anywhere ─▶ notification removed
```

## Migration test

`test/drift/app_database/migration_test.dart` (milestone 4) gets v2 → v3: an existing row keeps
every value and reads the seven defaults. `drift_schemas/app_database/drift_schema_v3.json` is
generated with `make-migrations` and committed.
