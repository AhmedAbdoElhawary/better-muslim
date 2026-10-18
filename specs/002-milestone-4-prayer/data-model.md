# Data Model: Milestone 4, Prayer

Schema version 2 of the encrypted store (R6). Dates are text `yyyy-MM-dd` through the `CivilDate`
converter and read back as `DateTime(y, m, d)` (R2). Enums are stored by name, like milestone 2.

## Stored: `prayer_log`

One row per prayer prayed on a prayer day.

| Column | Type | Rule |
| --- | --- | --- |
| date | text (`CivilDate`) | the prayer day the prayer belongs to, not the clock time it was marked |
| prayer | `Prayer` | fajr, dhuhr, asr, maghrib, isha |

Primary key `(date, prayer)`. Marking is `insertOrIgnore`, so a double tap or a second Mark prayed
from a notification leaves one row (FR-010, milestone 5 US3-5). Unmarking deletes the row.

## Stored: `qada_entries`

One row per prayer to make up.

| Column | Type | Rule |
| --- | --- | --- |
| id | int, auto increment | the undo of "made one up" finds the entry by it |
| prayer | `Prayer` | |
| missedOn | text? (`CivilDate`) | the prayer day, null = missed before using the app (FR-020) |
| madeUpAt | datetime? | when it was made up (an instant), null = still open (FR-021) |

Unique index `(missedOn, prayer)`. A prayer day is in qada once, dateless entries never collide
(SQLite nulls are distinct).

## Stored: `settings.firstUse`

| Column | Type | Default | Rule |
| --- | --- | --- | --- |
| firstUse | text? (`CivilDate`) | the date the row is created | the strip's earliest week. The v1 → v2 migration fills it with the upgrade date. Read clamped to today |

## Derived: prayer day and windows (core)

- `prayerDayProvider`: the location's date, or yesterday before today's Fajr (R3).
- `DayTimes.endOf(prayer, tomorrow)`: the next period start that has a time:

  | Prayer | Window ends at |
  | --- | --- |
  | Fajr | sunrise |
  | Dhuhr | Asr |
  | Asr | Maghrib |
  | Maghrib | Isha |
  | Isha | tomorrow's Fajr |

  A null time is skipped, so the next one with a time ends the window. Null when none is left.

## Derived: row state (feature domain)

`PrayerRowState { unavailable, prayed, next, later, mark, madeUp, inQada, addToQada }`, first match
wins (R4):

| Order | When | State | Trailing |
| --- | --- | --- | --- |
| 1 | no time that day | unavailable | the time shows as not available, no action |
| 2 | in `prayer_log` | prayed | "Prayed" chip, a toggle |
| 3 | now < time, and it is the next prayer | next | "in h:mm" chip |
| 3 | now < time | later | adhan icon |
| 4 | now < end | mark | "Mark" button |
| 5 | dated qada entry, made up | madeUp | "Made up" chip (green look of "Prayed"), a label, not a button |
| 5 | dated qada entry, open | inQada | "In qada" chip (outline look of "Add to qada") |
| 6 | otherwise | addToQada | "Add to qada" chip |

`isOpen` = time ≤ now < end: the row gets the primaryContainer fill and NOW, whatever its state.

The spec's FR-002 names: Current = `mark`, or `prayed` with `isOpen`. Passed = `addToQada`.
Prayed, Next, Later, In qada and Made up as named. `unavailable` is the polar edge case.
Sunrise is not a `Prayer` and only shows its time.

## Derived: week and summary (feature)

- Week start: the Sunday on or before a date.
- Pages: from the week of `firstUse` (clamped to today) to the week of the prayer day.
- `weekLogProvider(weekStart)`: `Map<DateTime, Set<Prayer>>` for the 7 days, one range query.
- Filled cell: the shown day. Future days keep grey numbers.
- Dots: 5 per day, filled in prayer order for the prayers in the day's set. They don't mirror.
- Summary: today's prayed count of 5, and the open qada entries with `missedOn` in today's
  Gregorian month. At 0 the second line is "Nothing to make up this month".
- Qada list: the open count per prayer and their total. Dateless entries count in the list, never
  in the month.

## State changes

```text
                 ┌──────── tap Prayed (toast: Undo → back) ────────┐
                 ▼                                                  │
later ──time──▶ mark ──Mark──────────────────────────────────▶ prayed
                 │
                end
                 ▼
            addToQada ──sheet: I prayed it───────────────────▶ prayed
                 │  ▲
  sheet: Add to qada  tap In qada (toast: Undo → back)
                 ▼  │
               inQada ──"Made one up" picks it (oldest first)──▶ madeUp
                          (toast: Undo → inQada)

qada list: + sheet, Add N ──▶ N open dateless entries (toast: Undo → removed)
           each ──"Made one up"──▶ made up, one at a time
```

## Undo

| Action | Undo does |
| --- | --- |
| unmark (tap "Prayed") | marks it again |
| I prayed it | no toast, like Mark. Tapping "Prayed" unmarks it |
| add to qada | deletes the entry |
| remove from qada (tap "In qada") | adds it back for the same day and prayer |
| made one up | sets `madeUpAt` back to null on the same id |
| + sheet, Add N | deletes those N entries |
