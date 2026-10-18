# Data Model: Milestone 3, Home

No new tables and no new settings. Home reads milestone 2's store and adds derived values only.
Everything below is computed from the clock, the location's times and the settings.

## Read from core (milestone 2, plus two seams for milestone 4)

| Value | Source | Changes |
| --- | --- | --- |
| now | `tickerProvider` (on the wall clock's second, R5) | every second |
| location | `locationProvider` | on choose, use auto, a 30 km move |
| current period | `periodProvider` | at each prayer time |
| next prayer and its time | `nextPrayerProvider` | at each prayer time |
| prayer day | `prayerDayProvider` (new, milestone 4's contract) | at Fajr |
| prayer day times | `dayTimesProvider(prayerDay)` | at Fajr, on a location or method change |
| logged prayers | `prayedProvider(prayerDay)` (new, `{}` until milestone 4) | on a log change |
| date, Hijri date | `todayProvider`, `hijriDateProvider(today)` | at midnight, on an adjustment |
| digits, reduce motion | `settingsProvider` | on a settings change |

## Derived in `features/home/model/`

Pure functions with no Flutter.

- **Bar share**: `(now − periodStart) / (next − periodStart)`, clamped to 0..1. `periodStart` is
  the time the current period began:
  - Duha begins at sunrise.
  - Isha before Fajr began at yesterday's Isha.
- **Sky state**: from the period. fajr → fajr, duha → sunrise, dhuhr → dhuhr, asr → asr,
  maghrib → maghrib, isha → isha. With no location there is no state, the sky shows the theme
  base.
- **Stars on**: the state is fajr, maghrib or isha, or the sky mode is theme base.
- **Sun share**: `BmSunArc.fraction(now, sunrise, maghrib)`, rounded to 0.001 so the provider
  notifies about once every 40 s. Null at night or when either time is missing.
- **Arc labels**: from sunrise to Maghrib, "Sunrise {sunrise}" and "Maghrib {maghrib}". From
  Maghrib until sunrise, "Isha {isha}" and "Fajr {next fajr}". Both come from the prayer day: the
  Isha that started the night and the Fajr that ends it.
- **Azkar window**: morning when the period is fajr, duha or dhuhr. Evening when it is asr,
  maghrib or isha, or null.
- **Glow breathing**: `0 < next − now ≤ 10 min`.
- **Countdown parts**: hours, minutes, seconds from `next − now` rounded to the nearest second.
  Shown `h:mm:ss`, hours not padded.
- **Strip cell state**: `logged` (check), `current` (highlight, plus a dot while not logged), or
  `plain`. The current cell is the period's prayer. During Duha no cell is current.

## Home view state

Each widget watches only its own slice with `.select()`.

| Slice | Who reads it | Notifies |
| --- | --- | --- |
| has location | page | on set or clear |
| place name (language) | location pill | on a location change |
| date line | date line | at midnight |
| period and its Arabic name | NOW block | at each prayer time |
| next prayer, its time | card title, adhan line, "Until …" | at each prayer time |
| time left | countdown digits, bar | every second |
| glow breathing | glow | twice per prayer |
| strip cells | strip | at prayer times, at Fajr, on a log change |
| sky state, stars on, sun share | sky | at prayer times, about every 40 s |
| azkar window | azkar row | at Fajr and Asr |

## Sample content (`home_samples.dart`, R14)

| Field | Value until replaced | Replaced by |
| --- | --- | --- |
| verse reference | Al-Fatiha 1:5 / الفاتحة ٥ | milestone 7, `TODO(ahmed)` for the dataset |
| verse text | إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ | milestone 7, `TODO(ahmed)` |
| verse translation | It is You we worship and You we ask for help. | milestone 7, `TODO(ahmed)` |
| continue reading | Al-Fatiha · ayah 3 of 7 | milestone 7 |
| evening azkar | 0 of 24 | milestone 8 |
| morning azkar | 0 of 12 | milestone 8 |
| reminder minutes | 10 | milestone 5 |

## Location choice

No change to milestone 2's data:
- picking a place: `LocationController.choose(place)`, mode manual
- "Use my location": `useAuto()`, mode auto

The sheet keeps only its search text, in memory.
