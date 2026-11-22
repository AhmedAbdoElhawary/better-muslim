---

description: "Tasks for milestone 7a, the Quran Mushaf reader"
---

# Tasks: Milestone 7a, Quran Mushaf Reader

**Input**: Design documents from `specs/003-milestone-7-quran/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/quran-assets.md,
contracts/recitation.md, contracts/reader-routes.md, quickstart.md

**Tests**: Included. Constitution VI asks for unit tests on logic and widget tests on screens, and
SC-001, SC-003, SC-005 and SC-006 are checked in tests. No goldens, no screenshots: I check the
screens on the phones with quickstart.md.

**Organization**: Grouped by user story (US0 to US7 in spec.md), so each can be built and checked on
its own.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an unfinished task)
- **[Story]**: The user story the task belongs to (US0 to US7)

## Before starting

- `audio_service` replaces `just_audio_background` (research R10), approved 2026-10-21. So are the
  page level motion (FR-060) and the 15 band rule for regular pages (research R2).
- Built on `feature/milestone-7`, cut from the reviewed milestone 12 work.
- Read `design_handoff_better_muslim/design/09 Quran.dc.html` in a browser, and
  `Living Sky prayer app branding 2/_gen/quran.js` and `_gen/kit.js` for the exact markup: sizes,
  gaps, radii, fonts and colors of 4.18 to 4.31 come from there (no `specs/screens` tree exists).
  4.07 comes from `design_handoff_better_muslim/specs/screens/4.07-quran-reader.md` (read
  `specs/HOW_TO_READ.md` first). Motion v2 values from `design/11 Motion v2.dc.html` and
  `_gen/motion.js`, `_gen/motion_logic.js`.
- Every value that isn't in a manager yet gets a named entry first (`SpaceManager.mushafLine`, ...).
  Widget code follows the `adaptive-widgets` and `flutter-design-craft` skills, and
  `flutter test test/architecture_test.dart` stays green after every UI task.
- The Quran glyphs are painted, never animated on their own, recolored, overlapped or cropped.
- `.specify/feature.json` points at this folder.

---

## Phase 1: Setup

**Purpose**: The constitution, the packages, the folders, the icons and the content assets.

- [X] T001 Amend `.specify/memory/constitution.md`: in Stack And Constraints add `audio_service` (the recitation in the background and on the lock screen) after `audio_session`, and `animations` (the container transform) after `share_plus`'s entry. In III. Faithful To The Design replace "Quran text is never animated, overlapped, cropped or used as decoration." with "Quran text is never animated, recolored, overlapped, cropped or used as decoration. The page as a whole may turn, open from a card, recede behind a sheet and peek beside the controls as the handoff designs it, the glyphs never move on their own." Bump the version MINOR (3.7.0) and the Last Amended date (2026-10-21). Nothing in `test/architecture_test.dart` checks it.
- [X] T002 Confirm `flutter pub get`, `flutter analyze` and `flutter test` are green before any change.
- [X] T003 Add `animations: ^3.0.0` and `audio_service: ^0.18.19` to `pubspec.yaml` (alphabetical with the others) and `- assets/quran/` and `- assets/quran/pages/` and `- assets/quran/surahs/` under assets; run `flutter pub get`.
- [X] T004 Create the folders `lib/core/quran/`, `lib/core/widgets/motion/`, `lib/features/quran/data/`, `lib/features/quran/domain/`, `lib/features/quran/presentation/providers/`, `lib/features/quran/presentation/view/widgets/`, `tool/quran/`, `assets/quran/pages/`, `assets/quran/surahs/`, `test/core/quran/`, `test/core/widgets/motion/`, `test/features/quran/`; add `tool/quran/.cache/` to `.gitignore` the way `tool/places/.cache/` is.
- [X] T005 [P] Add the 9 ui icons from the paths in `Living Sky prayer app branding 2/_gen/kit.js` (`ui/index`, `ui/translate`, `ui/words`, `ui/copy`, `ui/memorize`, `ui/prev`, `ui/spread`, `ui/timer`, `ui/chevron_down`) as svg files in `assets/icons/ui/` with the same viewBox, stroke and line caps as the existing ui icons, and their entries in `BmUiIcon` in `lib/core/resources/design/bm_icons.dart`.
- [X] T006 Write `tool/quran/build_quran.dart` on the shape of `tool/places/build_places.dart` (header comment with the run command and what it downloads, cache in `tool/quran/.cache/`): download `en.sahih` and `ar.muyassar` from tanzil.net's translation download and Tanzil's metadata `quran-data.js` (surah names, places, juz and hizb starts) as `sura|aya|text` into the cache once; read `madinah_v2_layout.sqlite` and `qpc_hafs_words.sqlite` from the cache (QUL, by hand); write `assets/quran/index.json`, `pages/001.json` to `604.json` and `surahs/001.json` to `114.json` exactly as contracts/quran-assets.md, sorted and with stable key order so a rebuild gives the same bytes. Put `// TODO(ahmed): download madinah_v2_layout.sqlite and qpc_hafs_words.sqlite from qul.tarteel.ai into tool/quran/.cache/ and confirm QUL's license and credit line, the reader has only page 1 without them.` above the two QUL paths, and `// TODO(ahmed): confirm Sahih International's and Al-Muyassar's terms for the store build.` above the Tanzil addresses. When the QUL files are missing the tool writes only Tanzil's surah files and stops with that message.
- [X] T007 Write `assets/quran/samples.json` with the Ibn Kathir, As-Sa'di and Clear Quran (Khattab) sample text 09 Quran shows for Al-Fatiha (`{"ibnKathir": {"1:5": "..."}, ...}`), with a `TODO(ahmed)` line in `tool/quran/build_quran.dart`'s header that these three come later. Until T006 has the QUL files, write `assets/quran/index.json` in full (114 surahs from 09 Quran's names and Tanzil's metadata, 30 juz, 604 page entries) and `assets/quran/pages/001.json` by hand from 09 Quran's 7 line Al-Fatiha page (`LINES` in `_gen/quran.js`, padded to 15 lines as the print has them), so every story can be built.

---

## Phase 2: Foundational

**Purpose**: Palettes, tokens, schema 10, the content reader, last read, audio use, keep screen on,
routes. Everything the stories stand on.

**⚠️ CRITICAL**: No story work starts before this phase is done

### Tests for the foundation

- [X] T008 [P] Write `test/core/quran/quran_assets_test.dart` (SC-001): 114 surahs, 30 juz, 604 page entries; for every page asset present, exactly 15 lines, `t` one of `a`, `s`, `b`, words `[surah, ayah, text]` with an optional end marker `1`; ayahs in order inside a page and across pages; `pageOf((2, 255))` is 42; `surahText(1)` has 7 translations and 7 tafsir lines. When `tool/quran/.cache/` has the sources, every word equals its source word byte for byte and every translation and tafsir line equals its source line; otherwise those checks are skipped with a reason.
- [X] T009 [P] Add a v9 → v10 step to `test/drift/app_database/migration_test.dart`: the settings row keeps every v9 value and gets the defaults of data-model.md (`lastReadSurah` 1, `lastReadAyah` 1, `lastReadPage` 1, `lastReadAt` null, `pageColor` followSky, `quranLayout` mushaf, `pageTurn` book, `keepScreenOn` false, `quranArabicSize` 0, `quranTranslationSize` 0, `reciteSpeed` 1.0, `reciteRepeat` 1, `recitePause` 0); `quran_bookmarks` and `quran_notes` exist and are empty.
- [X] T010 [P] Write `test/core/quran/last_read_test.dart`: a fresh store gives Al-Fatiha 1, page 1, no time; `save` writes surah, ayah, page and the clock's time and the provider emits it; Home and the feature read the same provider.

### Implementation for the foundation

- [X] T011 Add `BmPagePalette` to `lib/core/resources/design/bm_colors.dart` with `paper` and `night` exactly from `K.PAGE` in `_gen/kit.js` (every variable: bg, surface, raised, variant, outline, outline2, text, text2, text3, primary, on, pc, onpc, accent, ac, onac, success, pg, ink, ink2, orn, orn2, hl, hl2, hid, gut) as full `BmPalette`s with the page fields, and `cream` = paper's values with `// TODO(ahmed): cream's colors from the designer, 09 Quran names Cream but K.PAGE has no values.` above it. Add `oilLight` `#D9BE86` and `oilDark` `#8C7444` to every palette (the same in all 8 themes), and `pageGlass` (the page surface at 78%, `GLASS` in `_gen/quran.js`). Write `test/core/resources/page_palette_test.dart`: ink, ink2, text2 and text3 on page, surface and bg meet WCAG AA (4.5:1, 3:1 for the 18 pt and larger roles) on paper, cream and night (SC-008).
- [X] T012 Add to `ThemeEnum` in `lib/core/resources/theme_manager.dart`: `page`, `ink`, `ink2`, `ornament`, `ornamentSoft`, `selectionWash`, `followWash`, `pageHidden`, `gutter`, `pageGlass`, `oilLight`, `oilDark`, resolving from the palette's page fields, and for the 8 app palettes from paper or night by brightness (research R5).
- [X] T013 [P] Add to `lib/core/resources/design/bm_motion.dart`: `oilCycle` 1600 ms, `loaderDelay` 400 ms, `loaderMinimum` 600 ms, `shimmer` 1200 ms, `staggerStep` 30 ms, `staggerMax` 8, `staggerRise` 12, `pageSlide` 300 ms, `containerOpen` 520 ms (= emphasized), `pushReverse` 420 ms, the swipe rule `completeShare` .35 and `completeVelocity` 700, from 11 Motion v2's spec table.
- [X] T014 [P] Add every size the reader, sheets and motion widgets use to `lib/core/resources/dimensions_manager.dart` as named entries read from `_gen/quran.js` (mushaf frame insets, line height 58, header and page number positions, cartouche 263 x 44, wash radius 9, selection lift 24, sheet heights 452 and the large detent, mini player, dock 170, scrubber, thumbnail 60 x 85, ribbon, share card sizes 1080 and 1920) and the Mushaf font size 22.5 to `FontSizeManager` / `LineHeightManager` under quran names. Pages 1 and 2 use 4.19's 58 pt lines; pages 3 to 604 split the frame's inner height into 15 equal bands (about 45 pt at 393 pt) with a named entry `SpaceManager.mushafBand15` and a largest font size `FontSizeManager.quranPage` that the layout steps down from until the widest line fits (research R2).
- [X] T015 Add schema 10 to `lib/core/database/app_database.dart`: the settings columns of data-model.md with their defaults and checks (`lastReadPage` "check 1..604", `reciteRepeat` in `[1, 2, 3, 5, 10]`, `recitePause` in `[0, 1, 2, 3, 5]`, `quranArabicSize` and `quranTranslationSize` "steps -2..3", `reciteSpeed` in `[0.75, 1.0, 1.25, 1.5]`), enums `PageColor`, `QuranLayout`, `PageTurn`, `RibbonColor` in a new `lib/core/settings/quran.dart` (core can't import the feature), stored by name; tables `QuranBookmarks` (`id` auto, `surah`/`ayah` nullable "null for a page bookmark", `page` "always set, 1..604", `name` nullable, `color` RibbonColor, `createdAt`; unique on `(surah, ayah)` and a partial unique index on `page` where `surah` is null) and `QuranNotes` (`surah`, `ayah` primary key "one note per ayah", `text` not empty, `updatedAt`); `schemaVersion` 10 and `from9To10` adding the columns and creating the tables. Run `dart run build_runner build`, `dart run drift_dev make-migrations` for `drift_schemas/app_database/drift_schema_v10.json` and the steps file; T009 passes.
- [X] T016 Write `lib/core/quran/ayah_key.dart` (`AyahKey(surah, ayah)` with equality and `reference(String surahName)` → "Al-Fatiha 1:5") and `lib/core/quran/quran_assets.dart`: `QuranAssets` reading `index.json` once, `page(n)` and `surahText(n)` read on demand from the bundle and kept in a small cache (current page and its two neighbours, the open surah), `pageOf(AyahKey)`, `surah(n)`, `juz(n)`, and a `quranAssetsProvider`; one-line `///` on the public class. T008 passes.
- [X] T017 Write `lib/core/quran/last_read.dart`: `lastReadProvider` (a stream of the four settings columns through `.select`) and `saveLastRead(AyahKey, page)` writing them with the clock's time. T010 passes.
- [X] T018 [P] Write `lib/core/audio/audio_use.dart`: `enum AudioUse { none, recitation, adhan }` and `audioUseProvider` (a `Notifier` with `claim` and `release`). In `lib/features/notifications/data/adhan_player.dart` claim `AudioUse.adhan` before the in-app adhan plays and release it when it ends or stops.
- [X] T019 [P] Add `keepScreenOn(bool on)` to `lib/core/system/system_channel.dart` and its native side: `android/app/src/main/kotlin/com/elhawary/bettermuslim/MainActivity.kt` adds or clears `WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON`, `ios/Runner/AppDelegate.swift` sets `UIApplication.shared.isIdleTimerDisabled`, on the channel that file already uses.
- [X] T020 Add the routes of contracts/reader-routes.md to `lib/core/router/app_router.dart`: `Routes.quranPage(int page, {AyahKey? ayah})` → `/quran/page/:page?ayah=S:A` and `Routes.quranSaved` → `/quran/saved`, both outside the shell with `_page` (the reader page and Saved page are stubs until US1 and US5).
- [X] T021 Add every string of spec FR-051 to `lib/core/resources/strings_manager.dart` and both `assets/l10n/app_en.arb` and `app_ar.arb` with their placeholders, plus the surah and juz row labels, the Saved, recitation, share and display labels from 09 Quran; `test/core/resources/strings_manager_test.dart` passes.

**Checkpoint**: content, palettes, schema and routes ready.

---

## Phase 3: User Story 0 - Wait and open the way Motion v2 does (Priority: P1)

**Goal**: the oil drop loader, the container transform, the list entrance and skeletons in core.

**Independent Test**: spec US0: the dev page's Loader section, a surah row growing into a page, the
Quran tab's first open with skeletons, then reduce motion.

### Tests for User Story 0

- [X] T022 [P] [US0] Write `test/core/widgets/motion/loader_gate_test.dart` with fake time: nothing shown when the wait ends before 400 ms; shown at 400 ms; once shown, hidden no sooner than 600 ms later and only at the end of a cycle; a second gate while one is showing doesn't show its own.
- [X] T023 [P] [US0] Write `test/core/widgets/motion/oil_drop_test.dart`: at 48 pt the painter draws the drop, at 16 pt `showDrop` is false; with reduce motion no drop and no wave and the sun opacity moves between .45 and 1 on the 1600 ms cycle; a new `progress` springs the level toward it; the semantics label is "Loading" and the value the percent when `progress` is set.
- [X] T024 [P] [US0] Write `test/core/widgets/motion/container_transform_test.dart` and `stagger_test.dart`: the open takes 520 ms and the close reverses it; with reduce motion a 150 ms crossfade; rows 1 to 8 start 30 ms apart and rows past 8 with the eighth; the stagger runs only the first time the list shows on its screen; `BmSkeleton` hands over in one 150 ms crossfade.

### Implementation for User Story 0

- [X] T025 [US0] Write `lib/core/widgets/motion/oil_drop.dart`: `BmOilDrop({size = 48, progress})` and its painter from `_gen/motion.js` / `_gen/motion_logic.js` and 11 Motion v2's Flutter snippet: one repeating controller on `BmMotion.oilCycle` with the beats form .00–.35 (decelerate), hang .35–.50 (breathe), fall .50–.73 (easeInQuad), splash .73–.80, ripple and sun halo .73–1.0 (decelerate); the level on an unbounded controller with `SpringSimulation(BmMotion.gentle, ...)`; star in `ThemeEnum.primary`, oil `oilLight` → `oilDark`, sun `ThemeEnum.sun`; stroke weight up as the size goes down; no drop under 32 pt; reduce motion sun pulse; never mirrored; `RepaintBoundary` around it; `Semantics` with "Loading". T023 passes.
- [X] T026 [US0] Write `lib/core/widgets/motion/loader_gate.dart`: `BmLoaderGate(loading: bool, child, loader)` applying the 400 ms delay, the 600 ms minimum ending on a completed ripple, and one loader on screen at a time (a static count). T022 passes.
- [X] T027 [P] [US0] Write `lib/core/widgets/motion/container_transform.dart`: `BmContainerTransform({closedBuilder, openBuilder, radius})` on `OpenContainer` with `BmMotion.containerOpen`, the standard curve, the closed radius to 0, `ContainerTransitionType.fadeThrough` for the middle 40% crossfade, closed and open colors from `ThemeEnum`, and a 150 ms crossfade route with reduce motion.
- [X] T028 [P] [US0] Write `lib/core/widgets/motion/stagger.dart` (`BmStagger(index, child)`: 300 ms, `Interval` from `min(index, 7) * 30 ms`, 12 pt rise and fade, run once per screen) and `lib/core/widgets/motion/skeleton.dart` (`BmSkeleton(shape)`: a 1200 ms shimmer over `ThemeEnum.variant`, and `BmSkeletonSwitch(loading, skeleton, child)` with a 150 ms `AnimatedSwitcher` that keeps the size). Both off with reduce motion. T024 passes.
- [X] T029 [US0] Add the Loader section to `lib/features/notifications/presentation/view/dev_notifications_page.dart` (contracts/reader-routes.md): `BmOilDrop` at 48, 24 and 16 pt and a progress slider driving one more at 48, in a `GroupedSection`.

**Checkpoint**: Motion v2's pieces work on their own in the dev page.

---

## Phase 4: User Story 1 - Read the Mushaf page by page (Priority: P1) 🎯 MVP

**Goal**: 4.18, 4.19, 4.20, 4.21, the page turn and Follow the sky.

**Independent Test**: spec US1 and quickstart "Reading".

### Tests for User Story 1

- [X] T030 [P] [US1] Write `test/features/quran/domain/mushaf_layout_test.dart` for the layout of T033: words on a line laid right to left with equal gaps filling the width; a line wider than the page scaled down to fit; centered lines centered; every word has a rect inside its line band; the band is at least 44 pt tall at the smallest phone width; a surah name line and a basmallah line take their own bands.
- [X] T031 [P] [US1] Write `test/features/quran/presentation/page_turn_test.dart`: a drag past 35% or a fling over 700 px/s completes, less springs back; page 1 has no previous and 604 no next; Slide is 300 ms; reduce motion is a 150 ms crossfade; a turn interrupted mid flight retargets from its value; only the current page and two neighbours are built.
- [X] T032 [P] [US1] Write `test/features/quran/presentation/page_color_test.dart` and `quran_page_test.dart`: Follow sky gives paper between Fajr and Isha and night after Isha and before Fajr, paper with no location; a pick of Paper, Cream or Night is kept; the palette change at Isha takes 1.8 s with the sacred curve; 4.18 shows the title, "Madinah Mushaf · Hafs", Continue reading with the design scenario's "Al-Fatiha · Ayah 3" and "Page 1 · Juz 1 · Today 14:10", Listen, Bookmarks and Notes (no Memorize, no khatmah card, no search), the Surah, Juz and Page index with its first rows; tapping a surah row pushes `Routes.quranPage(firstPage)`.

### Implementation for User Story 1

- [X] T033 [US1] Write `lib/features/quran/domain/mushaf_page.dart` (`MushafPage`, `MushafLine` with type, centered, words; `MushafWord` with key, text, end) from the page asset, and the pure layout in `lib/features/quran/domain/mushaf_layout.dart`: given the page, the text painter's word widths and the page size, the lines' bands and every word's rect (research R2, R3). T030 passes.
- [X] T034 [US1] Write `lib/features/quran/presentation/view/widgets/mushaf_page_view.dart`: a `LeafRenderObjectWidget` with its `RenderBox` that measures the words with `TextPainter` and `GetRegularStyle(font: FontEnum.quran, ...)` from `lib/core/resources/styles_manager.dart` (never `TextStyle(` in the feature, architecture test), one size for the page, pages 3 to 604 on the 15 band rule of T014 with `// TODO(ahmed): a regular 15 line page from the designer, this rule stands in until then.` above it, runs T033's layout, paints the frame and corner stars on pages 1 and 2, the header (surah, juz), the surah cartouches, the Bismillah lines, the words in `ThemeEnum.ink`, the ayah markers in `ornament` and `ink`, the page number in the star, the gutter shadow on the spine side and the fore-edges on the other, all from `_gen/quran.js`. Laid out once per page and size, kept while the page lives; wrapped in a `RepaintBoundary`. `// TODO(ahmed): QCF V2 per page fonts here once licensed, the lines and hit test stay.` above the font pick.
- [X] T035 [US1] Write `lib/features/quran/presentation/providers/page_providers.dart`: `mushafPageProvider(page)` from `QuranAssets`, `pagePaletteProvider` (Follow sky from the app's prayer periods in `core/prayer_times`, or the picked `pageColor` via `.select`), and the reader's `currentPageProvider`. T032's page color part passes.
- [X] T036 [US1] Write `lib/features/quran/presentation/view/widgets/page_turn.dart` (research R7): drag driven controller, Book leaf with a perspective `Matrix4.rotationY` on the spine and a shading gradient from the angle, `SpringSimulation(BmMotion.gentle)` release from the velocity, the completion rule from `BmMotion`, Slide at 300 ms, crossfade under reduce motion, taps on the left 12% turn to the next page, the page turn haptic only when it's on. T031 passes.
- [X] T037 [US1] Write `lib/features/quran/presentation/view/reader_page.dart`: the route page for `/quran/page/:page`, a `Theme` with the page palette around everything, `PageTurn` of `MushafPageView`s, the palette crossfade at Isha over `BmMotion.skyChange` with `BmMotion.sacred`, keep screen on when the setting is on (T019), tab bar hidden, back to where it came from.
- [X] T038 [US1] Write `lib/features/quran/presentation/view/widgets/page_chrome.dart` and `scrubber.dart` (4.21): margin tap toggles; the glass top bar (back, surah, "Juz {j} · Hizb {h} · Page {p}", bookmark) and the glass dock (scrubber right to left with juz ticks and "Page {p} · Juz {j}" while dragging, Index, Listen, Translation, Display; no Memorize, no search) slide in on `ThemeEnum.pageGlass` with the 24 pt blur and 1.5 saturation; the page springs to a card (`spring.gentle`) with the next page peeking on the left; the scrubber opens its page on release. The chrome is mirrored in Arabic, the scrubber and turn keep the Mushaf's direction.
- [X] T039 [US1] Write `lib/features/quran/presentation/view/quran_page.dart` (4.18) replacing the placeholder, with `widgets/continue_card.dart` (thumbnail of the last read page, `BmContainerTransform` into the reader), the tools row (Listen, Bookmarks, Notes), and `widgets/surah_index.dart` (the `Segmented` Surah, Juz, Page; 114 surah rows with the number in the star, English name, "{place} · {n} ayahs · p. {page}", Arabic name; 30 juz rows; 604 page rows; each row a `BmContainerTransform` into its page; `BmSkeletonSwitch` and `BmStagger` on the first show), the large title with `TitleGlow` as the other tabs. T032 passes.
- [X] T040 [US1] Make the design scenario in `lib/core/flavor/design_scenario.dart` set last read to Al-Fatiha 3, page 1, at 14:10 on the scenario day (FR-054), with no audio and no network.

**Checkpoint**: the Mushaf can be read, turned and opened from the tab. MVP.

---

## Phase 5: User Story 2 - Act on an ayah (Priority: P1)

**Goal**: 4.22 and 4.23, the washes, Copy.

**Independent Test**: spec US2 and quickstart "Ayah".

### Tests for User Story 2

- [X] T041 [P] [US2] Write `test/features/quran/presentation/ayah_selection_test.dart`: a tap on a word selects its ayah, a tap on another ayah moves it, a tap outside the text toggles the chrome instead; a long press selects too; an ayah split over two pages is selected whole; the wash rects are one per line part, radius 9, behind the glyphs; the lift is `max(0, ayahBottom + 24 - sheetTop)`.
- [X] T042 [P] [US2] Write `test/features/quran/presentation/ayah_sheet_test.dart`: the medium detent shows "Al-Fatiha · Ayah 5", "Juz 1 · Page 1 · Meccan", the Sahih International line and Play from here, Tafsir, Bookmark, Note, Share, Copy (no Word by word, no Memorize); Tafsir opens the large detent with Tafsir, Translation, Notes (no Words); back and forward move the ayah and the wash; Al-Muyassar on any ayah; Ibn Kathir on Al-Fatiha shows the sample and "Coming soon" elsewhere; in Arabic the translation slot is Al-Muyassar; Copy puts Arabic, translation and "Al-Fatiha 1:5" on the clipboard and shows "Copied".

### Implementation for User Story 2

- [X] T043 [US2] Add hit testing and washes to `mushaf_page_view.dart`: `hitTest` maps a position to the word on its line band and reports the ayah through callbacks for tap and long press; `selected` and `following` ayah keys paint `selectionWash` and `followWash` rects behind the glyphs, fading in 150 ms by alpha only. A selection gives the light haptic through `BmHaptics` (FR-047). Write `lib/features/quran/presentation/providers/selection.dart` (the selected ayah, null when none). T041 passes.
- [X] T044 [US2] Write `lib/features/quran/presentation/view/widgets/ayah_sheet.dart`: a sheet with medium (452) and large detents that springs between them (`spring.gentle`), the page lift driven from its height, the large detent receding the page (scale .92, up 16, dim .28 from `_gen/quran.js`), the header with close (and back and forward at large), the translation with its name, the six action tiles; tapping outside or close clears the selection and settles the page.
- [X] T045 [US2] Write `lib/features/quran/presentation/view/widgets/study_tabs.dart`: the ayah on top in `FontEnum.quran`, `Segmented` Tafsir, Translation, Notes; the Tafsir chips Al-Muyassar, Ibn Kathir, As-Sa'di with their texts from `QuranAssets` and `samples.json` and the credit line; the Translation list (Sahih International, Clear Quran sample, Arabic Al-Muyassar summary); the Notes pane stub until US5. Copy in the actions with `Clipboard.setData` and the toast. T042 passes.

**Checkpoint**: every ayah opens its sheet, tafsir and translation.

---

## Phase 6: User Story 3 - Listen and follow along (Priority: P1)

**Goal**: 4.25, the mini player, background play, downloads.

**Independent Test**: spec US3 and quickstart "Recitation".

### Tests for User Story 3

- [X] T046 [P] [US3] Write `test/features/quran/domain/recitation_queue_test.dart` for T049: a range from 1:1 to the end of the surah; Bismillah first on every surah but 1 and 9; repeat 3 puts each ayah 3 times; pause 2 s waits between different ayahs only; the end of the range stops, or starts again when repeat covers the range; sleep end of surah stops after the last ayah; following turns off when I turn the page and back on when I come back, tap next or previous; last read follows the playing ayah.
- [X] T047 [P] [US3] Write `test/features/quran/data/recitation_files_test.dart` with a fake http client and a temp folder (SC-005): the address is `https://everyayah.com/data/Alafasy_128kbps/001005.mp3`; a complete file with ID3 or a frame sync is kept; a short body, a wrong first bytes and a full disk leave no file and report the error; offline with no file reports offline; the rest of the surah downloads one at a time after the first; the folder is excluded from backup on creation; the request has no extra headers.
- [X] T048 [P] [US3] Write `test/features/quran/presentation/mini_player_test.dart` and `recitation_sheet_test.dart` with a fake `Recitation`: the mini player shows "{surah} · Ayah {n}", "Mishary Alafasy · 1.0×", play or pause and next, LTR in Arabic; the sheet shows the reciter, "Murattal · Hafs · downloaded" only when the surah is complete, "Ayah 3 of 7", the time, and the four rows with their choices (repeat off, 2, 3, 5, 10; pause off, 1, 2, 3, 5 s; sleep off, 5, 10, 15, 30, 60 min, end of surah; speed .75 to 1.5); the toasts for offline and failed download with Try again; `AudioUse.adhan` pauses it.

### Implementation for User Story 3

- [X] T049 [US3] Write `lib/features/quran/domain/recitation.dart`: the `Recitation` interface and `RecitationState` of contracts/recitation.md, and the pure queue rules (playlist from a range with Bismillah and repeat, which ayah an index is, when to pause, sleep). T046 passes.
- [X] T050 [US3] Write `lib/features/quran/data/recitation_files.dart` (research R9, contracts/recitation.md): https download to `.part`, the length and first bytes check, rename, the cache folder in Application Support with `BackupExclusion.exclude`, download ahead one at a time, `isSurahReady`. `// TODO(ahmed): the recitation's address, EveryAyah's Alafasy 128 kbps until I pick the final source.` above the base address. T047 passes.
- [X] T051 [US3] Write `lib/features/quran/data/audio_service_recitation.dart`: `AudioServiceRecitation` with a `BaseAudioHandler` around its own `AudioPlayer`, the playlist of T049, speed, the pause between ayahs on index change, the sleep fade (volume to 0 over 3 s), media items titled "{surah} · Ayah {n}" with the reciter as artist, previous, play or pause and next controls, `audio_session` music config (the same as `JustAudioClipPlayer` and the adhan player, so the shared session never flips) with interruptions and noisy pausing and never resuming, claiming `AudioUse.recitation` and pausing when the adhan claims. Init it from `lib/bootstrap.dart` the way the audio_service docs ask, only in the app's own run, never in a background engine (workmanager, a notification's background isolate), provided through `recitationProvider`.
- [X] T052 [US3] Native setup for `audio_service`: `MainActivity` extends `AudioServiceActivity` keeping its channels; `android/app/src/main/AndroidManifest.xml` gets `com.ryanheise.audioservice.AudioService` with `foregroundServiceType="mediaPlayback"`, `com.ryanheise.audioservice.MediaButtonReceiver`, and `FOREGROUND_SERVICE` / `FOREGROUND_SERVICE_MEDIA_PLAYBACK` permissions; check iOS `UIBackgroundModes` has `audio`. Both debug builds pass.
- [X] T053 [US3] Write `lib/features/quran/presentation/providers/recitation_providers.dart` (state, following, the playing ayah into the page's follow wash, turning the page while following, last read from the playing ayah through `saveLastRead`) and `view/widgets/mini_player.dart` (rises over the dock, `BmLoaderGate` with the 16 pt oil drop in the play button while loading) and `view/widgets/recitation_sheet.dart` (4.25, the page lifted so the playing ayah stays clear). Wire Play from here and Listen. A tap on the media notification and opening the reader while it plays go to `Routes.quranPage(playing page)` with the playing ayah (US3 scenario 8). Add to T048's test that the follow wash changes on the same frame as the fake's index change (SC-003). T048 passes.

**Checkpoint**: recitation plays, follows, keeps playing locked and offline once downloaded.

---

## Phase 7: User Story 4 - Pick up where I left off (Priority: P2)

**Goal**: last read written and shown everywhere.

**Independent Test**: spec US4 and quickstart "Last read".

- [X] T054 [P] [US4] Write `test/features/quran/presentation/last_read_flow_test.dart`: a page settling without audio saves its first ayah; leaving the reader saves it; while playing only the playing ayah is saved; Continue reading on 4.18 and Home's shortcut both open `Routes.quranPage(lastRead.page)`; a fresh install shows Al-Fatiha, Ayah 1, Page 1.
- [X] T055 [US4] Save last read in `reader_page.dart` when a page settles and on dispose, skipped while the recitation plays.
- [X] T056 [US4] In `lib/features/home/view/widgets/shortcuts_card.dart` make Continue reading read `lastReadProvider` (via `.select`) for its subtitle and push `Routes.quranPage(page)`; in `lib/features/home/view/widgets/verse_card.dart` open the verse's page with the ayah washed through `QuranAssets.pageOf`. Update `test/features/home/` for both. T054 passes.

---

## Phase 8: User Story 5 - Bookmark and note (Priority: P2)

**Goal**: ribbons, Saved (4.29), notes.

**Independent Test**: spec US5 and quickstart "Last read, bookmarks, notes".

### Tests for User Story 5

- [X] T057 [P] [US5] Write `test/features/quran/data/quran_store_test.dart` with an in-memory store: an ayah bookmark is unique per ayah and a page bookmark per page; rename, recolor (primary, accent, neutral only) and move keep the id; list newest first; one note per ayah, trimmed, empty refused; delete and Undo put the same row back; a backup and restore carries both tables (`test/helpers/backup.dart`).
- [X] T058 [P] [US5] Write `test/features/quran/presentation/saved_page_test.dart`: Bookmarks lists Last read first marked Auto, then bookmarks with name, "{surah} {s}:{a} · Page {p}" and date; Notes lists notes; long press opens Rename, Color, Move here; tapping a row pushes its page with the ayah; empty shows "No bookmarks yet"; the ribbon shows on a bookmarked page in its color; removing shows "Bookmark removed" with Undo for 4 s.

### Implementation for User Story 5

- [X] T059 [US5] Write `lib/features/quran/domain/bookmark.dart`, `note.dart` and `lib/features/quran/data/quran_store.dart` on the shape of `lib/features/prayer/data/qada_repository.dart`. T057 passes.
- [X] T060 [US5] Write `view/widgets/ribbon.dart` (hangs on the page in the bookmark's color, from `_gen/quran.js`), Bookmark in the ayah sheet and the top bar, and the toast with Undo.
- [X] T061 [US5] Write `lib/features/quran/presentation/view/saved_page.dart` (4.29, `Segmented` Bookmarks and Notes, no Highlights, no search), `view/widgets/bookmark_menu.dart` (Rename in a `BmTextField`, Color, Move here) and `view/widgets/note_editor.dart` (write, change, delete with Undo), and the Notes pane in `study_tabs.dart` with Add note. Tools Bookmarks and Notes and the bar's bookmark on 4.18 open `Routes.quranSaved`. T058 passes.

---

## Phase 9: User Story 6 - Share an ayah as an image (Priority: P3)

**Goal**: 4.30.

**Independent Test**: spec US6 and quickstart "Share and display".

- [X] T062 [P] [US6] Write `test/features/quran/presentation/share_sheet_test.dart`: the preview shows the ayah, its marker, "Al-Fatiha · 5" and "Better Muslim"; Paper, Night, Emerald, Sky and square or story change it; Include translation and Show app name toggle; Al-Baqarah 282 shrinks to fit whole and moves to story under the smallest size; Share renders 1080 x 1080 or 1080 x 1920 and calls `share_plus` with a png.
- [X] T063 [US6] Write `view/widgets/share_card.dart` (the still card from 4.30, never cropped or overlaid, laid out at fixed 1080 sizes outside ScreenUtil so the output is the same on every phone) and `view/widgets/share_sheet.dart` (preview, the four backgrounds, size, the two switches, Share through `lib/core/system/share.dart` after `RepaintBoundary.toImage`). T062 passes.

---

## Phase 10: User Story 7 - Set the page up for me (Priority: P3)

**Goal**: 4.31 and the translation layouts.

**Independent Test**: spec US7 and quickstart "Share and display".

- [X] T064 [P] [US7] Write `test/features/quran/presentation/display_sheet_test.dart` and `translation_view_test.dart`: Page Follow sky, Paper, Cream, Night; Layout Mushaf, Translation, Both; Page turn Book, Slide; Keep screen on; "Madinah · Hafs"; no Tajweed colors; each kept in settings; switching layout keeps the same ayah on screen; Translation is 4.07's cells; Both is the page with its cells under it; the Arabic and translation sizes change at once with the selection haptic and keep the ayah in view; Keep screen on calls `keepScreenOn(true)` in the reader and `false` on leaving.
- [X] T065 [US7] Write `view/widgets/display_sheet.dart` (4.31) and `view/widgets/translation_view.dart` (4.07 from `design_handoff_better_muslim/specs/screens/4.07-quran-reader.md`, the verse cells with Arabic in `FontEnum.quran`, translation, selection and follow washes as cell fills), the Both layout in `reader_page.dart`, the dock's Translation switching Mushaf and Translation. T064 passes.

---

## Phase 11: Polish & Cross-Cutting Concerns

- [X] T066 [P] Add the credits to `lib/features/more/model/credits.dart` (QUL Mushaf layout and words, Tanzil's Sahih International and Tafsir al-Muyassar, EveryAyah and Mishary Rashid Alafasy, Amiri Quran under the OFL) with a `TODO(ahmed)` for QUL's exact credit line.
- [X] T067 [P] Semantics across the reader (FR-052): each ayah read as surah, number, Arabic and translation; every action and player button labelled; play, pause and each page turn announced; every control at least 44 x 44. A test in `test/features/quran/presentation/semantics_test.dart`.
- [X] T068 [P] Write `integration_test/quran_journey_test.dart` on the shape of `integration_test/azkar_journey_test.dart`: open the tab, Continue reading, turn a page, select an ayah, bookmark it, write a note, kill and reopen, the bookmark, the note and last read are there.
- [X] T069 Run the `break-ui` pass on the reader, 4.18, the ayah sheet and Saved (text scale 2.0, Arabic, the longest surah names, Al-Baqarah 282, 0 and 200 bookmarks, a tablet) and fix what breaks.
- [X] T070 Run `flutter test test/architecture_test.dart` and the four greps from my global rules on every touched file; fix every hit.
- [X] T071 Run `dart format --set-exit-if-changed lib test tool`, `flutter analyze`, `flutter test`; all green.
- [ ] T072 Walk quickstart.md on the iOS simulator and an Android phone; in profile mode check a page opens from the tab in under 1 s and 20 page turns in a row show no janky frames in the performance overlay (SC-002); note anything I must check myself.
- [X] T073 Update milestone 7 in `CLAUDE.md`: "7a. Quran reader: the Mushaf page by page, ayah sheet, tafsir and translation, recitation, bookmarks and notes, share, display, with the Motion v2 loader and container transform first. **Done, waiting for my review.** 7b (word by word, memorise, search, khatmah) comes next."

---

## Dependencies & Execution Order

- **Setup (T001–T007)** → **Foundational (T008–T021)** → stories.
- **US0 (T022–T029)** first: US1 uses the container transform, stagger and skeleton, US3 the loader.
- **US1 (T030–T040)** before every other story: they all sit on the reader page.
- **US2 (T041–T045)** needs US1. **US3 (T046–T053)** needs US1, and US2 for Play from here (Listen
  works without it). **US4 (T054–T056)** needs US1, and US3 for last read while playing.
  **US5 (T057–T061)** needs US2. **US6 (T062–T063)** needs US2. **US7 (T064–T065)** needs US1.
- **Polish (T066–T073)** last.

```text
Setup → Foundational → US0 → US1 → US2 → { US3, US5, US6 } ; US1 → US7 ; US3 → US4
```

## Parallel Examples

- Foundational: T008, T009, T010 together; then T013, T014, T018, T019 beside T011 → T012.
- US0: T022, T023, T024 together; T027 and T028 beside T025 → T026.
- US1: T030, T031, T032 together.
- US3: T046, T047, T048 together; T050 beside T049.
- After US2: US5, US6 and US7 can run side by side (different files).

## Implementation Strategy

1. **MVP**: Setup, Foundational, US0, US1. The Mushaf reads and turns, opened from the tab. Stop
   and check quickstart "Motion phase" and "Reading".
2. Add US2 and US3, the ayah and the recitation, check again.
3. Add US4 to US7, then Polish. Stop for my review.
