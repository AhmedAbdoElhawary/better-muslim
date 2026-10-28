# Research: Enhancements after the review

Checked on 2026-10-26 against the code on `feature/milestone-7` (milestones 1 to 12 and 7a built),
the handoff (4.01, 4.16, README, MOTION.md, `01 Brand.dc.html`), Flutter 3.47.5's `scaffold.dart`,
`overlay.dart` and `routes.dart`, and the files in `tool/quran/.cache/`.

## R1. The More title after a language switch

- **Decision**: `_LargeTitleState` (`core/widgets/compact_app_bar.dart`) keeps the text direction
  it measured with. In `didChangeDependencies` it reads `Directionality.of(context)`. When the
  direction differs from the kept one, it sets `_ends = null` and measures again after the frame.
  Reading `Directionality` there also makes the title depend on it, so the const More header
  rebuilds.
- **Rationale**: Prayer and Quran work only because their headers are not const. The bug is in
  core, so it gets fixed in core, once.
- **Alternatives**:
  - make `_Header` non const: fixes More only, and the next const header breaks again;
  - add the direction to `_LargeTitleScope`: the scope sits above the direction change anyway.

## R2. Toasts above everything

- **Decision**:
  - `App`'s `builder` wraps the router's child in an app-level `Overlay`, the outermost one.
  - `showToast` inserts one `OverlayEntry` into it with `Overlay.of(context, rootOverlay: true)`.
    The root navigator's overlay is a child of it, so sheets, dialogs and routes pushed later
    all stay under the toast.
  - The entry draws today's toast body (the `SnackBar` content moves into a `_Toast` widget).
  - It is placed above the nav bar the same way: bottom padding from the shell's nav height.
  - It slides in, waits for `BmMotion.toast`, then slides out. One static entry is kept, so a new
    toast removes the old one first.
  - `reset_row.dart` switches to `showToast`.
- **Rationale**: one change in core. The 17 call sites and the signature stay the same.
- **Alternatives**:
  - a `ScaffoldMessenger` per sheet: fixes sheets only, not dialogs;
  - inserting into the root navigator's overlay: a sheet opened after the toast covers it.

## R3. The glass

- **Decision**:
  - New `core/widgets/glass.dart`: `Glass(child, opacity)`. A `ClipRect`, then
    `BackdropFilter(blur BmGlass.blurSigma)`, then `ColoredBox(surface at opacity)`.
  - `CompactAppBar` replaces its inline copy with it.
  - `NavBar` uses it in place of its `DecoratedBox`. The top border stays.
  - The opacity follows the top glow like the bar does (`BmGlass.surfaceOpacity` with the glow,
    .8 without).
  - `AppShell`'s `Scaffold` gets `extendBody: true`. Flutter then adds the nav bar's height to the
    body's `MediaQuery` bottom padding. Any tab list that ends with `MediaQuery.paddingOf(context)
    .bottom` (or a `SafeArea`) clears the bar by itself. The tasks walk the five tabs and add that
    padding where a list ends with a fixed gap.
- **Rationale**: one glass recipe in core, three users (app bar, nav bar, toast if needed). No
  per-tab nav height constant.
- **Alternatives**: a second blur recipe for the nav bar (two copies), or keeping the body above
  the bar (then nothing is under the glass).

## R4. Dialog backdrop

- **Decision**: `showBmDialog`'s `transitionBuilder` puts a `BackdropFilter` behind the card. Its
  sigma is `animation.value * SizeManager.sheetBlur`, the same as the sheets' barrier. The barrier
  color stays.
  - With reduce motion the blur fades with the opacity: it's the same animation, now a fade.
- **Rationale**: the same feel as the sheets, no new widget.

## R5. The splash symbol

- **Decision**:
  - Render `assets/app_icon/splash_symbol.svg` with ImageMagick (`magick`, installed) into a
    1152 × 1152 transparent PNG. The symbol is scaled so its box is 60% of the side (about
    690 px), centered.
  - Rerun `dart run flutter_native_splash:create`.
  - If `magick` renders the strokes badly (no librsvg delegate), I export it from the SVG by hand
    and the task becomes a `TODO(ahmed)`.
- **Rationale**: Android 12's splash icon shows the middle 2/3 circle, so 60% stays inside it. The
  strokes come out three times thicker on screen than today's.

## R6. Verse of the day

- **Decision**:
  - `features/home/model/verse_of_day.dart`: `AyahKey verseOfDay(DateTime date, List<AyahKey>
    candidates)`.
  - The index is `(y * 10000 + m * 100 + d) * 2654435761 % 2^32 % candidates.length`, a fixed
    multiplicative hash. It's the same on every phone, and two days in a row land far apart.
  - The candidates come once from `QuranAssets`: every ayah whose word count, read from the 604
    pages, is between 6 and 40.
  - `verseOfDayProvider` (a `FutureProvider` on `todayProvider`) gives the key, the Arabic built
    from the page words, the translation, and the surah name.
  - `verse_card.dart` reads it, with the existing skeleton while it loads.
- **Rationale**: no stored state, testable for a date, Quran text from the licensed data.
- **Alternatives**: `Random(seed)` (Dart's generator isn't promised stable across versions), or a
  hand-picked list (Ahmed chose all ayahs).
- **Cost**: reading the 604 pages for the counts takes too long at launch. The tool writes the
  word count per ayah into `assets/quran/index.json` (`words` per surah) once, so it's one small
  read.

## R7. One share sheet in core

- **Decision**:
  - `core/widgets/share/`:
    - `share_options.dart`: `ShareBackground`, `ShareSize`, `ShareFont`, `ShareOrnament` and the
      `ShareOptions` record;
    - `share_sheet.dart`: `showShareSheet(context, {content, rows})`, with the preview, the
      swatches, size, Solid color, Ornament, Font, app name and the capture;
    - `share_frame.dart`: the background fill, the ornament layer and the footer.
  - A feature passes:
    - `content`: a builder `(ShareOptions, Size) → ShareLayout`, which returns its painter and
      whether it fits;
    - `rows`: its own option rows (the ayah's text picker).
  - The capture stays `RepaintBoundary.toImage(pixelRatio: 1080 / width)`.
  - Moved out of `features/quran`: `ShareBackground`, `ShareSize`, `ShareBackgroundFill`, the
    swatch and the sheet's frame. Quran keeps `ayah_share.dart` (its painter, fit and footer).
    Duas keeps `dua_share.dart` (its painter).
  - Fixed while moving:
    - `AppTheme.page(color, themeId)` gets the user's theme;
    - the unused `isLight` goes;
    - the ornament color comes from each background's own light or dark.
- **Rationale**: principle IV, two features use it. The dua share's offscreen `OverlayEntry` goes.

## R8. Ornament and solid

- **Decision**:
  - Ornament: the SVG drawn with `SvgPicture.asset(fit: BoxFit.cover, colorFilter: srcIn
    ornament)`, at `SizeManager.shareOrnamentOpacity` (.10), under the text.
  - Patterns: `pattern_khatam`, `pattern_star_cross`, plus `frame_arch` for duas.
  - Their C2PA metadata block is stripped from the SVG files: about 60% of their size, and
    `flutter_svg` doesn't need it.
  - Solid color: `ShareBackground.solidOf()` returns the middle stop. The switch is hidden for
    `solid`-style backgrounds.
- **Rationale**: the assets are already there, and the pattern stays a faint texture so the text
  keeps its contrast.

## R9. Fonts

- **Decision**: three families in `pubspec.yaml`: `AmiriQuran` (there), `KfgqpcHafs` and
  `ScheherazadeNew`.
  - Scheherazade New (OFL, SIL) is downloaded from SIL's GitHub release v4.300 into
    `assets/fonts/`.
  - KFGQPC Uthmanic Script Hafs: Ahmed puts the file in `assets/fonts/` (QUL ships it). It gets a
    `TODO(ahmed)` on its license. Until it's there, the option shows but falls back to Amiri
    Quran.
  - `QuranFont { amiri, kfgqpc, scheherazade }` in `core/settings/quran.dart`. Its `family` is
    used by `RenderMushafPage`'s word painters and the share painters.
  - A `quranFont` column holds it (R14).
  - The mushaf already measures every word and shrinks the page font until the widest line fits
    (`mushaf_page_view.dart:891-920`). That holds for any font, so no per-font numbers are needed.
- **Rationale**: the QPC Hafs text is made for KFGQPC. Amiri Quran draws a few of its small marks
  in other places, which may be part of the "glitch" (R11).

## R10. Several ayahs

- **Decision**:
  - `selection.dart` becomes `({AyahKey? sheet, Set<AyahKey> chosen, bool choosing})`:
    - a long press calls `startChoosing(key)`;
    - a tap while choosing calls `toggle(key)`;
    - `clear()` ends choosing.
  - The page paints chosen ayahs with today's `selectionWash`.
  - A `ChoosingBar` (`quran/presentation/view/widgets/choosing_bar.dart`) replaces the dock while
    choosing: "Share (n)" and Cancel.
  - The ayah card's layout (`ayah_share.dart`) sorts the keys and groups runs (same surah, ayah +
    1). Each run is one paragraph with its markers. Between runs comes `divider_section.svg`. The
    footer is the runs joined with " · ".
  - The fit (FR-017) is a loop over the steps:
    1. scales 1, .9, .8, .7;
    2. story if the size isn't locked;
    3. tafsir off from the last ayah back, at .7;
    4. otherwise "doesn't fit".
  - "Locked" means the user tapped Square themselves.
  - The add check runs the same fit with the new ayah before checking it. If it doesn't fit, a
    toast shows and it isn't added.
- **Rationale**: the selection lives where the sheet's already does. One fit function serves the
  sheet and the add check.

## R11. Android sharpness

- **Decision**: diagnose first (FR-025). Compare on Ahmed's Android phone, at rest, turning, and
  with the controls showing (0.84), in four runs:
  1. as it is today;
  2. with `--no-enable-impeller`;
  3. with the page's `CustomOpacity` removed;
  4. with KFGQPC.

  Then fix what shows:
  - if it's the transform, `PageTurner` builds the settled page with no `Transform` and no
    opacity layer, and only wraps it while it moves;
  - if it's the 0.84 scale, the controls shrink the page by laying it out at the smaller size
    instead of scaling a picture;
  - if it's the font, R9.

  The finding goes in the plan's Answered table before the fix lands.
- **Rationale**: four likely causes, and one run each tells them apart. Guessing would change
  working code.

## R12. Page palettes

- **Decision**:
  - `PageColor` gains `sepia`, `green` and `navy`, and `cream` gets its own base.
  - `BmPagePalette.base(PageColor)` returns paper, ink, ink2, ornament, ornamentSoft and gutter.
  - `BmPagePalette.tint(base, theme)` runs as today.
  - The values are proposed in `bm_colors.dart`, near the paper and night ones. Text contrast is
    at least 7:1 for ink on paper, tested in `page_color_test.dart`.
  - The Display swatches show seven: the six plus Follow sky.
  - The stored value is the enum name, so old values keep working with no migration.
- **Rationale**: the existing tint keeps each palette in the app theme.

## R13. The page curl

- **Decision**:
  - `shaders/page_curl.frag`: a cylinder curl. Its inputs are:
    - the page image (sampler), size, the corner point under the finger, the curl radius, the
      paper back color and the shadow strength.
  - What it draws:
    - Points past the fold line are mapped around a cylinder of radius `r`.
    - The back of the page is the paper color darkened by `SizeManager.curlBackShade` (.06).
      The glyphs aren't drawn through, so no mirrored Quran shows.
    - The page under it gets a soft shadow along the fold.
  - `PageTurner` (`page_turn.dart`):
    - On drag start it takes the current page's image once, with
      `RenderRepaintBoundary.toImageSync(pixelRatio: devicePixelRatio)`.
    - It draws the page through the shader while the drag or the spring runs.
    - The page underneath is the next real page widget.
    - On settle it disposes the image and shows the real page again (sharp, R11).
    - The corner point comes from the drag position and the controller's value, so the spring
      animates the same uniform.
    - `completeShare`, `completeVelocity`, the rubber band and `BmMotion.gentle` stay.
  - Mushaf direction: the page turns from the left edge toward the right (RTL book) in both
    languages, the same as today.
  - Reduce motion and Slide mode don't touch the shader.
- **Rationale**:
  - A real curl needs per-pixel bending, so a fragment shader is the only cheap way.
  - The repo already runs `liquid_glass.frag` with the same loading pattern.
  - `toImageSync` is one GPU copy per turn, not per frame.
- **Alternatives**:
  - a package (`turn_page_transition`): a flat fold, and it was declined;
  - a mesh of strips: more draw calls and a visible bend.

## R14. Storage

- **Decision**: schema 11 adds one column to `Settings`: `quranFont` (text, default `amiri`).
  - The page palettes reuse `pageColor`.
  - Tafsir files live on disk, not in the database. The share options aren't saved (the sheet
    today doesn't save them either).
- **Rationale**: one migration, the smallest one.

## R15. Tafsir files

- **Decision**:
  - The tool: `tool/quran/build_quran.dart --tafsir` reads QUL's Ibn Kathir (Arabic) and
    As-Sa'di exports from `tool/quran/.cache/` and writes `build/tafsir/ibn_kathir.json.gz` and
    `saadi.json.gz`. Each is `{surah: [text per ayah]}`, plain text, HTML stripped. It prints
    their sha256.
  - Ahmed downloads the two exports from QUL (it needs a sign-in) and uploads the outputs to a
    release of this repo. Both are `TODO(ahmed)`.
  - The app: `features/quran/data/tafsir_files.dart`, a copy of `recitation_files.dart`'s shape:
    - `TafsirSource { muyassar, ibnKathir, saadi }`, each with a url and a sha256 constant (a
      `TODO(ahmed)` until uploaded);
    - `download(source, onProgress)`: `HttpClient`, https only, writes to `.part` while hashing
      the stream with `crypto`'s sha256, then renames when the hash matches. It deletes `.part` on
      any failure and doesn't need Content-Length (progress is unknown without it);
    - files go in Application Support `tafsir/`, `BackupExclusion.exclude`;
    - `text(source, key)` reads the gz once into memory per source (about 10 MB for Ibn Kathir),
      kept while the reader is open.
  - `crypto` is already in the lock file through drift's tools. If it isn't a direct dependency,
    it's added: it's from dart.dev, the stack's own.
  - The same Content-Length fix goes in `recitation_files.dart`.
  - `StudyTabs`: a chip not downloaded shows a download mark, a tap starts the download with
    progress in the tab body, then the text.
  - Share text picker: Translation, Muyassar, Ibn Kathir, Sa'di.
- **Rationale**: principle VII (https, validated), VIII (downloaded once, cached). A sha256 is a
  stronger check than the recitation's sniffing.
- **Alternatives**: shipping in the app (+30 to 40 MB), or quran.com's API (a third-party service
  per ayah).

## R16. Home arc points

- **Decision**:
  - `home_moment.dart`: `ArcPoint(name, time, share)` and `arcPoints(now, yesterday, today,
    tomorrow)` return the arc's kind (day or night) and its points.
    - Day: sunrise, dhuhr, asr, maghrib over sunrise → maghrib.
    - Night: maghrib, isha, last third, fajr, sunrise over maghrib → next sunrise. The night before
      sunrise uses yesterday's maghrib.
    - `share` is the time's place between the two ends, 0 to 1.
    - Null times are left out.
  - `DayTimes.lastThird(nextFajr)`: `fajr' - (fajr' - maghrib) / 3`, in `core/prayer_times/
    day_times.dart`.
  - `nightShare` mirrors `sunShare`.
  - `SkyLabels` lays out each point's label just outside the arc, along its angle's normal. The
    end points keep today's spots under the horizon. A label that would overlap its neighbour, or
    any middle label above text scale 1.4, shows only its time.
  - The painter draws a dot (`SizeManager.arcPointDot`) at each share.
- **Rationale**: one shape for both arcs, so the painter and labels don't care which it is.

## R17. Night marker, sun shine and the wheel

- **Decision**:
  - Stars: three 8-point stars (`mushafStar` path, small) in a triangle around the marker's point.
    Each twinkles with `ambientBreathe` on its own period (2100, 2700, 3300 ms).
  - Sun: the pulse goes from 1.12 to 1.18 and the glow alpha from .5 to .6. Twelve rays (short
    lines from `r * 1.5` to `r * 2.1`, `sun` at .25) turn once per 60 s.
  - Wheel: `sky_header.dart` tweens a `turn` from 0 to 1 when the arc kind changes, 1800 ms on
    `sacred`, beside the sky tween. The painter rotates the outgoing arc's content by `π * turn`
    about the arc center, clipped at the horizon. The incoming content comes up from below by
    `π * (turn - 1)`. Labels fade out in the first half and in during the second.
  - With reduce motion it's a 300 ms crossfade of the two arcs.
  - The rays and twinkle stop with the ambient loop (low power, offscreen, reduce motion).
- **Rationale**: the brand page's sun-then-moon rotation, inside one painter, with no new ticker.
