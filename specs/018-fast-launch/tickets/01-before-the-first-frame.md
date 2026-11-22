# 01: Only what Home needs before the first frame

**What to build:** The cold open does its independent work at once and leaves the rest for after
Home is drawn.

**Blocked by:** None (can start immediately)

**Status:** done, the numbers wait for a run on my phones

- [x] The store, the phone's zone, both strings files and the adhan folder start together, the time
      zones decode while they run.
- [x] Localizations gets the strings already read, so it doesn't hold the first frame.
- [x] The verse of the day is read before `runApp`, 300 ms at most.
- [x] audio_service, Workmanager and the removed adhans' cleanup run after the launch settles.
- [x] The profile log prints the store's and the whole run's ms.
- [ ] Before and after numbers in `numbers.md`.
