# Research: Milestone 5, Notifications and Adhan

Checked on 2026-10-17 against the code of milestones 1 and 2, the specs and plans of milestones 3
and 4, and the package sources from pub.dev: flutter_local_notifications 22.3.2, workmanager
0.10.10 (workmanager_apple 0.9.11, workmanager_android 0.10.9), just_audio 0.10.6, audio_session
0.2.4, drift_flutter 0.3.1.

## R1. Where the code goes

- **Decision**:
  - `features/notifications/` in the clean shape (constitution I names "notifications + adhan"
    as clean). `domain/` holds the schedule as pure functions, `data/` the notification plugin,
    the Android channel, the players and the background entry points, `presentation/` the adhan
    screen, the dua sheet, the dev page and the boot wiring.
  - `core/settings/` gets `PrayerSound` and the new settings columns, since Home (milestone 3)
    reads the reminder minutes and core can't import a feature.
  - `bootstrap.dart` starts the feature's wiring (`NotificationsBoot.start`) with the app's
    `ProviderContainer`. `core/router/` adds the adhan route and the dev page route, it is the
    one core file allowed to import features.
  - Android native code in `android/app/src/main/kotlin/com/elhawary/bettermuslim/adhan/`.
- **Rationale**: no feature imports another. More (milestone 9 placeholder for now) reaches the
  dev page through a route, never through an import.
- **Alternatives**: the scheduler in core (only one feature uses it until the azkar nudges of
  milestone 8, it moves to core then), a separate `adhan` feature next to `notifications` (they
  share the schedule, the payload and the player, two features would need each other).

## R2. The notification engine

- **Decision**: flutter_local_notifications 22.3.2 for every notification on iOS, and on Android
  for Tone, Silent, reminders and the clip fallback (R4). `zonedSchedule({id, scheduledDate,
  notificationDetails, androidScheduleMode, title, body, payload})`, all named in 22.x.
  - **iOS** (`DarwinNotificationDetails`):

    | Kind | `sound` | `presentSound` | `interruptionLevel` | `presentBanner` / `presentList` | category |
    | --- | --- | --- | --- | --- | --- |
    | Adhan | the prayer's clip file | false | `timeSensitive` | false / true | `adhan` |
    | Tone | null | true | `timeSensitive` | true / true | `adhan` |
    | Silent | null | false | `timeSensitive` | true / true | `adhan` |
    | Reminder | null | false | `passive` | true / true | none |

    The plugin sets `content.sound` from `sound` whatever `presentSound` says, and reads
    `presentSound` only for the foreground. So an Adhan notification plays its clip with the app
    closed and stays quiet with the app open, where the full adhan plays instead (FR-021).
  - **Android**: one channel per prayer and sound, id `adhan_<prayer>_<sound>`, named after the
    prayer, in a group "Adhan", importance high. Adhan channels carry the clip as their sound,
    Tone the default sound, Silent no sound and no vibration. When a prayer's sound changes the
    other two channels of that prayer are deleted, so the phone's settings show one entry per
    prayer (FR-017). Reminders get one channel `reminders`, importance default.
  - The category `adhan` (iOS) and the action `mark_prayed` (both) carry "Mark prayed". iOS
    categories are registered in `initialize`, so `initialize` runs again after a language change.
  - Setup: core library desugaring with `desugar_jdk_libs` 2.1.5 (the plugin asks for 2.1.4 or
    later), `compileSdk` 35 or more, the plugin's three receivers in the manifest, `RECEIVE_BOOT_COMPLETED`, `POST_NOTIFICATIONS`,
    `SCHEDULE_EXACT_ALARM`. iOS: `setPluginRegistrantCallback` in
    `didInitializeImplicitFlutterEngine` (the app uses UIScene) and the time sensitive
    entitlement.
- **Rationale**: it's in the constitution's list and does the schedule, the channels, the actions
  with a background isolate, the launch details and the reboot rescheduling on both platforms.
- **Alternatives**: native notifications on both platforms (much more native code for what the
  plugin already does).

## R3. The full adhan on Android with the app closed

- **Decision**: a small native part in Kotlin, no package:
  - `AdhanAlarms`: keeps the adhan entries (JSON in the app's private preferences) and sets one
    `setExactAndAllowWhileIdle` alarm per entry. Restores future entries after
    `BOOT_COMPLETED` and `MY_PACKAGE_REPLACED`.
  - `AdhanReceiver`: when an alarm fires it checks silent, vibrate and Do Not Disturb (R4). Ringer
    on: it starts `AdhanService`. Otherwise it posts the plain adhan notification quietly.
  - `AdhanService`: a foreground service of type `mediaPlayback`. `MediaPlayer` on the Flutter
    asset (`FlutterInjector.flutterLoader().getLookupKeyForAsset`), so the audio file exists once.
    Volume fades from 0 to 1 over 1.5 s. A `MediaSessionCompat` gives the shade its progress
    (duration in the metadata, position in the playback state), and the notification uses
    `MediaStyle` from `androidx.media:media` 1.8.0. Pause, Mark prayed and Stop are playback state custom
    actions, since Android 13+ builds the media controls from the session, not the notification.
    It asks for audio focus: other audio pauses, any loss of focus (a call) stops it (FR-025).
  - One notification id per prayer and day (R6). The receiver's plain notification and the
    service's media notification use the same id, so there is never more than one. When the
    adhan ends on its own the service detaches and posts the plain notification under that id
    (FR-027). Stop removes it (FR-026).
  - Starting a foreground service from the background is allowed for an exact alarm the user set
    up (Android 12 exemption). Android 14 needs `FOREGROUND_SERVICE_MEDIA_PLAYBACK`.
- **Rationale**: code has to run at prayer time with the app killed, and the 5.2 progress bar
  needs a media session. The handoff names Kotlin for the Android notifications (SCREENS.md,
  system surfaces). Four small files, no package outside the constitution.
- **Alternatives**: android_alarm_manager_plus to run Dart at the alarm and audio_service for the
  media notification (two packages outside the list, audio_service is built around the main
  engine and its activity, starting it from an alarm isolate is fragile), the clip only (breaks
  5.2 and FR-020).

## R4. Silent mode, Do Not Disturb and exact alarms on Android

- **Decision**:
  - The adhan sounds only when `AudioManager.ringerMode` is `RINGER_MODE_NORMAL` and
    `NotificationManager.currentInterruptionFilter` is `INTERRUPTION_FILTER_ALL`. Checked in
    `AdhanReceiver` and again when the app asks to play (FR-022).
  - Exact alarms: `canScheduleExactNotifications()` decides the path at every scheduling. Allowed:
    Adhan prayers go to `AdhanAlarms`, the rest to the plugin with `exactAllowWhileIdle`. Not
    allowed: everything goes to the plugin with `inexactAllowWhileIdle`, Adhan prayers on their
    clip channel (FR-023).
  - First launch asks with `requestNotificationsPermission()` and then
    `requestExactAlarmsPermission()` (opens "Alarms & reminders"), once (FR-004, FR-005).
- **Rationale**: the same check iOS does by itself, and the plugin already exposes both
  permission calls.
- **Alternatives**: `USE_EXACT_ALARM` (Play limits it to alarm and calendar apps), a package to
  read the ringer mode (two lines of Kotlin).

## R5. Mark prayed without opening the app

- **Decision**:
  - One Dart function, `markFromPayload(String payload)`, opens the store, calls milestone 4's
    `AppDatabase.markPrayed(day, prayer)` and closes. Three entry points call it, each marked
    `@pragma('vm:entry-point')`:
    1. the plugin's `onDidReceiveBackgroundNotificationResponse` (iOS and Android actions),
    2. `markPrayedInBackground(List<String> args)`, run by Kotlin `MarkPrayedReceiver` in a
       headless `FlutterEngine` for the media and plain adhan notifications,
    3. the adhan screen, which calls `markPrayed` through the app's own store.
  - `_connect` turns on `DriftNativeOptions.shareAcrossIsolates`. A background engine in the
    same process then talks to the app's store isolate when the app is running, so Home and
    Prayer update at once. When the app isn't running it opens its own connection.
  - Background code opens the store with a new `AppDatabase.openExisting()` that returns null
    instead of resetting. Only the app in front may reset the store (milestone 2 FR-024), a
    locked keychain or a race in the background must never wipe the log.
  - The day passed is the prayer day the notification was scheduled for (milestone 4 contract),
    taken from the payload, so Isha after midnight lands on the day it started (FR-038).
  - iOS actions run without `authenticationRequired`. The key is `first_unlock_this_device`
    since milestone 2, readable from the lock screen.
- **Rationale**: one write path, the milestone 4 contract as written, and no second copy of the
  log anywhere.
- **Alternatives**: a queue of pending marks in preferences applied at the next launch (prayer
  history outside the encrypted store, against constitution VII), the action opening the app
  (FR-018 says without opening).

## R6. The schedule

- **Decision**:
  - `buildSchedule` (pure, `domain/schedule.dart`) takes now, the day times of 6 prayer days (the
    prayer day of now and the 5 after it), the five sounds and the reminder minutes. It returns the
    adhan and reminder alerts that are still in the future, skipping prayers with no time
    (FR-012). 6 days × (5 + 5) = 60 at most, the dev test notification makes 61, under iOS's 64.
  - Calendar days, not a 144 hour window: Fajr moves earlier by up to a minute a day, so a 144 hour
    window can hold 7 Fajrs.
  - Ids: `day number × 10 + slot`, day number = days since 2020-01-01 (UTC dates), slot 0 to 4 the
    adhan of Fajr to Isha, 5 to 9 their reminders. An id gives back its day and prayer, so cleanup
    needs no payload (R15). The dev test notification uses 1,000,000.
  - `apply` replaces everything every time: cancel all pending (plugin
    `cancelAllPendingNotifications()`, native `cancelAll`), then add the new list. Delivered
    notifications stay.
  - Triggers (FR-009, FR-010): app start, app resumed, a change of the schedule inputs (location,
    method, Asr, Hijri adjustment for Ramadan Isha, the five sounds, reminder minutes, app
    language, digits, phone time zone), and the background top-up (R7). The phone's 12/24 hour
    setting and the clock are read again on every resume. Changes are debounced by 500 ms.
  - Nothing is scheduled without a location, without permission, or in the design scenario
    (FR-012, FR-013).
- **Rationale**: replacing all 60 is cheap and can never leave an old time behind (FR-011).
- **Alternatives**: diffing pending against the new list (more code, no gain at 60 items), a
  rolling 144 hour window (the 7 Fajr case).

## R7. Topping up in the background

- **Decision** (the package isn't in the constitution, approved 2026-10-18): workmanager 0.10.10.
  - One periodic task, `better_muslim.topup` as both its unique name and its task name, since iOS
    only runs a task whose name is in `BGTaskSchedulerPermittedIdentifiers`. Every 12 h on Android
    (WorkManager), and every 6 h at the earliest
    on iOS (`BGAppRefreshTask`, iOS picks the moment).
  - The task (`callbackDispatcher`) runs in a background isolate: `AppDatabase.openExisting()`,
    settings and location from the store, the phone's zone from flutter_timezone, texts from the
    arb file for the phone's language, then `buildSchedule` and `apply`, the same code as in front.
  - iOS: `BGTaskSchedulerPermittedIdentifiers` = `better_muslim.topup`, `UIBackgroundModes`
    `fetch`, and in `AppDelegate` `WorkmanagerPlugin.setPluginRegistrantCallback` and
    `WorkmanagerPlugin.registerPeriodicTask(withIdentifier:frequency:)`.
  - Spec FR-009 said Android also tops up "each time an adhan fires". The native receiver can't
    run the Dart schedule, and the 12 h task covers the same need, so that wording changes to "in
    the background at least every 12 hours".
- **Rationale**: pub.dev shows fluttercommunity.dev as the publisher, 2.4k likes, 140 points,
  updated 2026-09-07, iOS through BGTaskScheduler. Without it a phone left alone for 6 days goes
  silent on both platforms.
- **Alternatives**: background_fetch (transistorsoft, 1.3k likes, fewer downloads, same job),
  native `BGTaskScheduler` and `WorkManager` code running a headless engine (the same thing done by
  hand), no background top-up at all (FR-009 drops to launch and resume only).

## R8. Playing the adhan in the app

- **Decision**: one `AdhanPlayer` type with two implementations behind `adhanPlayerProvider`:
  - Android `NativeAdhanPlayer`: the `AdhanService` of R3 through the method and event channels
    (`contracts/adhan-channel.md`). The app never plays audio itself on Android, so the screen and
    the shade always show the same playback (FR-024). `play` is a no-op when that prayer is already
    playing, since the alarm and the app can both start it.
  - iOS `JustAudioAdhanPlayer`: just_audio on the Flutter asset, audio_session as `playback`
    (keeps playing with the screen locked, pauses other audio, FR-025). An interruption (a call)
    stops it. The fade is a volume ramp over 1.5 s. `UIBackgroundModes` gets `audio`.
  - `length(recording)` gives a recording's duration (just_audio's load, Kotlin
    `MediaMetadataRetriever`), used by the tap rule of R9. No hard-coded lengths, so the real files
    can come later without a code change.
  - iOS has no public way to read the ring/silent switch. `playback` plays even with the switch
    on silent, decided 2026-10-18 (FR-022a). The notification itself follows the switch.
- **Rationale**: two platforms, two engines. The type is the seam the screen and the tests use.
- **Alternatives**: just_audio on Android too (a second player next to the service, the shade and
  the screen would drift apart), audio_service (R3).

## R9. The adhan screen at prayer time and from a tap

- **Decision**:
  - In front: `NotificationsBoot` listens to `periodProvider` (milestone 2, notifies only on
    change). When it changes to a prayer whose sound is Adhan, while the app is resumed and not in
    the design scenario, it pushes `Routes.adhan(prayer, day)` and calls `player.play`. Never on
    the first value, so opening the app a minute after a prayer shows no adhan screen.
  - Taps: the plugin's `onDidReceiveNotificationResponse` (taps in the main isolate),
    `getNotificationAppLaunchDetails()` at start, and the native `opened` event and
    `launchPayload` for the media and plain notifications. Each payload goes through
    `tapTarget(payload, now, length)` (pure): an Adhan prayer tapped less than the recording's
    length after its time → `Routes.adhan(prayer, day, from: now - time)`, anything else →
    `Routes.prayerAt(day, prayer)` from milestone 4. A reminder tap just opens the app.
  - `Routes.adhan` is a root route outside the shell, with a `CustomTransitionPage`: Motion 06
    (circle reveal from the sun, 520 ms decelerate, text 300 ms later), a 300 ms fade with reduce
    motion.
- **Rationale**: the period provider already ticks on the prayer boundaries, so no new timer.
- **Alternatives**: a full screen intent (Play limits it), a timer per prayer (duplicates the
  period provider).

## R10. The adhan screen itself

- **Decision**:
  - Sky: Maghrib uses 4.03's four stops, halo and sun on the horizon exactly. The other prayers
    use their `BmSkyStops` from `core/resources/design/bm_sky.dart`. The sun's height comes from
    `BmSunArc.fraction` at the prayer time: `y = horizon - sin(pi × fraction) × (horizon - 120)`,
    which gives the horizon at Maghrib. Fajr and Isha are night, no sun and no halo. I check
    those four in the app.
  - Colors: 4.03 is an always dark surface, so its literal colors live in one file,
    `presentation/view/adhan_colors.dart`, added to the architecture test's allow list (project
    CLAUDE.md). Sizes are named entries in `SizeManager` and `SpaceManager` (`adhanSun`,
    `adhanHalo`, `adhanCardTop` and so on).
  - Text: Reem Kufi and Marcellus through `font: FontEnum.display`, the rest Schibsted. The
    progress row and the time sit in `Directionality(ltr)`.
  - The halo breathes (MOTION.md `halo`, 3000 ms alternate) and stands still with reduce motion.
  - Mark prayed: `markPrayed` with `BmHaptics` Mark prayed, then the button shows "Prayed" with
    the check, like milestone 4's chip.
  - Read dua: `showBmSheet` (milestone 4's core sheet) with a dua card laid out like 4.14: title
    "After the adhan", source, Arabic, transliteration, translation. In Arabic only the Arabic and
    the source show. The text is in `data/dua_after_adhan.dart` with a `TODO(ahmed)`.
- **Rationale**: Q1 of the clarify session, and the project's rule for always dark surfaces.

## R11. The audio files

- **Decision**:

  | File | Where | Used by |
  | --- | --- | --- |
  | `adhan_makkah.m4a`, `adhan_makkah_fajr.m4a` | `assets/audio/` | the full adhan, just_audio on iOS, `AdhanService` on Android |
  | `adhan_makkah_clip.caf`, `adhan_makkah_fajr_clip.caf` (30 s or less) | `ios/Runner/Sounds/`, in the Runner target | iOS Adhan notifications |
  | `adhan_makkah_clip.m4a`, `adhan_makkah_fajr_clip.m4a` | `android/app/src/main/res/raw/` | Android Adhan channels, heard only without exact alarms |

  - Placeholders are made with macOS `say` and `afconvert` (a spoken "adhan placeholder" plus
    silence), so the full ones have a progress bar to test. Tone and the reminder use the phone's
    default sound.
  - Each file name sits once in `data/adhan_recording.dart` with a `TODO(ahmed)`, and the
    `assets/audio/` line in `pubspec.yaml` gets one too.
- **Rationale**: iOS notification sounds must be in the app bundle, Android channel sounds in
  `res/raw`. The full adhan stays a single Flutter asset for both players.

## R12. Texts outside a widget

- **Decision**: `AppLocalizations` gets a static `load(Locale)` that the delegate also uses.
  `formatTime` and `formatDigits` move into plain functions taking the language, the 24 hour flag
  and the digits, and the `BuildContext` extension calls them. The background reads the language
  from `PlatformDispatcher.locale` and the 24 hour flag from
  `PlatformDispatcher.alwaysUse24HourFormat`.
- **Rationale**: notifications are built in the background and at scheduling time, with no
  context, and they have to read exactly like the screens.

## R13. Checking it

- **Decision**:
  - Milestone 3 removes the dev readout (its FR-002), so the two dev buttons sit on a dev page,
    `Routes.devNotifications`, in the notifications feature. More shows one row to it in dev
    builds only. Its labels are dev text with `translate: false`, like the old readout.
  - The design scenario overrides `adhanPlayerProvider` with a fixed player at 0:42 of 2:56,
    paused and silent (FR-042), and `NotificationsBoot` schedules nothing.
  - Tests: unit tests for `buildSchedule`, the ids, `tapTarget` and the texts. A fake
    `FlutterLocalNotificationsPlatform` and a fake channel for `apply`, migration test v2 to v3,
    widget tests for the adhan screen and the dua sheet. No golden tests and no comparing against
    the PNG (constitution 3.0.0). The Kotlin part
    and real delivery are checked on phones with `quickstart.md`.
- **Spec change**: FR-041 says "the dev readout", it becomes "a dev page reached from More".

## R14. Privacy

- **Decision**: what a notification shows (prayer, time, city) is kept by iOS for pending
  notifications and, on Android, by the plugin and `AdhanAlarms` in the app's private
  preferences, which are out of backups (`allowBackup="false"` since milestone 2). That is the
  minimum for a notification to fire with the app closed. The log is never kept outside the
  encrypted store (R5). Scheduling errors are reported with the step name only, never a payload,
  a place or a time (FR-040). Errors in a background isolate aren't reported, the next launch
  tries again.
- **Rationale**: constitution VII. Without these copies there are no notifications at all.

## R15. Home's adhan line and cleaning up delivered notifications

- **Decision**:
  - Home (milestone 3) reads `settingsProvider.select((s) => s.value?.reminderMinutes)`:
    `adhanAtReminder` while it is above 0, the new `adhanAt` at 0 (FR-036).
  - The Prayer tab's later rows keep their adhan icon, nothing to change (FR-037).
  - Cleanup (FR-039): when the prayer log changes and when the app resumes, `NotificationsBoot`
    reads `getActiveNotifications()`, turns each id back into a day and prayer (R6), and cancels
    the ones milestone 4's log has as prayed. The plugin's `cancel(id:)` also removes the native
    plain notification, since both share the id. A playing adhan's media notification belongs to
    its service and stays until the adhan ends.
