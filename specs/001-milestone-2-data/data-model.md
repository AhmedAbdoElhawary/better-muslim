# Data Model: Milestone 2, Data

## Stored: `settings` (encrypted store, one row)

One table, one row with `id = 1`. A missing row is created with the defaults on first open. Enums
are stored by name (drift `textEnum`), so reordering an enum never changes stored data.

| Column | Type | Default | Rule |
| --- | --- | --- | --- |
| id | int | 1 | always 1 |
| latitude | real? | null | -90 to 90, null = no location yet |
| longitude | real? | null | -180 to 180, set together with latitude |
| placeName | text? | null | the place's English (Latin) name |
| placeNameAr | text? | null | Arabic name when the list has one |
| regionName | text? | null | region in English |
| regionNameAr | text? | null | region in Arabic |
| countryCode | text? | null | ISO 3166-1 alpha-2, drives the method by country |
| timeZone | text? | null | IANA id of the place, used in manual mode |
| locationMode | `LocationMode`? | null | auto or manual, null = no location yet |
| method | `PrayerMethod`? | null | null = by country (FR-010), a value = picked by the user (FR-012) |
| asrMethod | `AsrMethod`? | null | null = by country (FR-011), a value = picked by the user |
| hijriAdjust | int | 0 | -2 to 2, a check constraint keeps it there |
| digits | `Digits` | eastern | only used in Arabic |
| theme | `BmThemeId` | qiyamEmerald | existing design enum |
| themeMode | `BmThemeMode` | followSky | existing design enum |
| reduceMotion | bool | false | |
| haptics | bool | true | |
| uiSounds | bool | false | |
| storeResetPending | bool | false | set by a store reset, cleared once the user is told (milestone 10) |

The place's names are stored, not only its id, so starting the app never needs the place list.

## Enums (core)

- `LocationMode { auto, manual }`
- `PrayerMethod { ummAlQura, egyptian, dubai, qatar, kuwait, turkiye, singapore, karachi, tehran, northAmerica, muslimWorldLeague }`.
  `PrayerMethod.forCountry(code)` follows the FR-010 table, everything not listed is
  `muslimWorldLeague`. Each value maps to its adhan_dart preset.
- `AsrMethod { standard, hanafi }`. `AsrMethod.forCountry(code)` is hanafi for PK, IN, BD, standard elsewhere.
- `Digits { eastern, western }`
- `Prayer { fajr, dhuhr, asr, maghrib, isha }`: the five, used for "next".
- `Period { fajr, duha, dhuhr, asr, maghrib, isha }`: the current period (FR-015a).

## In memory: `Place` (from the place list)

| Field | Type | Note |
| --- | --- | --- |
| name | String | GeoNames `name` |
| nameAr | String? | from `alternateNamesV2`, isolanguage ar |
| region | String? / regionAr String? | admin1 |
| countryCode | String | |
| country / countryAr | String / String? | for search results |
| latitude, longitude | double | from ×1e4 ints |
| population | int | list order |
| timeZone | String | IANA |

A place is identified by its position in the list, which is only valid while the list is loaded.
What gets saved is the values above, never the index.

## Derived: `Location`

Built from the settings row when latitude is set: coordinates, the place names, country code, the
zone in use (phone zone for auto, `timeZone` for manual, R11) and the mode. A null location means
"no location yet" (edge case: never made up).

## Derived: `DayTimes`

For one local date at one location with the effective method and Asr:

| Field | Type | Note |
| --- | --- | --- |
| date | DateTime (local date) | |
| fajr, sunrise, dhuhr, asr, maghrib, isha | TZDateTime? | null = not available (polar, R9) |
| method | PrayerMethod | the effective one |
| asrMethod | AsrMethod | the effective one |

Functions on it:
- `periodAt(now)` → `Period?`: Fajr from fajr to sunrise, Duha from sunrise to dhuhr, then Dhuhr,
  Asr, Maghrib, and Isha until the next day's fajr. Before today's fajr it is yesterday's Isha.
- `next(now)` → `(Prayer, TZDateTime)`: the next of the five, skipping sunrise. After Isha it is
  tomorrow's Fajr, so the caller passes tomorrow's `DayTimes`.

Rules:
- Umm al-Qura adds 30 minutes to Isha when the adjusted Hijri month is Ramadan (FR-014).
- The high latitude rule is picked from the latitude, never stored (FR-013).

## Derived: `HijriDate`

`day`, `month` (1 to 12), `year` for a local date after `hijriAdjust`. Month names are arb keys
`hijriMonth1` to `hijriMonth12`.

## State changes

```text
no location ──allow + fix──▶ auto ◀──switch back to auto──┐
     │                        │                            │
     └──pick a place──▶ manual ◀──pick a place─────────────┘
auto: on start/resume, fix ≥ 30 km away ──▶ new place, method by country unless picked
manual: GPS never changes it
store can't open ──▶ fresh store, defaults, storeResetPending = true
```
