# Implementation Plan: Enhancements after the review

**Branch**: `feature/enhancements` | **Date**: 2026-10-26 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/008-enhancements/spec.md`

## Summary

Four phases, each stopping for my review:

- **Phase A, quick fixes** (US1, US2):
  - the large title measures again when the direction changes (R1);
  - toasts go in an app-level overlay above the navigator (R2);
  - one core `Glass` for the app bar and the nav bar, with the body under the bar (R3);
  - dialogs blur their backdrop (R4);
  - the splash symbol is redrawn at 60% (R5);
  - the verse of the day comes from a date hash over the ayahs of 6 to 40 words (R6).
- **Phase B, share** (US3 to US5):
  - one share sheet in core for ayahs and duas, with ornament, solid and font (R7 to R9);
  - select mode for several ayahs, runs and dividers, and the fit steps (R10);
  - Ibn Kathir and As-Sa'di built by the tool, hosted on a release, downloaded with a sha256
    check (R15).
- **Phase C, reader** (US6 to US8):
  - the Android sharpness diagnosis and its fix (R11);
  - the font setting (R9, schema 11);
  - page palettes (R12);
  - the page curl shader (R13).
- **Phase D, Home arc** (US9, US10):
  - day and night points (R16);
  - the three star marker, the sun's rays and the wheel (R17).
- **Phase E, after D's review** (US5's hosting, US11, US12):
  - the tafsirs built from quran.com's api, hosted on the public `better-muslim-content` repo;
  - Home's compact bar with the next prayer, reusing `CompactAppBar` and `Countdown`;
  - the splash as vector on both platforms, `flutter_native_splash` removed;
  - the mushaf ink painted with no offscreen layer, S1 answered (T085, T089);
  - the android 12+ splash icon as an animated vector, a still one is stretched as a bitmap (T090).

One new font file from me (KFGQPC), one downloaded (Scheherazade New), one shader. Schema 11.
`crypto` becomes a direct dependency (P1).

## Technical Context

**Language/Version**: Dart 3.13, Flutter 3.47.5 stable, GLSL for the curl shader.

**Primary Dependencies**:
- Already in: flutter_riverpod 3.4.3, drift 2.35, flutter_svg 2.3, share_plus 13.3.1,
  path_provider. flutter_native_splash is removed in phase E.
- Flutter's own `BackdropFilter`, `Overlay`, `FragmentProgram`, `toImageSync`.
- New: `crypto` as a direct dependency (P1). It's already in the lock file.

**Storage**: drift, schema 11 (`quranFont`). Tafsir files on disk in Application Support,
outside backup.

**Testing**:
- Unit:
  - `verseOfDay` (stable for a date, changes the next day, always a candidate);
  - `DayTimes.lastThird`;
  - `arcPoints` (day, night, before sunrise, polar nulls);
  - the ayah runs and the footer;
  - the fit steps (scale → story → tafsir hidden → refused);
  - `TafsirFiles` (hash mismatch deletes `.part`, no Content-Length works, offline);
  - migration v10 → v11;
  - palette contrast ≥ 7:1.
- Widget:
  - LargeTitle after a locale flip;
  - a toast over an open sheet and over a dialog;
  - the nav bar with `extendBody` (the last row reachable);
  - the dialog's blur;
  - the share sheet (rows, solid hidden on solid backgrounds, the font applied, the note);
  - select mode (long press, toggle, Cancel, the bar's count);
  - the study tab download states;
  - the Display font row;
  - the arc labels at 1.0 and 2.0 in both languages.
- No goldens and no screenshots. The look, the curl, sharpness and the wheel are checked on the
  phones with quickstart.md.

**Target Platform**: iOS 15+, Android 8.0+ (minSdk 26).

**Project Type**: mobile app

**Performance Goals**:
- the curl at the phone's full refresh rate: one `toImageSync` per turn, the shader per frame,
  nothing rebuilt per frame;
- the nav bar's blur is one static backdrop layer;
- the verse pick needs one read of `index.json`, which is already loaded;
- a tafsir loads once per source while the reader is open.

**Constraints**:
- offline after the one tafsir download, which is https with a sha256 check;
- nothing about me leaves the phone;
- every new motion has its reduce-motion fallback, and Quran glyphs only move with the page;
- English and Arabic, text scale 1.0 and 2.0, 8 themes, both modes.

**Scale/Scope**:
- about 14 new Dart files and 40 changed;
- 1 shader, 2 fonts, schema 11;
- about 30 strings in 2 languages;
- 1 tool flag.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Result |
| --- | --- | --- |
| I. Structure | The share sheet, `Glass` and the toast host go into core, used by two features or more. Quran keeps the ayah painter, select mode and the tafsir files (clean: data has `tafsir_files.dart`). Duas keeps its painter. Home keeps the arc and the verse pick (MVVM). No feature imports another | pass |
| II. Design system | Colors from `getColor`, palettes and glass inside core. New sizes in the managers (`shareOrnamentOpacity`, `curlBackShade`, `arcPointDot`, ...), strings in `StringsManager` and both arbs, icons from `BmIcon` | pass |
| III. Faithful | Every break is in the spec's Approved breaks. What has no design (palettes, curl look, night marker, rays, wheel) is checked by me on the phone | pass with the approved breaks |
| IV. Simplicity | One share sheet instead of two. One glass. One fit function for the sheet and the add check. No page-curl package | pass |
| V. Performance | The curl samples one image per turn. The settled page has no transform or opacity layer. `.select()` on every new read | pass |
| VI. Tests | Every new piece of logic has a unit test, the screens get widget tests, the migration is tested | pass |
| VII. Privacy | Tafsir over https with sha256, stored outside backups. No data is sent | pass |
| VIII. Offline and free | The tafsirs are content downloaded once and cached. The host is this repo's free releases | pass |
| Stack | `crypto` (dart.dev, already in the lock file) as direct, approved in P1 | pass |

**Post-design re-check**: still passes. The fonts are assets, not packages.

## Project Structure

### Documentation (this feature)

```text
specs/008-enhancements/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── share-sheet.md
│   └── tafsir-files.md
├── checklists/requirements.md
└── tasks.md                    # /speckit-tasks
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── app/app.dart                                # app-level Overlay in builder (R2)
│   ├── database/app_database.dart                  # schema 11, quranFont
│   ├── settings/quran.dart                         # QuranFont, PageColor + sepia, green, navy
│   ├── prayer_times/day_times.dart                 # lastThird
│   ├── quran/quran_assets.dart                     # words per ayah, stale doc fixed
│   ├── resources/
│   │   ├── design/bm_colors.dart                   # page palettes
│   │   ├── font_manager.dart                       # quran font families
│   │   ├── dimensions_manager.dart                 # new sizes
│   │   └── strings_manager.dart                    # new keys
│   └── widgets/
│       ├── glass.dart                              # new
│       ├── compact_app_bar.dart                    # Glass, LargeTitle direction (R1)
│       ├── bm_dialog.dart                          # backdrop blur
│       ├── toast/toast.dart                        # overlay entry
│       ├── shell/app_shell.dart, nav_bar.dart      # extendBody, Glass
│       └── share/                                  # new: share_options, share_sheet, share_frame, swatch
└── features/
    ├── home/
    │   ├── model/home_moment.dart                  # ArcPoint, arcPoints, nightShare
    │   ├── model/verse_of_day.dart                 # new
    │   ├── model/home_samples.dart                 # verse constants removed
    │   ├── view_model/home_providers.dart          # arcPointsProvider, verseOfDayProvider
    │   └── view/widgets/sky_header*.dart, sky_labels.dart, verse_card.dart
    ├── quran/
    │   ├── data/tafsir_files.dart                  # new
    │   ├── data/recitation_files.dart              # Content-Length fix
    │   └── presentation/
    │       ├── providers/selection.dart            # chosen set, choosing
    │       └── view/
    │           ├── reader_page.dart                # long press, ChoosingBar
    │           └── widgets/
    │               ├── ayah_share.dart             # new, from share_card.dart
    │               ├── choosing_bar.dart           # new
    │               ├── mushaf_page_view.dart       # font, chosen wash
    │               ├── page_turn.dart              # curl, settled page without layers
    │               ├── display_sheet.dart          # font row, seven swatches
    │               ├── study_tabs.dart             # download chips
    │               └── translation_view.dart       # font
    │               # removed: share_sheet.dart, share_card.dart, swatch.dart (to core)
    ├── duas/view/
    │   ├── widgets/dua_share.dart                  # new, from share_card.dart
    │   └── share_dua.dart                          # removed, actions open the core sheet
    └── more/model/credits.dart                     # fonts and tafsir credits

shaders/page_curl.frag                              # new
tool/quran/build_quran.dart                         # --tafsir, words per ayah
assets/fonts/ScheherazadeNew-Regular.ttf, KfgqpcHafs.ttf
assets/app_icon/png/splash_symbol.png
assets/l10n/app_en.arb, app_ar.arb
drift_schemas/app_database/drift_schema_v11.json
```

**Structure Decision**: the same single Flutter app. The shared share sheet and the glass go to
core. Each feature changes only its own files.

## Key Flows

1. **Language switch**: settings → `MaterialApp.locale` → `Directionality` changes → every
   `LargeTitle` measures again on the next frame.
2. **Toast**: `showToast` → the root overlay (app level) → an entry above the navigator → slides
   out after `BmMotion.toast`.
3. **Choose and share**:
   - long press → choosing `{k}`;
   - each tap → `canAdd` check → toggle, or a toast;
   - Share → `showShareSheet(AyahShare(sorted))` → layout steps → preview → capture → share
     sheet → selection cleared.
4. **Tafsir pick**: not ready → download with progress → hash ok → rename → text. On a failure:
   delete `.part` and show a toast.
5. **Turn**: drag start → `toImageSync` → the shader follows the finger → release → spring →
   settle → the real page shows, and the image is disposed.
6. **Maghrib passes**: `arcPointsProvider` kind flips → the `turn` tween runs 1800 ms → the night
   arc is up.

## Answered (2026-10-26)

| # | Question | Answer |
| --- | --- | --- |
| P1 | `crypto` as a direct dependency for the tafsir sha256 | Yes, added in T047 |
| I1 | A single ayah too long for any card (analyze) | The first ayah is always accepted and shrinks below .7. Only additions are refused, FR-018 updated |
| I2 | The ayah's text source in core's `ShareOptions` (analyze) | Moved into `AyahShare`, core stays feature-free |
| U1 to U4 | Font glyphs, the wheel offscreen, nav bar contrast, curl profiling (analyze) | Phone check in quickstart C2, T074 skips offscreen, T004 checks contrast, quickstart C5 |
| S1 | What makes the Android page soft (T053) | The offscreen layer that tinted the ink (2026-10-27, `NO_INK_LAYER` was sharp on my Android 14). The text now carries its own ink, the layer only paints during an ink crossfade (T089) |
| C1 | Ornament 3:1 on every palette (T056) | Only on the new palettes. Paper and night stay as the designer made them |

## Complexity Tracking

| Addition | Why Needed | Simpler Alternative Rejected Because |
| --- | --- | --- |
| a fragment shader for the curl | a real bend needs per-pixel mapping (FR-028) | a package was declined, and a rotation isn't a curl |
| an app-level overlay | toasts must be above every route, including ones opened after the toast (FR-002) | the navigator's overlay puts later routes over the toast |
| a select mode in the reader | several ayahs from different pages (FR-015) | an "add ayah" button from the sheet was declined |
| a downloader with a hash | content from the network must be validated (principle VII) | shipping 30 to 40 MB in every install |
