# 05: Coming up counts from today

**What to build:** Coming up still lists the events after the selected day, but each event's pill
counts from today, so "in 12 days" is true whichever day I tapped.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] The list starts the day after the selected day, as now.
- [x] Each pill counts from today: "Today" on today, "in N days" ahead, a muted "N days ago" for
      an event already passed.
- [x] New strings in both arb files, with Arabic plurals like the existing day counts.
- [x] Gregorian mode and the date adjustment count the same way.
- [x] `coming_up_test` covers a past, today's and a future selected day.
