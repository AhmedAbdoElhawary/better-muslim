# Implementation Plan: Milestone 5, Notifications and Adhan

**Branch**: `feature/milestone-5`, cut once milestones 2 to 4 are merged | **Date**: 2026-10-17 |
**Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/002-milestone-5-notifications/spec.md`

## Summary

Each prayer reaches the phone with the app closed, the adhan screen comes up when the app is open,
and on Android the full adhan plays as a media notification:
- **Schedule** (pure Dart): 6 prayer days of adhan and reminder alerts, rebuilt and replaced on
  every change, top-up in the background (R6, R7).
- **Notifications**: flutter_local_notifications for iOS and for Android Tone, Silent, reminders
  and the clip fallback (R2). A small Kotlin part plays the full adhan on Android with a media
  session (R3, R4).
- **Mark prayed**: one function on milestone 4's `markPrayed`, called from the plugin's background
  isolate, a headless engine on Android and the adhan screen. The store shares one connection
  across isolates so Home and Prayer update at once (R5).
- **Adhan screen**: 4.03 for Maghrib, each prayer's own sky for the others, Motion 06, the dua
  sheet (R9, R10).
- **Store**: schema v3 adds the five sounds, the reminder minutes and "asked once".
- **Checking it**: the design scenario shows 4.03 with fixed progress, a dev page sends a test
  notification (R13).

## Technical Context

**Language/Version**: Dart 3.13, Flutter 3.47.5 stable. Kotlin (JVM 17) and Swift for the native
parts.

**Primary Dependencies**: new: flutter_local_notifications 22.3.2, just_audio 0.10.6,
audio_session 0.2.4 (all three in the constitution's list), workmanager 0.10.10 (not in the list,
approved 2026-10-18, research R7). Native: androidx.media 1.8.0 (approved with Decision 2),
desugar_jdk_libs 2.1.5 (required by flutter_local_notifications). Already in:
flutter_riverpod, drift + drift_flutter, go_router, timezone, flutter_timezone, intl.

**Storage**: the encrypted store, schema v3 (data-model.md). Notification content is also kept by
the OS and in the app's private preferences on Android (R14).

**Testing**: unit tests for the schedule, ids, tap rule and texts. A fake plugin platform and a
fake channel for `apply`. Migration test v2 → v3. Widget tests and the 4.03 check in the design
scenario. Real delivery on phones per quickstart.md.

**Target Platform**: iOS 15+, Android 8.0+ (minSdk 26), compileSdk 35 or more

**Project Type**: mobile app

**Performance Goals**:
- Stop silences within 0.5 s (SC-004)
- a reschedule of 60 alerts in under a second, off the frame
- delivery within a minute of the prayer with exact alarms (SC-001)

**Constraints**:
- offline only
- at most 64 pending on iOS (61 used)
- the log only in the encrypted store
- never two adhans at once
- background code never resets the store
- 4.03 within 1 pt, text scale 2.0, reduce motion, RTL with the time and progress unmirrored

**Scale/Scope**: 7 new settings columns, 1 feature (3 domain files, 7 data files, 1 screen with 5
widgets, 1 sheet, 1 dev page, the boot widget), 4 Kotlin classes, AppDelegate and Info.plist
changes, about 10 strings in 2 languages, 6 audio placeholders.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Result |
| --- | --- | --- |
| I. Structure | `features/notifications/{domain,data,presentation}`, clean as the constitution says. `PrayerSound` and the columns in `core/settings` and `core/database`, since Home reads the reminder. The adhan and dev routes in `core/router/`. `bootstrap.dart` wraps the app in the feature's `NotificationsBoot`. More reaches the dev page by route. No feature imports another | pass |
| II. Design system | weight text widgets, `font: FontEnum.display` for Reem Kufi and Marcellus, adaptive paddings, `RSizedBox`, named manager sizes, `BmIcon`, `BmHaptics`, `BmMotion`. 4.03's literal colors in one allow-listed file, as the project CLAUDE.md allows for always dark surfaces. New strings in `StringsManager` and both arb files. Dev page text is `translate: false`, like milestone 2's readout | pass |
| III. Faithful | 4.03 from its spec for Maghrib, Motion 06 and the halo from MOTION.md, Mark prayed haptic. The other four skies, the dua sheet and the "Prayed" state of the button have no PNG and wait for my OK on screenshots. 5.1 and 5.2 are drawn by the phone, matched in texts and actions | pass |
| IV. Simplicity | one `AdhanPlayer` type with two implementations, one per platform (Complexity Tracking). The schedule is pure functions, `apply` replaces everything. No repository interfaces | pass |
| V. Performance | `.select()` on settings, the period provider for the prayer moment (no new timer), debounced rescheduling, const leaves, lazy audio load | pass |
| VI. Tests | unit, data with fakes, migration, widget, architecture test with the allow list entry | pass |
| VII. Privacy | the log never leaves the encrypted store, payloads carry no place, crash reports carry only a step name, background never resets the store. Notification content held by the OS is the minimum to fire (R14). Kotlin keeps the pending adhan entries (times, texts, city) in Android's private preferences, out of backups: not the `shared_preferences` package and no app data, the same thing the notification plugin already does for its own schedule | pass |
| VIII. Offline and free | no network, audio bundled | pass |
| Stack | the three listed packages arrive in the milestone that first needs them. workmanager is outside the list, approved 2026-10-18, T078 adds it to the constitution | pass |

**Post-design re-check**: unchanged after Phase 1. The workmanager gate closed with my OK on
2026-10-18.

## Project Structure

### Documentation (this feature)

```text
specs/002-milestone-5-notifications/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── notifications.md
│   └── adhan-channel.md
├── checklists/requirements.md
└── tasks.md            # /speckit-tasks
```

### Source Code (repository root)

```text
lib/
├── bootstrap.dart                              # NotificationsBoot around App, workmanager init
├── core/
│   ├── app/app_localizations.dart              # + static load(Locale) for the background
│   ├── database/app_database.dart              # v3 columns, openExisting, shareAcrossIsolates
│   ├── extensions/time_format.dart             # formatTime/formatDigits as plain functions too
│   ├── settings/settings.dart                  # PrayerSound, soundOf
│   ├── resources/
│   │   ├── strings_manager.dart                # + new keys
│   │   └── dimensions_manager.dart             # + adhan screen sizes
│   └── router/app_router.dart                  # Routes.adhan, Routes.devNotifications
└── features/
    ├── home/view/...                           # adhan line follows the reminder (FR-036)
    ├── more/view/more_page.dart                # dev only row to the dev page
    └── notifications/
        ├── domain/
        │   ├── alert.dart                      # Alert, AlertKind, ids, payload
        │   ├── schedule.dart                   # buildSchedule
        │   └── tap_target.dart                 # tapTarget
        ├── data/
        │   ├── adhan_recording.dart            # file names, TODO(ahmed)
        │   ├── dua_after_adhan.dart            # the dua text, TODO(ahmed)
        │   ├── alert_texts.dart                # titles and bodies, no context
        │   ├── notification_scheduler.dart     # init, channels, permissions, apply, cleanup
        │   ├── adhan_channel.dart              # Android method and event channels
        │   ├── adhan_player.dart               # AdhanPlayer, native, just_audio, fixed
        │   └── background.dart                 # the three entry points, markFromPayload, topUp
        └── presentation/
            ├── notifications_boot.dart         # permissions, triggers, taps, cleanup
            ├── providers/adhan_providers.dart  # player, playback state
            └── view/
                ├── adhan_page.dart
                ├── adhan_colors.dart           # 4.03 literals, allow-listed
                ├── dev_notifications_page.dart
                └── widgets/
                    ├── adhan_sky.dart  adhan_header.dart  adhan_progress.dart
                    ├── adhan_dua_card.dart  adhan_buttons.dart
                    └── dua_sheet.dart

assets/audio/                                   # adhan_makkah(.m4a), adhan_makkah_fajr (placeholders)
assets/l10n/app_en.arb, app_ar.arb              # + new strings
drift_schemas/app_database/drift_schema_v3.json

android/app/build.gradle.kts                    # desugaring, androidx.media
android/app/src/main/AndroidManifest.xml        # permissions, service, receivers
android/app/src/main/kotlin/com/elhawary/bettermuslim/
├── MainActivity.kt                             # registers the adhan channels
└── adhan/AdhanAlarms.kt  AdhanReceiver.kt  AdhanService.kt  MarkPrayedReceiver.kt
android/app/src/main/res/raw/                   # adhan clips (placeholders)
android/app/src/main/res/drawable-*/ic_notification.png

ios/Runner/AppDelegate.swift                    # plugin registrant callbacks, workmanager task
ios/Runner/Info.plist                           # UIBackgroundModes audio, fetch, BG task id
ios/Runner/Runner.entitlements                  # time sensitive notifications
ios/Runner/Sounds/                              # adhan clips (placeholders)

test/
├── features/notifications/{domain,data,presentation}/
├── core/database/  core/extensions/
└── drift/app_database/                         # v3 schema, migration v2 → v3
```

**Structure Decision**: one Flutter app. The notifications feature is new and clean. Two core
files change shape slightly (`app_localizations.dart`, `time_format.dart`) so texts can be built
without a context. Native code goes only where Dart can't run (R3).

## Key Flows

1. **Start**: `bootstrap.dart` registers the top-up. `NotificationsBoot` initializes the plugin
   (categories in the app's language), asks for permission once after the location settles (R4),
   applies the schedule unless in the design scenario, and handles the launch payload (R9).
2. **Reschedule**: a provider of the schedule inputs changes, or the app resumes → debounce 500 ms
   → `dayTimesProvider` for 6 prayer days → `buildSchedule` → `alertTexts` → `scheduler.apply`.
3. **Prayer time, app in front**: `periodProvider` changes to an Adhan prayer → push
   `Routes.adhan` → `player.play` (iOS just_audio, Android the service, already started by its
   alarm).
4. **Prayer time, app closed**: iOS shows the notification with its clip. Android with exact
   alarms: `AdhanReceiver` → `AdhanService` (or the quiet plain notification). Otherwise the
   plugin's notification.
5. **Mark prayed**: the screen → `markPrayed`. A notification action → the plugin's background
   isolate or `MarkPrayedReceiver` → `markFromPayload` → `markPrayed`. The shared store connection
   updates Home and Prayer. The log change → cleanup removes the delivered notification.
6. **Tap**: payload → `tapTarget` → `Routes.adhan(from:)` or `Routes.prayerAt`.
7. **Background top-up**: workmanager `better_muslim.topup` → `openExisting` → the same steps as 2.

## Decisions (2026-10-18)

The clarify answers are in the spec. All seven plan decisions took the recommendation:
1. **workmanager** for the background top-up (R7). Without it nothing tops up while the app stays
   closed.
2. **Native Kotlin for the Android full adhan** (R3), with `androidx.media` 1.8.0, instead of
   android_alarm_manager_plus and audio_service.
3. **iOS in-app adhan plays with the silent switch on** (`playback`, R8, FR-022a). It keeps playing
   with the screen locked, and Stop is one tap.
4. **Dev buttons on a dev page reached from More** (R13, FR-041), since milestone 3 removes the
   readout.
5. **After Mark prayed on the adhan screen** the button shows "Prayed" with the check (FR-031).
6. **The dua in Arabic** shows only the Arabic and its source (FR-032).
7. **Android tops up in the background at least every 12 hours** (FR-009), instead of each time an
   adhan fires.

## Complexity Tracking

| Addition | Why Needed | Simpler Alternative Rejected Because |
| --- | --- | --- |
| Kotlin alarms, receiver, service and headless mark (R3, R5) | code must run at prayer time with the app killed, and 5.2's progress needs a media session | the clip only breaks FR-020 and 5.2. Two packages outside the list and fragile background start |
| `AdhanPlayer` with two implementations | iOS plays in the app, Android plays in the service, the screen and tests need one type | one class with platform branches mixes two engines and can't be faked |
| `openExisting` next to `open` | a background engine must never reset the store | one `open` with a flag hides a data loss risk behind a boolean |
| workmanager (pending OK) | FR-009 top-up with the app closed | native BGTaskScheduler and WorkManager code doing the same by hand |
