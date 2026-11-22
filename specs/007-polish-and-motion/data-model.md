# Data Model: Milestone 12, Polish and Motion

Schema version 8 of the encrypted store, plus the calendar and Tasbih models in their features.
Enums are stored by name, like milestones 2 to 11.

## Stored: `settings`

| Column | Type | Default | Rule |
| --- | --- | --- | --- |
| calendarMode | text enum `CalendarMode { hijri, gregorian }` | `hijri` | the title tap writes it (FR-001) |
| topGlow | bool | true | More › Appearance › Top glow (FR-042) |
| subhanallahCount | int ≥ 0 | 0 | Tasbih's first dhikr, up to 33 |
| alhamdulillahCount | int ≥ 0 | 0 | the second, up to 33 |
| allahuAkbarCount | int ≥ 0 | 0 | the third, up to 34 |
| tasbihDhikr | int 0 to 2 | 0 | unchanged, the dhikr shown |
| ~~tasbihCount~~ | | | dropped, its value moves to the shown dhikr's column |

- All five are the user's, so a backup carries them like the rest of the row.
- `CalendarMode` lives in `core/settings/settings.dart` next to `Digits`.
- The counts never pass their dhikr's target in the app, the check only keeps them ≥ 0 as before.

## Migration 7 → 8

- One `alterTable(TableMigration(schema.settings, ...))`, the same way as v4 → v5 (sqlite can't drop
  a column with a check in place):
  - `newColumns`: `calendarMode`, `topGlow` (their defaults)
  - `columnTransformer`: each count reads `tasbih_count` when `tasbih_dhikr` is its index, else 0
  - `tasbihCount` isn't in the new table, so it goes
- `dart run build_runner build` and `dart run drift_dev make-migrations` write
  `drift_schema_v8.json`, the steps and `test/drift/app_database/generated/schema_v8.dart`.
- `migration_test.dart` checks v7 → v8: every row kept, the mode reads Hijri, the glow on, a v7 row
  with Alhamdulillah at 12 gives 0, 12, 0 and Alhamdulillah shown.
- A v7 backup goes through the same steps when `readBackup` opens it (R4).

## Tasbih round (`features/azkar/model/tasbih_state.dart`)

`TasbihState(dhikr, counts)`, `counts` three ints in `tasbihDhikr`'s order.

| Member | Rule |
| --- | --- |
| `count`, `target`, `done` | of the shown dhikr |
| `doneAt(i)` | `counts[i] >= tasbihDhikr[i].target` |
| `complete` | all three done |
| `nextOpen` | the first dhikr after the shown one, going around, that isn't done; null when complete |
| `tap()` | complete → `(0, [1, 0, 0])`. Shown done → `nextOpen` at its count + 1. Else the shown + 1 |
| `advance()` | `nextOpen` shown, counts unchanged; the same state when complete |
| `select(i)` | `i` shown, counts unchanged |
| `reset()` | `(0, [0, 0, 0])` |
| `position` | the bead in focus on the string (below) |

Rules: a count never passes its target. 100 taps from reset give 33, 33, 34 and `complete`
(SC-005). `==` and `hashCode` over both fields, like now.

### The string (FR-030)

| Place | Bead index |
| --- | --- |
| SubhanAllah's 33 | 0 to 32 |
| marker | 33 |
| Alhamdulillah's 33 | 34 to 66 |
| marker | 67 |
| Allahu Akbar's 33 | 68 to 100 |
| head bead with its tassel | 101 |

- The bead in focus is `start(dhikr) + count - 1`, with `start` 0, 34, 68. A count of 0 focuses the
  place before the dhikr's first bead (the free end before bead 0, or the marker before 34 and 68).
- Allahu Akbar's 34th count is the head bead (101).
- The strip shows a window around the focus and clamps at both ends: the free end of the string
  shows before bead 0, nothing past the tassel.

### The automatic move

| State | Event | Then |
| --- | --- | --- |
| counting | a tap finishes the shown dhikr, another isn't done | waiting (timer `completionPause`) |
| counting | a tap finishes the last one left | complete |
| waiting | the timer ends | `advance()`, counting |
| waiting | a tap | timer cancelled, `tap()` (moves and counts 1), counting |
| waiting | a chip | timer cancelled, `select(i)` |
| waiting | Reset | timer cancelled, `reset()`, the toast with Undo |
| waiting | leaving the page | timer cancelled, nothing moves (counts already saved) |
| complete | a tap | a new round at SubhanAllah 1 |

The waiting state is the page's, not stored: a restart during it opens on the done dhikr, the next
tap moves (spec edge case).

## Azkar set: the automatic move

| State | Event | Then |
| --- | --- | --- |
| counting | `SetTap.done` on a card that isn't the last | waiting (timer `completionPause`) |
| counting | `SetTap.setDone` | set complete, nothing moves |
| waiting | the timer ends | `moveNext()` |
| waiting | a tap | `tap()` answers `moved` for the done card, the timer is cancelled |
| waiting | a page change (swipe) or leaving | timer cancelled |

## Calendar (`features/hijri_calendar/`)

### `CalendarMonth` (sealed)

| Member | `HijriMonth(year, month)` | `GregorianMonth(year, month)` |
| --- | --- | --- |
| range | 1356/1 to 1500/12 | 1937/4 to 2077/10 |
| `days(adjust)` | each Gregorian date of the Hijri month, the adjustment applied | each date of the month |
| `blanks(adjust)` | cells before the first day, the week from Sunday | the same |
| `previous`, `next`, `canGoBack`, `canGoForward` | as now, the arrows check `canGo*` | the same, April 1937 and October 2077 are the ends |
| `of(day, adjust)` | the month holding a Gregorian day | the same |
| `compareTo` | for the slide's direction | the same |

### State (`view_model/calendar_providers.dart`)

| Provider | Value | Lives |
| --- | --- | --- |
| `calendarModeProvider` | `CalendarMode` from the settings | the app |
| `selectedDayProvider` | a date, today on open | the page (autoDispose) |
| `calendarPageProvider` | `(view: CalendarView, month: CalendarMonth)` | the page |
| `dayTabProvider` | `DayTab { prayerTimes, comingUp, events }`, Prayer times on open | the page |
| `comingUpProvider` | `ComingUp` from the selected day, today, the adjustment, the mode | the page |
| `todayEnabledProvider` | false when the selected day is today, the view is days and the month holds today | the page |

`CalendarView { days, months, years }`. The years view's page holds 12 years: first year
`1356 + 12k` or `1937 + 12k` holding the shown month's year. The arrows step a month, a year or 12
years, disabled past the range.

### `ComingUp` (`model/coming_up.dart`)

| Field | Rule |
| --- | --- |
| year | the walked year: Hijri in Hijri mode, Gregorian in Gregorian mode |
| next | true when the selected day's year had nothing left |
| groups | `(month, current, items)`, the selected day's month first (`current`, "This month"), then each later month with an item |
| item.event | a `HijriEvent` |
| item.first | the Gregorian date of the event's first day |
| item.daysAway | whole days from the selected day to `first`, ≥ 1 |
| item.estimated | the event's Hijri month is after today's Hijri month |

- The walk: the day after the selected day to the year's last day, never past the table's end.
- An item is an event whose first day (`from`) falls on a walked day, so a running event isn't
  listed.
- Empty: the next year's walk with `next: true`. Still empty: no groups, "No more events".

## Theme sky (`core/resources/theme_sky.dart`)

`themeSky(BmThemeId) → Map<BmSkyState, BmSkyStops>`, kept once per theme.

| Theme | Rule |
| --- | --- |
| Qiyam Emerald | `bmSkyQiyamEmerald` as is |
| any other, Isha | the theme's dark `sky1`, `sky2`, `sky3` |
| any other, Fajr to Maghrib | each of Emerald's three stops in OKLCH, hue turned by `hue(theme.dark.sky3) − hue(emerald.dark.sky3)`, chroma scaled by their ratio (0.5 to 1.5), lightness kept, chroma cut until it fits sRGB |

`bmSkyIsBright` stays per state. Read by `SkyHeader`, `WelcomeSky`, `SnippetSky`. The adhan screen
and the system surfaces keep `bmSkyQiyamEmerald`.

## Contact details (`features/more/model/contact.dart`)

| Constant | Used by | Hidden when |
| --- | --- | --- |
| `email` | Send feedback | null |
| `appStoreUrl`, `playStoreUrl` | Rate (the platform's), Share (the platform's link) | the platform's is null |
| `developerName`, `website` | Developer (name as the value, opens the site) | either is null |

Each starts null with a `TODO(ahmed)`. CONTACT is hidden when all its rows are.
