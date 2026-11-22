# Implementation Plan: Milestone 7a, Quran Mushaf Reader

**Branch**: `feature/milestone-7`, cut when the build starts | **Date**: 2026-10-21 | **Spec**:
[spec.md](spec.md)

**Input**: Feature specification from `specs/003-milestone-7-quran/spec.md`

## Summary

The Madinah Mushaf a page at a time, with the Motion v2 parts it needs built first in core:
- **Motion phase**: `BmOilDrop` with its 400 / 600 ms gate, `BmContainerTransform` on the
  `animations` package, `BmStagger` and `BmSkeleton`, in `core/widgets/motion/` (R13).
- **Content**: QUL's Madinah V2 layout and QPC Hafs words, Sahih International and Al-Muyassar from
  Tanzil, turned by a tool into small per page and per surah json assets, all offline (R1, R8).
- **Page**: one render object lays a page's 15 lines out justified in Amiri Quran, keeps every
  word's rect for the hit test and paints the washes behind the glyphs (R2 to R4). Paper, cream
  and night palettes, Follow the sky from the prayer times (R5, R6). The Book leaf on a perspective
  transform with a spring release, or Slide (R7).
- **Ayah**: a detented sheet that lifts the page, the large detent with Tafsir, Translation and
  Notes, Copy, the share image (R14).
- **Recitation**: Alafasy from EveryAyah, checked files cached ahead, one `audio_service` handler
  with a gapless playlist for repeat, range and pause, lock screen controls, paused by calls and
  the adhan (R9 to R12).
- **Stored**: last read and reader choices in `settings`, `quran_bookmarks` and `quran_notes`,
  schema 10, carried by the backup file.

Two new packages, both approved: `animations` and `audio_service`, which replaces
`just_audio_background` because that one supports a single player and the app has two already
(R10).

## Technical Context

**Language/Version**: Dart 3.13, Flutter 3.47.5 stable. Kotlin for `MainActivity` and the
system channel, Swift for the system channel.

**Primary Dependencies**: already in: just_audio 0.10.6, audio_session 0.2.4, drift 2.35,
flutter_riverpod 3.4.3, go_router 18.1, share_plus 13.3, path_provider. New: `animations` ^3.0.0,
`audio_service` ^0.18.19. The tool uses `sqlite3` (already in through drift) and `dart:io`.

**Storage**: drift schema 10 (data-model.md). Read only json assets in `assets/quran/`
(contracts/quran-assets.md). Recitation files in Application Support, out of every backup.

**Testing**: unit tests for the assets (counts, order, source equality), the page layout (justify,
scale down, centered, hit test, washes per line part), the recitation queue (repeat, range,
pause, sleep, following, last read), the download checks (partial, wrong, full storage), the
store (bookmarks, notes, uniqueness), migration v9 → v10, Follow the sky periods, the loader gate.
Widget tests for 4.18, the reader with controls, the ayah sheet and detents, Saved, share and
display sheets, the motion widgets with reduce motion. One integration journey: open, turn, select,
bookmark, note, restart. Phones by quickstart.md.

**Target Platform**: iOS 15+, Android 8.0+ (minSdk 26), phones, tablets on the stretched phone
layout.

**Project Type**: mobile app

**Performance Goals**:
- a page laid out once (under 8 ms on a mid-range phone) and cached for the current page and its
  two neighbours; a turn only paints (SC-002)
- the page assets read on demand, about 3 KB each; the index once at start, about 40 KB
- the follow wash on the frame `currentIndexStream` changes (SC-003)
- transform and opacity only in the turn, the container transform and the stagger, each page in a
  `RepaintBoundary`, the loader repaints its own layer

**Constraints**:
- the text, layout, translation and tafsir work with no internet; only recitation files download
- the Quran glyphs are never recolored, overlapped, cropped or moved apart from the page itself;
  no control or sheet covers the text (the page lifts or recedes)
- no Material or Cupertino icons, every new icon from `_gen/kit.js` into `BmIcon`
- the reader's colors come from the page palette through `ThemeEnum` (R5)

**Scale/Scope**: 604 page assets, 114 surah assets, about 5 MB. About 30 Dart files in the feature,
6 in core motion, 3 in core quran, 1 tool, schema 10, about 70 strings in 2 languages, 9 icons.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Result |
| --- | --- | --- |
| I. Structure | `features/quran/` clean (data, domain, presentation), as listed. `core/quran/` holds the assets reader and last read because Home needs them. `core/widgets/motion/` for the Motion v2 pieces Zakat will reuse. `core/audio/audio_use.dart` so the adhan and the recitation never import each other. No feature imports another | pass |
| II. Design system | page palettes and oil colors in `lib/core/resources/design/` from the kit's values, read through new `ThemeEnum` roles. Text through the adaptive texts; the Mushaf glyphs are painted by the page render object with `GetRegularStyle(font: FontEnum.quran)` from `styles_manager.dart`, so no `TextStyle(` in the feature (R2). Sizes through the managers, a named entry for each reader-only value. Icons through `BmIcon`. Strings in both arbs | pass |
| III. Faithful | 4.18 to 4.31 built from 09 Quran and its `_gen/quran.js` (no tree exists), 4.07 from its tree. Cream has no values in the design: paper values with a `TODO(ahmed)` until it comes. Regular pages have no design: the 15 band rule (R2). The page as a whole turns, opens, recedes and peeks as designed, the glyphs never move on their own: approved 2026-10-21, written into principle III by T001 (FR-060) | pass with T001 |
| IV. Simplicity | one render object for the page instead of thousands of word widgets, one handler for audio, json assets instead of a second database, the system channel for keep screen on instead of a package | pass |
| V. Performance | see Performance Goals; `.select()` on every settings read; the page widget reads its own page | pass |
| VI. Tests | as in Testing; architecture and strings tests green | pass |
| VII. Privacy | bookmarks, notes, last read only in the encrypted store and the backup file; recitations out of iCloud and Android backup; a download sends only the file name | pass |
| VIII. Offline and free | all content shipped; recitation downloads are the allowed network use, cached after | pass |
| Stack | `animations` and `audio_service` aren't in the stack line. T001 adds them (MINOR, 3.7.0), both approved 2026-10-21 | pass with T001 |
| Handoff code | `lib/core/resources/design/` gains the page palettes, oil colors and `BmMotion.oilCycle` (1600 ms), nothing changed | pass |

**Post-design re-check**: still passes. Flags left for me: cream's values and a regular page from
the designer, the QUL downloads and licenses.

## Project Structure

### Documentation (this feature)

```text
specs/003-milestone-7-quran/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── quran-assets.md
│   ├── recitation.md
│   └── reader-routes.md
├── checklists/requirements.md
└── tasks.md            # /speckit-tasks
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── audio/audio_use.dart                      # none, recitation, adhan
│   ├── database/app_database.dart                # schema 10, two tables, settings columns
│   ├── quran/
│   │   ├── quran_assets.dart                     # index, pages, surah texts, pageOf(ayah)
│   │   ├── ayah_key.dart
│   │   └── last_read.dart                        # lastReadProvider, Home reads it too
│   ├── resources/
│   │   ├── design/bm_colors.dart                 # BmPagePalette paper, night, cream TODO, oil
│   │   ├── design/bm_motion.dart                 # oilCycle, loader delay and minimum
│   │   ├── design/bm_icons.dart                  # 9 new ui icons
│   │   ├── theme_manager.dart                    # page roles, oil roles
│   │   ├── dimensions_manager.dart  font_manager.dart  strings_manager.dart
│   ├── settings/quran.dart                       # PageColor, QuranLayout, PageTurn, RibbonColor
│   ├── router/app_router.dart                    # /quran/page/:page, /quran/saved
│   ├── system/system_channel.dart                # keepScreenOn
│   └── widgets/motion/
│       ├── oil_drop.dart                         # BmOilDrop + painter
│       ├── loader_gate.dart                      # 400 ms delay, 600 ms minimum, one at a time
│       ├── container_transform.dart              # BmContainerTransform on OpenContainer
│       ├── stagger.dart                          # BmStagger
│       └── skeleton.dart                         # BmSkeleton
└── features/
    ├── home/view/widgets/shortcuts_card.dart     # Continue reading from lastReadProvider
    ├── home/view/widgets/verse_card.dart         # opens its ayah
    ├── notifications/data/adhan_player.dart      # claims AudioUse.adhan
    ├── notifications/presentation/view/dev_notifications_page.dart   # Loader section
    ├── more/model/credits.dart                   # QUL, Tanzil texts, EveryAyah, Amiri Quran
    └── quran/
        ├── data/
        │   ├── quran_store.dart                  # bookmarks, notes, reader settings
        │   ├── recitation_files.dart             # download, check, cache, ahead
        │   └── audio_service_recitation.dart     # the handler
        ├── domain/
        │   ├── mushaf_page.dart                  # page, line, word
        │   ├── bookmark.dart  note.dart
        │   ├── recitation.dart                   # interface, state, queue rules
        └── presentation/
            ├── providers/                        # page, selection, chrome, recitation, saved
            └── view/
                ├── quran_page.dart               # 4.18
                ├── reader_page.dart              # 4.19 to 4.21, layouts
                ├── saved_page.dart               # 4.29
                └── widgets/
                    ├── mushaf_page_view.dart     # the render object
                    ├── page_turn.dart            # Book and Slide
                    ├── page_chrome.dart  scrubber.dart  mini_player.dart
                    ├── ayah_sheet.dart           # medium and large detents, page lift
                    ├── study_tabs.dart           # Tafsir, Translation, Notes
                    ├── recitation_sheet.dart     # 4.25
                    ├── share_sheet.dart  share_card.dart   # 4.30
                    ├── display_sheet.dart        # 4.31
                    ├── translation_view.dart     # 4.07 cells
                    ├── continue_card.dart  surah_index.dart  ribbon.dart
                    └── bookmark_menu.dart  note_editor.dart

tool/quran/build_quran.dart                       # sources → assets/quran/
assets/quran/                                     # index, pages, surahs, samples
assets/icons/ui/                                  # index, translate, words, copy, memorize,
                                                  # prev, spread, timer, chevron_down
android/app/src/main/AndroidManifest.xml          # audio service and receiver
android/.../MainActivity.kt                       # AudioServiceActivity, keepScreenOn
ios/Runner/AppDelegate.swift                      # keepScreenOn
pubspec.yaml                                      # animations, audio_service, assets/quran/
drift_schemas/app_database/drift_schema_v10.json

test/core/quran/  test/core/widgets/motion/  test/features/quran/
test/drift/app_database/migration_test.dart       # v9 → v10
integration_test/quran_journey_test.dart
```

**Structure Decision**: one Flutter app. Content and last read in `core/quran/` because Home uses
them, Motion v2 pieces in `core/widgets/motion/` because Zakat and later screens reuse them, the
rest in the clean `features/quran/`.

## Key Flows

1. **Open**: a row or the card → `BmContainerTransform` → `ReaderPage(page)`. The page provider
   reads `pages/NNN.json` (its neighbours too), the render object lays it out, keep screen on is
   set, the palette is the page's.
2. **Turn**: the drag drives the leaf, release springs it. On settle the index changes, last read
   is written (not while playing), the next neighbour is read.
3. **Select**: the hit test gives the ayah → selection provider → wash fades in, the sheet springs
   to medium and the page lifts by `max(0, ayahBottom + 24 - sheetTop)`.
4. **Play**: the handler claims `AudioUse.recitation`, asks the files for the first ayah (the
   loader gate runs if it takes over 400 ms), builds the playlist, plays. Each index change moves
   the follow wash, writes last read and, while following, turns the page when the ayah is on the
   next one. The files download the rest of the surah ahead.
5. **Interrupt**: a call or the adhan → pause; nothing resumes until I tap play.
6. **Isha**: the period provider changes → the palette crossfades over 1.8 s.

## Answered

Taken from my answers on 2026-10-21 (every recommendation):

- the 7a and 7b split, the Motion v2 phase first, only the parts 7a uses
- local only with the backup file, no sync
- Amiri Quran on the Mushaf lines until QCF V2
- Sahih International and Al-Muyassar in full, the rest sample with `TODO(ahmed)`
- Alafasy from EveryAyah with background play, no Cast
- `animations` for the container transform
- `audio_service` instead of `just_audio_background` (R10), the music audio session for all three
  players (R12)
- the page level motion approved against principle III with an amendment (FR-060)
- the 15 band rule for pages 3 to 604 until the designer sends a regular page

## Open, needs me

1. Cream's colors and a regular 15 line page from the designer (R5, R2). Until then paper's values
   and the 15 band rule, each with a `TODO(ahmed)`.
2. The QUL downloads and the license lines for QUL, Sahih International and Al-Muyassar (R1, R8),
   `TODO(ahmed)` in the tool.

## Complexity Tracking

No violations to justify.
