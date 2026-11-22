# Quickstart: checking milestone 10

## Before

```bash
flutter pub get
cd ios && pod install && cd ..
dart run build_runner build
```

file_picker is new (approved in the spec). build_runner regenerates the store for schema 6.

## 1. Tests (all offline)

```bash
dart format --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
```

Expected, among the rest:
- `test/drift/app_database/migration_test.dart`: v5 → v6 keeps every row, a row with a place
  reads onboarded, one without reads not.
- `test/core/backup/`: a round trip gives back every table and value, this phone's own columns
  stay; wrong password, a foreign file, a cut file and a newer schema each change nothing and
  give their own error; an older schema restores; the file has no plaintext (SC-006); every table
  of the store is in the copy.
- `test/core/settings/onboarding_test.dart` and the router test: not done goes to `/onboarding`,
  `/adhan` passes, done leaves `/onboarding`, replay shows it again.
- `test/features/onboarding/model/sun_choreography_test.dart`: the size by height, the lift, the
  build values at known points.
- `test/features/onboarding/view/`, `test/features/notifications/presentation/`,
  `test/features/theme_picker/`, `test/features/more/`: the first screen (below and above the
  horizon, flick, tap, screen reader tap, reduce motion), 4.10's end state, the reset notice,
  4.11 granted, refused and by city, 4.12 defaults, Allow and Not now, the theme step, More's
  backup rows and sheets. English and Arabic, dark and light, text scale 2.0, 44 x 44.
- `test/architecture_test.dart`, `strings_manager_test.dart`, `font_manager_test.dart` green.

```bash
flutter test integration_test/onboarding_journey_test.dart -d <simulator>
```

Replays onboarding on the design scenario and walks it to Home with no system dialog.

## 2. In the app

Run "Dev · design scenario", phone in dark:

1. The app opens on Home (the scenario counts as finished). More → Notifications (dev) → Replay
   onboarding.
2. The first screen: the base sky, "Every prayer, in its time.", the glass dome at the bottom,
   "Swipe up to begin". Pull the sun halfway, let go: it sinks back.
3. Pull it past the middle: it gets small, bends the headline, the gold arc lights, "Let go to
   begin" with a tick. Let go: 4.10 builds (horizon, mark, the stars out of the sun, the title
   out of it, tagline, buttons) and ends as 4.10.
4. Pull the sun down to the bottom and let go: back to the first screen, the stars fade. Begin
   again. On Android press back on 4.10: the sun sinks the same way. Begin again.
5. Get started: 4.11 builds with the first dot wide. Choose a city instead → Makkah: 4.12 builds
   with 04:58, 12:05, 15:27, 17:56, 19:26. Back: 4.11. Forward again.
6. Set Dhuhr to Silent, the reminder to 15. Not now: the theme step builds, no back chevron.
   Pick Iznik, Apply: Home in Iznik. Set Qiyam Emerald back from More.
7. More → YOUR DATA shows Back up and Restore from backup above Reset prayer journey.
8. Phone in Arabic: replay, every step right to left, the sun's gesture the same.
9. Reduce motion on (More): replay, tap "Swipe up to begin": 4.10 crossfades, no flight.

Then the plain Dev run, on a real phone (delete the app first):

10. First launch: no system dialog before 4.11's Use my location. Allow "while using": 4.12 with
    this place's times. Allow notifications: the dialog (and the alarms page on Android 12+).
    Apply: Home. The dev page's "Test notification in 1 min" arrives.
11. Delete and reinstall, refuse location on 4.11: the city search opens with the line. Close it:
    still on 4.11.
12. Log a few prayers, add qada, save a dua, apply Iznik. More → Back up → "test1234" twice →
    Save backup → save to Files (iOS) or Drive (Android).
13. Delete and reinstall. Raise the sun, Restore from backup, pick the file. "wrong": its line.
    "test1234": the steps follow with Iznik and the sounds picked, Home shows the log and qada,
    Duas the saved one.
14. Restore from More: the dialog first, Restore, the toast. Pick a photo instead: "This file
    isn't a Better Muslim backup."
15. On an older Android phone without the shader filter: the frosted glass, same motion.
16. SC-002 on a 2021 mid range Android (Galaxy A52 class): `flutter run --profile --flavor dev
    -t lib/main_dev.dart --dart-define-from-file=dart_define/dev.json`, the performance overlay
    on, replay onboarding, drag the sun up and down, let the welcome build: no frame over 16 ms.
