---
description: "Tasks for the finishing pass"
---

# Tasks: Finishing pass

**Input**: `specs/009-finishing/spec.md`, `plan.md`

## Phase 1: Reader speed (US1)

- [x] T001 [US1] `PageTurner` builds the shown page first, then one neighbour per frame, in
  `lib/features/quran/presentation/view/widgets/page_turn.dart`.
- [x] T002 [US1] `_Laid.of` measures each line once for the scale and each word once, in
  `mushaf_page_view.dart`.
- [x] T003 [US1] `QuranAssets.surahText` keeps the last three surahs, in
  `lib/core/quran/quran_assets.dart`.
- [ ] T004 [US1] Profile on my phone, decide the glass (waits for the phone).

## Phase 2: Font and size (US3, US4)

- [x] T005 [US4] Ship `assets/fonts/KfgqpcHafs.ttf`, turn `kfgqpcShipped` on, default `kfgqpc`,
  credit, tests' font loader.
- [x] T006 [US3] Schema 12: `mushafSize`, the `quranFont` default, `both` to `translation`,
  schema dump and migration test.
- [x] T007 [US3] `reflowMushaf` in `lib/features/quran/domain/mushaf_layout.dart` with unit tests.
- [x] T008 [US3] The render object takes the size: narrower below 100%, reflowed and as tall as
  its lines above it, in a scroll view in the reader. Sheet lift and follow scroll.
- [x] T009 [US3] The Mushaf size row in Display, strings in both arbs, widget test.

## Phase 3: Translation (US2)

- [x] T010 [US2] Remove `QuranLayout.both`, Translation is the page plus cells, Display's
  segmented control and the tests.

## Phase 4: Prayer calendar (US5)

- [x] T011 [US5] `DayDots` to `lib/core/widgets/day_dots.dart`.
- [x] T012 [US5] Calendar day fill and outline from `prayedProvider`, dots in the day details,
  widget tests.
- [x] T013 [US5] The Prayer header's calendar button, its string, a widget test.

## Phase 5: TODOs (US6)

- [x] T014 [US6] Listen on the Quran tab plays from the last read ayah, with a test.
- [x] T015 [US6] Dua after the adhan, `API_BASE_URL`, recitation source: remove the TODOs.
- [x] T016 [US6] The last notification when the iOS schedule runs out, with a test.
- [ ] T017 [US6] The welcome and sky scrims, unskip the contrast tests.
  Waits for me: AA needs about 52% black on the bright skies (28% today) and up to 48% on the
  light base skies that have none, not a slight change.
- [x] T018 [US6] Run the two `gh` commands for the tafsir release, remove the TODO.
- [x] T019 [US6] Azkar and duas Arabic and sources from Hisn al-Muslim, English stays TODO(ahmed).

## Polish

- [x] T020 `dart format`, `flutter analyze`, `flutter test` green.
