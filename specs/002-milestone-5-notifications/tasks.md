---

description: "Tasks for milestone 5, notifications and adhan"
---

# Tasks: Milestone 5, Notifications and Adhan

**Input**: Design documents from `specs/002-milestone-5-notifications/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Included. Constitution VI asks for unit tests on the notification schedule, the spec's
checking story (US8) and SC-006 ask for the 4.03 check.

**Organization**: Grouped by user story, so each story can be built and checked on its own.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an unfinished task)
- **[Story]**: The user story the task belongs to (US1 to US8)

## Before starting

- Milestones 2, 3 and 4 are merged, `feature/milestone-5` is cut from them. This milestone uses
  milestone 4's `markPrayed`, `prayedProvider`, `prayerDayProvider`, `Routes.prayerAt`,
  `showBmSheet` and schema v2, and milestone 3's Home card.
- The plan's Decisions 1 to 7 took the recommendation on 2026-10-18 (workmanager, Kotlin with
  androidx.media, iOS adhan plays with the silent switch on, dev page from More, "Prayed" on the
  button, Arabic dua without transliteration, 12 h top-up on Android).
- T061's file path comes from milestone 3's plan. Check it there before starting US4.
- Every UI file goes through the `adaptive-widgets` rules, and
  `flutter test test/architecture_test.dart` stays green.

---

## Phase 1: Setup

**Purpose**: Packages, native build config, placeholder audio

- [X] T001 Add to `pubspec.yaml`:
  - dependencies: `flutter_local_notifications: ^22.3.2`, `just_audio: ^0.10.6`,
    `audio_session: ^0.2.4`, and `workmanager: ^0.10.10` (Decision 1)
  - `assets/audio/` under `flutter: assets:`, with a yaml comment above it:
    `# TODO(ahmed): replace the placeholder adhan files in assets/audio/ with the licensed recordings, same names.`

  Then run `flutter pub get`.
- [X] T002 [P] In `android/app/build.gradle.kts`:
  - `compileOptions { isCoreLibraryDesugaringEnabled = true }`
  - a `dependencies { coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5"); implementation("androidx.media:media:1.8.0") }` block
  - keep `compileSdk = flutter.compileSdkVersion` (36 on Flutter 3.47.5, the plugin needs 35+)
- [X] T003 [P] Make the placeholder audio with macOS `say` and `afconvert` (research R11), each a
  spoken "adhan placeholder" plus silence:
  - `assets/audio/adhan_makkah.m4a` (about 60 s) and `assets/audio/adhan_makkah_fajr.m4a` (says
    "fajr adhan placeholder"), AAC
  - `ios/Runner/Sounds/adhan_makkah_clip.caf` and `adhan_makkah_fajr_clip.caf`, 25 s, IMA4 or
    linear PCM
  - `android/app/src/main/res/raw/adhan_makkah_clip.m4a` and `adhan_makkah_fajr_clip.m4a`, 25 s
- [X] T004 [P] Copy `assets/app_icon/png/notification_small/drawable-*/` into
  `android/app/src/main/res/drawable-*/ic_notification.png` and add
  `android/app/src/main/res/values/colors.xml` with `notification_accent` `#A88A52` (system
  surfaces use the dark Qiyam Emerald, TOKENS.md).
- [X] T005 [P] In `test/architecture_test.dart` add
  `const _adhanColors = 'lib/features/notifications/presentation/view/adhan_colors.dart';` and add
  it to `allowedIn` of the colors rule, next to `_skyPainter`.

---

## Phase 2: Foundational

**Purpose**: Settings v3, the shared store across isolates, texts without a context, ids and
payloads, the Android channel's Dart side

**⚠️ CRITICAL**: No story work starts before this phase is done

- [X] T006 In `lib/core/settings/settings.dart` add `enum PrayerSound { adhan, tone, silent }` and an
  extension `soundOf(Prayer prayer)` on `AppSettings` that returns the matching column (sunrise
  is never asked).
- [X] T007 In `lib/core/database/app_database.dart`:
  - add to `Settings`: `fajrSound` (`textEnum<PrayerSound>()`, default `'adhan'`), `dhuhrSound`
    (`'tone'`), `asrSound` (`'tone'`), `maghribSound` (`'adhan'`), `ishaSound` (`'tone'`),
    `reminderMinutes` (`integer()`, default 10, "check: one of 0, 5, 10, 15, 20, 30. 0 is off"),
    `notificationsAsked` (`boolean()`, default false)
  - `schemaVersion` 3, with a v2 → v3 step that runs `addColumn` for each of the seven
  - `DriftNativeOptions(shareAcrossIsolates: true, ...)` in `_connect` (research R5)
  - `static Future<AppDatabase?> openExisting()`: the same as `open()` but returns null where
    `open()` would reset, and never calls `CrashReporter`. One-line `///`: background code must
    never reset the store.

  Then run `dart run build_runner build --delete-conflicting-outputs` and
  `dart run drift_dev make-migrations`, and commit `drift_schemas/app_database/drift_schema_v3.json`.
- [X] T008 [P] Extend `test/drift/app_database/migration_test.dart`: v2 → v3 keeps every value and
  reads the seven defaults. Add `test/core/database/open_existing_test.dart`: a missing key or an
  unreadable file gives null and leaves the file in place.
- [X] T009 [P] In `lib/core/app/app_localizations.dart` add `static Future<AppLocalizations> load(Locale locale)`
  and have the delegate's `load` call it.
- [X] T010 [P] In `lib/core/extensions/time_format.dart` add plain functions
  `formatTimeIn(TZDateTime time, {required String language, required bool use24h, required Digits digits})`
  and `formatDigitsIn(String text, {required String language, required Digits digits})`. The
  context extension calls them with the context's values. Add cases to
  `test/core/extensions/time_format_test.dart` for both.
- [X] T011 [P] Add these keys to `lib/core/resources/strings_manager.dart`, `assets/l10n/app_en.arb`
  and `assets/l10n/app_ar.arb` (with `@` placeholders where they have one):

  | Key | English | Arabic |
  | --- | --- | --- |
  | `adhanAt` | Adhan at {time} | الأذان {time} |
  | `adhanOfMakkah` | Adhan of Makkah | أذان مكة |
  | `notifReminderBody` | {time} · {city} | {time} · {city} |
  | `reminders` | Reminders | التذكيرات |
  | `stop` | Stop | إيقاف |
  | `pause` | Pause | إيقاف مؤقت |
  | `play` | Play | تشغيل |

  Skip any that milestone 3 or 4 already added. `strings_manager_test` stays green.
- [X] T012 [P] Add the 4.03 sizes to `lib/core/resources/dimensions_manager.dart` as named entries,
  values from `design_handoff_better_muslim/specs/screens/4.03-adhan.md`: sun 84, sun glow blur
  50 and spread 18, halo 420 × 280 at top 400, horizon top 540, header top 120 with gap 10, star
  34, name gap 8, progress width 200, top margin 22, bar height 3, card top 572 with side 16,
  radius 20, padding 16/18, gap 6, buttons bottom 44, height 52, radius 14, gap 10.
- [X] T013 [P] Create `lib/features/notifications/domain/alert.dart`:
  - `enum AlertKind { adhan, reminder }` and `Alert` with `id`, `day`, `prayer`, `kind`, `at`,
    `sound` as in data-model.md
  - `int alertId(DateTime day, Prayer prayer, AlertKind kind)`: days since 2020-01-01 (UTC dates)
    × 10 + slot, slot 0 to 4 the adhan of Fajr to Isha, 5 to 9 the reminders
  - `({DateTime day, Prayer prayer, AlertKind kind})? alertFromId(int id)`, null for
    `testAlertId = 1000000`
  - `String payloadOf(Alert)` and `Alert? alertFromPayload(String)` with
    `yyyy-MM-dd|prayer|kind|sound|atMillis`, no place in it
- [X] T014 [P] `test/features/notifications/domain/alert_test.dart`: ids round trip for every
  prayer and kind across a year, the test id gives null, a payload round trips and never contains
  a place.
- [X] T015 [P] Create `lib/features/notifications/data/adhan_recording.dart`:
  `enum AdhanRecording { makkah }` with the full asset, the Fajr full asset, the iOS clip names
  and the Android raw names from research R11, and `fullAsset(Prayer)` / `clipOf(Prayer)` that
  pick the Fajr variant. One `// TODO(ahmed):` above the enum: the files are placeholders until
  the licensed Makkah recordings come, keep the names.
- [X] T016 [P] Create `lib/features/notifications/data/adhan_channel.dart`, the Dart side of
  `contracts/adhan-channel.md`: `MethodChannel('better_muslim/adhan')` with `schedule`,
  `cancelAll`, `play`, `pause`, `resume`, `stop`, `markPrayedAction`, `length`, `dismiss`,
  `launchPayload`, and the event channels `better_muslim/adhan/state` and
  `better_muslim/adhan/opened` as streams. Every call is a no-op off Android.

**Checkpoint**: settings v3 and the shared store in place, texts can be built without a context

---

## Phase 3: User Story 1 - Each prayer reaches me with the app closed (Priority: P1) 🎯 MVP

**Goal**: At each prayer the phone shows the notification with the prayer's sound, offline, for
6 days, with the app closed

**Independent Test**: Allow notifications, airplane mode, kill the app, the next prayer's
notification arrives at its minute with its sound (quickstart §3, steps 1 to 3)

### Tests for User Story 1

- [X] T017 [P] [US1] `test/features/notifications/domain/schedule_test.dart`:
  - 6 normal prayer days from 15 Oct 2026 10:00 Makkah give 29 adhans (today's Fajr is past)
  - nothing in the past, nothing for a prayer with a null time (Tromsø 21 Jun 2026)
  - at 00:30 the first day is yesterday's prayer day, so the next Fajr is today's
  - the count never passes 30 adhans, even when Fajr gets a minute earlier each day
- [X] T018 [P] [US1] `test/features/notifications/data/alert_texts_test.dart`: "Maghrib · 17:56"
  and "It is time for Maghrib in Makkah. Tap to mark it prayed." in English. The Arabic with
  Eastern digits and the Arabic place name. "5:56 PM" on a 12 hour phone.
- [X] T019 [P] [US1] `test/features/notifications/data/notification_scheduler_test.dart` with a
  fake `FlutterLocalNotificationsPlatform` and a fake channel:
  - `apply` calls `cancelAllPendingNotifications` before anything else
  - iOS details follow the research R2 table for Adhan, Tone and Silent
  - Android uses channel `adhan_<prayer>_<sound>` and deletes the prayer's other two
  - `exactAllowWhileIdle` when exact alarms are allowed, `inexactAllowWhileIdle` otherwise
  - nothing without a location or without permission
  - a plugin call that throws reaches a fake `CrashReporter` with only `{'step': 'schedule'}`, no
    payload, place or time in the error context (FR-040)

### Implementation for User Story 1

- [X] T020 [US1] Create `lib/features/notifications/domain/schedule.dart`:
  - `const scheduleDays = 6`, with this line above it:
    `// TODO(ahmed): when the 6 days run out on iOS the phone goes quiet, a last "open the app" message could go here if I design one.`
  - `List<Alert> buildSchedule({required DateTime now, required List<DayTimes?> days, required Map<Prayer, PrayerSound> sounds})`:
    `days` are the prayer day of now and the 5 after it. It returns the adhan alerts after `now`,
    skipping null times. Reminders come in US4.
- [X] T021 [P] [US1] Create `lib/features/notifications/data/alert_texts.dart`: `AlertTexts` built
  from `AppLocalizations`, the language, `use24h`, `Digits` and the location. `titleOf(Alert)` →
  `notifAdhanTitle`, `bodyOf(Alert)` → `notifAdhanBody`, with the place name in the app's
  language (`placeNameAr` in Arabic when it exists). Uses `formatTimeIn` and `formatDigitsIn`.
- [X] T022 [US1] Create `lib/features/notifications/data/notification_scheduler.dart`:
  - `init()`: `initialize` with the Android small icon `ic_notification` and
    `DarwinInitializationSettings` with every `request*Permission` false (asking is explicit)
  - `ensureChannels(Map<Prayer, PrayerSound>)`: the R2 channels in group "Adhan" (name from
    `soundAdhan`), deleting the unused two per prayer. Adhan channels sound
    `RawResourceAndroidNotificationSound(clipOf(prayer))`, Silent `playSound: false` and
    `enableVibration: false`
  - `apply(List<Alert>, AlertTexts)`: `cancelAllPendingNotifications()`, then `zonedSchedule` each
    alert with `payloadOf(alert)` and the R2 iOS details. On Android every alert goes through the
    plugin in this story (`exactAllowWhileIdle` when `canScheduleExactNotifications()`, else
    `inexactAllowWhileIdle`). US2 moves Adhan prayers to the channel. The whole body is wrapped in
    a try/catch that reports to `CrashReporter` with `{'step': 'schedule'}` only (FR-040).
  - `Future<bool> askPermission()`: iOS `requestPermissions(alert: true, sound: true)`, Android
    `requestNotificationsPermission()`
  - a provider `notificationSchedulerProvider`
- [X] T023 [US1] Create `lib/features/notifications/presentation/notifications_boot.dart`, a
  `ConsumerStatefulWidget` that returns its child:
  - `initState`: `scheduler.init()`. Unless `flavorProvider` says design scenario: await
    `locationControllerProvider`'s `firstLocate`, then ask once (FR-004) when `notificationsAsked`
    is false, storing `notificationsAsked: true` before asking, then reschedule.
  - in `lib/core/location/location_controller.dart` add `Future<void> get firstLocate`, a
    completer finished when the first `_locate` ends, whatever the outcome (saved, refused,
    timeout)
  - an `AppLifecycleListener` that reschedules on `resumed`
  - `_reschedule()`: returns at once in the design scenario (FR-013), so no trigger added later can
    schedule there. Otherwise reads `locationProvider`, `prayerDayProvider` (milestone 4), the 6
    `dayTimesProvider(date)`, the settings, builds the alerts and texts, calls `apply`.
- [X] T024 [US1] In `lib/bootstrap.dart` wrap the app: `child: const NotificationsBoot(child: App())`.
- [X] T025 [P] [US1] Android manifest (`android/app/src/main/AndroidManifest.xml`): add
  `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`, and the plugin's
  `ScheduledNotificationReceiver`, `ScheduledNotificationBootReceiver` (boot, package replaced,
  quickboot actions) and `ActionBroadcastReceiver`, all `exported="false"`.
- [X] T026 [P] [US1] iOS:
  - `ios/Runner/AppDelegate.swift`: in `didInitializeImplicitFlutterEngine` call
    `FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in GeneratedPluginRegistrant.register(with: registry) }`,
    and set `UNUserNotificationCenter.current().delegate = self` in `didFinishLaunchingWithOptions`
  - `ios/Runner/Runner.entitlements` with `com.apple.developer.usernotifications.time-sensitive`
    true, wired as `CODE_SIGN_ENTITLEMENTS` for every configuration in
    `ios/Runner.xcodeproj/project.pbxproj`, with
    `<!-- TODO(ahmed): turn on Time Sensitive Notifications for the app ids in the Apple developer account, without it iOS delivers adhans as normal notifications. -->`
  - `ios/Runner/Sounds/*.caf` added to the Runner target's resources in `project.pbxproj`

**Checkpoint**: notifications arrive with the app closed on both platforms, Android Adhan prayers
with the clip for now

---

## Phase 4: User Story 2 - The full adhan, and one tap to stop it (Priority: P1)

**Goal**: The adhan screen over anything with the full adhan when the app is open, and on Android
the full adhan as a media notification with the app closed

**Independent Test**: In front, a test Adhan prayer opens the screen and plays, Stop silences at
once. On Android with the app closed the media notification plays and stops (quickstart §3 step 3,
§2)

### Tests for User Story 2

- [X] T027 [P] [US2] `test/features/notifications/data/adhan_player_test.dart`: the native player
  maps the state events to playback state and sends `play` once for the same id twice. The
  just_audio player is checked through a fake `AudioPlayer` for the 1.5 s fade target and stop on
  interruption.
- [X] T028 [P] [US2] `test/features/notifications/presentation/adhan_page_test.dart` with a fake
  player at 0:42 of 2:56: the 4.03 texts, Stop calls `stop` and pops, reduce motion gives the
  fade transition and a still halo, Arabic keeps the progress row left to right, text scale 2.0
  cuts nothing.
- [X] T029 [P] [US2] Extend `notification_scheduler_test.dart`: with exact alarms allowed, Adhan
  prayers go to the channel's `schedule` (entries as in data-model.md) and not to the plugin.
- [X] T030 [P] [US2] `test/features/notifications/presentation/notifications_boot_test.dart`: a
  period change to an Adhan prayer while resumed pushes `/adhan` and calls `play`. The first period
  value, a Tone prayer and the design scenario push nothing.

### Implementation for User Story 2

- [X] T031 [P] [US2] Create `android/app/src/main/kotlin/com/elhawary/bettermuslim/adhan/AdhanAlarms.kt`:
  keep entries as JSON in private `SharedPreferences` `adhan_alarms`, `schedule(entries)` replaces
  all and sets `setExactAndAllowWhileIdle` per entry (`PendingIntent` request code = id),
  `cancelAll()`, `restore()` for future entries.
- [X] T032 [P] [US2] Create `.../adhan/AdhanReceiver.kt`: on the alarm, ringer
  `RINGER_MODE_NORMAL` and `INTERRUPTION_FILTER_ALL` → `startForegroundService(AdhanService)` with
  the entry, else post the plain notification on the entry's channel with `setSilent(true)`, small
  icon `ic_notification`, color `notification_accent`, the payload in its content intent to
  `MainActivity`. On `BOOT_COMPLETED` and `MY_PACKAGE_REPLACED` call `AdhanAlarms.restore()`.
- [X] T033 [US2] Create `.../adhan/AdhanService.kt` (foreground, `mediaPlayback`):
  - `MediaPlayer` on the Flutter asset through `FlutterInjector.instance().flutterLoader().getLookupKeyForAsset`
    and `assets.openFd`, wake mode partial, seek to `fromMillis`
  - volume ramp 0 → 1 over 1500 ms
  - audio focus `AUDIOFOCUS_GAIN`, any focus loss stops (FR-025)
  - `MediaSessionCompat` with title, `adhanOfMakkah`, duration metadata and a playback state
    updated every 500 ms, custom actions Pause/Play and Stop
  - the notification under the entry's id with `MediaStyle().setMediaSession(...)`, `setSilent(true)`,
    sub text "Adhan", the content intent with the payload
  - on completion: `stopForeground(STOP_FOREGROUND_DETACH)` and post the plain notification under
    the same id (FR-027). On Stop: `stopForeground(STOP_FOREGROUND_REMOVE)` (FR-026)
  - state events for the event channel
- [X] T034 [US2] In `android/app/src/main/kotlin/com/elhawary/bettermuslim/MainActivity.kt`
  override `configureFlutterEngine` and register the method channel and the two event channels of
  `contracts/adhan-channel.md` (`play` checks the ringer like the receiver), plus
  `launchPayload` from the start intent and `opened` from `onNewIntent`.
- [X] T035 [P] [US2] Manifest: `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`,
  `WAKE_LOCK`, the `AdhanService` with `foregroundServiceType="mediaPlayback"` and the
  `AdhanReceiver` with boot and package replaced actions (`contracts/adhan-channel.md`).
- [X] T036 [US2] In `notification_scheduler.dart`, when `canScheduleExactNotifications()` is true,
  send Adhan alerts to `adhanChannel.schedule` as alarm entries (texts, channel id, asset,
  localized action labels) and the rest to the plugin. Call `adhanChannel.cancelAll()` at the
  start of `apply`.
- [X] T037 [P] [US2] Create `lib/features/notifications/data/adhan_player.dart`:
  - `abstract class AdhanPlayer` with `play(Alert, {Duration from})`, `pause`, `resume`, `stop`,
    `length(Prayer)`, `Stream<Playback> playback`
  - `NativeAdhanPlayer` over `adhan_channel.dart`
  - `JustAudioAdhanPlayer` (FR-022a): `AudioSession` configured as `AudioSessionConfiguration.music()`
    (playback), `setAsset(fullAsset(prayer))`, seek to `from`, volume ramp over 1500 ms, stop on
    `interruptionEventStream` begin
  - `FixedAdhanPlayer(position, duration)`: paused, silent, for the design scenario
- [X] T038 [US2] Create `lib/features/notifications/presentation/providers/adhan_providers.dart`:
  `adhanPlayerProvider` (Android → native, iOS → just_audio, design scenario → `FixedAdhanPlayer`
  at 0:42 of 2:56) and `playbackProvider` as a `StreamProvider`.
- [X] T039 [P] [US2] iOS `ios/Runner/Info.plist`: `UIBackgroundModes` with `audio`.
- [X] T040 [US2] In `lib/core/router/app_router.dart` add `Routes.adhan(Prayer, DateTime, {Duration from})`
  → `/adhan?prayer=&day=&from=` (`from` in whole seconds) as a root `GoRoute` outside the shell with a
  `CustomTransitionPage`: Motion 06 (`ClipPath` circle from the sun's position, 520 ms
  `BmMotion` decelerate, text fade and slide 300 ms later), a 300 ms fade with reduce motion.
- [X] T041 [P] [US2] Create `lib/features/notifications/presentation/view/adhan_colors.dart`: every
  literal color of 4.03 (sky stops, halo, sun and glow, horizon line, `#F1E3C4`, `#EADBC6`, card
  `rgba(24,16,20,.6)`, glass button, primary button `#F6EAD6` on `#1E1A26`), as one `abstract final class AdhanColors`.
- [X] T042 [P] [US2] Create `lib/features/notifications/presentation/view/widgets/adhan_sky.dart`:
  a `CustomPainter` widget. Maghrib draws 4.03 exactly (4 stops, halo, sun on the horizon with its
  glow, horizon line). Other prayers use their `BmSkyStops` and the sun at
  `horizon - sin(pi × BmSunArc.fraction) × (horizon - 120)`, no sun and no halo at Fajr and Isha
  (FR-029). The halo breathes per MOTION.md `halo` and stands still with reduce motion.
- [X] T043 [P] [US2] Create `.../widgets/adhan_header.dart`: the star mark (brand art
  `assets/brand/star_8point.svg` through `SvgPicture.asset` tinted `#F1E3C4` from `AdhanColors`, it
  isn't a `BmIcon`), "ADHAN · {city}"
  (`adhanHeader`), the Arabic name in `FontEnum.display` (Reem Kufi 40), the English name
  (Marcellus 60), the time, then `adhan_progress.dart` with elapsed, bar and total inside
  `Directionality(ltr)`, reading `playbackProvider.select(...)`.
- [X] T044 [P] [US2] Create `lib/features/notifications/data/dua_after_adhan.dart` with the dua's
  title key, source, Arabic, transliteration and translation, and
  `// TODO(ahmed): check the dua text, transliteration and translation against Bukhari 614.` Then
  `.../widgets/adhan_dua_card.dart`: "After the adhan" and "Read dua ›" (`readDua`, `ui/forward`
  14), the first line in Amiri 22, the translation's first line (4.03 card).
- [X] T045 [US2] Create `.../widgets/adhan_buttons.dart` (Mark prayed glass, Stop adhan primary,
  52 high, 44 × 44 minimum) and `lib/features/notifications/presentation/view/adhan_page.dart`
  laying out 4.03 with the sky, header, card and buttons. Stop → `player.stop()` and pop.
- [X] T046 [US2] In `notifications_boot.dart` listen to `periodProvider`: a change to a prayer
  whose sound is Adhan, while resumed and not in the design scenario, pushes
  `Routes.adhan(prayer, prayerDay)` and calls `player.play(alert)`. Never on the first value.

**Checkpoint**: US1 and US2 together are the MVP: notifications with the app closed, the full adhan
on Android, the adhan screen in front

---

## Phase 5: User Story 3 - Mark the prayer from the adhan (Priority: P2)

**Goal**: Mark prayed on the screen and on every notification, without opening the app, and taps
that land on the right place

**Independent Test**: Mark prayed from a notification with the app closed, open the app, Home and
Prayer show it prayed (quickstart §3 step 4, §4)

### Tests for User Story 3

- [X] T047 [P] [US3] `test/features/notifications/domain/tap_target_test.dart`: an Adhan payload at
  0 s and at the length minus 1 s → adhan target with `from`, at the length plus 1 s → Prayer
  target, Tone and Silent → Prayer target, a reminder → no target, Isha after midnight keeps its
  day.
- [X] T048 [P] [US3] `test/features/notifications/data/background_test.dart`: `markFromPayload` on
  an in-memory store logs the payload's day and prayer once, twice changes nothing, a passed
  prayer is logged the same way (FR-038), a null store does nothing.
- [X] T049 [P] [US3] Extend `notifications_boot_test.dart`: a logged prayer cancels the delivered
  notification whose id decodes to it (FR-039), an unlogged one stays. Extend
  `adhan_page_test.dart` (FR-031): Mark prayed logs once through an in-memory store, the fake
  player keeps playing, the button shows "Prayed" with the check and a second tap does nothing.

### Implementation for User Story 3

- [X] T050 [P] [US3] Create `lib/features/notifications/domain/tap_target.dart`:
  `sealed class TapTarget` with `AdhanTarget(prayer, day, from)`, `PrayerTarget(day, prayer)`,
  `NoTarget`, and `tapTarget(String payload, DateTime now, Duration length)` per research R9.
- [X] T051 [US3] Create `lib/features/notifications/data/background.dart`:
  - `Future<void> markFromPayload(String payload, {AppDatabase? db})`: decodes, opens
    `AppDatabase.openExisting()` unless given, `markPrayed(day, prayer)`, closes what it opened
  - `@pragma('vm:entry-point') void onNotificationActionInBackground(NotificationResponse response)`
    for action id `mark_prayed`
  - `@pragma('vm:entry-point') Future<void> markPrayedInBackground(List<String> args)`: calls
    `WidgetsFlutterBinding.ensureInitialized()` and `markFromPayload(args.first)`, and ends with
    `MethodChannel('better_muslim/adhan/background').invokeMethod('done')` so Kotlin can destroy
    the engine
- [X] T052 [US3] In `notification_scheduler.dart`: iOS category `adhan` with
  `DarwinNotificationAction.plain('mark_prayed', markPrayed)` (no foreground, no authentication),
  Android `AndroidNotificationAction('mark_prayed', markPrayed, showsUserInterface: false, cancelNotification: true)`
  on adhan notifications, and `onDidReceiveBackgroundNotificationResponse: onNotificationActionInBackground`
  in `initialize`. Re-run `init()` after a language change so the action title follows.
- [X] T053 [US3] Create `.../adhan/MarkPrayedReceiver.kt`: `goAsync()`, a `FlutterEngine` running
  `DartEntrypoint(findAppBundlePath(), "package:better_muslim/features/notifications/data/background.dart", "markPrayedInBackground")`
  with `[payload]`, destroys the engine on `done` or after 20 s, then asks `AdhanService` (if
  playing that id) to drop the Mark prayed action, or cancels the plain notification. Register it
  in the manifest. Add the Mark prayed custom action to `AdhanService` and the plain notification
  of `AdhanReceiver`.
- [X] T054 [US3] In `adhan_buttons.dart` wire Mark prayed: `db.markPrayed(day, prayer)` through
  the app's store, `BmHaptics` Mark prayed, then the button shows "Prayed" (`prayed`, `ui/check`)
  and is disabled (Decision 5), and `adhanChannel.markPrayedAction(id)` on Android. The adhan keeps
  playing.
- [X] T055 [US3] In `notifications_boot.dart`:
  - taps: `getNotificationAppLaunchDetails()` and `adhanChannel.launchPayload()` at start,
    `onDidReceiveNotificationResponse` and the `opened` stream after, each through `tapTarget`
    with `player.length(prayer)` → `router.push(Routes.adhan(..., from:))` or
    `router.go(Routes.prayerAt(day, prayer))`
  - cleanup (FR-039): on a change of `prayedProvider(prayerDay)` and on resume, read
    `getActiveNotifications()`, decode each id with `alertFromId`, `cancel(id:)` those the log has
    as prayed, skipping the id that is playing

**Checkpoint**: marking works from every surface, taps land on the adhan screen or the Prayer tab

---

## Phase 6: User Story 4 - A reminder before each prayer (Priority: P2)

**Goal**: The quiet reminder, and Home's adhan line following the reminder setting

**Independent Test**: With 10 minutes, the reminder comes 10 minutes before the next prayer. Off,
none comes, and Home reads "Adhan at {time}" (quickstart §3)

### Tests for User Story 4

- [X] T056 [P] [US4] Extend `schedule_test.dart`: reminders at the prayer time minus the minutes,
  for all five whatever their sound, none at 0, a reminder already past is skipped while its adhan
  stays, 60 at most for 6 full days.
- [X] T057 [P] [US4] Extend `notification_scheduler_test.dart` and `alert_texts_test.dart`: reminders
  use channel `reminders` (default importance) and iOS `passive` with no sound, title "Maghrib in
  10 minutes", body "17:56 · Makkah", Arabic forms.
- [X] T058 [P] [US4] A widget test next to milestone 3's Home card test: "Adhan at 17:56 · reminder
  10 min before" at 10, "Adhan at 17:56" at 0.

### Implementation for User Story 4

- [X] T059 [US4] In `schedule.dart` take `required int reminderMinutes` and add the reminder alert
  of each prayer when it is above 0 and still in the future.
- [X] T060 [US4] In `alert_texts.dart` and `notification_scheduler.dart`: `notifReminderTitle` and
  `notifReminderBody`, the `reminders` channel (name `reminders`, importance default, the phone's
  default sound), iOS `InterruptionLevel.passive`, `presentSound: false`, no category.
- [X] T061 [US4] In milestone 3's Home card (the widget that shows "Adhan at 17:56 · reminder 10
  min before", under `lib/features/home/view/widgets/`) read
  `settingsProvider.select((s) => s.value?.reminderMinutes)`: `adhanAtReminder` above 0, `adhanAt`
  at 0. Remove milestone 3's sample marker for it (FR-036).

**Checkpoint**: reminders arrive and Home tells the truth about them

---

## Phase 7: User Story 5 - The schedule stays right when things change (Priority: P2)

**Goal**: Every pending notification follows changes at once and the 6 days stay topped up

**Independent Test**: Switch Makkah to Cairo by hand, every pending notification shows Cairo's
times. Leave the app closed a day, 6 days are still pending (quickstart §5)

### Tests for User Story 5

- [X] T062 [P] [US5] Extend `notifications_boot_test.dart`: a change of location, method, Asr, Hijri
  adjustment, any sound, the reminder, the language, the digits or the phone zone gives exactly
  one `apply` after 500 ms. Resume gives one `apply`. In the design scenario neither gives any
  (FR-013).

### Implementation for User Story 5

- [X] T063 [US5] In `notifications_boot.dart` add `_scheduleInputsProvider` (a `Provider` of a
  record built with `.select()` from `locationProvider`, `settingsProvider` and `phoneZoneProvider`
  plus the app's locale) and listen to it with a 500 ms debounce that calls `_reschedule()`. On
  resume also compare `PlatformDispatcher.alwaysUse24HourFormat` and the locale.
- [X] T064 [US5] Move the body of `_reschedule()` into `Future<void> topUp(AppDatabase db, {required Locale locale, required bool use24h})`
  in `lib/features/notifications/data/background.dart`, so the app and the background run the same
  steps. It computes the 6 `DayTimes` with `DayTimes.compute` from the stored location and
  settings (no Riverpod), the prayer day from milestone 4's rule.
- [X] T065 [US5] (Decision 1) In `background.dart` add `@pragma('vm:entry-point') void callbackDispatcher()`
  with `Workmanager().executeTask`: `tz.initializeTimeZones()`, `openExisting()`, the phone zone
  from flutter_timezone, `AppLocalizations.load(PlatformDispatcher.instance.locale)`, `topUp`,
  close. In `lib/bootstrap.dart` call `Workmanager().initialize(callbackDispatcher)` and
  `registerPeriodicTask('better_muslim.topup', 'better_muslim.topup', frequency: Duration(hours: 12), existingWorkPolicy: ExistingPeriodicWorkPolicy.keep)`
  outside the design scenario. The name has to be the iOS identifier of T066, or iOS never runs it.
- [X] T066 [US5] (Decision 1) iOS: `BGTaskSchedulerPermittedIdentifiers` = `better_muslim.topup` and
  `fetch` in `UIBackgroundModes` in `ios/Runner/Info.plist`. In `AppDelegate.swift`
  `WorkmanagerPlugin.setPluginRegistrantCallback { registry in GeneratedPluginRegistrant.register(with: registry) }`
  and `WorkmanagerPlugin.registerPeriodicTask(withIdentifier: "better_muslim.topup", frequency: NSNumber(value: 6 * 60 * 60))`.
  The same string as T065's task name.

**Checkpoint**: nothing pending is ever stale, the schedule refills itself

---

## Phase 8: User Story 6 - Asked once, at the right moment (Priority: P2)

**Goal**: The alarms page on Android after notifications, no nagging after a refusal, a later
grant picked up

**Independent Test**: Fresh install, refuse notifications, the app works and asks nothing more.
Allow in the phone's settings, come back, the schedule is made (quickstart §3 steps 1 and 6)

### Tests for User Story 6

- [X] T067 [P] [US6] Extend `notifications_boot_test.dart` with a fake scheduler: the ask happens
  once after the location settles, never in the design scenario. Refused: nothing scheduled, no
  second ask after a restart. Android 12+: the alarms page opens once after notifications are
  allowed. A permission granted later: the next resume schedules.

### Implementation for User Story 6

- [X] T068 [US6] In `notification_scheduler.dart` add `Future<bool> askExactAlarms()`
  (`requestExactAlarmsPermission()` when `canScheduleExactNotifications()` is false, Android 12+
  only) and `Future<bool> isAllowed()` (iOS `checkPermissions`, Android `areNotificationsEnabled`).
  In `notifications_boot.dart` call `askExactAlarms()` right after a granted notifications ask, and
  have `_reschedule()` return early when `isAllowed()` is false.

**Checkpoint**: a refused permission never breaks or nags, a later grant works

---

## Phase 9: User Story 7 - Read the dua after the adhan (Priority: P3)

**Goal**: The full dua in a sheet, the adhan keeps playing

**Independent Test**: On the adhan screen tap Read dua, the sheet shows the dua with its source,
closing it returns to the screen with the adhan still playing

### Tests for User Story 7

- [X] T069 [P] [US7] `test/features/notifications/presentation/dua_sheet_test.dart`: English shows
  title, source, Arabic, transliteration and translation, Arabic shows only the Arabic and the
  source (Decision 6), the player is never stopped.

### Implementation for User Story 7

- [X] T070 [US7] Create `lib/features/notifications/presentation/view/widgets/dua_sheet.dart` laid
  out like the 4.14 dua card (title, source, Arabic in Amiri, transliteration, translation) and
  open it from "Read dua" in `adhan_dua_card.dart` with milestone 4's `showBmSheet` (Motion 15).

**Checkpoint**: the adhan screen is complete

---

## Phase 10: User Story 8 - Checking it against the design (Priority: P3)

**Goal**: 4.03 opens in the design scenario, and a test notification comes in a minute

**Independent Test**: Design scenario → More → Notifications (dev) → Open adhan screen shows
4.03's values. In a normal dev run the test notification arrives a minute later (quickstart §2, §3)

### Tests for User Story 8

- [X] T071 [P] [US8] `test/features/notifications/presentation/dev_notifications_page_test.dart`:
  both buttons exist in dev and the page route doesn't exist in staging and production. Extend
  `adhan_page_test.dart`: in the design scenario the page shows Maghrib 17:56, "ADHAN · MAKKAH"
  and 0:42 of 2:56 (FR-042).

### Implementation for User Story 8

- [X] T072 [US8] In `notification_scheduler.dart` add `testIn1Minute(Alert next, AlertTexts texts)`:
  the next prayer's notification with its sound at now + 1 min under `testAlertId`, through the
  channel for an Android Adhan prayer with exact alarms, the plugin otherwise.
- [X] T073 [US8] Create `lib/features/notifications/presentation/view/dev_notifications_page.dart`:
  two rows, "Open adhan screen" (pushes `Routes.adhan` for the next prayer, Maghrib in the
  scenario) and "Test notification in 1 min", dev text with `translate: false`. Add
  `Routes.devNotifications` → `/dev/notifications` to `lib/core/router/app_router.dart`, registered
  only when the flavor is dev.
- [X] T074 [US8] In `lib/features/more/view/more_page.dart` add one row "Notifications (dev)" at the
  end, shown only in dev builds, that pushes `Routes.devNotifications`.

**Checkpoint**: everything in quickstart.md can be run

---

## Phase 11: Polish & Cross-Cutting Concerns

- [ ] T075 Run `dart format --set-exit-if-changed lib test tool`, `flutter analyze` and `flutter test`,
  and fix everything. Run the adaptive-widgets self-check greps on `lib/features/notifications/`.
- [ ] T076 Run `specs/002-milestone-5-notifications/quickstart.md` §2 to §5 on an iPhone and an
  Android 13+ phone. Note the delivery delay with exact alarms (SC-001), the Stop delay (SC-004),
  the pending count on iOS (SC-008).
- [ ] T077 Check WCAG AA contrast of every text on the adhan screen against each
  of the five skies, and list any miss in the milestone reply.
- [ ] T078 [P] In `.specify/memory/constitution.md`: add workmanager to the domain packages
  (Decision 1), and add to principle II the exception the project CLAUDE.md already allows (always
  dark surfaces like the adhan screen keep their literal colors in one allow-listed file). Bump the
  MINOR version from the version found in the file then, and update the date.
- [ ] T079 [P] Mark milestone 5 as "Done, waiting for my review." in `CLAUDE.md`.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: none. T001 before anything that imports the new packages.
- **Foundational (Phase 2)**: after Setup, blocks every story. T008 needs T007. T014 needs T013.
- **US1 (Phase 3)**: after Foundational. T022 needs T020 and T021. T023 needs T022. T024 needs
  T023.
- **US2 (Phase 4)**: after US1 (it extends the scheduler and the boot widget). T033 needs T031 and
  T032. T034 needs T033. T036 needs T034. T045 needs T041 to T044. T046 needs T038, T040 and T045.
- **US3 (Phase 5)**: after US2 (the media notification and the adhan buttons). T053 needs T051.
  T055 needs T050.
- **US4 (Phase 6)**: after US1. It can run next to US2 and US3, except T060 edits the scheduler
  too.
- **US5 (Phase 7)**: after US1. T064 before T065.
- **US6 (Phase 8)**: after US1.
- **US7 (Phase 9)**: after US2 (T044, T045).
- **US8 (Phase 10)**: after US2. T072 needs US1's scheduler.
- **Polish (Phase 11)**: after all stories.

### Within Each Story

Tests first and failing, then domain, data, native, presentation, wiring.

## Parallel Examples

```text
# Foundational, after T001 to T005:
T009 app_localizations | T010 time_format | T011 strings | T012 sizes | T013 alert.dart | T015 recording | T016 channel

# US1 tests together:
T017 schedule_test | T018 alert_texts_test | T019 notification_scheduler_test

# US2 native and Dart side by side:
T031 AdhanAlarms.kt | T032 AdhanReceiver.kt | T037 adhan_player.dart | T041 adhan_colors | T042 adhan_sky | T043 adhan_header | T044 dua card

# After US1, three tracks:
US4 (T056 to T061) | US5 (T062 to T066) | US6 (T067, T068)
```

## Implementation Strategy

### MVP First (User Stories 1 and 2)

1. Phase 1 and Phase 2.
2. Phase 3 (US1): notifications with the app closed, the clip everywhere.
3. Phase 4 (US2): the full adhan on Android and the adhan screen.
4. Stop and check with quickstart §2 and §3.

### Incremental Delivery

US1 → US2 → US3 (Mark prayed, taps) → US4 (reminders, Home line) → US5 (follows changes,
top-up) → US6 (permissions) → US7 (dua sheet) → US8 (dev page) → Polish. Each step keeps the
earlier ones green.
