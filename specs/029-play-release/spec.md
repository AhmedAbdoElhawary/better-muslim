# Feature Specification: Play release

**Feature Branch**: `feature/release-prep`, cut from `feature/enhance1`

**Created**: 2026-11-15

**Status**: Built, waiting for my review (grilled once, Q1 to Q13, all recommendations but Q6 and Q8)

**Input**:

```text
i want to publish the app to store (for now will be google store), so i want from you to deep dive
and tell me if there is anything left we suppost to do before or any security issue
```

## What the check found fine

- Target SDK 36, Play's rule for new apps since 31 Aug 2026. Min SDK 26.
- Every 64-bit native library in the bundle is 16 KB or 64 KB aligned and stripped.
- No secret in git, all 19 CI secrets set.
- The store is encrypted, its key is 32 bytes from `Random.secure` and lives only in the Keystore,
  with no backup.
- Downloads are https only, GitHub content is checked by sha256.
- No advertising id, no full-screen intent, no background location. `SCHEDULE_EXACT_ALARM` needs no
  declaration, Play only restricts `USE_EXACT_ALARM`.

## Decisions

- My Play account is personal and newer than 13 Nov 2023, so a closed test with 12 testers for 14
  days comes before production.
- 1.0.0 ships without Firebase Analytics. Tickets 06 and 07 of specs/012 and the ask sheet of 08
  come after launch.
- A crash reports switch in YOUR DATA, on by default. Sentry waits for it: errors before the store
  is read are held, then sent or dropped. Off, Sentry never starts, in the app or in the background.
  A background task starts Sentry only for an error, and only with the switch on.
- Feedback still goes with the switch off, someone tapped Send.
- The privacy policy is rewritten to match the app, then lives on GitHub Pages in
  `better-muslim-content` once I approve it. A Privacy policy row in About opens it.
- The listing stops saying nothing is sent, the Play text names the Android widgets and the
  countdown notification instead of the Live Activity, and gets an Arabic version.
- I design the screenshots myself (Q6).
- Phones stay in portrait. Android 16 still turns tablets and foldables.
- No open source licenses page (Q8), credits stay as specs/027 left them.
- Google creates the app signing key, my keystore stays the upload key.
- `.github/LAUNCH.md` has every Play Console answer, target audience 13 and over.
- Production and staging fall back to their own flavor when the define file is missing.
- Geolocator's location service stays in the manifest: its position stream doesn't start without
  that service bound. Play may ask about it, `LAUNCH.md` has the answer.
- `CHANGELOG.md` gets the 1.0.0 entry, written for people who aren't developers.
- Staged rollout: 20%, then 100% after a few days with no new crash. The Shorebird rehearsal patch
  goes out during the closed test.

## Done

- [x] `crashReports` in settings, schema 32
- [x] `Monitoring.follow`, the held errors, background tasks and feedback with the switch off
- [x] Crash reports row in YOUR DATA, Privacy policy row in About, both strings in English and Arabic
- [x] Portrait lock
- [x] Flavor fallbacks, `android/.kotlin/` ignored
- [x] Privacy policy draft, listing, `LAUNCH.md`, `CHANGELOG.md`, `RELEASE_TODO.md`, specs/012
      tickets

## Left for me

- Approve the privacy policy, then it goes live.
- The screenshots and the feature graphic, the two foreground service videos.
- Everything in `.github/LAUNCH.md`.
