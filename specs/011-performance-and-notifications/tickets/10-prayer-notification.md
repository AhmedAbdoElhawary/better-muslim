# 10: The prayer notification on Android

**What to build:** Every prayer time goes through kotlin: the countdown goes, the old notification goes, the new one comes with Mark prayed and Add to qada and comes back after a swipe.

**Blocked by:** 08, 09

**Status:** waiting for a run on the phone

- [x] Each prayer keeps its own id so the cleanup can read it, the alarm clears the old one first.
- [x] Each sound path posts it, the full adhan after it ends or stops.
- [x] Answering in the app removes it.
- [x] The next countdown removes it.
