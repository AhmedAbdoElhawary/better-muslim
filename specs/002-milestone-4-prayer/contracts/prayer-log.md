# Contract: the prayer log for the other features

What milestone 3 (Home), 5 (notifications and adhan), 9 (More) and 11 (widgets) use. It adds to the
milestone 2 contract (`specs/001-milestone-2-data/contracts/core-data.md`). Qada stays inside the
prayer feature and is not part of this contract.

## Read

| Provider | Type | Gives |
| --- | --- | --- |
| `prayerDayProvider` | `Provider<DateTime>` | the day whose prayers are current: the location's date, yesterday before today's Fajr. Notifies only when it changes |
| `prayedProvider` | `Provider.autoDispose.family<Set<Prayer>, DateTime>` | the prayers logged on a day. Home's strip checks: `ref.watch(prayedProvider(ref.watch(prayerDayProvider)))` |
| `weekLogProvider` | `StreamProvider.autoDispose.family<Map<DateTime, Set<Prayer>>, DateTime>` | the 7 days from a Sunday, one query |

`DayTimes.endOf(Prayer prayer, DayTimes? tomorrow)` gives the end of a prayer's window, the same
boundaries as `periodAt`.

## Write

| Call | Effect |
| --- | --- |
| `AppDatabase.markPrayed(DateTime day, Prayer prayer)` | logs it, a second call changes nothing |
| `AppDatabase.unmarkPrayed(DateTime day, Prayer prayer)` | removes it |

Both are plain store methods. They work without widgets or Riverpod, so milestone 5's notification
action can call them from a background engine after `AppDatabase.open()`. The day passed is the
prayer day of that prayer: for a notification, the date the notification was scheduled for, not
the date it is tapped.

## Navigate

| Route | Opens |
| --- | --- |
| `Routes.prayerAt(DateTime day, Prayer prayer)` → `/prayer?day=2026-10-15&prayer=asr` | the Prayer tab on that day, scrolled to the row. Home's strip cells (milestone 3), notification taps (milestone 5) |
| `Routes.prayer` | the Prayer tab on the prayer day |
| `Routes.qada` → `/prayer/qada` | the qada list, pushed inside the Prayer branch |

## Uses from milestone 3

The location sheet, in `core/`. The Prayer tab's pin opens the same sheet as Home's location pill.
If milestone 3 built it under `features/home/`, this milestone moves it to `core/` first (R14).

## Guarantees

- A log row is keyed by prayer day and prayer, never by clock time. Location, method, Asr and time
  zone changes never move or drop it.
- Nothing in the log leaves the phone or reaches a crash report.
- Writes from another engine or isolate show up once the reader's connection sees them (research
  notes for milestone 5).
