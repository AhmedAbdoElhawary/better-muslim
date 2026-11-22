# Research: Milestone 2, Data

Everything below was checked on 2026-10-16 against pub.dev, the package sources in the pub cache,
and small probes run outside the repo.

## R1. Encrypted store

- **Decision**: drift 2.35.2 + drift_flutter 0.3.1 on sqlite3 3.7.1, with SQLite3MultipleCiphers
  picked by the sqlite3 build hook:

  ```yaml
  hooks:
    user_defines:
      sqlite3:
        source: sqlite3mc
  ```

  The key goes in with `pragma key` inside `DriftNativeOptions.setup`, which runs in drift's
  background isolate before any query.
- **Rationale**: one line of pubspec, no native setup. A probe on the Mac with the same versions
  showed `pragma cipher` = `chacha20`, no plaintext in the file, `file is not a database` without the
  key and the data back with it. The same hook builds for the host, so `flutter test` can check
  encryption for real.
- **Alternatives**: `sqlcipher_flutter_libs` (end of life, pub says move to sqlite3 3.x),
  `source: sqlcipher` (links OpenSSL on Android, older SQLite), encrypting single fields (every
  query gets harder), a plain database (turned down in the question round).
- **Note**: the hook downloads the prebuilt library from the sqlite3 GitHub release (sha256 checked)
  on the first build, CI needs network for that, it already has it. A change to native code means a
  full release, not a Shorebird patch.

## R2. Where the key lives

- **Decision**: flutter_secure_storage 11.2.0. Key = 32 bytes from `Random.secure()`, hex. iOS
  `KeychainAccessibility.first_unlock_this_device`, Android default options (AES-GCM,
  `resetOnError: true`).
- **Rationale**: `first_unlock` lets the milestone 5 background top-up read the key while the phone
  is locked. `this_device` keeps the key off other phones, which matches the store staying out of
  backups. `resetOnError` turns a broken Keystore into "no key", which lands in the store reset
  path (R4) instead of a crash.
- **Alternatives**: `unlocked` (background work fails while locked), `first_unlock` without
  `this_device` (the key would travel in an encrypted iCloud backup while the store does not).

## R3. Store file and backups

- **Decision**: the store lives in Application Support (`getApplicationSupportDirectory`, passed as
  `DriftNativeOptions.databaseDirectory`).
  - iOS: a small method channel in `AppDelegate.swift` sets `isExcludedFromBackup` on the file.
  - Android: `android:allowBackup="false"` plus `data_extraction_rules.xml` that excludes
    everything from cloud backup and device transfer. flutter_secure_storage's README asks for the
    same, a restored Keystore blob throws `Failed to unwrap key`.
- **Rationale**: drift_flutter's default folder is Documents, which iOS backs up and the Files app
  can show.
- **Alternatives**: Caches (iOS may purge it under low storage), a pub package for the exclude
  flag (none maintained enough for 15 lines of Swift).
- **Approved 2026-10-16**: `path_provider` as a direct dependency. It is flutter.dev's own package
  and already in the build through drift_flutter. It is now in the constitution's storage line.

## R4. When the store can't be opened

- **Decision**: `AppDatabase.open()` in bootstrap reads the key, opens the store and runs one probe
  query. Any of these starts fresh:
  - a store file exists but there is no key
  - `SqliteException` code 26 (`SQLITE_NOTADB`)
  - the probe fails

  Starting fresh means deleting the file (and its `-wal`, `-shm`), making a new key, opening an
  empty store and setting `storeResetPending = true`. The error is reported through
  `CrashReporter.instance.recordError` with `{'reason': ...}` only, never a path or a value from
  the store.
- **Rationale**: prayer times keep working, the user is told once later (FR-024), nothing personal
  reaches Sentry.

## R5. Place list format

- **Decision**: one gzip asset, `assets/places/places.tsv.gz`. Sections `#zones`, `#countries`,
  `#regions`, `#places`. Places are sorted by population, biggest first. The list is loaded only
  when needed (naming a new position, searching) with `Isolate.run`, and is dropped again when
  nothing listens.
- **Measured**: GeoNames `cities1000` today has 171,306 places in 392 time zones. The compact rows
  are 8.2 MB raw and 3.2 MB gzipped. Arabic names add an estimated 0.3 MB (about 32k places have an
  Arabic-script name). Installed growth is about 3.5 MB on both platforms, well inside SC-008.
- **Alternatives**: a prebuilt SQLite asset (about 12 MB raw, and Android has to copy it out of
  the APK, so 15+ MB installed, which breaks SC-008), FTS5 (bigger again), `geocoding` (turned down,
  needs internet), the 5k or 15k lists (turned down for coverage).

## R6. Building the place list

- **Decision**: `tool/places/build_places.dart`, run by hand when GeoNames should be refreshed.
  - Downloads `cities1000.zip`, `admin1CodesASCII.txt`, `countryInfo.txt` and
    `alternateNamesV2.zip` (205 MB) into `tool/places/.cache/` (git ignored), using `curl` and
    `unzip` through `Process.run`, so no new package.
  - Keeps `isolanguage = ar` names for places, regions and countries. Preferred names win, historic
    and colloquial names are skipped.
  - Checks every time zone against `package:timezone`.
  - Writes the asset.
- **Rationale**: Arabic names need `alternateNamesV2`. The plain `alternatenames` column has no
  language tags, so Urdu and Persian spellings (کراچی) would end up in the Arabic UI.
- **Credit**: CC BY 4.0. A `LicenseRegistry` entry next to the font licenses now, the visible credit
  line in More in milestone 9.

## R7. Search and nearest place

- **Decision**: each place carries one search key: lower-case ASCII name + Arabic name normalized.
  Normalizing strips harakat (U+064B to U+0652, U+0670) and tatweel, maps أ إ آ ٱ to ا, ة to ه, ى
  to ي, ؤ to و and ئ to ي. The query is normalized the same way. The search scans in population
  order and stops at 30 matches.

  Nearest place is a linear scan over `Int32List` coordinates (×1e4) with an equirectangular
  distance.
- **Rationale**: a scan of 171k short strings is about 10 ms in AOT code, and common names stop much
  earlier because big places come first. Nearest is about 2 ms. Both fit SC-004 without an index.
- **Alternatives**: a prefix index (only finds name starts, more code), a long-lived search isolate
  (not needed at these numbers).

## R8. Position

- **Decision**: geolocator 14.1.1.
  - `checkPermission` / `requestPermission` (while in use only).
  - `getCurrentPosition(locationSettings: LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 15)))`,
    falling back to `getLastKnownPosition`.
  - `distanceBetween` ≥ 30,000 m triggers an update.
  - Refresh on start (after the saved location is already in use) and on resume through
    `AppLifecycleListener`, at most once per 30 minutes.
  - Android declares `ACCESS_COARSE_LOCATION` only. iOS gets `NSLocationWhenInUseUsageDescription`
    in English and Arabic, worded from `locBody`.
- **Rationale**: a coarse fix (about 2 km) is plenty for prayer times. GPS works offline.
  Milestone 6 decides whether the Qibla needs fine location.
- **Alternatives**: background location (turned down), fine location now (not needed yet).

## R9. Prayer times

- **Decision**: adhan_dart 2.0.1. Every method in FR-010 exists as a `CalculationMethodParameters`
  preset:

  | FR-010 method | Preset |
  | --- | --- |
  | Umm al-Qura | `ummAlQura` |
  | Egyptian | `egyptian` |
  | Dubai | `dubai` |
  | Qatar | `qatar` |
  | Kuwait | `kuwait` |
  | Diyanet | `turkiye` |
  | Singapore | `singapore` |
  | Karachi | `karachi` |
  | Tehran | `tehran` |
  | ISNA | `northAmerica` |
  | Muslim World League | `muslimWorldLeague` |

  - Hanafi Asr is `Madhab.hanafi`.
  - The high latitude rule is `HighLatitudeRule.recommended(coordinates)`: seventh of the night
    above 48°, middle of the night below.
  - Umm al-Qura Ramadan: `adjustments[Prayer.isha] = 30` when the adjusted Hijri month is 9. The
    package README says to do exactly this.
  - Times come back in UTC and go through `tz.TZDateTime.from` with the location's zone. Rounding
    stays the preset's own (`precision: false`). Singapore rounds up.
- **Polar days**: the package does not return NaN. For Tromsø on 21 June it returned a Fajr on
  5 June and a Maghrib on 14 July. Any time more than 14 hours from that day's Dhuhr is treated
  as not available. A same-day check was tried first and dropped a real Isha after local
  midnight (northern Spain in summer, or a phone whose zone is far from its position).
- **Alternatives**: the AlAdhan API (network), prayer_time_plus (new, no users),
  `PolarCircleResolution.aqrabYaum` (always gives a time, the spec chose "not available").

## R10. Design scenario against real calculation

- **Measured** for Makkah on Thu 15 Oct 2026, Umm al-Qura, Asia/Riyadh:

  | Source | Fajr | Sunrise | Dhuhr | Asr | Maghrib | Isha |
  | --- | --- | --- | --- | --- | --- | --- |
  | handoff | 04:58 | 06:15 | 12:05 | 15:27 | 17:56 | 19:26 |
  | adhan_dart (Kaaba and GeoNames Makkah coordinates) | 05:00 | 06:16 | 12:06 | 15:27 | 17:56 | 19:26 |
  | AlAdhan API, method 4 | 05:00 | 06:16 | 12:06 | 15:27 | 17:56 | 19:26 |

  Two independent calculators agree. The handoff's Fajr, Sunrise and Dhuhr can't come out of a
  real calculation. Hijri matches: 15 Oct 2026 = 4 Jumada I 1448, and 1 Jumada I = 12 Oct 2026, so
  the check OVERVIEW asks for passes.
- **Decision (confirmed 2026-10-16)**: the design scenario uses the handoff's six times as
  fixed values, since it exists only for the PNG checks. Everything else, including every test of
  the calculation, uses adhan_dart. SC-001 holds as written. The real Makkah day is tested against
  the AlAdhan numbers above.
- **Alternative**: the scenario calculates too, and three numbers on the screens differ from the
  PNGs.

## R11. Time zones

- **Decision**: timezone 0.11.2 with `data/latest_all.dart`, initialized once in bootstrap. The
  adhan README warns that `latest.dart` lacks zones like `Europe/Oslo`. flutter_timezone 5.1.1
  `getLocalTimezone().identifier` for auto mode. Manual mode uses the place's zone. On resume the
  phone's zone is read again and times recompute if it changed. An unknown phone zone falls back to
  the place's zone.

## R12. Hijri date

- **Decision**: hijri 3.0.1, `HijriCalendar.fromDate(localDate.add(Duration(days: adjust)))`. Month
  names come from the arb files, not the package, so they follow the StringsManager rule.
  The table covers 1356 to 1500 AH.

## R13. Clock, ticking and midnight

- **Decision**: `clockProvider` returns `DateTime Function()`, `DateTime.now` by default.
  - A one-second ticker stream feeds the countdown.
  - The local day comes from a timer set to the next local midnight of the location's zone.
  - The design scenario overrides the clock with the fixed instant 2026-10-15 13:32 UTC (16:32
    Riyadh).
- **Alternatives**: `package:clock` (a new package for one function).

## R14. 12/24 hour and digits

- **Decision**: `MediaQuery.alwaysUse24HourFormatOf(context)` picks `DateFormat.Hm` or
  `DateFormat.jm` (intl is already a dependency). Then Western digits are mapped to Eastern when the
  locale is Arabic and the digits setting is eastern. Nothing in core does digits yet, so this is one
  small extension in `core/extensions/`.

## R15. Code generation and CI

- **Decision**: drift_dev + build_runner as dev dependencies. The generated `*.g.dart` files are
  committed, because `ci.yml` runs analyze and test without build_runner.
  `analysis_options.yaml` already excludes `**/*.g.dart`, and the architecture test already skips
  `*.g.dart`. `drift_dev make-migrations` stores the version 1 schema in
  `drift_schemas/`, so later layout changes get real migration tests (FR-022).

## R16. Reference times for SC-002

- **Decision**: SC-002 compares against an independent calculator with the same method, plus the
  official timetable where one is published. Fixtures are saved once as JSON in
  `test/fixtures/prayer_times/`, each with its source:
  - Makkah: the official Umm al-Qura calendar where it can be read, else AlAdhan method 4.
  - Istanbul: Diyanet's own site.
  - Cairo, Karachi, Jakarta, Dubai, London, New York, Oslo: AlAdhan with the method FR-010 picks.

  Dates: the scenario day, both daylight saving switch days for London and New York, and 21 June
  for Oslo. The tests run offline.
- **Risk**: Diyanet and Kemenag (Jakarta) add their own minute offsets, so they may sit more than
  1 minute from adhan's presets. Any such gap is written next to the fixture and reported instead
  of being forced to pass.

## R17. Packages

| Package | Version | In the constitution list | Use |
| --- | --- | --- | --- |
| drift | 2.35.2 | storage: drift | store |
| drift_flutter | 0.3.1 | part of drift | opens the store in a background isolate |
| flutter_secure_storage | 11.2.0 | yes | store key |
| geolocator | 14.1.1 | yes | position |
| adhan_dart | 2.0.1 | yes | prayer times |
| hijri | 3.0.1 | yes | Hijri date |
| timezone | 0.11.2 | yes | zones |
| flutter_timezone | 5.1.1 | yes | phone's zone |
| path_provider | 2.1.x | yes, approved 2026-10-16 | Application Support folder |
| drift_dev, build_runner (dev) | latest | yes, approved 2026-10-16 as part of drift | code generation |
