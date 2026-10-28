# Quickstart: checking milestone 11

## Before

```bash
flutter pub get
dart run build_runner build
```

No new pub package. build_runner regenerates the store for schema 7. The iOS target needs the
app groups and the extension app ids in my Apple account first (`grep -rn "TODO(ahmed)" ios`),
and a signing team on `PrayerWidgets` in Xcode.

## 1. Tests (all offline)

```bash
dart format --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
```

Expected, among the rest:
- `test/drift/app_database/migration_test.dart`: v6 → v7 keeps every row, the countdown reads on.
- `test/core/surfaces/surface_data_test.dart`:
  - every 5 minutes across the 7 days, for Makkah (Umm al-Qura), Istanbul (Turkey, a daylight
    saving change inside the 7 days) and Tromsø in June (no Isha): the entry in force gives the
    same next prayer, minutes left, prayer day, strip, ticks, bar start, sunrise and maghrib, Hijri
    line and date line as Home's providers at that moment (SC-001)
  - the windows: 2 hours before; Isha starting at Maghrib with 90 minutes between them; Fajr's in
    the night with its bar from last night's Isha; Dhuhr's label "Sunrise {time}"; a prayer with
    no time has no window; 6 days only; none with the switch off or no place
  - after Isha: Fajr next, no highlighted cell, every cell past
  - the texts in English and Arabic, Eastern and Western digits, 12 and 24 hour ("5:56 PM")
  - the JSON's keys are exactly contracts/surface-data.md's (SC-006), no place gives `place: false`
    and nothing else
  - two builds in the same stretch give the same JSON, one across a prayer time doesn't
- `test/core/surfaces/backup_rules_test.dart`: Android keeps `allowBackup="false"` and every
  domain excluded in `data_extraction_rules.xml`, so `surfaces.json` never reaches a backup (SC-006).
- `test/core/surfaces/write_surfaces_test.dart`: reads the store and hands the JSON to a fake
  channel; a channel error is reported and leaves nothing half done.
- `test/features/surfaces/presentation/surfaces_boot_test.dart`: one write after launch, one 500 ms
  after a burst of changes (place, method, digits, reminder, switch), one after a prayer is marked,
  one on resume, none in the design scenario.
- `test/features/notifications/`: the countdown row on Adhan and reminders turns the setting on
  and off, in both languages and at text scale 2.0; the dev page's two rows only in dev;
  `markFromPayload` and the top-up both write the surfaces, the top-up also with notifications
  refused.
- `test/core/resources/contrast_test.dart`: every text color of the surfaces meets AA on its
  background (FR-031).
- the architecture and strings tests stay green.

## 2. iPhone, Dev, real times

```bash
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=dart_define/dev.json
```

1. Add the small, medium and large widgets and the three lock screen accessories. Each shows the
   next prayer and the same minutes left as Home. The small widget's sun sits where Home's does.
2. Mark the last prayer in the Prayer tab: the medium and large tick it within seconds, the count
   goes up.
3. Airplane mode, close the app, wait past the next prayer: every widget moves on within a minute.
4. Dev page → "Start countdown now": the Live Activity on the lock screen (5.3), the island compact,
   minimal (start a timer in Clock) and expanded (long press). The bar fills as Home's.
5. Mark the start prayer in the app: its label ends in "· prayed".
6. Keep the app open across the prayer time: the countdown ends at that second. Close the app
   before another one's time: it shows "Now" with the bar full, and goes when I open the app.
7. iOS 26: countdown on, app closed, 2 hours before a prayer: it starts by itself with no sound.
   Fajr's in the night must not light the screen (else back to the plan).
8. Adhan and reminders → turn "Countdown before each prayer" off: the running one ends, none
   starts.
9. Arabic, Western digits, 12 hour time: every surface follows within seconds; names in Reem Kufi,
   the strip from the right, the arc, bar and ring not mirrored.
10. Tap the small widget: Home. Tap Maghrib on the medium: the Prayer tab at Maghrib.
11. On the simulator the file is out of iCloud backup:
    `xattr -l "$(xcrun simctl get_app_container booted com.elhawary.bettermuslim.dev group.com.elhawary.bettermuslim.dev)/surfaces.json"`
    lists `com.apple.metadata:com_apple_backup_excludeItem`.

## 3. Android, Dev

1. Add the widget: 4 x 2 by default (5.8), in the app's fonts. Resize to 2 x 2 (the sky band) and
   4 x 1 (the times row).
2. Screen on: the countdown changes each minute; past times dimmed, the next one highlighted.
   Lock for a while past a prayer, unlock: already moved on.
3. "Start countdown now": the silent ongoing notification with the prayer, "Next prayer ·
   {city}", the seconds countdown and the bar. Android 16: the countdown chip in the status bar.
   At the prayer's second it goes.
4. Notifications refused: no countdown, the widget still works.
5. Tap a prayer cell: the Prayer tab at it. Tap the band: Home.
6. The file holds only the listed fields:
   `adb shell run-as com.elhawary.bettermuslim.dev cat files/surfaces.json`

## 4. Changes, no place, out of date

1. Switch Makkah → Istanbul, Umm al-Qura → Turkey, change the Hijri adjustment and the reminder:
   every surface follows within seconds.
2. Delete the app, install it again and add a widget before finishing onboarding: "Open Better
   Muslim to set your place", no countdown starts. Finish onboarding: the times show.
3. Set the phone's date 8 days ahead with the app closed: "Open Better Muslim to update the
   times". Open the app: the times again.
4. Reset prayer journey, then Restore from a backup: the ticks and the count follow.

## 5. Design scenario

Run the design scenario: the surfaces keep what Dev wrote last, the scenario writes nothing.
