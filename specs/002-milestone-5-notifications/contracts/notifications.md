# Contract: notifications for the rest of the app

What milestones 3 (Home), 8 (azkar nudges), 9 (More, the "Adhan and reminders" page), 10
(onboarding 4.12) and 11 (widgets) use. Adds to the milestone 2 contract
(`specs/001-milestone-2-data/contracts/core-data.md`) and the milestone 4 one
(`specs/002-milestone-4-prayer/contracts/prayer-log.md`).

## Settings (core)

| Read | Gives |
| --- | --- |
| `settingsProvider.select((s) => s.value?.soundOf(prayer))` | the prayer's `PrayerSound` |
| `settingsProvider.select((s) => s.value?.reminderMinutes)` | 0 (off), 5, 10, 15, 20 or 30 |

| Write | Effect |
| --- | --- |
| `AppDatabase.updateSettings(SettingsCompanion(fajrSound: Value(PrayerSound.silent)))` | the schedule follows within a second (research R6). Milestones 9 and 10 write here, nothing else to call |
| `AppDatabase.updateSettings(SettingsCompanion(reminderMinutes: Value(15)))` | same |

## Navigate

| Route | Opens |
| --- | --- |
| `Routes.adhan(Prayer prayer, DateTime day, {Duration from = Duration.zero})` → `/adhan?prayer=maghrib&day=2026-10-15&from=42` (`from` in whole seconds) | the adhan screen over everything, on the root navigator |
| `Routes.devNotifications` → `/dev/notifications` | dev builds only, the two test buttons |

## The store from a background engine (core)

| Call | Effect |
| --- | --- |
| `AppDatabase.openExisting()` | the store if it opens, null otherwise. Never resets. For every background entry point |
| `AppDatabase.open()` | unchanged, the app in front only. Its connection now shares across isolates, so a background write shows up in the app's streams at once |

## Background entry points (feature, `@pragma('vm:entry-point')`)

| Function | Called by |
| --- | --- |
| `onNotificationActionInBackground(NotificationResponse)` | the plugin, for Mark prayed on iOS and Android |
| `markPrayedInBackground(List<String> args)` | Kotlin `MarkPrayedReceiver`, args = `[payload]` |
| `callbackDispatcher()` | workmanager, task `better_muslim.topup` |

Milestone 8's azkar nudges move the scheduler to `core/` and add their own slot range and
category. Ids from this milestone keep their meaning.

## Guarantees

- The schedule never has more than 61 pending items (60 plus the dev test).
- A payload has no place, no name and no coordinates.
- Logging from a notification goes through milestone 4's `markPrayed` only.
- Nothing is scheduled in the design scenario.
