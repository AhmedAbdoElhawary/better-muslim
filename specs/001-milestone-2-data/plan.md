# Implementation Plan: Milestone 2, Data

**Branch**: `feature/milestone-2` | **Date**: 2026-10-16 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/001-milestone-2-data/spec.md`

## Summary

Everything lives in `core/`, because every later feature reads it:
- the place: GPS fix or a city picked by hand, named from a GeoNames list shipped in the app
- the six prayer times for that place, with the method by country
- the Hijri date
- all settings, in an encrypted drift store whose key is in the phone's secure store

Nothing touches the network. A dev-only readout on the Home placeholder and a frozen "design
scenario" run entry show it working. Unit tests prove the numbers.

## Technical Context

**Language/Version**: Dart 3.13, Flutter 3.47.5 stable

**Primary Dependencies**: flutter_riverpod 3.4 (already in), drift 2.35.2 + drift_flutter 0.3.1 on
sqlite3 3.7.1 with the `sqlite3mc` hook, flutter_secure_storage 11.2.0, geolocator 14.1.1, adhan_dart
2.0.1, hijri 3.0.1, timezone 0.11.2, flutter_timezone 5.1.1, path_provider 2.1 (approved, R17).
Dev: drift_dev, build_runner.

**Storage**: one encrypted SQLite file through drift in Application Support, out of iCloud and
Android backups. One read-only gzip asset for the place list.

**Testing**: flutter_test unit tests (logic and store on the host, with the real encrypted SQLite),
widget tests for the readout, the existing architecture test.

**Target Platform**: iOS 15+, Android 8.0+ (minSdk 26)

**Project Type**: mobile app

**Performance Goals**:
- times ready within 1 s of start with a saved location (SC-005)
- search under 100 ms per key (SC-004)
- the place list parses off the main isolate

**Constraints**:
- offline only
- no paid service
- no background location
- the place list adds ≤ 10 MB installed (measured about 3.5 MB)
- nothing personal in crash reports

**Scale/Scope**: 171k places, one settings row, 11 methods, 2 languages

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Result |
| --- | --- | --- |
| I. Structure | prayer times, location, Hijri, settings and store go in `core/`. The readout is in `features/home/view/widgets/` and reads core providers only. No feature imports another, core imports no feature | pass |
| II. Design system | the readout uses the weight text widgets, adaptive paddings, `RSizedBox`, managers, `ThemeEnum`. New strings go into `StringsManager` and both arb files (method names, Asr names, Duha, Hijri months, no-location, manual suffix), and later screens need them anyway | pass |
| III. Faithful | no designed screen is built or changed. The readout is dev-only and goes away in milestone 3. The scenario keeps the PNG moment (R10) | pass |
| IV. Simplicity | providers and plain classes, no repository interfaces, no new abstractions. Packages land in this milestone, the first that needs them. `path_provider` approved (R17) | pass |
| V. Performance | the place list loads lazily off the main isolate and is dropped when unused. Widgets use `.select()` | pass |
| VI. Tests | unit tests for times, methods, Hijri, search, the 30 km rule, the store and the reset. The architecture test still guards everything | pass |
| VII. Privacy | encrypted store, key in Keychain or Keystore, out of backups, no network, no personal data to Sentry | pass |
| VIII. Offline and free | no network at runtime. AlAdhan is used once at dev time for test fixtures only. GeoNames credited (LicenseRegistry now, More in milestone 9) | pass |
| Stack | drift encrypted with its key in secure storage, no geocoding, no shared_preferences | pass |

**Post-design re-check**: unchanged after Phase 1. No open items.

## Project Structure

### Documentation (this feature)

```text
specs/001-milestone-2-data/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── core-data.md
│   └── places-asset.md
└── tasks.md            # /speckit-tasks
```

### Source Code (repository root)

```text
lib/
├── bootstrap.dart                          # init zones, open store, ProviderScope overrides, scenario
├── core/
│   ├── clock/clock.dart                    # clockProvider, tickerProvider
│   ├── database/
│   │   ├── app_database.dart               # Settings table, open(), reset, updateSettings
│   │   ├── app_database.g.dart             # generated, committed
│   │   ├── database_key.dart               # key in flutter_secure_storage
│   │   └── backup_exclusion.dart           # iOS method channel call
│   ├── settings/settings.dart              # settingsProvider, enums (LocationMode, Digits)
│   ├── location/
│   │   ├── place.dart                      # Place
│   │   ├── place_list.dart                 # load, parse, search, nearest, Arabic normalize
│   │   ├── location.dart                   # Location, locationProvider
│   │   ├── position_source.dart            # geolocator wrapper, faked in tests
│   │   └── location_controller.dart        # refresh, 30 km rule, choose, useAuto, resume hook
│   ├── prayer_times/
│   │   ├── prayer_method.dart              # PrayerMethod, AsrMethod, forCountry, adhan presets
│   │   ├── day_times.dart                  # DayTimes, Prayer, Period, compute, polar check
│   │   └── prayer_times_providers.dart     # today, dayTimes, todayTimes, period, nextPrayer
│   ├── hijri/hijri_date.dart               # HijriDate, hijriDateProvider
│   ├── extensions/time_format.dart         # context.formatTime, Eastern digits
│   └── flavor/
│       ├── flavor_config.dart              # + scenario from SCENARIO dart-define, flavorProvider
│       └── design_scenario.dart            # overrides: frozen clock, Makkah, handoff times
└── features/home/view/
    ├── home_page.dart                      # shows DevReadout in dev
    └── widgets/dev_readout.dart            # temporary, removed in milestone 3

assets/places/places.tsv.gz                 # generated by the tool, committed
tool/places/build_places.dart               # GeoNames → asset
drift_schemas/                              # schema v1 dump for migration tests

ios/Runner/AppDelegate.swift                # backup exclusion channel
ios/Runner/Info.plist                       # NSLocationWhenInUseUsageDescription
ios/Runner/{en,ar}.lproj/InfoPlist.strings  # permission text in both languages
android/app/src/main/AndroidManifest.xml    # coarse location, backups off
android/app/src/main/res/xml/data_extraction_rules.xml

.vscode/launch.json, .run/Dev_design_scenario.run.xml   # "Dev · design scenario"

test/
├── core/prayer_times/  core/hijri/  core/location/  core/database/  core/flavor/
├── features/home/dev_readout_test.dart
├── fixtures/prayer_times/*.json            # SC-002 reference times with sources
└── app_test.dart                           # now overrides the store with an in-memory one
```

**Structure Decision**: one Flutter app. The new folders sit next to the existing `core/`
folders (app, extensions, flavor, monitoring, resources, router, widgets), one folder per concern.
That matches constitution I, which says these concerns go in `core/`.

## Key Flows

1. **Start**:
   - bootstrap initializes the zones and reads the key.
   - It opens the store, starting fresh on failure (R4).
   - It overrides `databaseProvider` and `flavorProvider`, and adds the design scenario overrides
     when the build is dev with `SCENARIO=design`.
   - `runApp`. The saved location gives times at once.
   - `locationControllerProvider` then refreshes in the background (R8).
2. **Fix**: the 30 km rule (FR-008). A move loads the place list, names the position, saves the place,
   region, country and zone, and leaves method and Asr null unless the user picked one.
3. **Times**: `dayTimesProvider(date)` = adhan preset for the effective method, with Asr, the high
   latitude rule from the latitude, and +30 min Isha in Ramadan for Umm al-Qura. The result goes into
   the location's zone, and times off the local day become null.
4. **Midnight, zone change, resume**: `todayProvider` changes, then everything downstream
   recomputes.

## Decisions (2026-10-16)

1. **Design scenario times (R10)**: real calculation gives Fajr 05:00, Sunrise 06:16, Dhuhr 12:06 for
   the scenario day, and the handoff shows 04:58, 06:15, 12:05. The scenario shows the handoff's
   values as fixed data, real calculation everywhere else.
2. **`path_provider`** is approved as a direct dependency (R17), and drift_dev and build_runner count
   as part of drift.

## Complexity Tracking

| Addition | Why Needed | Simpler Alternative Rejected Because |
| --- | --- | --- |
| iOS method channel (about 15 lines of Swift) | FR-023: the store must be out of iCloud backup | Caches folder can be purged; no maintained package for one flag |
| `tool/places/build_places.dart` | Arabic names and region names need GeoNames' alternate names joined at build time | building on the phone would ship 200 MB |
| committed `*.g.dart` | CI runs analyze and test without build_runner | adding build_runner to CI slows every run for one table |
