# Quickstart: checking milestone 5

Milestones 3 and 4 are merged first. Real delivery needs real phones: an iPhone (iOS 15+) and an
Android 13+ phone, plus an Android 12 or older one for the permission paths if at hand.

## Before

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart run drift_dev make-migrations      # schema v3 and its migration test
```

## 1. Tests (all offline)

```bash
dart format --set-exit-if-changed lib test tool
flutter analyze
flutter test
```

Expected, among the rest:
- `test/features/notifications/domain/`: `buildSchedule` gives 60 alerts for 6 normal days, fewer
  after a polar gap, none in the past, Isha after midnight on the day it started, reminders off
  give only adhans. Ids round trip through `alertFromId`. `tapTarget` at 0 s, the recording's
  length minus 1 s, and plus 1 s, for Adhan, Tone, Silent and a reminder.
- `test/features/notifications/data/`: with a fake plugin and a fake channel, `apply` cancels all
  first, sends Adhan prayers to the channel only when exact alarms are allowed, uses the clip
  channel otherwise, sets the iOS presentation flags of research R2, and builds the texts in
  English and Arabic with Eastern digits and a 12 hour phone.
- `test/drift/app_database/migration_test.dart`: v2 → v3 keeps every value, reads the defaults.
- `test/features/notifications/presentation/`: the adhan screen in the design scenario, Mark
  prayed logs once and keeps playing, Stop pops, Read dua opens the sheet, reduce motion fades.
- `test/architecture_test.dart`: green, with `adhan_colors.dart` on the allow list.

## 2. The adhan screen against 4.03

```bash
flutter run --flavor dev -t lib/main_dev.dart \
  --dart-define-from-file=dart_define/dev.json --dart-define=SCENARIO=design
```

More → Notifications (dev) → "Open adhan screen". Expected: Maghrib 17:56, "ADHAN · MAKKAH",
0:42 of 2:56, side by side with `design_handoff_better_muslim/reference/screens/4.03-adhan.png`
within 1 pt. Repeat in Arabic, light mode (it stays dark), text scale 2.0, reduce motion.
Nothing is scheduled: Settings → Notifications on the phone shows no pending items for the app.

## 3. Delivery with the app closed (real dev build, no scenario)

1. Fresh install. After the location dialog the notification dialog shows. Android 12+: then the
   "Alarms & reminders" page. Allow both.
2. More → Notifications (dev) → "Test notification in 1 min". Kill the app, turn on airplane mode.
3. Expected in a minute:
   - iPhone: the next prayer's notification, its clip if it's an Adhan prayer (Fajr and Maghrib by
     default), time sensitive.
   - Android: an Adhan prayer plays the full adhan with the media notification (header, title,
     "Adhan of Makkah", progress, Pause, Mark prayed, Stop). A Tone prayer gives the default
     sound.
4. Mark prayed from the notification, open the app: Home and Prayer show it prayed, the
   notification is gone.
5. Android: set the phone to vibrate, repeat: the notification shows, no adhan.
6. Android: refuse "Alarms & reminders" in the phone's settings, repeat: the notification comes
   (maybe late) with the clip, no media notification.
7. Restart the Android phone before the test fires: it still fires.

## 4. Taps

- Tap an Adhan notification within the recording's length: the adhan screen opens and the adhan
  goes on from that point.
- Tap one later, or a Tone one: the Prayer tab on that prayer and day.
- Mark a prayer in the Prayer tab while its notification is in the list: it disappears.

## 5. The schedule follows

- Pick another city in the location sheet (milestone 3): the pending list shows the new times and
  name (iOS: a debug log of `pendingNotificationRequests()` from the dev page).
- Change the phone's language: the pending texts follow after the app comes back to the front.
- Leave the app closed for a day with background refresh on: the pending list still covers 6 days.

## 6. Before calling it done

Screenshots of the adhan screen for all five prayers, dark and light, English and Arabic, phone and
tablet, plus the media notification and the iOS lock screen, for my review.
