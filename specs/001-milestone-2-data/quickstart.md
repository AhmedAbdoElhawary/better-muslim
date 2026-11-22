# Quickstart: checking milestone 2

## Before

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # only after changing a table
```

The first build downloads SQLite3MultipleCiphers for each platform (needs network once).

## 1. Tests (all offline)

```bash
dart format --set-exit-if-changed lib test tool
flutter analyze
flutter test
```

Expected, among the rest:
- `test/core/prayer_times/` passes the FR-010 and FR-011 tables, the scenario day, the SC-002
  fixtures, Ramadan Isha and polar "not available".
- `test/core/hijri/` passes: 15 Oct 2026 = 4 Jumada I 1448, ±2 adjustment.
- `test/core/location/` passes search (English, Arabic with and without harakat and alef forms),
  nearest place and the 30 km rule.
- `test/core/database/` passes: settings survive reopening, the file has no plaintext and can't be
  opened without the key, and a lost key leads to a fresh store with `storeResetPending`.
- `test/architecture_test.dart` passes, including no `geocoding` import.

## 2. Design scenario

Run **Dev · design scenario** (VS Code or Android Studio), or:

```bash
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=dart_define/dev.json --dart-define=SCENARIO=design
```

The Home readout shows:
- Makkah · auto, Umm al-Qura, Standard Asr
- Fajr 04:58, Sunrise 06:15, Dhuhr 12:05, Asr 15:27, Maghrib 17:56, Isha 19:26
- Period Asr, next Maghrib in 1:24:00, not moving
- 4 Jumada I 1448

No location dialog. Arabic shows the same in Eastern digits.

## 3. Real phone, offline

1. Airplane mode on, location on.
2. Fresh install of **Dev**. The OS asks for location (while using), allow it.
3. The readout shows the nearest place, its method and today's times. Compare with the official
   timetable for that country.
4. Kill and reopen: the times show at once, before any new fix.
5. Deny location on a fresh install: the readout says there is no location yet, and nothing is made
   up.

## 4. Store is encrypted and out of backups

- iOS simulator: find `Library/Application Support/better_muslim.sqlite`, open it with `sqlite3`.
  Expected: `file is not a database`. `xattr -l` on it shows the backup exclusion.
- Android: `adb shell dumpsys backup` lists the app as not eligible, and `adb backup` gets no data.

## 5. Place list refresh (only when updating GeoNames)

```bash
dart run tool/places/build_places.dart
```

It downloads about 220 MB into `tool/places/.cache/` (git ignored) and rewrites
`assets/places/places.tsv.gz`. It prints the place count and size and fails above 8 MB.
