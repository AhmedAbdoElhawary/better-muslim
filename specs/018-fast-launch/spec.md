# Feature Specification: Fast launch

**Feature Branch**: `feature/quran-reading`

**Created**: 2026-11-09

**Status**: Clarified (grilled, Q1 to Q7, all recommendations)

## What I want

The cold open feels like a native app: the splash goes straight to a whole Home, nothing pops in
after it, and the first second doesn't stutter.

## Decisions

- Only the cold open to Home. Resume is already one frame. Onboarding gets the same gains but isn't
  tuned on its own.
- Flutter can't be exactly native, starting the engine and Dart costs about 150 to 300 ms a native
  app doesn't pay. Everything after it is ours.
- Judged in profile only, never on a debug run. `flutter run --profile --trace-startup`, 5 cold
  opens on the CPH2773 and the iPhone, the middle number. No fixed target, before and after go in
  `numbers.md`.
- Before the first frame, everything that doesn't wait on something else starts at once: the store,
  the phone's zone, both strings files and the adhan folder, while the time zones decode.
- After the first frame: audio_service, Workmanager and the removed adhans' cleanup. A play in the
  first second waits for audio_service.
- Held until Home is drawn and has had a second (3 s at most when the phone is asleep): the
  notification reschedule, the widget data and the gps check. A notification tap still opens its
  target at once.
- The verse of the day is read before the first frame, 300 ms at most, so its card is whole from
  the start.
- The svg icons stay as they are. flutter_svg always shows an icon one frame after it's built and
  already parses off the UI thread, warming its cache would need each icon's color in every theme.
- The store key goes in as a raw key with a one time rekey only if the store open takes over 30 ms
  on the CPH2773. The profile run prints it: `cold open: store N ms, run N ms`.

## On my phones

- [ ] Before numbers (from the commit before this work) and after numbers in `numbers.md`.
- [ ] The store's ms from the profile log, ticket 03 goes on or closes by it.
- [ ] A launch with the phone asleep: no `Fatal signal` in `logcat -b crash`, the notifications
      still get scheduled.
- [ ] Opening from a prayer notification still lands on its page.
- [ ] Play a recitation right after a cold open, it starts and shows on the lock screen.
