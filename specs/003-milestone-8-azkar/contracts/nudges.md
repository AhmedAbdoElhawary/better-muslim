# Contract: azkar nudges and the azkar values the rest of the app reads

Adds to milestone 5's `specs/002-milestone-5-notifications/contracts/notifications.md`.

## The nudge alert (notifications feature)

| | Value |
| --- | --- |
| kind | `AlertKind.azkar` |
| prayer | `Prayer.fajr` for the morning set, `Prayer.asr` for the evening set |
| day | the window's prayer day |
| at | the prayer's time + 20 minutes (`nudgeDelay`) |
| sound | `PrayerSound.silent`, never a sound or a vibration |
| id | `2000000 + days since 2020-01-01 * 2 + (0 morning, 1 evening)`. Outside `alertFromId`, so the delivered cleanup ignores it |
| payload | the milestone 5 format, kind `azkar`: `2026-10-15|asr|azkar|silent|<millis>` |
| how many | the next 3 after now (`nudgeCount`), whose window isn't done, only with `azkarNudges` on |
| iOS | `InterruptionLevel.passive`, no sound, banner and list |
| Android | channel `azkar`, name "Azkar", default importance, no sound, no vibration |
| title | "Morning azkar" / "Evening azkar" |
| body | `notifAzkarMorningBody` / `notifAzkarBody` with `count` (items in the set) and `minutes` |
| tap | `AzkarTarget(set)` → `Routes.azkarSet(set)` |

The iOS pending count stays at 63 (60 prayer alerts + 3), 64 with the dev test notification.

## Rescheduling

The boot's schedule inputs gain `settings.azkarNudges` and `azkarProgressProvider(set).done ==
total` for both sets. A change reschedules after the usual 500 ms. The background top-up reads the
same from the store and `loadAzkarContent()`.

## Azkar values (core)

| Read | Gives |
| --- | --- |
| `currentAzkarSetProvider` | `AzkarSet.morning` from Fajr until Asr, `evening` until the next Fajr |
| `azkarProgressProvider(set)` | `(done, total)` of the set's latest window |
| `azkarBadgeProvider` | true while the current set's window hasn't been opened |
| `AppDatabase.azkarCounts(set, day)` | the counts of one window, no Riverpod, for the background |

## Navigate

| Route | Opens |
| --- | --- |
| `Routes.azkarSet(AzkarSet set)` → `/azkar/morning`, `/azkar/evening` | the set at the first card not done, in the Azkar tab |
| `Routes.tasbih` → `/azkar/tasbih` | Tasbih, in the Azkar tab |
| `Routes.duas` → `/duas` | Duas, outside the shell (no tab bar) |
| `Routes.duaCategory(String id)` → `/duas/<id>` | a category's page, outside the shell |
