# Quickstart: checking milestone 9

## Before

```bash
flutter pub get
dart run build_runner build
```

No new package. build_runner regenerates the store for schema 5.

## 1. Tests (all offline)

```bash
dart format --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
```

Expected, among the rest:
- `test/drift/app_database/migration_test.dart`: v4 → v5 keeps every row, adds Makkah for the five
  recordings, takes 25 minutes.
- `test/core/settings/appearance_test.dart`: dark, light, Follow sky one minute before and after
  sunrise and Maghrib, on a daylight saving day, after a location change, with no location.
- `test/core/resources/design/bm_theme_test.dart`: the palette lerp at 0, 0.5 and 1.
- `test/features/hijri_calendar/model/`: every month 1440 to 1460 AH with adjustments −2 to +2
  starts and ends where the table says (SC-003), 1 Jumada I 1448 = 12 Oct 2026, the header across
  two years, the first and last month the table converts. The looks' order, no white day on 13
  Dhu al-Hijjah, COMING UP for 15 Oct 2026 is Ayyam al-Bid, Jumada II begins (with the sighting
  line), Rajab begins.
- `test/features/notifications/`: the channel ids per recording, a recording change deletes the
  old channel, the alarm entry plays the prayer's recording, 25 minutes schedules reminders.
- `test/features/more/`, `theme_picker/`, `hijri_calendar/view/`: the pages in English and
  Arabic, dark and light, text scale 2.0, every action at least 44 x 44.
- `test/architecture_test.dart`, `strings_manager_test.dart`, `font_manager_test.dart` green.

## 2. In the app

Run "Dev · design scenario" (VS Code or Android Studio), phone in dark:

1. More looks like 4.09: Umm al-Qura, "10 min before", "Makkah · auto", Qiyam Emerald, Follow sky,
   Reduce motion off, Haptics on, UI sounds off. Below: YOUR DATA, ABOUT, and the dev row.
2. Qibla and Duas tiles open their screens. Hijri calendar looks like 4.13.
3. Calendar: forward 4 times → Ramadan 1448 with 1 Ramadan marked. The calendar icon → Jumada I.
   Tap 13 → the day sheet with 24 Oct, six times, Ayyam al-Bid.
4. Date adjustment → +1 → Save: the row says "+1 day", today is 5, Home's Hijri date moves.
   Set it back to 0.
5. Theme → tap Dark: 4.15. Tap Iznik: only the preview changes. Back: still Qiyam Emerald. Again,
   Iznik, Apply: a 300 ms crossfade, back on More, the row says Iznik.
6. Light and dark → Light: the app turns light at once. Back to Follow sky.
7. Reduce motion on: Home's sky stops drifting. Haptics off: Mark on the Prayer tab doesn't
   vibrate.
8. Reset prayer journey → Cancel: nothing changes. → Reset: Prayer and Home show nothing logged.
   The scenario's store is in memory, a restart brings the week back.
9. Credits: GeoNames with CC BY 4.0, the link opens the browser. Open source licenses lists the
   packages. Version shows "1.0.0 (n)".
10. Switch the phone to Arabic: the same screens right to left, the calendar's Sunday on the
    right, Eastern digits. The digits toggle shows in APPEARANCE, off turns every number Western.

Then the plain Dev run, on a real phone:

11. Adhan and reminders: Dhuhr → Silent, Fajr's recording → Madinah (it plays, Save stops it),
    reminder → 15. More says "15 min before". The dev page's "Test notification in 1 min" plays
    the chosen recording.
12. Turn notifications off for the app in the phone's settings: the page shows the line with
    "Open settings", which opens that settings page.
13. UI sounds on: the tasbih counts with a sound, nothing with the silent switch on (iPhone) or
    the ringer on vibrate (Android).
14. Follow sky with the clock set a minute before Maghrib (Settings › Date & time): the app goes
    dark while open.
