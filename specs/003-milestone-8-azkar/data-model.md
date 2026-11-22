# Data Model: Milestone 8, Azkar, Tasbih and Duas

Schema version 4 of the encrypted store (R5). Dates are text `yyyy-MM-dd` through `CivilDate`,
enums are stored by name, like milestones 2 and 4. Content (sets, duas) is not in the store, it
ships as JSON (R2, `contracts/content-files.md`).

## Stored: `settings`, new columns

| Column | Type | Default | Rule |
| --- | --- | --- | --- |
| tasbihDhikr | int | 0 | 0 SubhanAllah, 1 Alhamdulillah, 2 Allahu Akbar. Check 0 to 2 |
| tasbihCount | int | 0 | never below 0, never above the dhikr's target |
| morningOpenedOn | text? (`CivilDate`) | null | the morning window last opened, the badge reads it |
| eveningOpenedOn | text? (`CivilDate`) | null | the same for the evening |
| azkarNudges | bool | true | the switch on the Azkar tab (FR-041) |

## Stored: `azkar_counts`

| Column | Type | Rule |
| --- | --- | --- |
| setId | `AzkarSet` | morning, evening |
| day | text (`CivilDate`) | the window's prayer day (R4) |
| zikr | text | the item's `id` from `azkar.json` |
| count | int | 0 to the item's count |

Primary key `(setId, day, zikr)`. Written on every tap (upsert). The first write in a new window
deletes that set's rows of older days. A zikr id no longer in the content is ignored when read.

## Stored: `saved_duas`

| Column | Type | Rule |
| --- | --- | --- |
| dua | text | the dua's `id` from `duas.json`, primary key |
| savedAt | datetime | newest first in the Saved chip |

Save inserts, removing deletes, Undo inserts the same row back with its old `savedAt`. An id no
longer in the content is skipped when read.

## Migration 3 → 4

`from3To4`: add the five settings columns, create `azkar_counts` and `saved_duas`. Nothing to fill,
the defaults are right for an existing install. Export `drift_schemas/drift_schema_v4.json`,
generate `test/drift/app_database/generated/schema_v4.dart`, add the v3 → v4 case to
`migration_test.dart`.

## Content (read only, from JSON)

- **Zikr**: id, arabic, transliteration, translation, source (en, ar), grading (en, ar)?, count
  (times said, at least 1), quran (bool), note?.
- **AzkarSet content**: the set, minutes (for the nudge), its zikr in order. Total = number of
  items.
- **TasbihDhikr** (consts): arabic (with marks, for the big line), arabicName (plain, for the
  chip in Arabic), name, meaning, target (33, 33, 34).
- **Dua**: id, arabic, transliteration, translation, source (en, ar), grading?, audio (asset
  path)?, note?.
- **DuaCategory**: id, name (en, ar), chip, duas in order.
- **DuaChip**: all, morningEvening, home, travel, sleep, saved. All and Saved aren't in the file.

## Derived (core/azkar)

- `currentAzkarSet(Period?)`: morning in Fajr, Duha, Dhuhr, evening otherwise.
- `azkarWindowDay(set, prayerDay, period)`: the latest window's day (R4).
- `azkarCountsProvider(set)`: the latest window's counts, a stream.
- `azkarProgressProvider(set)`: `(done, total)`, done = items whose count reached their number.
- `azkarBadgeProvider`: a location, and the current set's window ≠ its opened day.

## State machines

**Tasbih** (one dhikr i, count n, target t):
- tap: n < t → n + 1 (at t: done, Motion 12, set complete haptic). n = t → i + 1 (after 2 → 0), n
  = 1.
- chip j → i = j, n = 0. Reset → i = 0, n = 0, Undo → the (i, n) from before.

**Set page** (cards 0..k, counts c):
- open → the first card with c < count, or the last if all done.
- tap on card j: c < count → c + 1 (at count: done). c = count and j < k → move to j + 1. c =
  count and j = k → nothing.
- every card done → "Set complete" once.

**Saved dua**: not saved → Save → saved. Saved → tap → removed + toast → Undo → saved (same
savedAt).

**Nudge** (per window): pending (switch on, after now, window not done, among the next 3) →
shown. Window done, switch off or later than the next 3 → not scheduled.
