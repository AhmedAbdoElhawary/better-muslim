---

description: "Tasks for the enhancements after the review"
---

# Tasks: Enhancements after the review

**Input**: Design documents from `specs/008-enhancements/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/share-sheet.md,
contracts/tafsir-files.md, quickstart.md

**Tests**: Included. Constitution VI asks for unit tests on logic and widget tests on screens, and
the spec's acceptance scenarios name the checks. Looks, the curl, sharpness and the wheel are
checked on the phones with quickstart.md (no goldens, no screenshots).

**Organization**: Five phases, each stopping for my review: A (US1, US2), B (US3, US4, US5), C
(US6, US7, US8), D (US9, US10), E (US5's hosting, US11, US12). Inside a phase, tasks are grouped by user story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an unfinished task)
- **[Story]**: The user story the task belongs to (US1 to US12)

## Before starting

- Branch `feature/enhancements`, and `.specify/feature.json` points at this folder.
- Dart files follow the `adaptive-widgets` and `flutter-design-craft` rules, and
  `flutter test test/architecture_test.dart` stays green after every task. New sizes go into the
  managers as named entries first. New strings go into `StringsManager` and both arbs together.
- Every new animation uses values from `BmMotion`, has a reduce-motion fallback through
  `MediaQuery.disableAnimationsOf(context)`, and can be interrupted.
- Quran glyphs only move with the whole page or card (constitution III).
- A string key nothing reads any more is removed in the task that removes its last reader.

---

## Phase 1: Setup

- [x] T001 Confirm the branch is `feature/enhancements`, `.specify/feature.json` points at `specs/008-enhancements`, and `flutter pub get`, `flutter analyze` and `flutter test` are green before any change.

---

# Phase A: quick fixes (US1, US2)

## Phase 2: User Story 1 - The shell behaves (Priority: P1) 🎯 MVP

**Goal**: The title follows the language, toasts are on top, the nav bar and dialogs are glass,
and the splash is sharp.

**Independent Test**: quickstart.md Phase A, steps 1 to 5.

### Tests for User Story 1

- [x] T002 [P] [US1] Widget test: pump a `LargeTitleScrollView` with a const `LargeTitle` under `Directionality(ltr)`, scroll to 0.5, flip to `rtl`, pump a frame, scroll again. The title's x moves toward the bar center from the right side. Add it to test/core/widgets/compact_app_bar_test.dart.
- [x] T003 [P] [US1] Widget test: open `showBmSheet` and then call `showToast` from inside the sheet. The toast's text is hit-testable and painted above the sheet (find it with `find.text` and check `tester.getRect` is inside the screen and the toast's ancestor overlay is the app-level one). Do the same with `showBmDialog`. Also check that a second toast replaces the first. In test/core/widgets/toast_test.dart.
- [x] T004 [P] [US1] Widget test: `AppShell` with a long `ListView` that uses `MediaQuery.paddingOf(context).bottom`. With `extendBody`, the last item scrolls fully above the nav bar, and a `BackdropFilter` is under the nav bar. In test/core/widgets/shell/app_shell_test.dart. Also, in test/core/resources/contrast_test.dart, check that the nav label colors (selected and not) meet AA against the surface at the bar's opacity, blended over the darkest and lightest sky color, in 8 themes × 2 modes (spec edge case).
- [x] T005 [P] [US1] Widget test: `showBmDialog` has a `BackdropFilter` whose sigma grows with the open animation and is 0 at the start. In test/core/widgets/bm_dialog_test.dart.

### Implementation for User Story 1

- [x] T006 [US1] In lib/core/widgets/compact_app_bar.dart `_LargeTitleState`, keep a `TextDirection? _direction`. In `didChangeDependencies` read `Directionality.of(context)`. If it differs from `_direction`, store it, set `_ends = null` and schedule `_measure` after the frame (R1).
- [x] T007 [US1] In lib/core/app/app.dart `builder`, wrap the existing child in an `Overlay(initialEntries: [OverlayEntry(builder: (_) => child)])` (an entry kept in state so it isn't rebuilt each time), so it's the app's outermost overlay (R2). `day_complete.dart`'s `rootOverlay: true` will then also draw above sheets, which is fine.
- [x] T008 [US1] Rewrite lib/core/widgets/toast/toast.dart so `showToast` keeps its signature and inserts one static `OverlayEntry` into `Overlay.of(context, rootOverlay: true)`. Move the current `SnackBar` content into a private `_Toast` widget with the same look:
  - it sits above the nav bar using the shell's nav height from `SizeManager`;
  - it slides in, then out after its current duration, with `BmMotion`;
  - with reduce motion it fades;
  - a new toast removes the old entry first;
  - the action button still works.
- [x] T009 [US1] Switch lib/features/more/view/widgets/reset_row.dart from `ScaffoldMessenger` to `showToast`, and remove the `/// todo:` above the toast in lib/features/quran/presentation/view/widgets/share_sheet.dart.
- [x] T010 [P] [US1] Create lib/core/widgets/glass.dart: `Glass({required child, double opacity = BmGlass...})`, which is `ClipRect` → `BackdropFilter(ImageFilter.blur(BmGlass.blurSigma))` → `ColoredBox(context.getColor(ThemeEnum.surface).withValues(alpha: opacity))`. Copy the recipe from `CompactAppBar` (`compact_app_bar.dart:46-66`).
- [x] T011 [US1] Make `CompactAppBar` use `Glass` in place of its inline blur, with no visual change, in lib/core/widgets/compact_app_bar.dart.
- [x] T012 [US1] In lib/core/widgets/shell/nav_bar.dart, replace the opaque `DecoratedBox` with `Glass`. Keep the top outline border. Choose the opacity by `topGlowProvider` (`.select`) like the app bar. In lib/core/widgets/shell/app_shell.dart, set `extendBody: true`.
- [x] T013 [US1] Walk the five tab roots (lib/features/home/view/home_page.dart, the prayer tab page under lib/features/prayer/presentation/view/, lib/features/quran/presentation/view/quran_page.dart, lib/features/azkar/view/azkar_page.dart, lib/features/more/view/more_page.dart) and every scroll view they end with. Where a list ends with a fixed bottom gap instead of `MediaQuery.paddingOf(context).bottom`, add the padding so the last row clears the glass bar (FR-003). Keep each change to the list's end padding.
- [x] T014 [US1] In lib/core/widgets/bm_dialog.dart `transitionBuilder`, put a `BackdropFilter(ImageFilter.blur(sigma: animation.value * SizeManager.sheetBlur))` behind the card, the same value as `bm_sheet.dart:95`. Reduce motion already turns the animation into a fade, so the blur fades with it.
- [x] T015 [US1] Re-render assets/app_icon/png/splash_symbol.png at 1152 × 1152 from assets/app_icon/splash_symbol.svg, with the symbol's box at 60% of the side, centered, on transparent, using `magick` (R5). Check the PNG by eye. If the strokes are wrong, leave the old file and add a `TODO(ahmed)` above `image:` in the `flutter_native_splash` block of pubspec.yaml. Then run `dart run flutter_native_splash:create`.

**Checkpoint**: US1 tests green, quickstart Phase A steps 1 to 5.

---

## Phase 3: User Story 2 - A verse for today (Priority: P2)

**Goal**: A different verse each day, the same on every phone.

**Independent Test**: quickstart.md Phase A, step 6.

### Tests for User Story 2

- [x] T016 [P] [US2] Unit test lib/features/home/model/verse_of_day.dart in test/features/home/model/verse_of_day_test.dart:
  - the same date gives the same key;
  - 30 dates in a row give no two equal neighbours;
  - the key is always in the candidates;
  - an empty candidate list throws.

### Implementation for User Story 2

- [x] T017 [US2] In tool/quran/build_quran.dart, write each surah's word count per ayah into assets/quran/index.json as `"words": [int, ...]`, counted from the QPC words (the ayah-number marker isn't counted). Run the tool and commit the regenerated index.json only.
- [x] T018 [US2] In lib/core/quran/quran_assets.dart:
  - read `words` into the surah index;
  - add `List<AyahKey> verseCandidates()`: every ayah with 6 ≤ words ≤ 40;
  - add `Future<String> ayahText(AyahKey)`: joins the ayah's words from `page(pageOf(key))`, and from the next page when the ayah continues there;
  - fix the stale "only page 1" comment at line 136.
- [x] T019 [US2] Create lib/features/home/model/verse_of_day.dart with `AyahKey verseOfDay(DateTime date, List<AyahKey> candidates)` (R6 hash: `(y*10000+m*100+d) * 2654435761 % 2^32 % length`).
- [x] T020 [US2] Add `verseOfDayProvider` in lib/features/home/view_model/home_providers.dart. It's a `FutureProvider` watching `todayProvider` and `quranAssetsProvider`, and returns the key, Arabic, translation (`surahText(surah).translation[ayah-1]`) and surah name.
- [x] T021 [US2] Make lib/features/home/view/widgets/verse_card.dart read `verseOfDayProvider` (`.select` per field). Show the existing skeleton while it loads and open the reader on the key. Remove the verse constants and their `TODO(ahmed)` from lib/features/home/model/home_samples.dart. Update test/features/home tests that read the sample verse.

**Checkpoint**: Phase A done. Run format, analyze and test. **Stop for my review.**

---

# Phase B: share (US3, US4, US5)

## Phase 4: Foundational for Phase B

**Purpose**: The shared sheet in core and the selection model. Both are needed by US3 to US5.

**⚠️ CRITICAL**: no Phase B story starts before this phase is done. P1 (`crypto`) is approved.

- [x] T022 Create lib/core/widgets/share/share_options.dart, with `ShareBackground` (moved from quran's share_card.dart unchanged, plus `Color solidOf()` returning the middle stop and `bool get isGradient`), `ShareSize` (moved), `ShareOrnament { khatam, starCross, arch }` with its asset path, and the `ShareOptions` record from data-model.md (`background` paper, `size` square, `sizeLocked` false, `solid` false, `ornament` null, `font` = reader font, `appName` true). No content-specific field goes in it (the ayah's text source lives in `AyahShare`).
- [x] T023 Create `QuranFont { amiri, kfgqpc, scheherazade }` with `family` getters in lib/core/settings/quran.dart, and add the family names to lib/core/resources/font_manager.dart. The `quranFont` setting itself comes in T058. Until then, the share default is `amiri`.
- [x] T024 Create lib/core/widgets/share/share_frame.dart:
  - the background fill (moved `ShareBackgroundFill`, honoring `solid`);
  - the ornament layer (`SvgPicture.asset`, `BoxFit.cover`, srcIn ornament color, at `SizeManager.shareOrnamentOpacity` .10);
  - the footer (symbol, app name, the content's footer line).

  Ornament color comes from each background's own light or dark (fixes the `dark != paper` rule).
- [x] T025 Create lib/core/widgets/share/share_sheet.dart per contracts/share-sheet.md:
  - `showShareSheet(context, {content, rows, ornaments})`;
  - the preview (as today's `_Preview`), the swatches (move quran's swatch.dart to lib/core/widgets/share/swatch.dart), size (sets `sizeLocked`), Solid color (hidden when `!background.isGradient`), Ornament with its picker, Font, app name, then the feature's `rows`;
  - the `ShareLayout.note` line under the preview;
  - the capture `toImage(pixelRatio: 1080 / width)` and `shareProvider`;
  - `MediaQuery.withNoTextScaling` and `AppTheme.page(background.page, themeId)` with the user's theme.
- [x] T026 Strip the C2PA metadata blocks from assets/ornaments/pattern_khatam.svg, pattern_star_cross.svg, frame_arch.svg and divider_section.svg, keeping the drawing. Check that each still renders in a quick widget test.
- [x] T027 Add the new sizes (`shareOrnamentOpacity`, the choosing bar's height, the note's gap) to lib/core/resources/dimensions_manager.dart. Add every Phase B string (Font, Ornament, Solid color, the pattern names, Share ({n}), Cancel if missing, "Tafsir hidden for {n} ayahs", "This ayah doesn't fit the image", Translation / Muyassar / Ibn Kathir / As-Sa'di, Download, Downloading, "Needs internet once", "Download failed") to lib/core/resources/strings_manager.dart and both arbs, in my tone.
- [x] T028 Change lib/features/quran/presentation/providers/selection.dart to the data-model.md shape `({AyahKey? sheet, Set<AyahKey> chosen, bool choosing})`, with `select(key)` (sheet), `startChoosing(key)`, `toggle(key)` (an empty set ends choosing), `clear()`. Update every reader of `selectionProvider` (reader_page.dart, ayah_sheet.dart, mushaf_page_view.dart via its caller) to `.select((s) => s.sheet)`.

### Tests for the foundation

- [x] T029 [P] Unit test the selection transitions in test/features/quran/presentation/selection_test.dart, and `ShareBackground.solidOf` / `isGradient` in test/core/widgets/share/share_options_test.dart.
- [x] T030 [P] Widget test the core sheet with a fake `ShareContent` in test/core/widgets/share/share_sheet_test.dart:
  - Solid color is hidden on a solid background;
  - a size tap locks the size;
  - the note shows;
  - the feature's rows are appended;
  - text scale 2.0 doesn't change the card.

---

## Phase 5: User Story 3 - Share several ayahs (Priority: P1)

**Goal**: Select mode, runs and dividers, the fit steps, the add warning.

**Independent Test**: quickstart.md Phase B, steps 1 to 3.

### Tests for User Story 3

- [x] T031 [P] [US3] Unit test the ayah layout in test/features/quran/presentation/ayah_share_test.dart:
  - runs: 2:255, 2:256, 2:257 and 3:18 give two runs;
  - footer: "Al-Baqarah 255–257 · Āl ʿImrān 18", and the Arabic form;
  - the fit order: scale down to .7, then story when not locked, then tafsir hidden from the last ayah back with `note`;
  - `canAdd(2:282, 2:283)` is false (the forgiving options still don't fit), and `canAdd` of a short ayah to a short one is true;
  - a single 2:282 with tafsir is accepted: tafsir hidden, story, and the scale goes below .7 until it fits (FR-018);
  - the ayah text is never cut.
- [x] T032 [P] [US3] Widget test select mode in test/features/quran/presentation/ayah_selection_test.dart:
  - a long press starts it with the ayah checked and no ayah sheet;
  - a tap toggles;
  - the bar reads "Share (n)";
  - Cancel and back clear it;
  - turning a page keeps the choices;
  - an ayah that can't fit with the chosen ones shows the toast and stays unchecked, and a long press on 2:282 alone always starts choosing.

### Implementation for User Story 3

- [x] T033 [US3] Create lib/features/quran/presentation/view/widgets/ayah_share.dart from today's share_card.dart `ShareText`, `_ShareText` and `_Footer`, as a `ShareContent` for `List<AyahKey>`:
  - sort the keys, group runs (same surah, ayah + 1);
  - each run is one paragraph with its ﴿n﴾ markers in the ornament color;
  - `divider_section.svg` goes between runs;
  - each ayah's text slot comes from `AyahShare.textSource` (`ShareTextSource`, kept in the content, not in core's `ShareOptions`);
  - the fit steps per R10 with `SizeManager.shareFit` cut to [1, .9, .8, .7]. For a single ayah that still doesn't fit, it keeps shrinking by .05 until it does;
  - `canAdd(chosen, key)`, which is skipped for the first ayah;
  - a tafsir longer than the space is cut at the last sentence end (`.`, `۔`, `؛`) that fits, plus "…".
- [x] T034 [US3] Replace quran's share_sheet.dart with a thin `showAyahShare(context, keys)` in the same file. It calls the core `showShareSheet` with `AyahShare(keys)` and the text picker row: Translation, Muyassar, Ibn Kathir, Sa'di. Not-ready sources show a download mark, wired in US5. The default is translation in English and Muyassar in Arabic. Delete the old share_card.dart and swatch.dart, and update the ayah sheet's share action to `showAyahShare(context, [ayah])`.
- [x] T035 [US3] In lib/features/quran/presentation/view/widgets/mushaf_page_view.dart (via its caller in reader_page.dart):
  - a long press on an ayah calls `startChoosing` instead of opening the sheet;
  - while choosing, a tap calls `toggle`. Adding to a non-empty selection first checks `canAdd` (toast `StringsManager.ayahDoesntFit` when false);
  - chosen ayahs paint with `selectionWash`.
- [x] T036 [US3] Create lib/features/quran/presentation/view/widgets/choosing_bar.dart, built from the dock's glass (`ReaderGlass`): "Share (n)" (`args: {'n': ...}`) and Cancel. Both are 44 pt or more, with `BmHaptics.select` on tap. In reader_page.dart, swap the dock for it while `choosing`, with an `AnimatedSwitcher` (crossfade with reduce motion). Back while choosing calls `clear()` (`PopScope`). Share calls `showAyahShare(sorted)` and then `clear()`.
- [x] T037 [US3] Update test/features/quran/presentation/share_sheet_test.dart and break_ui_test.dart for the new sheet and imports.

**Checkpoint**: US3 tests green, quickstart Phase B steps 1 to 3.

---

## Phase 6: User Story 4 - A share card that looks like mine (Priority: P2)

**Goal**: Font, ornament and solid work on ayahs, and duas use the same sheet.

**Independent Test**: quickstart.md Phase B, steps 4 and 5.

### Tests for User Story 4

- [x] T038 [P] [US4] Widget test in test/core/widgets/share/share_sheet_test.dart:
  - picking a font runs `layout` again with it;
  - ornament on draws one `SvgPicture` under the text, off draws none;
  - solid on a gradient fills with `solidOf()`.
- [x] T039 [P] [US4] Widget test the dua share in test/features/duas/view/dua_share_test.dart: Share opens the core sheet, `arch` is among the ornaments, and text scale 2.0 doesn't change the card.

### Implementation for User Story 4

- [x] T040 [US4] Download Scheherazade New v4.300 (OFL) from SIL's GitHub release into assets/fonts/ScheherazadeNew-Regular.ttf and register the `ScheherazadeNew` family in pubspec.yaml. Register a `KfgqpcHafs` family pointing at assets/fonts/KfgqpcHafs.ttf only once the file exists. Until then, add a `TODO(ahmed):` above the fonts block: "put KFGQPC Uthmanic Script Hafs (QUL's file) at assets/fonts/KfgqpcHafs.ttf and confirm its license, the kfgqpc font falls back to Amiri Quran until then". `QuranFont.kfgqpc.family` falls back to `AmiriQuran` when the asset is missing (one `const bool` in font_manager.dart that I flip).
- [x] T041 [US4] Make `AyahShare`'s Arabic painter use `options.font.family`. Ornament and solid come from the core frame with no ayah code.
- [x] T042 [US4] Create lib/features/duas/view/widgets/dua_share.dart, a `ShareContent` for a dua: Arabic (`options.font` for Quranic duas, `DuaText`'s font otherwise), translation and source, with the same fit steps minus tafsir. Footer: the dua's source. Delete lib/features/duas/view/share_dua.dart and the old lib/features/duas/view/widgets/share_card.dart. Make dua_actions.dart call `showShareSheet(context, content: DuaShare(dua), ornaments: [...ShareOrnament.patterns, ShareOrnament.arch])`.
- [x] T043 [US4] Add the Scheherazade New and KFGQPC credits to lib/features/more/model/credits.dart (Acknowledgements), in the existing entries' tone.

**Checkpoint**: US4 tests green, quickstart Phase B steps 4 and 5.

---

## Phase 7: User Story 5 - Ibn Kathir and As-Sa'di (Priority: P2)

**Goal**: Both tafsirs download once with a hash check and show in study and share.

**Independent Test**: quickstart.md Phase B, step 6.

### Tests for User Story 5

- [x] T044 [P] [US5] Unit test lib/features/quran/data/tafsir_files.dart with a fake `HttpClient` in test/features/quran/data/tafsir_files_test.dart:
  - a good body with the right hash is renamed and readable;
  - a wrong hash leaves no file and no `.part`;
  - no Content-Length works, with null progress;
  - a socket error throws `offline`;
  - a non-https url is refused;
  - cancel deletes `.part`;
  - `text` reads an ayah.
- [x] T045 [P] [US5] Unit test the Content-Length fix in test/features/quran/data/recitation_files_test.dart: a response with no length but a valid mp3 header is kept.
- [x] T046 [P] [US5] Widget test the study tabs in test/features/quran/presentation/study_tabs_test.dart: the Ibn Kathir chip shows its download mark, a tap shows progress then the text, offline shows the toast and stays on Muyassar.

### Implementation for User Story 5

- [x] T047 [US5] Add `crypto` to pubspec.yaml dependencies (the lock's version). Then add `--tafsir` to tool/quran/build_quran.dart per contracts/tafsir-files.md:
  - read QUL's exports from tool/quran/.cache/;
  - strip HTML and footnotes;
  - repeat grouped texts;
  - check the counts against index.json;
  - write build/tafsir/{ibn_kathir,saadi}.json.gz and print their sha256.

  Add a `TODO(ahmed):` at the top: "download QUL's Ibn Kathir (Arabic) and As-Sa'di exports into tool/quran/.cache/, run with --tafsir, upload build/tafsir/* to a tafsir-v1 release and paste the hashes into tafsir_files.dart".
- [x] T048 [US5] Create lib/features/quran/data/tafsir_files.dart per contracts/tafsir-files.md, modelled on recitation_files.dart:
  - `TafsirSource { muyassar, ibnKathir, saadi }` with url and sha256 constants, each under a `TODO(ahmed):` until uploaded;
  - https only, status 200, redirects followed;
  - streams to `.part` while hashing, renames on a match, deletes on any failure;
  - files in Application Support `tafsir/`, `BackupExclusion.exclude`;
  - `isReady`, `download`, `cancel`, `text`;
  - its provider in the quran feature's data providers.
- [x] T049 [US5] Fix lib/features/quran/data/recitation_files.dart so a missing Content-Length (`fetched.length == -1` or null) skips the length check and relies on the mp3 header check.
- [x] T050 [US5] Wire lib/features/quran/presentation/view/widgets/study_tabs.dart:
  - the Ibn Kathir and Sa'di chips lose "Coming soon";
  - not ready shows a download mark, a tap downloads with progress in the tab body (cancel shown), then the text;
  - offline or failed shows a toast and goes back to Muyassar.
- [x] T051 [US5] Wire the share text picker from T034 to `tafsirFiles`: picking a not-ready source starts the download with progress in the row, then the card lays out again with it.
- [x] T052 [US5] Add QUL's credit for Ibn Kathir and As-Sa'di to lib/features/more/model/credits.dart, and remove the `TODO(ahmed)` about them from tool/quran/build_quran.dart line 8 and the empty keys from assets/quran/samples.json if nothing reads them.

**Checkpoint**: Phase B done. Run format, analyze and test. **Stop for my review.**

---

# Phase C: reader (US6, US7, US8)

## Phase 8: User Story 6 - Sharp pages on Android (Priority: P1)

**Goal**: Find why the mushaf is soft on Android and fix it.

**Independent Test**: quickstart.md Phase C, step 1.

- [x] T053 [US6] Run the four comparisons of research R11 on my Android phone (I run them, you prepare the builds and a debug flag that removes the page's `CustomOpacity`). Write what each shows in plan.md under a new "Answered" table, row S1.
- [x] T054 [US6] Fix what S1 found in lib/features/quran/presentation/view/widgets/page_turn.dart. The expected fix: the settled current page builds with no `Transform` and no `CustomOpacity`, and both wrap it only while the controller moves. The controls' 0.84 shrink lays the page out at the smaller size if S1 points at the scale. Add a widget test in test/features/quran/presentation/page_turn_test.dart: at rest, no `Transform` or `Opacity` is above the current `_MushafPaper`.

---

## Phase 9: User Story 7 - My font and my page (Priority: P2)

**Goal**: A font setting and six page palettes.

**Independent Test**: quickstart.md Phase C, steps 2 and 3.

### Tests for User Story 7

- [x] T055 [P] [US7] Migration test v10 → v11 in test/drift/app_database/migration_test.dart: `quranFont` defaults to `amiri` and the old rows keep their values. Backup test in test/core/backup/backup_file_test.dart: a v10 backup restores with `amiri`.
- [x] T056 [P] [US7] Palette test in test/features/quran/presentation/page_color_test.dart: for each of the six palettes × 8 themes, ink on paper ≥ 7:1 and ornament on paper ≥ 3:1.
- [x] T057 [P] [US7] Widget test the Display sheet in test/features/quran/presentation/display_sheet_test.dart: the Font row writes `quranFont`, and seven swatches show.

### Implementation for User Story 7

- [x] T058 [US7] Schema 11 in lib/core/database/app_database.dart: add `quranFont` text with default `'amiri'` and `from10To11`, then run build_runner and `drift_dev schema dump` to drift_schemas/app_database/drift_schema_v11.json. Add the field to the backup file's settings.
- [x] T059 [US7] Read `quranFont` with a provider (`.select`) and pass its family to `RenderMushafPage` in lib/features/quran/presentation/view/widgets/mushaf_page_view.dart. A font change invalidates the measured words and lays out again. Do the same in translation_view.dart. Make the share default (`ShareOptions.font`) read it.
- [x] T060 [US7] Add the Font row (three choices, each name drawn in its own font) to lib/features/quran/presentation/view/widgets/display_sheet.dart.
- [x] T061 [US7] Add `sepia`, `green` and `navy` to `PageColor` in lib/core/settings/quran.dart. In lib/core/resources/design/bm_colors.dart, give `cream` its own base (removing the TODO at line 250) and add the three new bases (page, ink, ink2, ornament, ornamentSoft, gutter, dark flag for night and navy). Show seven swatches in display_sheet.dart `_pageColors`, and add the strings.

---

## Phase 10: User Story 8 - A real page turn (Priority: P3)

**Goal**: The curl shader for Book mode.

**Independent Test**: quickstart.md Phase C, step 4.

- [x] T062 [US8] Write shaders/page_curl.frag (R13). It takes uniforms for size, the corner point, the fold radius, the back color, the back shade and the shadow strength, plus one sampler for the page image. It maps points past the fold around the cylinder, draws the back as the paper color darkened by `curlBackShade`, and draws a soft shadow on the page underneath along the fold. Register it in pubspec.yaml under `shaders`. Load it the way the liquid glass does (`GlassProgram` pattern) in lib/features/quran/presentation/view/widgets/page_curl.dart.
- [x] T063 [US8] In page_turn.dart, Book mode:
  - on drag start take `toImageSync(pixelRatio: devicePixelRatio)` of the current page's boundary;
  - draw it through `PageCurl` while dragging or springing, with the corner point from the drag position and the controller value, and the real neighbour page underneath;
  - on settle dispose the image and show the real page.

  Remove the `rotateY` book transform and its `_tint`. Keep the spring, `completeShare`, `completeVelocity`, the rubber band and the haptics. Slide and reduce motion stay untouched. Add `curlBackShade` and `curlRadius` to dimensions_manager.dart. Check it in profile mode with the performance overlay (quickstart C5, SC-007).
- [x] T064 [US8] Update test/features/quran/presentation/page_turn_test.dart: Book mode keeps the same turn and fall back thresholds, the image is disposed after settle, and reduce motion still crossfades. The shader isn't loaded in tests, so a test-only fallback draws the image flat.

**Checkpoint**: Phase C done. Run format, analyze and test. **Stop for my review.**

---

# Phase D: Home arc (US9, US10)

## Phase 11: User Story 9 - The whole day on the arc (Priority: P1)

**Goal**: Four day points, five night points, and the three-star marker.

**Independent Test**: quickstart.md Phase D, steps 1, 2 and 4.

### Tests for User Story 9

- [x] T065 [P] [US9] Unit test in test/core/prayer_times/day_times_test.dart: `lastThird` for Makkah on 15 Oct 2026 equals fajr(16th) − (fajr(16th) − maghrib(15th)) / 3.
- [x] T066 [P] [US9] Unit test `arcPoints` and `nightShare` in test/features/home/model/home_moment_test.dart:
  - at 16:32 on the frozen day: day kind, four points with dhuhr at about .5;
  - at 23:00: night kind, five points in order, with the marker share between isha and last third;
  - at 05:00: night uses yesterday's maghrib and today's sunrise;
  - a null asr drops its point.
- [x] T067 [P] [US9] Widget test the labels in test/features/home/view/sky_header_test.dart: at text scale 1.0 and 2.0, English and Arabic, no two label rects overlap and all are inside the screen, and above 1.4 the middle labels show only the time.

### Implementation for User Story 9

- [x] T068 [US9] Add `DateTime? lastThird(DateTime? nextFajr)` to `DayTimes` in lib/core/prayer_times/day_times.dart.
- [x] T069 [US9] In lib/features/home/model/home_moment.dart, replace `arcLabels` with `ArcPoint` and `arcPoints(now, yesterday, today, tomorrow)` (R16), and add `nightShare`. In home_providers.dart, replace `arcLabelsProvider` with `arcPointsProvider`, and `sunShareProvider` with `markerShareProvider` (the day or night share). Add the strings Dhuhr, Asr and Last third if missing.
- [x] T070 [US9] In lib/features/home/view/widgets/sky_header_painter.dart:
  - draw a dot (`SizeManager.arcPointDot`) at each point's share;
  - draw the progress arc up to the marker by day and at night;
  - at night draw three small `mushafStar` stars in a triangle at the marker, each twinkling with `ambientBreathe` on 2100, 2700 and 3300 ms.

  Remove `BmSunArc`'s unused `fraction` and `sunCenter` only if nothing reads them.
- [x] T071 [US9] Rewrite lib/features/home/view/widgets/sky_labels.dart:
  - end labels keep today's spots under the horizon;
  - middle labels sit outside the arc along the point's normal (`SizeManager.arcLabelGap`);
  - above text scale 1.4, or when a label would overlap its neighbour, a middle label shows only the time;
  - clamped 14 pt inside the screen;
  - the arc is never mirrored, and digits follow the digit setting.
- [x] T072 [US9] Update home_page.dart's `_Sky` to the new providers and remove `arcLabels` users. Update the README night note's test expectations in test/features/home.

---

## Phase 12: User Story 10 - Day turns into night (Priority: P3)

**Goal**: The wheel and the sun's shine.

**Independent Test**: quickstart.md Phase D, steps 3 and 4.

- [x] T073 [P] [US10] Widget test in test/features/home/view/sky_header_test.dart:
  - a kind change runs the `turn` tween for 1800 ms, with nothing swapped in the first frame;
  - with reduce motion it's a 300 ms crossfade;
  - the rays and twinkle are off when the ambient loop is off.
- [x] T074 [US10] In sky_header.dart, add a `TweenAnimationBuilder` for `turn` on the arc kind, beside the sky tween: `BmMotion.skyChange` on `sacred`, and with reduce motion `standard` on linear. Pass `turn` and the outgoing points to the painter. When `TickerMode` is off (Home offscreen) the kind change jumps to the end with no tween, so coming back shows the new arc (spec edge case).
- [x] T075 [US10] In sky_header_painter.dart:
  - rotate the outgoing content by `π * turn` and the incoming one by `π * (turn - 1)` about the arc center, clipped above the horizon;
  - under reduce motion, crossfade them instead;
  - labels fade out in the first half and in during the second (sky_labels.dart takes `turn`);
  - sun: pulse 1 → 1.18, glow alpha .6, and twelve rays from `r*1.5` to `r*2.1` at `sun` .25, turning once per 60 s from the ambient elapsed time;
  - all of it is still when `elapsed` is null.

**Checkpoint**: Phase D done. Run format, analyze and test. **Stop for my review.**

---

## Phase 13: Polish & Cross-Cutting

- [x] T076 Run `/break-ui` on the share sheet (multi-ayah, 2:282, Arabic, 2.0) and on the Home arc (2.0, Arabic, polar null times), and fix what breaks.
- [x] T077 Update CLAUDE.md's milestone list with "13. Enhancements after the review (specs/008)" and its status, and my memory file.
- [x] T078 Run `dart format --set-exit-if-changed lib test`, `flutter analyze` and `flutter test`, and confirm `grep -rn "TODO(ahmed)"` lists only the expected new ones (KFGQPC, tafsir hosting and hashes, splash if any).

---

## Phase 14: Phase E - after phase D's review

**Goal**: Tafsirs that download, the next prayer in a Home bar, a vector splash.

- [x] T079 [US5] In tool/quran/build_quran.dart, build `--tafsir` from quran.com's api (Ibn Kathir 14, Sa'di 91), one cached request per surah, an ayah the api leaves out repeats the one before. Build build/tafsir/*.
- [x] T080 [US5] Point `TafsirSource.base` at `AhmedAbdoElhawary/better-muslim-content`'s `tafsir-v1` release and paste both sha256 values. Credit quran.com in credits.dart. Update contracts/tafsir-files.md.
- [ ] T081 [US5] Me: create the public repo and the release with both built files (the `TODO(ahmed)` in tafsir_files.dart has the commands), then download both on the phone.
- [x] T082 [US11] In home_page.dart, a `CompactAppBar` over Home with the next prayer's name and a `Countdown` at title size, its fill scroll linked from the card reaching the bar (or the last bar height of scroll), settling to either end, a tap to the top, the status bar following the theme while it shows. `Countdown` takes a `fontSize`.
- [x] T083 [P] [US11] Widget test in home_page_test.dart: scrolled to the end the bar has the name and countdown, a tap brings Home back up.
- [x] T084 [US12] Replace the splash bitmaps with android `drawable/splash_symbol.xml` (Android 12+ icon and the older layer-list) and an svg `LaunchImage` kept as vector on iOS, the star at 40%. Remove `flutter_native_splash` and its pubspec block.
- [x] T086 [US12] Splash strokes 1.8 → 2.9 (about 4 dp) in the drawable and both svgs.
- [x] T087 [US6] A `NO_INK_LAYER` define in mushaf_page_view.dart paints the ink with no offscreen layer (the text colored itself, relaid out when the ink changes).
- [x] T088 [US11] Replace the rising bar text with a flight: `CardFlight` on `NextPrayerCard` (keys, hidden while flying), `_FlyingPrayer` above the bar moving each part from the card to its slot, font crossfade from .7, glass from .7, snap over the whole flight. Tests for the flight and reduce motion.
- [x] T085 Me: run the four builds (as now, `NO_INK_LAYER`, `--no-enable-impeller`, both) on my Android 14 phone and tell which page is sharp. Then the sharpest way stays and the flags go.
- [x] T089 [US6] `NO_INK_LAYER` was sharp, so it's the default: the text is laid out in its own ink, the tint layer only paints while the ink crossfades and the page lays out once in the new ink 300 ms after it settles. `NO_INK_LAYER` and `OLD_PAGE_LAYERS` removed.
- [x] T090 [US12] The android 12+ splash still blurred: a still icon is drawn once into a bitmap and stretched, so `windowSplashScreenAnimatedIcon` is now `drawable/splash_symbol_animated.xml`, the vector with the 300 ms fade in, drawn as vector every frame.

**Checkpoint**: Phase E done. Run format, analyze and test. **Stop for my review.**

---

## Dependencies & Execution Order

- Phase A (T001 to T021) → review → Phase B (T022 to T052) → review → Phase C (T053 to T064) → review → Phase D (T065 to T075) → review → Polish → Phase E (T079 to T090) → review.
- Inside Phase A, US1 and US2 are independent.
- Phase B: T022 to T028 block US3 to US5. US4 depends on US3's `ayah_share.dart` (T033). US5's share picker (T051) depends on T034.
- Phase C: T053 (my device run) blocks T054. US7 is independent of US6. US8 depends on T054 (the settled page without layers).
- Phase D: US10 depends on US9's providers (T069).

## Parallel Opportunities

- Every test task marked [P] in a story can be written together before its implementation.
- In Phase A: T010 (glass) with T006 to T009. US2 (T016 to T021) alongside US1.
- In Phase B: T029 and T030 together. T044 to T046 together.
- In Phase D: T065 to T067 together.

## Implementation Strategy

1. Phase A first: small, visible and low risk. Stop for review.
2. Phase B: the core sheet first, then several ayahs (the biggest user value), then the look, then
   the tafsirs (which wait on my QUL download and hosting). Stop for review.
3. Phase C: diagnose before changing the page, then the font and palettes, the curl last. Stop for
   review.
4. Phase D: the points before the wheel. Stop for review.
