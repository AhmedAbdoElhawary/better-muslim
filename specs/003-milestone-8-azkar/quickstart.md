# Quickstart: checking milestone 8

## Before

```bash
flutter pub get
dart run build_runner build
```

share_plus is the one new package. build_runner regenerates the store for schema 4.

## 1. Tests (all offline)

```bash
dart format --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
```

Expected, among the rest:
- `test/core/azkar/`: the current set and the latest window at one minute before and after Fajr
  and Asr, after midnight, on a daylight saving day and after a zone change (SC-004). Progress
  `(done, total)` from counts, an unknown zikr id ignored. The shipped `azkar.json` follows
  `contracts/content-files.md`.
- `test/core/app/app_localizations_test.dart`: a message with two plurals formats both, Arabic 1,
  2, 3 to 10 and 11 or more.
- `test/drift/app_database/migration_test.dart`: v3 → v4 keeps every row and adds the defaults.
- `test/features/azkar/model/`: the tasbih and set state machines of data-model.md, 20 taps give
  20, never past the target.
- `test/features/azkar/view/`: Tasbih in the design scenario (SubhanAllah, 16 of 33), 17 taps to
  "Set complete", one more to Alhamdulillah 1, after Allahu Akbar back to SubhanAllah 1, a chip from
  0, reset with Undo, kept after a new ProviderScope. The set page opens at the first card not done,
  the tap after done moves on, a swipe doesn't count, "Set complete" once. The Azkar tab rows and
  the switch. Arabic, text scale 2.0, reduce motion.
- `test/features/duas/`: FR-019 for every chip, the empty Travel chip, search with and without
  diacritics, by transliteration, by "5095" and "٥٠٩٥", no results. Save, remove with Undo, the
  Saved chip and its empty state. Listen does nothing without a clip, with a fake player it plays,
  stops on a second dua and when the page isn't current. Share builds a PNG (a fake share call).
- `test/features/notifications/domain/schedule_test.dart`: the next 3 nudges at Fajr and Asr + 20
  min, none for a done window, none with the switch off, 60 + 3 at most.
- `test/features/notifications/domain/tap_target_test.dart`: an azkar payload gives
  `AzkarTarget`.
- `test/architecture_test.dart` and `strings_manager_test.dart` pass.

## 2. The design scenario

```bash
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=dart_define/dev.json \
  --dart-define=SCENARIO=design
```

(or "Dev · design scenario" in VS Code and Android Studio)

- Home (English): "Evening azkar · After Asr · 0 of 24". Tap it: the evening set at card 1 of 24.
- The Azkar tab has the badge until the evening set is opened.
- Azkar › Tasbih: as 4.08, SubhanAllah 16 of 33.
- More › Duas: as 4.14, All selected, Leaving the home on the card, the four rows with 1, 3, 2, 2.

## 3. On a phone (dev flavor)

- Count tasbih fast with the screen off to the side: every tap felt, no lag at the end.
- Read a set halfway, close the app, open it: the same card and counts.
- Save a dua, kill the app, open Duas › Saved: it's there.
- Share a dua: the share sheet shows the card. Check it in English and Arabic, dark and light (no
  design, FR-027).
- Nudges: notifications allowed, the switch on, wait for Fajr or Asr + 20 min with the app closed
  and the phone in airplane mode: a quiet notification, a tap opens the set. Finish the set first:
  no nudge. Switch off: none.
- Arabic: duas and zikr cards show the Arabic and the source only, Tasbih's chips are Arabic, the
  ring and beads don't mirror, Eastern digits.

## 4. What I check myself (no PNG)

The Azkar tab, the set page, the dua category page, the Saved chip, the empty states and the share
card, in dark and light, English and Arabic (FR-001, FR-006, FR-020, FR-027).
