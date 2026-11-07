# Feature Specification: Shipping

**Feature Branch**: `feature/shipping`, cut from `develop` after `feature/enhancment-5` is merged

**Created**: 2026-11-07

**Status**: Clarified (grilled, Q1 to Q32, all recommendations)

## What I want

- The pipeline I copied from the kit actually ships: tester builds, tags, Store releases, Patches.
- Crashes I can read, and usage numbers only from people who said yes.
- Nothing personal leaves the phone.

## Decisions

### Repo and branches

- The repo stays private and moves to GitHub Pro, so the rulesets make a red merge impossible.
- `develop`, `staging`, `production`, the `release:` marker and the tag shapes stay as they are.
  `main` is deleted.
- The version line starts at `1.0.0`, the first tag is `v1.0.0-dev.1`.
- `CHANGELOG.md` is English. The Arabic "what's new" is written by hand at store upload.
- `verify` in `deploy.yml` runs only for break-glass tags, a normal merge already passed `ci-ok`.
- `overallMin` in the coverage gate goes to 85, logic stays ungated.

### Flavors

- Dev and staging get a corner badge on the icon, on both platforms. The production icon doesn't
  change.
- `API_BASE_URL` goes, there is no backend.

### Privacy

- Never sent, by anything: location, city, the prayer log, qada, notes, bookmarks, highlights,
  tasbih counts, what someone reads. Only screens, feature names and technical errors leave the
  phone. `docs/adr/0002` has the why, the constitution goes to 5.3.0.
- Analytics is off until the person says yes. The ask is a one-time sheet on the first Home after
  onboarding, with two equal buttons.
- Crash reports are on by default.
- Both have a switch in YOUR DATA in More.

### Sentry

- One project in my EU org, split by environment. IP storage is off in the project.
- Pages get fixed names like `quran_reader`, never a page number or a dua id.
- Production traces are 10%.
- Background tasks report errors only, no sessions or traces, and follow the switch.

### Firebase

- One project, `better-muslim`, on `elhawarydev@gmail.com`, an app per flavor and platform.
- One tester group, `testers`.
- Analytics runs in release builds of every flavor, reports filter to production.
- Analytics sends only these, by hand, with no automatic tracking:
  - `tab_opened`: home, prayer, quran, azkar, more
  - `feature_opened`: qibla, tasbih, duas, hijri_calendar, quran_reader, recitation, share_card,
    theme
  - `onboarding_step`: welcome, location, notifications, theme, done
  - `permission_answered`: location, notifications, exact_alarm, with yes or no
  - the app language as a user property
- No advertising id, Google signals, ad personalization or granular location, and the shortest
  retention. Google still works out the country from the IP for people who said yes, the privacy
  policy says so.

### Shorebird

- Production only, on the free plan. One rehearsal Patch before the public launch.
- `patch.yml` uploads its symbols to Sentry.
- Look at the plan again before 5,000 active users, one Patch could use the whole allowance.

### Stores

- Android goes live first, the iOS lane follows in this milestone.
- Play upload stays by hand. `SCHEDULE_EXACT_ALARM` stays for the first submission.
- iOS goes to TestFlight, built in CI only on production tags, signed with an App Store Connect API
  key and no fastlane. Dev and staging run from Xcode. App Store submission is by hand.
- iOS ships without `--obfuscate` until Shorebird's iOS symbol issues are closed.
- The privacy policy lives on GitHub Pages in `better-muslim-content`, in English and Arabic.
- `.github/LAUNCH.md` holds the exact Play and App Store answers.

## Left for me

- Is my Apple Developer membership active? Ticket 12 waits for it.
- Is my Play account personal and newer than 13 Nov 2023? Then a closed test with 12 testers for 14
  days comes before production.
