# Quickstart: checking milestone 4

## Before

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart run drift_dev make-migrations      # writes schema v2, the step by step file and its test
```

## 1. Tests (all offline)

```bash
dart format --set-exit-if-changed lib test tool integration_test
flutter analyze
flutter test
```

Expected, among the rest:
- `test/core/prayer_times/`: `endOf` for every prayer, polar gaps, Ramadan Isha. The prayer day at
  Fajr minus 1 minute is yesterday, at Fajr it is today.
- `test/features/prayer/domain/`: every row state one minute either side of sunrise, each prayer,
  midnight and Fajr, on a normal day, a Ramadan day, a daylight saving day and after a time zone
  change (SC-004). Week start, the page count from first use, the month count.
- `test/features/prayer/data/`: "made one up" takes dateless first, then the oldest date. Undo
  brings the same id back. A prayer day can't go in qada twice. A batch of N from + and its Undo.
- `test/core/database/`: `markPrayed` twice leaves one row. A logged prayer stays on its date after
  the phone's zone changes.
- `test/drift/app_database/migration_test.dart`: v1 → v2 keeps every settings column and fills
  `first_use`.
- `test/core/app/app_localizations_test.dart`: Arabic counts 0 to 12 give the right forms.
- Widget tests for the Prayer tab: Mark, unmark and Undo, the passed sheet, Day complete only on
  the fifth mark, the week swipe stopping at first use and at this week, the qada list, the
  method sheet, the + sheet's 1 to 999 limits.
- `test/architecture_test.dart` passes.

Journey test, on a simulator or a phone (R16):

```bash
flutter test integration_test/prayer_journey_test.dart --flavor dev -d <device id>
```

## 2. Design scenario (the PNG check, SC-001)

Run **Dev · design scenario**. On the Prayer tab:
- "Prayer times", "Makkah · Umm al-Qura", Sun 11 to Sat 17 with Thursday highlighted.
- Dots: Sun, Mon, Wed 5; Tue 4; Thu 2; Fri and Sat none.
- "2 of 5 prayed today", "3 missed this month to make up".
- Fajr and Dhuhr "Prayed", Sunrise time only, Asr filled with NOW and Mark, Maghrib "in 1:24",
  Isha with the adhan icon.

Put it next to `4.04-prayer.png` (dark) and `4.17-prayer-arabic.png` (Arabic, light), within 1 pt.

Then:
1. Tap Mark on Asr: chip to "Prayed" (Motion 07), "3 of 5", ring at 3/5, Thursday 3 dots.
2. Tap "Prayed": back to 2, the toast with Undo above the tab bar. Undo: back to 3.
3. Tap Tuesday: Tuesday fills and Thursday doesn't, four "Prayed", Isha "In qada". Swipe the
   strip back: the week of 4 Oct, then the week of 27 Sep, then it stops (first use Thu 1 Oct).
   Swiping forward stops at this week.
4. Tap the summary card: the qada list with Fajr 2 and Isha 1. "Made one up" on Isha: the toast,
   "2 missed this month", Tuesday's Isha shows "Made up" and tapping it does nothing. Undo. Tap +
   on Fajr, set 2, Add: Fajr 4 left, the month count stays, Undo removes both.
5. Text scale 2.0, reduce motion on, both languages: rows stack, nothing is cut, Motion 07 turns
   into its 150 ms crossfade.

## 3. Real phone (plain Dev)

1. After Dhuhr, leave Dhuhr unlogged: it shows "Add to qada". Tap it: the sheet "Dhuhr has
   passed". "I prayed it" logs it, with no toast.
2. Mark all five on a day: Day complete plays once with its haptic. Unmark the fifth and mark it
   again: it plays again.
3. Sliders icon: "By country · <your country's method>" is selected. Pick Muslim World League, the
   subtitle and times change. Pick "By country", they go back.
4. After midnight, before Fajr: the tab still shows yesterday with Isha as NOW.
5. Tap the pin: the same location sheet as Home's pill. Pick a city: the subtitle and times change.
6. Airplane mode the whole time. Kill and reopen: everything is kept.

## 4. Upgrade from milestone 2

Install the milestone 2 build on the dev phone, change a few settings, then run this build over
it. The settings are kept, the strip reaches back to the upgrade week.
