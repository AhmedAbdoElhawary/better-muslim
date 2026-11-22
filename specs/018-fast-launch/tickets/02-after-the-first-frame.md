# 02: Background work waits for Home's first second

**What to build:** The notification reschedule, the widget data and the gps check start once Home
is drawn and has had a second.

**Blocked by:** None (can start immediately)

**Status:** done, the asleep launch waits for a run on my phone

- [x] `launchSettledProvider`: the first frame on screen (3 s at most) and one second, given by
      bootstrap, at once in tests.
- [x] NotificationsBoot opens a launch payload at once and reschedules after it.
- [x] SurfacesBoot writes after it, the gps check in App runs after it.
- [ ] A launch with the phone asleep still schedules and doesn't crash.
