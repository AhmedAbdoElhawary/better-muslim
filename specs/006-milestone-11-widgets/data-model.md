# Data Model: Milestone 11, Widgets and Live Activity

Schema version 7 of the encrypted store, plus one plain file the surfaces read. Enums are stored by
name, like milestones 2 to 10.

## Stored: `settings`, new column

| Column | Type | Default | Rule |
| --- | --- | --- | --- |
| prayerCountdown | bool | true | "Countdown before each prayer" (FR-013). In the backup like the reminder |

## Migration 6 → 7

- add `prayerCountdown` with default true, nothing else changes
- `dart run build_runner build` and `dart run drift_dev make-migrations` write
  `drift_schema_v7.json`, the steps and `test/drift/app_database/generated/schema_v7.dart`.
  `migration_test.dart` checks v6 → v7: every row kept, the new column reads true.

## Read by the surfaces: the store values

| Value | From | Written as |
| --- | --- | --- |
| place name | `placeName` / `placeNameAr` by language, as `AlertTexts.city` | in the texts |
| day times | `dayTimesAt` with method, Asr method, Hijri adjustment, for the 7 prayer days plus the day before (Fajr's bar starts at last night's Isha) and the day after (the last Isha's next Fajr) | epoch ms and formatted |
| method name | the picked one, or by country | "{city} · {method}" |
| reminder | `reminderMinutes`, 0 is off | the chip, or none |
| prayed | `prayer_log` of each entry's prayer day (only the current one can have marks) | ticks, the count, "· prayed" |
| digits | `digits`, read only in Arabic | formatted strings, `eastern` for the native countdowns |
| countdown switch | `prayerCountdown` | `countdown`, and no windows when off |
| language, 12/24 hour | the phone's, as the notifications | the strings |

## Written: the surface data file

`surfaces.json`, the whole shape in contracts/surface-data.md.
- iOS: the app group container, file protection until first unlock, excluded from backup after
  every write.
- Android: `filesDir`, already outside every backup.
- Made from the store, belongs to the phone, never in the app's backup file, never holds
  coordinates, the zone, history or anything of the database key (FR-004).

### Entry

One stretch of time with the same content. Ends at the next entry's `from`, the last at `until`.

| Field | Rule |
| --- | --- |
| from | epoch ms. The first is the start of the stretch the write falls in (the last boundary at or before it), so a second write in the same stretch is equal and skipped, then every fajr, sunrise, dhuhr, asr, maghrib, isha and local midnight |
| prayer, day | the next prayer and the prayer day shown (Fajr to Fajr, as `prayerDayOf`), for the tap URL |
| at | the next prayer's time, epoch ms |
| strip | the shown day's 5 prayers: name, time, logged, past. Past = before the next prayer in that day, all of them after Isha |
| next | index of the highlighted cell, null after Isha (the next Fajr is the next day's) |
| barFrom | the period's start (`periodStart`), null on a polar day without it |
| sunrise, maghrib | the local date's, null when missing. The sun shows only between them |
| strings | name, time, "at {time}", "{time} · {city}", "{prayer} {time}", the bar's start label (with "· prayed" when that prayer is logged, "Sunrise {time}" for Dhuhr), the Hijri line and "{hijri} · {city}", the large widget's date line, "{n} of 5 prayed today", the reminder chip |

### Countdown window

| Field | Rule |
| --- | --- |
| start | the later of 2 hours before the prayer and the previous prayer's time (Fajr: last night's Isha) |
| end | the prayer time |
| entry | index of the entry in force at the window's start (or now, for the one running) |

- Only in the first 6 prayer days, only with a place and the switch on.
- Never overlapping, so at most one runs.

### States a surface can be in

| State | When | Shows |
| --- | --- | --- |
| no place | no file yet, or `place: false` | the frame, the mark, "Open Better Muslim to set your place" (inline "Open Better Muslim", circular the mark) |
| ready | an entry covers now | the entry, the countdown counted natively |
| out of date | now is past `until` | the frame, the mark, "Open Better Muslim to update the times" |

### Countdown life

| Platform | Starts | Updates | Ends |
| --- | --- | --- | --- |
| Android | exact wakeup alarm at `start` | every write, every minute tick (the bar) | `setTimeoutAfter` at `end`, a write with the window gone, the switch off |
| iOS 26+ | scheduled at `start` by iOS | every write while the app or a background engine runs | the next sync after `end`; stale "Now" until then |
| iOS 16.2 to 18 | the first sync inside the window with the app open | every write while running | the same as iOS 26 |
