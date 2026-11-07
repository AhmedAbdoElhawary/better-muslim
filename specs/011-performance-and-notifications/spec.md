# Feature Specification: Performance, adhan and notifications

**Feature Branch**: `feature/enhancment-5`

**Created**: 2026-11-06

**Status**: Clarified (grilled, Q1 to Q20, all recommendations)

## What I want

- The app does no work when nobody touches it. A page with nothing moving builds no frames.
- Pushing, popping, scrolling and turning a Quran page stay smooth on my phone (CPH2773, 720p).
- The adhan plays with its progress on Android, and the page doesn't stay forever.
- One prayer notification at a time, and azkar kept apart from it.

## Decisions

### Performance

- Every number comes from Profile on the CPH2773, never Debug. `Dev · profile` is in the launch
  configs.
- Nothing loops without a finger on the screen. Only loaders run while they load. That stills the
  welcome sky, stars and sun, Home's sky, stars, sun and last 10 minutes glow, the adhan halo and
  the Qibla breathing. The sky change at each prayer and the countdown stay.
- This replaces the ambient tier of `MOTION.md`, so the constitution goes to 5.0.0 and
  `architecture_test` bans `.repeat(` outside the loaders.
- `CustomOpacity` follows its value in the same frame. A value that changes every frame must not
  start a 300 ms animation every frame.
- The Android bars lose their blur only if Profile shows the blur drops the frames. iOS keeps it.

### Adhan

- The state channel has one stream. Everyone in the app listens to that one.
- Silent, vibrate and Do Not Disturb stay quiet, and then no adhan page opens, only the
  notification. This keeps FR-022 and adds the page.
- The adhan page closes when the adhan ends, unless the dua sheet is open. This replaces FR-027.
- Prayer alarms use `setAlarmClock`. This phone gives exact alarms windows of up to an hour.

### Notifications

- "Reminder before each prayer" is the only row, off or 5 to 30 minutes. The countdown toggle goes.
- On Android the countdown is the reminder: it appears at that time with one sound and the tone
  button stays. It stays hidden while the app is on screen and appears if I leave during that time.
- At prayer time the countdown goes and "Dhuhr time in Alexandria" comes, the body is the time, the
  buttons are Mark prayed and Add to qada.
- That notification can't be dismissed. Android 14+ allows a swipe on an unlocked phone, so it comes
  right back. Only its buttons, or answering the prayer in the app, remove it.
- Tapping it only opens the app.
- One prayer notification at a time. The next countdown replaces one left unanswered, and so does
  the next prayer time.
- Add to qada saves at once, also while the prayer is still open. The row shows "In qada" once the
  time ends, and marking the prayer prayed removes the entry. Unanswered, nothing is saved.
- The full adhan keeps its media notification with Pause, Mark prayed and Stop. When it ends or is
  stopped it turns into the prayer notification. This changes FR-026.
- A silent prayer gets the same notification with no sound. It also comes with the app open. After
  a restart an unanswered one doesn't come back.
- Azkar stay apart and can be swiped. Evening removes morning and morning removes evening, a prayer
  notification never touches them.

### iOS

iOS can't block a dismiss, can't remove a delivered notification with the app closed, and can't
start a Live Activity at a set time without a server. So it gets the same text and buttons in one
stack, old ones go when the app opens or a top-up runs, the Live Activity starts only when I leave
the app during the reminder time, and the quiet reminder notification stays.
