---

description: "Tasks for milestone 11, widgets and live activity"
---

# Tasks: Milestone 11, Widgets and Live Activity

**Input**: Design documents from `specs/006-milestone-11-widgets/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/surface-data.md,
contracts/surfaces-channel.md, contracts/native-surfaces.md, quickstart.md

**Tests**: Included. Constitution VI asks for unit tests on logic and widget tests on screens.
SC-001, SC-004 and SC-006 ask for the builder against Home, the windows and the key set in tests.
The native surfaces have no Dart tests, I check them on the phones with quickstart.md (no goldens,
no screenshots).

**Organization**: Grouped by user story, so each story can be built and checked on its own.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an unfinished task)
- **[Story]**: The user story the task belongs to (US1 to US4)

## Before starting

- Built after milestone 10 on `feature/milestone-11` (already cut). Milestone 7 comes after 11, so
  nothing here touches the Quran reader.
- Read `design_handoff_better_muslim/specs/HOW_TO_READ.md`, then the 5.3, 5.4, 5.6, 5.7 and 5.8
  trees, section 04 of `design/07 System surfaces.dc.html` (the `cd` and `cdS` script), TOKENS.md
  (the dark Qiyam Emerald values) and OVERVIEW.md. 5.1, 5.2 and 5.5 show the surfaces in place,
  nothing to build from them.
- Every surface is built from its tree, with only the limits approved in plan.md "Answered" (Q1 to
  Q7). Nothing else drifts from the trees.
- Native colors live in one file per platform (`ios/PrayerWidgets/SurfaceColors.swift`,
  `packages/prayer_surfaces/android/src/main/res/values/surfaces_colors.xml`), the always dark
  exception. Dart files follow the `adaptive-widgets` rules and
  `flutter test test/architecture_test.dart` stays green.
- After each native task its platform builds:
  `flutter build apk --debug --flavor dev -t lib/main_dev.dart --dart-define-from-file=dart_define/dev.json`
  and
  `flutter build ios --debug --no-codesign --flavor dev -t lib/main_dev.dart --dart-define-from-file=dart_define/dev.json`.
- `.specify/feature.json` points at this folder. Parallel sessions pass it explicitly
  (`SPECIFY_FEATURE_DIRECTORY=specs/006-milestone-11-widgets`).

---

## Phase 1: Setup

**Purpose**: The constitution, the plugin, the folders, the iOS extension target.

- [X] T001 Amend `.specify/memory/constitution.md` for Q5 (approved in the spec's plan session): in Stack And Constraints drop "home_widget, live_activities" from the end of the domain packages (the list ends with file_picker), and in the native code line add `packages/prayer_surfaces` after `packages/adhan_alarms` as "(the widgets' data, the Live Activity and the Android countdown)". Bump the version MINOR (3.6.0) and the Last Amended date. Nothing in `test/architecture_test.dart` checks it.
- [X] T002 Confirm `flutter pub get`, `flutter analyze` and `flutter test` are green on `feature/milestone-11` before any change.
- [X] T003 Create the local plugin `packages/prayer_surfaces/` on the shape of `packages/adhan_alarms`: `pubspec.yaml` (description "The widgets' data, the Live Activity and the Android countdown, in every engine.", the same sdk, flutter and plugin comment, android `package: com.elhawary.bettermuslim.surfaces` and ios, both `pluginClass: PrayerSurfacesPlugin`), `.gitignore`, `android/build.gradle.kts` and `android/settings.gradle.kts` from adhan_alarms with the namespace changed, an empty `android/src/main/AndroidManifest.xml`, `ios/prayer_surfaces/Package.swift` (iOS 15, a `prayer_surfaces` library, the Flutter dependency the way Flutter's SwiftPM plugin template declares it), and in both languages a `PrayerSurfacesPlugin` that only registers `better_muslim/surfaces`. Add `prayer_surfaces: path: packages/prayer_surfaces` under adhan_alarms in `pubspec.yaml`, run `flutter pub get`, both builds pass.
- [X] T004 Create the folders `lib/core/surfaces/`, `lib/features/surfaces/presentation/`, `test/core/surfaces/`, `test/features/surfaces/presentation/`, `ios/PrayerWidgets/`.
- [X] T005 Make `ios/Runner/Sounds/silence.caf` (1 s of silence, `afconvert -f caff -d LEI16` from a generated silent WAV), the iOS 26 start alert's sound (research R7). Create every file of the plan's `ios/PrayerWidgets/` tree plus `MessageView.swift` (US4) as stubs that compile, so the target gets them once: an empty `@main` `WidgetBundle` in `PrayerWidgetsBundle.swift`, empty Swift files, `Assets.xcassets` with its `Contents.json`, `en.lproj/Localizable.strings` and `ar.lproj/Localizable.strings`, `Info.plist` (`NSExtension` → `com.apple.widgetkit-extension`, `AppGroup` = `$(APP_GROUP)`, `UIAppFonts` with the four font files), `PrayerWidgets.entitlements` (`com.apple.security.application-groups` = `$(APP_GROUP)`).
- [X] T006 Add the `PrayerWidgets` app extension to `ios/Runner.xcodeproj` with a one-off Ruby script on the installed `xcodeproj` gem (research R17), run from the scratchpad and not kept: the 9 flavor configurations with Runner's names (Debug, Profile, Release × dev, staging, production), deployment target 15.0, Swift 5, bundle id Runner's per configuration + `.widgets`, `APP_GROUP` per flavor on Runner and the extension (`group.com.elhawary.bettermuslim`, `.dev`, `.staging`), `CODE_SIGN_ENTITLEMENTS` and `INFOPLIST_FILE` for the extension, the T005 files in the target, `SchibstedGrotesk-Variable.ttf`, `Marcellus-Regular.ttf`, `NotoSansArabic-Variable.ttf` and `ReemKufi-Variable.ttf` from `assets/fonts/` as references in its Copy Bundle Resources (no copies in git), the extension embedded in Runner with Runner depending on it, `silence.caf` in Runner's resources. In `ios/Runner/Info.plist` add `NSSupportsLiveActivities` true, `AppGroup` = `$(APP_GROUP)` and `CFBundleURLTypes` with the `bettermuslim` scheme (research R11). In `ios/Runner/Runner.entitlements` add the app groups entitlement with `$(APP_GROUP)`. Add `TODO(ahmed):` above the app groups in both entitlements files (the three groups must exist in my developer account, else the widgets read nothing) and in `ios/PrayerWidgets/Info.plist` (the three extension app ids and the signing team on the new target). The iOS build passes.

---

## Phase 2: Foundational

**Purpose**: What every surface stands on: schema 7, the strings, the builder, the writer, the
channel, the boot, the file write on both platforms and the extension's shared Swift.

**⚠️ CRITICAL**: No story work starts before this phase is done

### Tests for the foundation

- [X] T007 [P] Write `test/core/surfaces/surface_data_test.dart` against `buildSurfaceData` (T014), on the decoded map:
  - SC-001: for Makkah (Umm al-Qura), Istanbul (Turkey, written on the Saturday before the last Sunday of October so the daylight saving change falls inside the 7 days) and Tromsø on 20 June (no Isha), every 5 minutes from the write to `until`: take the entry in force with the rule of contracts/native-surfaces.md (a few lines in the test) and compare with Home's providers in a `ProviderContainer` with `clockProvider` at that moment: the next prayer and its time (`nextPrayerProvider`), the minutes left (`timeLeftProvider` floored to minutes), the prayer day (`prayerDayProvider`), the strip's five times (`stripProvider`), `barFrom` (`periodStart` as `barShareProvider` calls it), `sunrise` and `maghrib` (`todayTimesProvider`), the Hijri line and `dateLine` as `DateLine` builds them. Marks on the first prayer day only.
  - the windows: 2 hours before; Isha's from Maghrib with Umm al-Qura's 90 minutes; Fajr's in the night with `barFrom` at last night's Isha; Dhuhr's `barFromLabel` "Sunrise {time}" with no "· prayed"; a prayer with no time has no window and is no one's previous; only the first 6 prayer days, at most 30; none with `prayerCountdown` false (and `countdown: false`) or with no place; never overlapping; each `entry` is the entry in force at its start.
  - after Isha: Fajr next, `next` null, every strip cell `past`; after midnight the same prayer day as Home.
  - the texts in English and Arabic, Eastern and Western digits (`eastern` true only for Arabic with Eastern), 12 and 24 hour ("5:56 PM", "17:56"), "NEXT · MAKKAH" upper cased in English only, `reminder` null at 0 minutes, `barFromLabel` ending in "· prayed" only when that prayer is logged, "3 of 5 prayed today".
  - SC-006: the top level keys, `texts`' keys, every entry's, strip cell's and window's keys are exactly the lists of contracts/surface-data.md. No place gives `place: false`, empty `entries` and `countdowns`, `until` 0, and the texts.
  - two builds in the same stretch (16:32 and 16:50 on 15 Oct in Makkah) give the same JSON, one after Maghrib doesn't (R5's equal check).
- [X] T008 [P] Write `test/core/surfaces/write_surfaces_test.dart` with an in-memory store and a `FakeSurfacesChannel` it adds in `test/helpers/surfaces.dart` (records every call): one `update` with the builder's JSON for the store's settings, place and the current prayer day's marks, `force` passed through; no place hands the `place: false` JSON; a `PlatformException(code: 'surfaces_failed')` is reported once through a fake `CrashReporter.instance` with the reason `write surfaces` and nothing throws; the returned moment is the next window start or end after now, null when there's none.
- [X] T009 [P] Write `test/features/surfaces/presentation/surfaces_boot_test.dart` with the fake channel and a fixed clock: one `update` after launch; one 500 ms after a burst of changes (place, method, Asr method, Hijri adjustment, digits, reminder, `prayerCountdown`); one after a prayer is marked and one after it's unmarked; one after `resetPrayerJourney`; one after a restore (`restore` from `lib/core/backup/restore.dart`); one on resume; none at all in the design scenario.
- [X] T010 [P] Write `test/core/surfaces/backup_rules_test.dart` (SC-006): `android/app/src/main/AndroidManifest.xml` keeps `android:allowBackup="false"` and `android/app/src/main/res/xml/data_extraction_rules.xml` excludes all five domains (root, file, database, sharedpref, external) in both `cloud-backup` and `device-transfer`, so `surfaces.json` in `filesDir` never reaches a backup. The iOS exclusion is checked on the simulator (quickstart 2.11).

### Implementation for the foundation

- [X] T011 Schema 7 in `lib/core/database/app_database.dart`: add `prayerCountdown` as `boolean().withDefault(const Constant(true))()` after `azkarNudges` with a one-line `///` ("Countdown before each prayer"), `schemaVersion => 7`, `from6To7`: `addColumn(schema.settings, schema.settings.prayerCountdown)` (data-model.md: "add `prayerCountdown` with default true, nothing else changes"). The backup carries it with the settings row, nothing to change there. Run `dart run build_runner build` and `dart run drift_dev make-migrations`, keep `drift_schemas/app_database/drift_schema_v7.json`, the steps and `test/drift/app_database/generated/schema_v7.dart` in git, and add the v6 → v7 case to `test/drift/app_database/migration_test.dart` (every row kept, the new column reads true).
- [X] T012 [P] Add the strings to `lib/core/resources/strings_manager.dart` and both `assets/l10n/app_en.arb` and `assets/l10n/app_ar.arb`, wording exactly as FR-034 and R15: `surfaceNext` (NEXT / التالية), `surfaceNextCity` (NEXT · {city} / التالية · {city}), `surfaceNextShort` (Next · {city} / التالية · {city}), `nameTime` ({prayer} {time} in both), `nameTimePrayed` ({prayer} {time} · prayed / {prayer} {time} · صلّيت), `reminderChip` (Reminder {time} / تذكير {time}), `prayerCountdown` (Countdown before each prayer / العد التنازلي قبل كل صلاة), `prayerCountdownLine` (Starts 2 hours before, ends at the adhan / يبدأ قبل الصلاة بساعتين وينتهي عند الأذان), `countdownChannel` (Prayer countdown / العد التنازلي للصلاة), `openToSetPlace` (Open Better Muslim to set your place / افتح مسلم أفضل لتحديد مكانك), `openToUpdateTimes` (Open Better Muslim to update the times / افتح مسلم أفضل لتحديث المواقيت), `openApp` (Open Better Muslim / افتح مسلم أفضل). Reused as they are: `nextPrayer`, `liveNextPrayer`, `inDuration`, `atTime`, `prayedToday`, `nowShort`, `notifReminderBody` ({time} · {city}), `sunriseLabel`, `timeLeftSemantics`, the prayer and Hijri month names. The four gallery and picker texts go in the native files (T027, T028, T043). `strings_manager_test.dart` stays green.
- [X] T013 [P] Move the two texts the builder shares with other features into core (constitution IV, "Never two copies"): `hijriLineIn(HijriDate hijri, String month, {bool year = true})` ("4 Jumada I 1448") and `dateLineIn(DateTime date, String hijriLine, String language)` (English "EEE d MMM", Arabic the full weekday, then " · " and the Hijri line) out of `lib/features/home/view/widgets/date_line.dart` into `lib/core/extensions/time_format.dart`, digits left to the caller; and `AlertTexts.city`'s pick into `String nameIn(String language)` on `Location` in `lib/core/location/location.dart`. `DateLine` and `AlertTexts.city` call them and show exactly what they showed; the widgets that select the two names for rebuilds keep their own lines. Unit tests in `test/core/extensions/time_format_test.dart` and a new `test/core/location/location_test.dart`; the home and notifications tests stay green.
- [X] T014 Write `lib/core/surfaces/surface_data.dart`: `Map<String, Object?> buildSurfaceData({required DateTime now, required Location? location, required AppSettings settings, required Set<Prayer> prayed, required AppLocalizations l10n, required String language, required bool use24h})`, pure (no clock, no store, no riverpod), with a one-line `///` (the prayer rules stay in dart, the native side only picks and counts). The shape of contracts/surface-data.md:
  - `version` 1, `place`, `language`, `eastern` ("true only in Arabic with Eastern digits"), `countdown` (`settings.prayerCountdown`), `until` (the end of the 7th prayer day, the next prayer day's Fajr), `texts` (the contract's keys; the city from `Location.nameIn` (T013), upper cased in `nextCity` in English only; `methodLine` = the city · the picked method's name, or the country's).
  - day times through `dayTimesAt` with the settings' method, Asr method and Hijri adjustment for the prayer day before the first (Fajr's bar from last night's Isha), the 7 prayer days and the one after (the last Isha's next Fajr). The first prayer day from `prayerDayOf` as `topUp` finds it.
  - entries ("ascending `from`"): the first at the start of the stretch now is in (the last fajr, sunrise, dhuhr, asr, maghrib, isha or local midnight at or before now), then one at each of them before `until`. Nothing holds the write's moment, so two writes in the same stretch are equal and the plugin skips the second (R5). Each for its moment: `prayer` and `at` from `DayTimes.next`; `day` the prayer day in `CivilDate`'s SQL form like `Routes.prayerAt`; `strip` ("always 5, Fajr first", "times of a polar day without one are '—'", `logged` from `prayed` on the first prayer day only, `past` = before the next prayer in that day, all of them after Isha); `next` ("0 to 4, or null after Isha"); `barFrom` from `periodStart` ("null when the day has no such time"); `barFromLabel` (`nameTime` of the period's start prayer, `nameTimePrayed` when it's logged, `sunriseLabel` for Dhuhr); `sunrise` and `maghrib` of the local date (null when missing); `hijri`, `hijriCity` and `dateLine` from the local date through `hijriLineIn` and `dateLineIn` (T013, `dateLine` without the Hijri year); `prayedLine`; `reminder` ("null when the reminder is off", else `reminderChip` at the prayer time minus the minutes); `name`, `time`, `atTime`, `timeCity`, `nameTime` through `formatTimeIn` and `formatDigitsIn` the way `AlertTexts` uses them.
  - countdowns (research R10, "ascending `start`, at most 30 (6 days x 5)"): for each prayer with a time in the first 6 prayer days, `start` = the later of 2 hours before and the previous prayer's time (Fajr's previous is last night's Isha, Dhuhr's is Fajr, a prayer with no time is skipped and is no one's previous), `end` = the prayer time, `entry` = the index of the entry in force at the later of `start` and now. Windows already over are left out. None without a place or with the switch off.
  - no place: `place: false`, `entries` and `countdowns` empty, `until` 0, `texts` as usual.
- [X] T015 [P] Write `lib/core/surfaces/surfaces_channel.dart`: `SurfacesChannel` on `MethodChannel('better_muslim/surfaces')` with `Future<void> update(String json, {bool force = false})` and `Future<bool> startNow()` (contracts/surfaces-channel.md), and `surfacesChannelProvider` for the boot and the dev page.
- [X] T016 Write `lib/core/surfaces/write_surfaces.dart`: `Future<DateTime?> writeSurfaces(AppDatabase db, {required SurfacesChannel channel, required Locale locale, required bool use24h, required String? phoneZone, bool force = false, DateTime? now})` with the same reads as `topUp` (settings, `savedPlaceOf`, `locationOf`, the first prayer day, its five `isPrayed`), `initializeDateFormatting()` and `AppLocalizations.load(locale)` (the background has no date symbols), then `buildSurfaceData`, `jsonEncode`, `channel.update`. Returns the next window start or end after now for the boot's timer (US2). A `PlatformException` goes to `CrashReporter.instance.recordError` with the reason `write surfaces` and isn't rethrown. No riverpod, the background calls it too.
- [X] T017 Write `lib/features/surfaces/presentation/surfaces_boot.dart` on the shape of `NotificationsBoot` (research R5): `SurfacesBoot(child:)`, a `ConsumerStatefulWidget`, with a private `_surfaceInputsProvider` reading through `.select` the place (latitude, longitude, placeName, placeNameAr, zone name) and the settings (method, asrMethod, hijriAdjust, digits, reminderMinutes, prayerCountdown). It writes once after launch, on every resume (the language and 12/24 hour read again there), 500 ms after the last input change, and after every `prayer_log` table update (`TableUpdateQuery.onTableName('prayer_log')`: marking anywhere in the app, Reset prayer journey, Restore). One write at a time through a `_running` chain like `_reschedule`. Nothing in the design scenario, whatever calls it (FR-033). Wrap the app in `lib/bootstrap.dart`: `NotificationsBoot(child: SurfacesBoot(child: App()))`. Add the `FakeSurfacesChannel` override (T008) to `testOverrides` and `designOverrides` in `test/helpers/providers.dart`, so no existing test reaches the platform channel.
- [X] T018 [P] Android plugin, the data side, in `packages/prayer_surfaces/android/src/main/kotlin/com/elhawary/bettermuslim/surfaces/`: `SurfaceData.kt` (reads and writes `surfaces.json` in `filesDir`, atomic through a temp file and a rename; `update(json, force)` returns whether it wrote, equal content without `force` writes nothing; parses with `org.json`; the state, the entry in force, minutes left, h:mm with `eastern` digits, the bar share, the sun share, the spoken line and the next redraw moment exactly as contracts/native-surfaces.md) and `PrayerSurfacesPlugin.kt` (the channel: `update` calls `SurfaceData.update`, the widget refresh (US1) and the countdown sync (US2) add their calls after it; `startNow` returns false until US2; errors come back as `surfaces_failed` with only a short code as contracts/surfaces-channel.md says, never a path). `allowBackup="false"` and `data_extraction_rules.xml` already keep the file out of every backup (research R4).
- [X] T019 [P] iOS plugin, the data side, in `packages/prayer_surfaces/ios/prayer_surfaces/Sources/prayer_surfaces/PrayerSurfacesPlugin.swift`: the channel; `update` reads the group id from the `AppGroup` Info.plist key, writes `surfaces.json` into `containerURL(forSecurityApplicationGroupIdentifier:)` atomically with `.completeFileProtectionUntilFirstUserAuthentication` when it differs (or `force`), sets `isExcludedFromBackup = true` again after every write (an atomic write replaces the flag, research R4), and calls `WidgetCenter.shared.reloadAllTimelines()` only when it wrote; the countdown sync comes in US2; `startNow` returns false until US2; errors as `surfaces_failed` with the code only.
- [X] T020 [P] The extension's shared code in `ios/PrayerWidgets/`: `SurfaceData.swift` (`Decodable` structs for contracts/surface-data.md read from the group file; `state(at:)`: no file or `place` false → no place, `now >= until` or `version` above 1 → out of date, else ready; the entry in force, minutes left, h:mm with `eastern` digits, the bar share, the sun share, the spoken line and the next redraw moment as contracts/native-surfaces.md), `Timeline.swift` (a `TimelineProvider`: one entry per countdown minute for the next 6 hours aligned to the prayer time's seconds, one at every data entry's `from` and one at `until`, policy `.atEnd`; placeholder and snapshot from the file), `SurfaceColors.swift` (the dark Qiyam Emerald values of TOKENS.md and the trees' own values, one `static let` per role), `SurfaceFonts.swift` (the four families by name, the weight through the `wght` axis of a `UIFontDescriptor`, fixed sizes through `Font(uiFont)` so text size never grows a box; Reem Kufi for Marcellus and Noto Sans Arabic for Schibsted Grotesk when `language` is `ar`), `Assets.xcassets` (the 8 point star from the trees' polygon, `ui/check` and `outline/adhan` from `assets/icons/` as template vectors), and in both `Localizable.strings` the no file message with the arb's `openToSetPlace` wording (no file means the app hasn't written yet, so the text can't come from the data).

**Checkpoint**: T007 to T010 green, a launch on Android writes the file
(`adb shell run-as com.elhawary.bettermuslim.dev cat files/surfaces.json`), both builds pass.

---

## Phase 3: User Story 1 - The day on my home screen (Priority: P1) 🎯 MVP

**Goal**: The iOS small, medium and large widgets and the Android widget at 4 x 2, 2 x 2 and 4 x 1,
counting and moving on by themselves.

**Independent Test**: Dev on an iPhone: add the three widgets, each shows the next prayer and the
minutes left as Home. Mark Asr: the medium and large tick it within seconds. Airplane mode, close
the app, wait past the next prayer: they move on. Android: add the 4 x 2, resize to 2 x 2 and
4 x 1.

### Tests for User Story 1

- [X] T021 [P] [US1] Write `test/core/router/deep_link_test.dart` on the design scenario: a platform `pushRouteInformation` on `SystemChannels.navigation` with `bettermuslim://open/prayer?day=2026-10-15&prayer=maghrib` opens the Prayer tab on 15 Oct at Maghrib, `bettermuslim://open/` opens Home; while onboarding isn't done both still go to `/onboarding` (research R11).
- [X] T022 [P] [US1] Extend `test/features/notifications/presentation/dev_notifications_page_test.dart`: "Refresh widgets" calls the fake channel's `update` with `force: true`; it isn't on the page in the design scenario.

### Implementation for User Story 1

- [X] T023 [US1] Add "Refresh widgets" to `lib/features/notifications/presentation/view/dev_notifications_page.dart` as a `_Row` with an English `static const` label like the others, inside `if (!isScenario)` (FR-033): `writeSurfaces` with the app's store, `surfacesChannelProvider`, the phone's locale and 12/24 hour as the test notification row reads them, `phoneZoneProvider`, `force: true`.
- [X] T024 [P] [US1] Write `ios/PrayerWidgets/SmallWidget.swift` from the 5.6 small tree: the gradient background (iOS 17+ `containerBackground(for: .widget)` with `contentMarginsDisabled`, iOS 15 and 16 the same gradient as a background), the dashed arc, the solid arc up to the sun and the horizon line drawn left to right in Arabic too, the 14 pt sun with its glow at the sun share (by night the dashed arc only, as Home), `texts.next` (11, tracking .12em), the name (Marcellus 24), `texts.inDuration` with h:mm (15 semibold, tabular, gold), `timeCity` at the bottom (12), `widgetAccentable()` on the sun and the countdown, one accessibility element with the spoken line with the arc and sun hidden, `widgetURL` `bettermuslim://open/`. A long city is cut with an ellipsis, never the time.
- [X] T025 [P] [US1] Write `ios/PrayerWidgets/MediumWidget.swift` from the 5.6 medium tree: the header (name Marcellus 24, `hijriCity` 12, h:mm 22 semibold gold), the 5 cells (gap 4, radius 12, white at 5%), the `next` cell highlighted (gold at 20% with the 1 pt inset at 45%, its name gold semibold), the 10 pt check under each `logged` cell, nothing under the others, no highlight when `next` is null (FR-007); the cells in the language's direction (FR-026); each cell a `Link` to `bettermuslim://open/prayer?day={day}&prayer={prayer}`, the rest `widgetURL` Home (FR-023); `widgetAccentable()` on the highlight and the countdown; the spoken line.
- [X] T026 [P] [US1] Write `ios/PrayerWidgets/LargeWidget.swift` from the 5.6 large tree: the header (`texts.nextCity` 11 tracking .12em, name Marcellus 28, h:mm 24 semibold gold, `atTime` 12), five 40 pt rows (name Marcellus 17, time 15 medium, the 16 pt check when logged, else the 12 pt ring with a 1.2 pt stroke), the `next` row highlighted like the medium's cell with its name gold, no highlight when `next` is null, the footer (`prayedLine` and `dateLine`, 12.5, the hairline above) (FR-008); each row a `Link` to its prayer that takes in the 2 pt gaps around it (42 pt, the break approved in the spec's analyze session), the rest Home; `widgetAccentable()` and the spoken line as the medium.
- [X] T027 [US1] Fill `ios/PrayerWidgets/PrayerWidgetsBundle.swift`: "Next prayer" (`.systemSmall`) and "Today's prayers" (`.systemMedium`, `.systemLarge`) as `StaticConfiguration`s on the `Timeline.swift` provider, `layoutDirection` and `locale` from the data, their gallery names and descriptions from both `Localizable.strings` with FR-034's wording ("Next prayer" · "Next prayer with the sun on its arc.", "Today's prayers" · "All five, with the ones you prayed ticked.", and the Arabic). The Live Activity (US2) and the lock screen kind (US3) join the bundle later.
- [X] T028 [P] [US1] Android resources in `packages/prayer_surfaces/android/src/main/res/`: `values/surfaces_colors.xml` (the 5.8 tree's values and the dark Qiyam Emerald ones, named by role), `xml/prayer_widget_info.xml` (`targetCellWidth` 4, `targetCellHeight` 2, `minResizeWidth` and `minResizeHeight` down to 2 cells wide and 1 cell high, `resizeMode` both ways, `widgetCategory` home_screen, `updatePeriodMillis` 0, `initialLayout`, `description`), `layout/prayer_widget.xml` (a `FrameLayout` with the drawn `ImageView`, the countdown `ImageView` on top and 5 transparent click cells over the times row), `drawable/` vectors for the check and the star from the trees' polygon, and `values/strings.xml` with `values-ar/strings.xml`: the picker label and description of FR-034 ("Prayer times", "The next prayer and today's five times.", and the Arabic) and the no file message with the arb's `openToSetPlace` wording.
- [X] T029 [US1] Write `packages/prayer_surfaces/android/src/main/kotlin/com/elhawary/bettermuslim/surfaces/WidgetPainter.kt` (research R8, Q1): the 5.8 tree on a `Canvas` at the size the launcher reports. 4 x 2: the 84 high sky band with its gradient, `texts.nextCityShort` 12, the name Marcellus 26, h:mm 24 semibold gold, `atTime` 12; the times row (padding 8 10 10, gap 4, radius 16), past cells' name and time in the tree's dim color, the `next` cell on its gold tint with its name gold semibold, no highlight when `next` is null. 2 x 2: the sky band only. 4 x 1: the times row only. Fonts loaded once with `Typeface.Builder(context.assets, "flutter_assets/assets/fonts/…")` and `'wght'` variation settings, Reem Kufi and Noto Sans Arabic for `ar`; RTL mirrors the header and the row, clock times never; a long city cut with an ellipsis; the countdown in its own small bitmap so a minute redraws only that; sizes from the tree, never the phone's font scale (FR-029).
- [X] T030 [US1] Write `PrayerWidget.kt` (an `AppWidgetProvider`: `onUpdate`, `onAppWidgetOptionsChanged` and `refresh(context)` draw each widget at its size, 2 x 2 under 3 cells wide, 4 x 1 under 2 cells high, else 4 x 2 (FR-011); a minute redraws only the countdown with `partiallyUpdateAppWidget`; the root's `contentDescription` is the spoken line (FR-030); each prayer cell a `PendingIntent` to `bettermuslim://open/prayer?day=…&prayer=…`, the rest to `bettermuslim://open/`, both the package's launch intent with the URI as data so the singleTop `MainActivity` also gets it in `onNewIntent`), `SurfaceTicks.kt` (the non wakeup exact `RTC` alarm at the next redraw moment of contracts/native-surfaces.md, an inexact one without the exact alarm permission, armed only while a widget exists or a countdown shows) and `SurfacesReceiver.kt` (the tick redraws and re-arms; `BOOT_COMPLETED`, `MY_PACKAGE_REPLACED`, `TIME_SET` and `TIMEZONE_CHANGED` redraw and re-arm). Register the provider (label "Prayer times" from the strings, `prayer_widget_info`) and the receiver in the plugin's `AndroidManifest.xml`. `PrayerSurfacesPlugin.update` calls `PrayerWidget.refresh` when the file was written and re-arms the tick on every update.

**Checkpoint**: the widgets on both platforms show what Home shows and move on without the app.

---

## Phase 4: User Story 2 - A countdown before each prayer (Priority: P1)

**Goal**: The switch, the Live Activity with the Dynamic Island on iOS, the ongoing notification on
Android, and the dev row to start one.

**Independent Test**: Dev on an iPhone with the Dynamic Island: "Start countdown now", lock the
phone: the 5.3 card. Long press the island: 5.4 expanded. A timer in Clock: minimal. Mark the start
prayer: "· prayed". At the prayer time it goes. Android: the same with the ongoing notification.

### Tests for User Story 2

- [X] T031 [P] [US2] Extend `test/features/notifications/presentation/view/adhan_settings_page_test.dart`: a group under the reminder's holds "Countdown before each prayer" with "Starts 2 hours before, ends at the adhan", on by default; a tap writes `prayerCountdown` false with one selection haptic, another writes true; Arabic and text scale 2.0, nothing cut.
- [X] T032 [P] [US2] Extend `test/features/notifications/presentation/dev_notifications_page_test.dart`: "Start countdown now" calls the fake channel's `startNow`; it isn't on the page in the design scenario.
- [X] T033 [P] [US2] Extend `test/features/surfaces/presentation/surfaces_boot_test.dart`: with a window starting 10 minutes after the fixed clock, one `update` at its start and one at its end while the app stays open; no timer left after dispose.

### Implementation for User Story 2

- [X] T034 [P] [US2] Write `lib/features/notifications/presentation/view/widgets/countdown_row.dart`: `CountdownRow`, a `ToggleRow(title: StringsManager.prayerCountdown, subtitle: StringsManager.prayerCountdownLine)` on `settingsProvider.select((settings) => settings.value?.prayerCountdown ?? true)`, writing it through `updateSettings`. Add it in its own `GroupedSection` under the reminder's in `lib/features/notifications/presentation/view/adhan_settings_page.dart`, the same `RSizedBox.vertical(SpaceManager.s3)` gap between them (FR-013).
- [X] T035 [US2] Add the window timer to `lib/features/surfaces/presentation/surfaces_boot.dart` (research R5): after each write one `Timer` to the moment `writeSurfaces` returned, which writes again, so iOS 16.2 to 18 starts a countdown that begins while the app is open and an open app ends it at the adhan's second. Replaced on the next write, cancelled on dispose.
- [X] T036 [P] [US2] Write `PrayerCountdownAttributes` twice with the same name and fields (research R7: ActivityKit matches it by name and the extension can't link the plugin), in `packages/prayer_surfaces/ios/prayer_surfaces/Sources/prayer_surfaces/PrayerCountdownAttributes.swift` and `ios/PrayerWidgets/PrayerCountdownAttributes.swift`, iOS 16.2: the attributes `prayer` and `day`; a `ContentState` with the strings of contracts/surface-data.md "Countdown content" (`nextPrayer`, `liveNext`, `name`, `atTime`, `barFromLabel`, `nameTime`, `methodLine`, `reminder` optional, `now`), `language`, `eastern`, and the dates `barFrom` (optional) and `at`. A one-line `///` on each: the other copy must match.
- [X] T037 [US2] Write `ios/PrayerWidgets/CountdownActivity.swift` (research R7), an `ActivityConfiguration(for: PrayerCountdownAttributes.self)` added to `PrayerWidgetsBundle.swift` behind an iOS 16.2 availability check:
  - the 5.3 card: the 40 pt star tile (radius 11, the tree's radial gradient, the 23 pt star), `liveNext` 12.5, the name Marcellus 24, the countdown `Text(timerInterval: barFrom...at, countsDown: true)` 28 semibold tabular (FR-016), `atTime` 12.5, the bar as `ProgressView(timerInterval: barFrom...at, countsDown: false)` in gold on the 20% white track with no sun dot (Q2), no bar when `barFrom` is null (as Home), `barFromLabel` and `nameTime` under it at 12; the card's background as `activityBackgroundTint`.
  - stale (`context.isStale`, stale date = `at`): `now` in place of the countdown and the bar full, never below zero or stuck at 0:00:00 (FR-019).
  - the Dynamic Island (5.4): compact leading the 18 pt star, compact trailing the same h:mm:ss timer at 15 semibold (Q3), minimal the star, expanded the 30 pt star, `nextPrayer`, the name, the timer 26, `atTime`, the bar and labels as the card, `methodLine` and the `reminderChip` with `outline/adhan` 15 only when `reminder` isn't null (FR-017).
  - digits (Q4): `.environment(\.locale, …)` from `language` and `eastern` (`ar`, `ar@numbers=latn`, `en`). Check on the iOS simulator in Arabic with both digit settings whether the system timer follows it, and write what it does into research.md R7.
  - `layoutDirection` from `language`, the bar and the timer left to right; `widgetURL` `bettermuslim://open/`; read in the order prayer, countdown, time, place, the star and the bar hidden (R16).
- [X] T038 [US2] Add the countdown sync to `PrayerSurfacesPlugin.swift` (contracts/surfaces-channel.md "Sync"), on every `update` whether or not the file changed, iOS 16.2 and later:
  - end every activity whose `at` has passed or whose window isn't in the file, all of them when `countdown` or `place` is false (FR-019, FR-020)
  - update the running one's content when it changed (a mark gives "· prayed"), with the stale date at `at`
  - iOS 16.2 to 18: request the window covering now when none runs, the app is active and `ActivityAuthorizationInfo().areActivitiesEnabled` (FR-015, FR-021)
  - iOS 26 and later: also schedule the later windows not scheduled yet, in order, with their `start` date and an alert of the entry's `name`, `liveNext` and `silence.caf`, stopping at the first one iOS refuses
  - `startNow`: the next prayer's activity from now to its `at`, whatever the 2 hours, its end kept in `UserDefaults.standard` so the sync keeps it until then; false when Live Activities are off or the request throws.
- [X] T039 [P] [US2] Write `packages/prayer_surfaces/android/src/main/kotlin/com/elhawary/bettermuslim/surfaces/CountdownNotification.kt` (research R9): the `prayer_countdown` channel named `texts.channel`, `IMPORTANCE_LOW` (no sound, no vibration, no heads up), created or renamed on each sync; `sync(context)`: with notifications allowed and the channel on, post or update the ongoing notification of the window covering now (title `nameTime`, text `texts.liveNext`, `setWhen(at)`, `setUsesChronometer(true)`, `setChronometerCountDown(true)`, `setTimeoutAfter(at - now)`, only alert once, the small icon milestone 5's notifications use, the tap `bettermuslim://open/` through the launch intent, no actions (FR-022)), the bar with `setProgress` on Android 15 and before, on Android 16 and later a Live Update (`setRequestPromotedOngoing(true)`, `Notification.ProgressStyle` with the progress and the sun as the tracker icon, not colorized, no custom view, FR-018); cancel it when no window covers now. Add `POST_PROMOTED_NOTIFICATIONS` to the plugin's manifest.
- [X] T040 [US2] Add the window alarms to `SurfaceTicks.kt` and `SurfacesReceiver.kt`: an exact wakeup alarm (`setExactAndAllowWhileIdle`, `RTC_WAKEUP`) at the next window's start that syncs the countdown and arms the next one (Isha starting at Maghrib's second starts at once); the minute tick also moves the bar while a countdown shows; both re-armed on boot, update, time and zone changes. `PrayerSurfacesPlugin.update` calls `CountdownNotification.sync` on every update. `startNow` posts the next prayer's notification from now to its `at`, its end kept in a small file next to `surfaces.json` so a sync keeps it until then, and returns false without the permission or with the channel off (FR-021).
- [X] T041 [US2] Add "Start countdown now" to `lib/features/notifications/presentation/view/dev_notifications_page.dart` as a `_Row` inside `if (!isScenario)`: `ref.read(surfacesChannelProvider).startNow()` (FR-033).

**Checkpoint**: the countdown starts, follows the marks and ends at the adhan on both platforms.

---

## Phase 5: User Story 3 - The next prayer on my lock screen (Priority: P2)

**Goal**: The circular, rectangular and inline accessories.

**Independent Test**: Dev on an iPhone: add the three to the lock screen, they show the next prayer
and the time left as Home, tinted like the clock. Change the lock screen color: they follow.

- [X] T042 [P] [US3] Write `ios/PrayerWidgets/Accessories.swift` from the 5.7 tree, monochrome and tinted by the system (FR-010): circular (`AccessoryWidgetBackground`, the 5 pt ring of radius 31 in a 72 box from 12 o'clock at the bar share, the track at 28%, the 13 pt star and h:mm 15 semibold), rectangular (the 12 pt star with `nameTime` 15 semibold, `texts.inDuration` with h:mm 15 at 80%, `hijri` 13 at 66%), inline (the star with `nameTime`); white and its opacities only; the ring never mirrored; taps Home; the spoken line.
- [X] T043 [US3] Add the lock screen kind to `ios/PrayerWidgets/PrayerWidgetsBundle.swift`: a third `StaticConfiguration` "Next prayer" with `.accessoryCircular`, `.accessoryRectangular` and `.accessoryInline` from iOS 16, on the same timeline, with its own gallery text in both `Localizable.strings` ("Next prayer" · "The next prayer and the Hijri date.", and the Arabic). Its own kind because a kind has one description and FR-034 gives the lock screen its own (research R6).

**Checkpoint**: the accessories show what the widgets show.

---

## Phase 6: User Story 4 - Right even when I don't open the app (Priority: P2)

**Goal**: The background writes, and the no place and out of date states on every surface.

**Independent Test**: Dev with every widget added: Makkah → Istanbul, Umm al-Qura → Turkey, Western
digits, 12 hour: every surface follows within seconds. A fresh install before onboarding ends: the
no place state. The phone's date 8 days ahead: the out of date state.

### Tests for User Story 4

- [X] T044 [P] [US4] Extend `test/features/notifications/data/background_test.dart` with the fake channel: `markFromPayload(payload, db: db, surfaces: fake)` writes once after the mark, without `surfaces` it writes nothing (the app's boot does); `backgroundTopUp` (T045) writes the surfaces before the notification permission check, so a refused scheduler still gets one `update` and no schedule.

### Implementation for User Story 4

- [X] T045 [US4] In `lib/features/notifications/data/background.dart` (research R5, FR-002): add `SurfacesChannel? surfaces` to `markFromPayload` and `writeSurfaces` after the mark when it's given, passed as `SurfacesChannel()` from `onNotificationActionInBackground` and `markPrayedInBackground` (the in-app `_onTap` passes none, the boot's `prayer_log` listener writes there). Move the top-up task's body into `backgroundTopUp(db, {scheduler, surfaces, locale, use24h, phoneZone})`: `writeSurfaces` first, then the permission check and `topUp`, so the widgets keep 7 days with notifications refused. Each with the phone's locale, 12/24 hour and `PhoneZone.read()`.
- [X] T046 [US4] iOS no place and out of date states (FR-024, research R12): `ios/PrayerWidgets/MessageView.swift` draws the widget's frame and background with the star mark and the message (`texts.noPlace`, `texts.outdated`, or the no file `Localizable` string); the small, medium and large widgets and the rectangular accessory show it when `state(at:)` isn't ready, the inline shows `texts.open`, the circular the star alone. The timeline ends with an out of date entry at `until`. No countdown starts in either state (T038 already ends them).
- [X] T047 [US4] Android states in `WidgetPainter.kt`: the same frame, band background, star and message at every size (the times row holds the message alone at 4 x 1), the strings.xml message with no file; `SurfaceTicks.kt` arms a redraw at `until`.

**Checkpoint**: everything the spec asks for is built.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [X] T048 [P] Add the surfaces' text colors to `test/core/resources/contrast_test.dart` (FR-031): each text color of the 5.3, 5.4, 5.6 and 5.8 trees against what it sits on (each end of its gradient, a highlighted cell's tint over it, black under the Live Activity and the island), as literal colors from the trees in one `const` list with a one-line `///` saying they mirror `SurfaceColors.swift` and `surfaces_colors.xml`; at least 4.5:1, 3:1 from 24 pt. The accessories are tinted by the system and left out. If a pair fails, stop and tell me which; never change a tree value.
- [X] T049 Run the self check of the `adaptive-widgets` skill on every new and changed Dart file (`countdown_row.dart`, `adhan_settings_page.dart`, `dev_notifications_page.dart`, `surfaces_boot.dart`), `flutter test test/architecture_test.dart`, and fix every hit.
- [X] T050 Build iOS in all three flavors (`flutter build ios --no-codesign --flavor dev|staging|production` with each flavor's `-t` and dart define file) to catch a wrong configuration of the 9, and Android dev. Fix every error before going on.
- [X] T051 Run Dev on the iOS simulator (iOS 26) and an Android emulator (Android 16) long enough to see the file written and no crash at launch, check the Android file holds only the listed fields (quickstart 3.6) and the iOS one carries the backup exclusion (quickstart 2.11), then hand me quickstart.md sections 2 to 5 to run myself. No simulator walk through of the surfaces, no screenshots.
- [X] T052 Hand me the SC-007 check to run myself: `flutter run --profile --flavor dev -t lib/main_dev.dart --dart-define-from-file=dart_define/dev.json` on a mid range Android with the performance overlay, mark a prayer, change the method, relaunch: no frame over 16 ms from the write. If some are, note it for a follow up, don't tune it blind.
- [X] T053 Run `dart format --set-exit-if-changed lib test integration_test`, `flutter analyze` and `flutter test`, all clean.
- [X] T054 [P] Update the milestone list in `CLAUDE.md`: "11. Widgets and Live Activity: the iOS home widgets and lock screen accessories, the Android widget, the countdown before each prayer as a Live Activity with the Dynamic Island and as an Android ongoing notification, all fed by `packages/prayer_surfaces`. **Done, waiting for my review.**"
- [X] T055 Run `grep -rn "TODO(ahmed)" lib assets ios android packages pubspec.yaml` and list in the reply what I still have to supply, the app groups, extension ids and signing team from T006 first.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: T001 first, the constitution before any code. T003 before T005 and T006,
  T005 before T006.
- **Foundational (Phase 2)**: after Setup. Blocks every story.
- **US1 (Phase 3)**: after Phase 2. The MVP: the home screen widgets.
- **US2 (Phase 4)**: after Phase 2. T040 after T030 (it extends `SurfaceTicks.kt` and
  `SurfacesReceiver.kt`), T041 after T023 (same file), T037 after T027 (the bundle).
- **US3 (Phase 5)**: after Phase 2 and T027 (the bundle).
- **US4 (Phase 6)**: T044 and T045 after Phase 2. T046 after US1 and US3 (the widgets and the
  accessories it switches), T047 after T029.
- **Polish (Phase 7)**: after the stories.

### Inside Phase 2

- T007 to T010 (tests) before their code.
- T011, T012 and T013 before T014 (the builder reads the new column, the strings and the core
  texts), T015 alongside, then T016, then T017.
- T018, T019 and T020 touch other files and run alongside T011 to T017.

### Inside the stories

- US1: T021, T022 first. T023 after T016. T024 to T026 in parallel, then T027. T028, then T029,
  then T030.
- US2: T031 to T033 first. T034 in parallel with T036 and T039. T035 after T033. T037 and T038
  after T036. T040 after T039.
- US3: T042, then T043.
- US4: T044 first, then T045. T046 and T047 in parallel.

### Parallel Opportunities

- Phase 2: T007 to T010 together, then T012, T013, T015, T018, T019, T020 together beside T011
  and T014.
- US1: T021, T022 together; T024, T025, T026 and T028 together.
- US2: T031 to T033 together; T034, T036 and T039 together.
- US4: T046 and T047 together.
- Polish: T048 and T054 beside the rest.

## Parallel Example: Phase 2

```text
Task: "T012 strings"
Task: "T013 date line, Hijri line and city into core"
Task: "T015 SurfacesChannel"
Task: "T018 Android SurfaceData and plugin"
Task: "T019 iOS plugin file write"
Task: "T020 extension shared code"
```

## Parallel Example: User Story 1

```text
Task: "T024 small widget"
Task: "T025 medium widget"
Task: "T026 large widget"
Task: "T028 Android resources"
```

## Implementation Strategy


### MVP First (User Story 1)

1. Phase 1 (constitution, plugin, iOS target), then Phase 2 (the data on both platforms).
2. US1: the home screen widgets. Stop and check them on an iPhone and an Android phone in Dev.

### Incremental Delivery

1. US1 → the widgets.
2. US2 → the countdown, the switch and the dev row.
3. US3 → the lock screen accessories.
4. US4 → the background writes and the empty states.
5. Polish → checks, builds, CLAUDE.md, my to-do list. Then stop for my review (constitution
   workflow).
