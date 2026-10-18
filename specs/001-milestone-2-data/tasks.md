---

description: "Tasks for milestone 2, data"
---

# Tasks: Milestone 2, Data

**Input**: Design documents from `specs/001-milestone-2-data/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Included. The spec's checking story (FR-027, clarification "unit tests plus a readout")
and constitution VI ask for unit tests on prayer times, the store and the location logic.

**Organization**: Grouped by user story, so each story can be built and checked on its own.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an unfinished task)
- **[Story]**: The user story the task belongs to (US1 to US6)

## Before starting

- Decided 2026-10-16: the design scenario shows the handoff's fixed times (R10), `path_provider`
  is approved (R17).
- Every UI file goes through the `adaptive-widgets` rules, and `flutter test test/architecture_test.dart`
  stays green.

---

## Phase 1: Setup

**Purpose**: Packages and build config

- [X] T001 Add to `pubspec.yaml`:
  - dependencies: `drift: ^2.35.2`, `drift_flutter: ^0.3.1`, `flutter_secure_storage: ^11.2.0`,
    `geolocator: ^14.1.1`, `adhan_dart: ^2.0.1`, `hijri: ^3.0.1`, `timezone: ^0.11.2`,
    `flutter_timezone: ^5.1.1`, and `path_provider: ^2.1.5`
  - dev_dependencies: `drift_dev` and `build_runner`
  - a top-level `hooks: user_defines: sqlite3: source: sqlite3mc` block
  - `assets/places/` under `flutter: assets:`

  Then run `flutter pub get`.
- [X] T002 [P] Add `tool/places/.cache/` to `.gitignore`.
- [X] T003 [P] Add `build.yaml` with drift_dev options: `databases: app_database: lib/core/database/app_database.dart`, `schema_dir: drift_schemas/`, `test_dir: test/drift/`.
- [X] T004 [P] Add a rule to `test/architecture_test.dart`: `'no network in the app, it is offline-first (FR-025)'` with `RegExp(r'package:(http|dio)/|\bHttpClient\(')`. The milestone 7 downloader will be the only allow-list entry.

---

## Phase 2: Foundational

**Purpose**: What every story stands on: the place list, the encrypted store, the clock, strings

**⚠️ CRITICAL**: No story work starts before this phase is done

- [X] T005 Write `tool/places/build_places.dart` following `contracts/places-asset.md`:
  - downloads over https from `https://download.geonames.org/export/dump/`: `cities1000.zip`,
    `admin1CodesASCII.txt`, `countryInfo.txt` and `alternateNamesV2.zip`, into `tool/places/.cache/` with `curl` and `unzip` through `Process.run`
  - keeps `isolanguage = ar` names: `isPreferredName` wins, `isHistoric` and `isColloquial` are
    skipped
  - checks every zone against `package:timezone/data/latest_all.dart` and fails on an unknown one
  - fails on a row with the wrong column count, a missing population or coordinates out of range
  - sorts places by population, biggest first
  - writes `assets/places/places.tsv.gz` with the `#geonames <date> CC BY 4.0`, `#zones`,
    `#countries`, `#regions` and `#places` sections
  - prints the place count and size, and fails above 8 MB
- [X] T006 Run `dart run tool/places/build_places.dart` and commit `assets/places/places.tsv.gz`. Also add `assets/places/LICENSE.txt` with the GeoNames CC BY 4.0 attribution (source, link, license link).
- [X] T007 [P] Create `lib/core/location/place.dart` with `Place` (fields as in data-model.md) and `lib/core/location/place_list.dart`:
  - `PlaceList.load()` reads the asset bytes and parses them in `Isolate.run`. Coordinates go into
    `Int32List` (×1e4), and each place gets its search key.
  - `placeListProvider` is a `FutureProvider.autoDispose<PlaceList>`.
- [X] T008 [P] Extend `lib/core/flavor/flavor_config.dart`:
  - `scenario` from `String.fromEnvironment('SCENARIO')`
  - `bool get isDesignScenario => flavor == Flavor.dev && scenario == 'design'`
  - `flavorProvider = Provider<FlavorConfig>` that throws unless overridden
- [X] T009 [P] Create `lib/core/clock/clock.dart`:
  - `clockProvider = Provider<DateTime Function()>((ref) => DateTime.now)`
  - `tickerProvider`, a `StreamProvider<DateTime>` that emits `clock()` every second
- [X] T010 [P] Create `lib/core/settings/settings.dart` with `enum LocationMode { auto, manual }` and `enum Digits { eastern, western }`. Create `lib/core/prayer_times/prayer_method.dart`:
  - `enum PrayerMethod { ummAlQura, egyptian, dubai, qatar, kuwait, turkiye, singapore, karachi, tehran, northAmerica, muslimWorldLeague }`
    with `forCountry(String code)`: SA ummAlQura; EG egyptian; AE dubai; QA qatar; KW kuwait; TR
    turkiye; SG, MY, ID singapore; PK, IN, BD karachi; IR tehran; US, CA northAmerica; everything
    else muslimWorldLeague
  - `CalculationParameters get parameters`, mapping to the adhan_dart presets (R9)
  - `enum AsrMethod { standard, hanafi }` with `forCountry`: hanafi for PK, IN, BD, standard
    elsewhere, and a `Madhab get madhab` getter
- [X] T011 [P] Create `lib/core/hijri/hijri_date.dart` with `HijriDate { day, month, year }` and `HijriDate.of(DateTime localDate, int adjust)` = `HijriCalendar.fromDate(localDate.add(Duration(days: adjust)))` (R12).
- [X] T012 [P] Create `lib/core/database/database_key.dart`:
  - `DatabaseKey.read()` returns the hex key, or null when there is none
  - `DatabaseKey.create()` writes 32 bytes from `Random.secure()` as hex and returns it
  - flutter_secure_storage with `IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device)`
    and default `AndroidOptions()`
- [X] T013 Create `lib/core/database/app_database.dart`, depends on T010 and T012:
  - the `Settings` table (`@DataClassName('AppSettings')`), one row with `id = 1`. Columns,
    defaults and rules exactly as in data-model.md:

    | Column | Type, default, rule |
    | --- | --- |
    | latitude | `real?`, "-90 to 90, null = no location yet" |
    | longitude | `real?`, "-180 to 180, set together with latitude" |
    | placeName, placeNameAr, regionName, regionNameAr | `text?` |
    | countryCode | `text?`, "ISO 3166-1 alpha-2" |
    | timeZone | `text?`, "IANA id of the place" |
    | locationMode | `textEnum<LocationMode>()?` |
    | method | `textEnum<PrayerMethod>()?`, "null = by country" |
    | asrMethod | `textEnum<AsrMethod>()?`, "null = by country" |
    | hijriAdjust | `int`, default 0, "-2 to 2, a check constraint keeps it there" |
    | digits | `textEnum<Digits>`, default eastern |
    | theme | `textEnum<BmThemeId>`, default qiyamEmerald |
    | themeMode | `textEnum<BmThemeMode>`, default followSky |
    | reduceMotion | default false |
    | haptics | default true |
    | uiSounds | default false |
    | storeResetPending | default false |

  - `AppDatabase.open()` uses `driftDatabase(name: 'better_muslim', native: DriftNativeOptions(databaseDirectory: getApplicationSupportDirectory, setup: (db) => db.execute("pragma key = '<key>'")))`
  - `AppDatabase.forTesting(QueryExecutor)`
  - `watchSettings()`, which inserts the default row when it is missing, and
    `updateSettings(SettingsCompanion)`
  - `databaseProvider` throws unless overridden

  Run `dart run build_runner build --delete-conflicting-outputs` and commit
  `lib/core/database/app_database.g.dart`.
- [X] T014 Add `settingsProvider = StreamProvider<AppSettings>` (from `watchSettings()`) in `lib/core/settings/settings.dart`.
- [X] T015 Update `lib/bootstrap.dart`:
  - `initializeTimeZones()` from `latest_all`
  - `await AppDatabase.open()`
  - `ProviderScope(overrides: [databaseProvider.overrideWithValue(db), flavorProvider.overrideWithValue(config)])`
  - a `LicenseRegistry` entry for `assets/places/LICENSE.txt`, next to `_fontLicenses`
- [X] T016 After T008 and T013, create `test/helpers/providers.dart` with `testOverrides()`: an in-memory `AppDatabase.forTesting(NativeDatabase.memory())` plus a dev `FlavorConfig`. Update `test/app_test.dart` so each `ProviderScope` uses it.
- [X] T017 After T014, create `lib/core/extensions/time_format.dart` with `context.formatTime(TZDateTime)`:
  - `DateFormat.Hm` when `MediaQuery.alwaysUse24HourFormatOf(context)`, else `DateFormat.jm`
  - Western digits become Eastern when the locale is Arabic and `digits == Digits.eastern` (FR-017a)

  Test it in `test/core/extensions/time_format_test.dart` for en 24h, en 12h, ar eastern and
  ar western.
- [X] T018 [P] Add keys to `lib/core/resources/strings_manager.dart`, `assets/l10n/app_en.arb` and `assets/l10n/app_ar.arb`, in the tone of the existing entries:
  - `methodUmmAlQura`, `methodEgyptian`, `methodDubai`, `methodQatar`, `methodKuwait`,
    `methodTurkiye`, `methodSingapore`, `methodKarachi`, `methodTehran`, `methodNorthAmerica`,
    `methodMuslimWorldLeague`
  - `asrStandard`, `asrHanafi`, `duha`
  - `hijriMonth1` to `hijriMonth12` (English "Jumada I" style as in the design)
  - `noLocationYet`
  - `manualSuffix` ("{city} · manual", matching `autoSuffix`)

  `strings_manager_test.dart` stays green.

**Checkpoint**: The store opens encrypted, the place list loads, and the app runs as before

---

## Phase 3: User Story 1 - Prayer times for where I am (Priority: P1) 🎯 MVP

**Goal**: Allow location once, get the place, the method by country, today's six times and the next
prayer, offline

**Independent Test**: Grant location with internet off, the dev readout shows the place, the method
and times that match the official timetable

### Tests for User Story 1

- [X] T019 [P] [US1] `test/core/prayer_times/prayer_method_test.dart`: every FR-010 row (including "everywhere else" for GB, FR, NG), FR-011 hanafi for PK, IN, BD and standard for SA, EG, US.
- [X] T020 [P] [US1] Save SC-002 fixtures in `test/fixtures/prayer_times/<city>.json`:
  - each fixture has `source`, `fetched` date, coordinates, zone, method and expected six times
  - Makkah: official Umm al-Qura where readable, else AlAdhan method 4. Istanbul: Diyanet.
  - Cairo, Karachi, Jakarta, Dubai, London, New York, Oslo: AlAdhan with the FR-010 method
  - dates: 15 Oct 2026 for all, the 2026 daylight saving switch days for London and New York,
    21 Jun 2026 for Oslo

  This is a dev-time download only, the tests read the files.
- [X] T021 [P] [US1] `test/core/prayer_times/day_times_test.dart`:
  - Makkah on 15 Oct 2026 gives 05:00 06:16 12:06 15:27 17:56 19:26 (R10)
  - every fixture is within 1 minute. A known gap (Diyanet, Kemenag offsets) is written in the
    fixture and reported, not hidden.
  - Umm al-Qura Isha is Maghrib + 120 on a Ramadan 1448 date and + 90 outside Ramadan
  - Tromsø on 21 Jun 2026 gives null for times off the local day
  - London in June still has Fajr and Isha (high latitude rule)
  - `periodAt`: Fajr until sunrise, Duha until Dhuhr, Isha before Fajr
  - `next`: after Fajr is Dhuhr, after Isha is tomorrow's Fajr
- [X] T022 [P] [US1] `test/core/location/place_list_test.dart` (nearest): the asset loads, Makkah coordinates name Makkah with its Arabic name, and a point at sea names the nearest listed place.
- [X] T023 [P] [US1] `test/core/location/location_controller_test.dart` with a fake `PositionSource`:
  - no location and permission granted: an auto location is saved with place, region, country and
    zone, and method and asrMethod stay null
  - denied: the location stays null, nothing is made up
  - timeout: the saved location stays
  - a method picked by the user stays after a fix in another country (FR-012)
  - no location data ever reaches `CrashReporter`

### Implementation for User Story 1

- [X] T024 [P] [US1] Create `lib/core/prayer_times/day_times.dart`:
  - `Prayer`, `Period` and `DayTimes` as in data-model.md
  - `DayTimes.compute(...)` takes the coordinates, local date, zone, method, asr method and
    `isRamadan`
  - it uses the adhan preset, the madhab and `HighLatitudeRule.recommended`, plus
    `adjustments[Prayer.isha] = 30` for ummAlQura in Ramadan, with `precision: false`
  - times go through `tz.TZDateTime.from`, and any time off the local day becomes null (R9)
  - `periodAt(now)` and `next(now, tomorrow)`
- [X] T025 [P] [US1] Add `PlaceList.nearest(lat, lng)` in `lib/core/location/place_list.dart`: equirectangular distance over the `Int32List` coordinates.
- [X] T026 [P] [US1] Create `lib/core/location/position_source.dart`:
  - `PositionSource` over geolocator: `permission()`, `request()` (while in use only)
  - `fix()` = `getCurrentPosition(locationSettings: LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 15)))`,
    falling back to `getLastKnownPosition()`, and returning null on timeout or no service
  - `positionSourceProvider` so tests can fake it
- [X] T027 [US1] Create `lib/core/location/location.dart`:
  - `Location` (data-model.md)
  - `phoneZoneProvider`, read with `FlutterTimezone.getLocalTimezone()` in bootstrap and on resume
  - `locationProvider`, built from `settingsProvider.select(...)`. It uses the phone zone in auto,
    the place zone in manual, and the place zone when the phone zone is unknown to `package:timezone`.
- [X] T028 [US1] Create `lib/core/location/location_controller.dart`:
  - `locationControllerProvider`. `refresh()` asks permission only when there is no decision yet,
    gets a fix, loads `placeListProvider`, calls `nearest`, and saves latitude, longitude, the
    place, region and country names, the zone and `LocationMode.auto` through `updateSettings`
  - nothing logged or reported carries coordinates or names (FR-025)
  - called once after the first frame, from `App` in `lib/core/app/app.dart`
  - extends `testOverrides()` in `test/helpers/providers.dart` with a fake `positionSourceProvider`
    (no permission, no fix), so `test/app_test.dart` never reaches geolocator
- [X] T029 [US1] Create `lib/core/prayer_times/prayer_times_providers.dart`:
  - `todayProvider`: the local date of the location's zone. A timer to the next local midnight
    makes it emit again.
  - `dayTimesProvider.family<DayTimes?, DateTime>`: effective method = `settings.method ?? PrayerMethod.forCountry(countryCode)`,
    and the same for Asr. `isRamadan` comes from `HijriDate.of(date, hijriAdjust).month == 9`.
  - `todayTimesProvider`
  - `periodProvider` and `nextPrayerProvider`, which follow `tickerProvider` and use tomorrow's
    times after Isha
- [X] T030 [P] [US1] iOS permission:
  - `NSLocationWhenInUseUsageDescription` in `ios/Runner/Info.plist`
  - `ios/Runner/en.lproj/InfoPlist.strings` and `ios/Runner/ar.lproj/InfoPlist.strings` worded
    from the `locBody` arb entries
  - add the `InfoPlist.strings` variant group to the Runner target resources in
    `ios/Runner.xcodeproj/project.pbxproj`
- [X] T031 [P] [US1] Add `<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>` to `android/app/src/main/AndroidManifest.xml` (coarse only, R8).
- [X] T032 [US1] Create `lib/features/home/view/widgets/dev_readout.dart` and show it from `lib/features/home/view/home_page.dart` only when `flavorProvider.select((f) => f.flavor == Flavor.dev)`. Each row is its own small widget class and watches one provider with `.select()`:
  - place with `autoSuffix`, using `placeNameAr` when the app is Arabic and the place has one
    (FR-003)
  - method name
  - Asr name
  - the six times through `context.formatTime`
  - current period
  - next prayer with time left from `tickerProvider`
  - `noLocationYet` when there is no location

  It uses only weight text widgets, adaptive paddings, `RSizedBox`, managers and `ThemeEnum`
  colors.
- [X] T033 [US1] `test/features/home/dev_readout_test.dart`: with overrides for Makkah and a fixed clock, it shows the six times and the next prayer in English, and in Arabic with Eastern digits and the Arabic place name. With no location it shows `noLocationYet`.

**Checkpoint**: US1 works on its own. Run quickstart §3 steps 1 to 4

---

## Phase 4: User Story 2 - Choose a city instead (Priority: P1)

**Goal**: Search a place by name in English or Arabic offline. A manual pick uses its own zone and
GPS never overrides it.

**Independent Test**: Permission denied, internet off: "Tanta" and "طنطا" find Tanta, picking it
gives Egyptian times

### Tests for User Story 2

- [X] T034 [P] [US2] Search cases in `test/core/location/place_list_test.dart`:
  - "tanta", "Tanta" and "طنطا" put Tanta, EG first
  - "مكة", "مكه" and "مَكَّة" find Makkah
  - "أسيوط" and "اسيوط" both find Asyut
  - "alexandria" lists the Egyptian one first, and results carry region and country so the US one
    can be told apart
  - at most 30 results, biggest first
  - 50 searches on the full list average under 100 ms
- [X] T035 [P] [US2] Manual cases in `test/core/location/location_controller_test.dart`:
  - `choose(place)` saves a manual location with the place's zone
  - `refresh()` does no fix while manual
  - picking New York while the phone is on Asia/Riyadh gives times in America/New_York
  - `useAuto()` goes back to GPS

### Implementation for User Story 2

- [X] T036 [US2] In `lib/core/location/place_list.dart`:
  - `normalizeArabic` (strip U+064B to U+0652, U+0670 and tatweel; أ إ آ ٱ → ا, ة → ه, ى → ي,
    ؤ → و, ئ → ي)
  - `PlaceList.search(query, {limit = 30})`: lower-case and normalize the query, scan in list order
    and stop at `limit`
- [X] T037 [US2] Add `choose(Place)` and `useAuto()` to `lib/core/location/location_controller.dart`. Make `refresh()` return early in manual mode (FR-006).
- [X] T038 [US2] Show `manualSuffix` in the readout's place row when manual, in `lib/features/home/view/widgets/dev_readout.dart`.

**Checkpoint**: US1 and US2 both work

---

## Phase 5: User Story 3 - My settings stay on this phone, protected (Priority: P2)

**Goal**: Settings survive restarts and updates, can't be read off the phone, and stay out of
backups. A broken store starts fresh and remembers it.

**Independent Test**: Change every setting, restart, all back. The copied file can't be opened
without the key.

### Tests for User Story 3

- [X] T039 [P] [US3] `test/core/database/app_database_test.dart`, on a temp file with a key:
  - a new store has the FR-020 defaults
  - every column survives close and reopen
  - `hijriAdjust` of 3 or -3 is rejected by the check constraint
  - `Value(null)` for method returns to "by country"
- [X] T040 [P] [US3] `test/core/database/encryption_test.dart`:
  - after saving placeName "Makkah" the file bytes don't contain it
  - opening without the key throws `SqliteException` with code 26
  - opening with the key reads it back
- [X] T041 [P] [US3] `test/core/database/store_reset_test.dart`:
  - an existing file with a missing or wrong key gives a fresh store with defaults and
    `storeResetPending == true`
  - a fake `CrashReporter` gets one error whose context is only `{'reason': ...}`, with no path and
    no values

### Implementation for User Story 3

- [X] T042 [US3] Store reset in `AppDatabase.open()` in `lib/core/database/app_database.dart` (R4):
  - probe query
  - on no key with an existing file, `SQLITE_NOTADB` or a failed probe: delete the file, `-wal`
    and `-shm`, call `DatabaseKey.create()`, open fresh, set `storeResetPending`
  - `CrashReporter.instance.recordError(error, stack, context: {'reason': reason})`
- [X] T043 [P] [US3] iOS backup exclusion:
  - a `better_muslim/backup` method channel with `exclude(path)` in `ios/Runner/AppDelegate.swift`,
    setting `URLResourceValues.isExcludedFromBackup = true`
  - `lib/core/database/backup_exclusion.dart`, called after `open()` on iOS for the store file
- [X] T044 [P] [US3] Android backups off:
  - `android:allowBackup="false"` and `android:dataExtractionRules="@xml/data_extraction_rules"`
    on `<application>` in `android/app/src/main/AndroidManifest.xml`
  - `android/app/src/main/res/xml/data_extraction_rules.xml` excluding every domain from
    `cloud-backup` and `device-transfer`
- [X] T045 [US3] Run `dart run drift_dev make-migrations`. Commit `drift_schemas/` (schema v1) and the generated `test/drift/` migration test (FR-022).

**Checkpoint**: US3 works on its own. Run quickstart §4

---

## Phase 6: User Story 4 - The Hijri date (Priority: P2)

**Goal**: The Umm al-Qura date with a ±2 day adjustment, in English and Arabic

**Independent Test**: 15 Oct 2026 = 4 Jumada I 1448. With +1 it is 5 Jumada I 1448.

### Tests for User Story 4

- [X] T046 [P] [US4] `test/core/hijri/hijri_date_test.dart`:
  - 15 Oct 2026 → 4/5/1448
  - 12 Oct 2026 → 1/5/1448
  - adjust +1 → 5/5/1448, and -2 and +2 work
  - the month key for 5 is `hijriMonth5`

### Implementation for User Story 4

- [X] T047 [US4] Add `hijriDateProvider.family<HijriDate, DateTime>` in `lib/core/hijri/hijri_date.dart`, reading `settingsProvider.select((s) => s.hijriAdjust)`.
- [X] T048 [US4] Add the Hijri row ("4 Jumada I 1448" with `hijriMonthN` and Eastern digits in Arabic) in `lib/features/home/view/widgets/dev_readout.dart`, plus a case in `test/features/home/dev_readout_test.dart`.

**Checkpoint**: US4 works

---

## Phase 7: User Story 5 - Times follow me when I travel (Priority: P3)

**Goal**: In auto mode, a move of 30 km or more updates the place and times on open or resume. Times
switch at midnight and on a zone change.

**Independent Test**: A fake fix 31 km away updates, 29 km doesn't

### Tests for User Story 5

- [X] T049 [P] [US5] Travel cases in `test/core/location/location_controller_test.dart`:
  - 31 km updates the place, the zone and, unless picked, the effective method
  - 29 km changes nothing
  - a second resume within 30 minutes does no fix
  - manual mode does no fix
- [X] T050 [P] [US5] `test/core/prayer_times/today_test.dart` with a fake clock: `todayProvider` and `todayTimesProvider` move to the next day after local midnight, and recompute when `phoneZoneProvider` changes. The Hijri date moves at the same midnight (FR-019).

### Implementation for User Story 5

- [X] T051 [US5] In `lib/core/location/location_controller.dart`:
  - the 30 km rule with `Geolocator.distanceBetween` ≥ 30000 m (FR-008)
  - an `AppLifecycleListener(onResume: ...)` that re-reads the phone zone, re-checks today's date (in case the clock was changed by hand)
    and calls `refresh()`,
    at most once per 30 minutes

**Checkpoint**: US5 works

---

## Phase 8: User Story 6 - Design scenario for checking screens (Priority: P3)

**Goal**: The "Dev · design scenario" run entry freezes Thu 15 Oct 2026 16:32 Makkah

**Independent Test**: The readout shows the handoff's six times, Maghrib next in 1:24:00, 4 Jumada I
1448, and nothing moves

### Tests for User Story 6

- [X] T052 [P] [US6] `test/core/flavor/design_scenario_test.dart`:
  - `isDesignScenario` is true only for dev with `SCENARIO=design`, false for staging and production
    with it
  - the overrides give the clock 2026-10-15T13:32:00Z, Makkah with Umm al-Qura and standard Asr,
    and the handoff's 04:58 06:15 12:05 15:27 17:56 19:26
  - next is Maghrib in 1:24:00, the Hijri date is 4 Jumada I 1448
  - `PositionSource` is never called

### Implementation for User Story 6

- [X] T053 [US6] Create `lib/core/flavor/design_scenario.dart` with `designScenarioOverrides`:
  - `clockProvider`, frozen
  - `locationProvider`: Makkah, `LocationMode.auto`, Asia/Riyadh
  - `todayTimesProvider` with the handoff's fixed times (R10)
  - `positionSourceProvider`, a no-op

  Add them in `lib/bootstrap.dart` when `config.isDesignScenario`.
- [X] T054 [P] [US6] Add a "Dev · design scenario" entry in `.vscode/launch.json` (toolArgs of Dev plus `--dart-define=SCENARIO=design`) and `.run/Dev_design_scenario.run.xml` (`additionalArgs` of Dev plus the same define).

**Checkpoint**: All six stories work

---

## Phase 9: Polish & Cross-Cutting Concerns

- [X] T055 Run `dart format --set-exit-if-changed lib test tool`, `flutter analyze` and `flutter test`, and fix everything. Run the adaptive-widgets self-check greps on `lib/features/home/view/` and `lib/core/extensions/time_format.dart`.
- [X] T056 Run `specs/001-milestone-2-data/quickstart.md` §2 to §4 on the iOS simulator and an Android emulator. Take screenshots of the readout on phone and tablet, dark and light, English and Arabic, normal Dev and the design scenario (constitution workflow).
- [X] T057 Measure with the steps in `specs/001-milestone-2-data/quickstart.md` and write in the milestone reply:
  - installed size growth from the place list (SC-008, ≤ 10 MB)
  - search time per key on a mid-range phone, naming the model (Pixel 6a or iPhone 12 class)
    (SC-004)
  - start-to-times with a saved location (SC-005, ≤ 1 s)
  - an airplane mode run (SC-003)
- [X] T058 [P] Add one line on rebuilding the place list (`dart run tool/places/build_places.dart`) to `README.md`.
- [X] T059 [P] Mark milestone 2 as "Done, waiting for my review." in `CLAUDE.md`.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: none.
- **Foundational (Phase 2)**: after Setup, blocks every story. T006 needs T005. T013 needs T010 and
  T012. T014, T015 and T016 need T013. T017 needs T014.
- **US1 (Phase 3)**: after Foundational.
- **US2 (Phase 4)**: after US1, since it extends `place_list.dart` and `location_controller.dart` and
  the readout.
- **US3 (Phase 5)**: after Foundational only. It can run alongside US1.
- **US4 (Phase 6)**: after Foundational. T048 needs the readout from T032.
- **US5 (Phase 7)**: after US1 (controller and providers).
- **US6 (Phase 8)**: after US1. T052 also checks the Hijri row from US4.
- **Polish (Phase 9)**: after all stories.

### Within Each Story

Tests first and failing, then models, providers, platform files, readout.

## Parallel Examples

```text
# Foundational, after T001 to T004:
T007 place_list.dart | T008 flavor_config.dart | T009 clock.dart | T010 enums | T011 hijri_date.dart | T012 database_key.dart | T018 strings

# US1 tests together:
T019 prayer_method_test | T020 fixtures | T021 day_times_test | T022 place_list_test | T023 location_controller_test

# US1 implementation together:
T024 day_times.dart | T025 nearest | T026 position_source.dart | T030 iOS plist | T031 Android manifest

# US3 next to US1:
T039 | T040 | T041 | T043 | T044
```

## Implementation Strategy

### MVP First (User Story 1)

1. Phase 1 and Phase 2.
2. Phase 3 (US1): times for the GPS position, readout on a phone, offline.
3. Stop and check with quickstart §3.

### Incremental Delivery

US1 → US2 (manual city) → US3 (protection, reset, backups) → US4 (Hijri) → US5 (travel) → US6
(design scenario) → Polish. Each step keeps the earlier ones green.
