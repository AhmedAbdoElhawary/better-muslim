# Data Model: Milestone 9, More, Theme and Hijri Calendar

Schema version 5 of the encrypted store. Enums are stored by name, like milestones 2 to 8. The
events, credits and recordings are code, not stored.

## Stored: `settings`, already there and now changed by More

| Column | Since | Changed by |
| --- | --- | --- |
| method, asrMethod | 2 | the method sheet (milestone 4) |
| latitude … locationMode | 2 | the location sheet (milestone 3) |
| hijriAdjust (−2 to 2) | 2 | the date adjustment sheet (FR-024) |
| digits (eastern, western) | 2 | the digits toggle, Arabic only (FR-035) |
| theme (`BmThemeId`) | 2 | Apply theme (FR-012) |
| themeMode (`BmThemeMode`) | 2 | Apply theme, the light and dark sheet (FR-016) |
| reduceMotion, haptics, uiSounds | 2 | the toggles (FR-005) |
| fajrSound … ishaSound (`PrayerSound`) | 5 | the Adhan, Tone, Silent control (FR-026) |
| reminderMinutes | 5 | the reminder sheet (FR-028), check widened to take 25 |

## Stored: `settings`, new columns

| Column | Type | Default | Rule |
| --- | --- | --- | --- |
| fajrRecording | `AdhanRecording` | makkah | the prayer's adhan, clip and Android channel sound |
| dhuhrRecording | `AdhanRecording` | makkah | same |
| asrRecording | `AdhanRecording` | makkah | same |
| maghribRecording | `AdhanRecording` | makkah | same |
| ishaRecording | `AdhanRecording` | makkah | same |

`AdhanRecording`: makkah, madinah, alAqsa, cairo, istanbul, takbir. A name the app no longer
knows reads as makkah.

## Migration 4 → 5

- add the five recording columns with their default
- remake `settings` with the reminder check `0, 5, 10, 15, 20, 25, 30`, every row and value kept
- `dart run drift_dev make-migrations` writes `drift_schema_v5.json`, the steps and the generated
  schema test, `migration_test.dart` checks v4 → v5

## Store calls

| Call | Does |
| --- | --- |
| `updateSettings(SettingsCompanion)` | every setting here, as today |
| `resetPrayerJourney()` | deletes all `prayer_log` and `qada_entries` rows in one transaction (FR-032) |

## Not stored: theme preview

| Field | Rule |
| --- | --- |
| theme | starts as the saved theme |
| mode | starts as the saved mode |

Lives while the theme page is open (`autoDispose`). Apply saves both, back drops them.

## Not stored: resolved mode

`themeModeProvider` → `ThemeMode`:

| Saved mode | Location | Result |
| --- | --- | --- |
| dark | any | dark |
| light | any | light |
| followSky | yes | light when sunrise < now < Maghrib today, else dark |
| followSky | none | system |
| followSky | design scenario | system |

## Not stored: Hijri month

| Field | Rule |
| --- | --- |
| year, month | 1356/1 to the table's last month |
| first | `hijriToGregorian(year, month, 1)` − adjustment, a date |
| length | 29 or 30, `getDaysInMonth(year, month)` |
| blanks | weekday of `first`, Sunday = 0 |
| days | `first + i` for i in 0 until length, each with its Gregorian label |

The shown month starts as today's Hijri month (with the adjustment) and moves with the arrows.
The calendar icon brings back today's. Selection lives while the day sheet is open.

## Not stored: Hijri event (const)

| Field | Values |
| --- | --- |
| month | 1 to 12, or every month (Ayyam al-Bid) |
| days | first and last Hijri day |
| look | event, sunnahFast, whiteDay |
| nameKey | StringsManager key |
| noteKey | StringsManager key or none |

The ten rows of FR-020. Ayyam al-Bid: 13 to 15, except Dhu al-Hijjah 14 and 15.

## Not stored: day look

One per cell, the first that applies: today, selected, sunnahFast, event, whiteDay, plain.

## Not stored: COMING UP item

| Field | Rule |
| --- | --- |
| hijri day, short month | the left column |
| title key + args | the event's name, "Ayyam al-Bid" or "{month} begins" |
| date line | inside the current Hijri month: the date or range alone. Else "Estimated {date}", the first month start in the list "Estimated {date} · confirmed by moon sighting". Ayyam al-Bid keeps its "White days, fasting recommended · {range}" |

Three items, from today on, nearest first. A month's first day that has an event shows as the
event only.

## Not stored: credit (const)

| Field | Rule |
| --- | --- |
| source | name as written by its owner, not translated |
| useKey | what the app uses it for, a key |
| license | "CC BY 4.0", "SIL OFL 1.1"… not translated |
| link | https, opened through the system channel |
