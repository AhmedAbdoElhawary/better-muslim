# Research: Milestone 7a, Quran Mushaf Reader

Every unknown in the plan's Technical Context, with the decision taken.

## R1. Text and page layout source

- **Decision**: QUL (Quranic Universal Library, qul.tarteel.ai) "Mushaf Al Madinah V2 (1421H print)"
  layout, 604 pages x 15 lines. Its pages table gives page, line, line type (ayah, surah_name,
  basmallah), centered flag, first and last word id. Words come from the same export (word id →
  surah, ayah, position, QPC Hafs text). `tool/quran/build_quran.dart` turns the export into the
  app's assets (contracts/quran-assets.md).
- **Rationale**: it is the same print QCF V2 is drawn from, so the day the licensed fonts come in,
  only the glyphs change, the lines and hit areas stay. QUL's data is meant to be packaged into apps
  and ships as sqlite or json, no api.
- **Alternatives**: Tanzil text with my own line breaking (lines would never match print);
  quran.com's api (online, breaks VIII); QCF V2 data alone (needs the fonts' license first).
- **Open for me**: QUL needs a sign in to download, and its license terms aren't on the resource
  page. `TODO(ahmed)` in the tool: download the two files into `tool/quran/.cache/` and confirm the
  license and credit line.

## R2. Rendering the page without QCF V2

- **Decision**: one `MushafPage` render object draws a page, its text style from `GetRegularStyle`
  in `lib/core/resources/styles_manager.dart` (`font: FontEnum.quran`), so no `TextStyle(` sits in
  the feature (architecture test). It draws a page: each line's words are measured in
  Amiri Quran at one font size for the whole page, then laid out right to left with the leftover
  width shared between the gaps (a justified line, like print). A line wider than the page is
  scaled down horizontally on its own. Centered lines (surah ends, page 1 and 2) are centered.
  Surah name lines draw the cartouche with the name, basmallah lines the Bismillah.
- **Line metrics**: pages 1 and 2 use 4.19's opening (58 pt lines inside the frame). The design has
  no regular page, so pages 3 to 604 split the frame's inner height into 15 equal bands (about 45 pt
  on a 393 pt phone) and take the largest font size at which the page's widest line fits, one size
  for the page. Both get named entries in the managers. `TODO(ahmed)`: a regular page from the
  designer.
- **Rationale**: the line content is fixed by the layout, so nothing reflows at any size. The page
  is laid out once and cached per page, so turning is only painting. Each word keeps its rect, which
  gives the hit test (R3) and the washes (R4) for free.
- **Alternatives**: one `RichText` per line with word spacing (no per word rects, harder hit test);
  a `Wrap` of word widgets (thousands of widgets per page, slow turns).
- `TODO(ahmed)` where the font is picked: QCF V2 per page fonts once licensed.

## R3. Hit testing

- **Decision**: a tap finds the line band under the finger (the full line height, at least 44 pt),
  then the word whose rect is nearest on that line, then its ayah. Long press does the same (word by
  word in 7b gets the word). A tap in the margin outside the text toggles the controls; the left 12%
  of the page turns to the next page (FR-008, US1).
- **Rationale**: line bands are never under 44 pt, so every ayah part is reachable (FR-052).

## R4. Selection and follow washes

- **Decision**: painted by the same render object, behind the glyphs: for each line part of the
  ayah, one rounded rect (radius 9) from its first to its last word, in `selectionWash` or
  `followWash` (data-model.md, palette). The wash fades in 150 ms by animating only its alpha.
- **Rationale**: the glyphs are never recolored or moved, the rule in 09 Quran and the constitution.

## R5. Page palettes

- **Decision**: `BmPagePalette` in `lib/core/resources/design/` with paper and night exactly as
  `K.PAGE` in `_gen/kit.js` (bg, surface, raised, variant, outline, text roles, primary, containers,
  accent, page, ink, ink2, ornament, ornament2, selection wash, follow wash, hidden, gutter). The
  reader wraps its subtree in a theme whose `BmPalette` is the page palette, so every
  `context.getColor` inside the reader reads the page, and the chrome takes the page palette, not
  the app mode (FR-010). New `ThemeEnum` roles: `page`, `ink`, `ink2`, `ornament`, `ornamentSoft`,
  `selectionWash`, `followWash`, `pageHidden`, `gutter`. Outside the reader they resolve to paper or
  night by the app's brightness.
- **Themes** (added 2026-10-22): the page follows the app's theme. `BmPagePalette.tint` keeps the
  paper, ink, chrome surfaces and text, and takes primary, accent, their containers and glow from
  the active theme. Ornament, soft ornament, selection and follow washes are the same mixes K.PAGE
  makes from Qiyam Emerald, made from the theme's glow, primary and accent. Qiyam Emerald gets K.PAGE
  back exactly. The share card keeps its designed palettes.
- **Cream**: the design names it (4.31) but `K.PAGE` has no cream values. Until the designer sends
  them, Cream uses paper's values with a `TODO(ahmed)` in the palette file.

- **Glass**: the reader's bars use the page's surface at 78% with a 24 pt blur and 1.5 saturation
  (`GLASS` in `_gen/quran.js`), a new `pageGlass` role, not the app's dark `glass`.
- **Contrast**: ink, ink2, text2 and text3 on page, surface and bg checked for WCAG AA in tests.

## R6. Follow the sky

- **Decision** (changed 2026-10-22): the page's Follow sky follows the app's own mode, paper when
  the app is light and night when it's dark. The app's Follow sky already switches at sunrise and
  Maghrib, so one rule drives both, and a picked Dark or Light or the phone's mode is respected.
  Before it was paper from Fajr to Isha and night from Isha to Fajr, read from the prayer period.
  `PageColor.resolve` in `core/settings/quran.dart`.

## R7. Page turn

- **Decision**: a `PageTurn` widget owns the page index and one `AnimationController` driven by the
  drag. Book: the turning page rotates on the spine with a perspective `Matrix4` (rotateY), a
  shading gradient that follows the angle on top of it, and the next page under it. Release springs
  to done or back with `SpringSimulation(BmMotion.gentle, ...)` from the finger's velocity. Past 35%
  or a fling over 700 px/s completes (Motion v2's rule). Slide: a plain 300 ms slide. Reduce motion:
  150 ms crossfade. Only the current page and its two neighbours are built.
- **Rationale**: transform and opacity only, each page in a `RepaintBoundary`, so the turn stays in
  the frame budget (SC-002).

## R8. Translation and Tafsir

- **Decision**: Tanzil's `en.sahih` (Sahih International) and `ar.muyassar` (Tafsir al-Muyassar),
  shipped in full, one file per surah. In Arabic the translation slot shows Al-Muyassar (FR-020).
  Ibn Kathir, As-Sa'di and Clear Quran: sample Al-Fatiha text from 09 Quran in
  `assets/quran/samples.json`, "Coming soon" on other ayahs.
- **Rationale**: Tanzil allows both for non commercial use with credit, and the app is free.
- **Open for me**: `TODO(ahmed)` in the tool: confirm Sahih International's and Al-Muyassar's terms
  for the store build, and supply the other three when licensed.

## R9. Recitation source and files

- **Decision**: EveryAyah, `https://everyayah.com/data/Alafasy_128kbps/{SSS}{AAA}.mp3`, one file per
  ayah. Every surah but 1 and 9 starts with `001001.mp3` as its Bismillah, which takes the follow
  wash on the Bismillah line. Files go to Application Support `recitations/alafasy/`, excluded from
  iCloud with `BackupExclusion` and out of the backup file. `TODO(ahmed)` at the base address.
- **Check before play** (FR-032): written to `.part`, renamed only when the byte count equals
  `Content-Length` and the file starts with an ID3 tag or an MPEG frame sync. Anything else is
  deleted. Requests carry no headers beyond the defaults (FR-034).
- **Downloads ahead**: the playing ayah first, then the rest of the surah one at a time (FR-031).

## R10. Background play: `audio_service`, not `just_audio_background`

- **Finding**: `just_audio_background` "supports the simple use case where an app has a single
  `AudioPlayer` instance". The app already has two (`JustAudioClipPlayer` for clips and the adhan
  preview, `AdhanPlayer` for the in-app adhan), and the recitation would be a third.
- **Decision**: `audio_service` 0.18.19 (same author, 1.3k likes, 140 pub points, it is what
  `just_audio_background` is built on) with one `RecitationHandler` around the recitation's own
  `AudioPlayer`. The other two players stay untouched. Android: `MainActivity` extends
  `AudioServiceActivity`, the manifest gets the service and media button receiver. iOS: the
  `audio` background mode is already on.
- **Approved** 2026-10-21.

## R11. Gapless, repeat, range, pause, speed, sleep

- **Decision**: the range becomes one `just_audio` playlist of the ayah files, each ayah in it as
  many times as Repeat each ayah says, so repeats and ayah changes stay gapless. With a pause
  between ayahs, the handler pauses on each index change that moves to a new ayah and plays again
  after the pause. Speed is `setSpeed`. The sleep timer ramps the volume to 0 over 3 s, then stops.
  End of surah stops after the last ayah.
- **Following**: `currentIndexStream` gives the playing ayah within one frame of the file starting
  (SC-003).

## R12. Interruptions and the adhan

- **Decision**: `audio_session` with the music config, the same as the clip and adhan players, so
  the shared session never flips between configs. A call, another app or unplugged headphones
  pause and never resume on their own (FR-028). The in-app adhan claims `core/audio/audio_use.dart`
  (a tiny notifier: none, recitation, adhan) before it plays, and the recitation pauses when the
  adhan claims it. The Android full adhan from `adhan_alarms` takes audio focus, which pauses it
  through the same interruption path.

## R13. Container transform, stagger, skeleton, loader

- **Decision**: `animations` 3.0.0 (flutter.dev, 160 points) `OpenContainer` wrapped as
  `BmContainerTransform` in `core/widgets/motion/` with 520 ms, the standard curve, radius 20 to 0,
  and a 150 ms crossfade with reduce motion. `BmStagger` (an `Interval` per index, capped at 8),
  `BmSkeleton` (a 1200 ms shimmer, handed over by `AnimatedSwitcher` at 150 ms) and `BmOilDrop` (a
  `CustomPainter` on one repeating controller and one spring driven level, from Motion v2's
  snippet) live there too, with `BmLoaderGate` for the 400 ms delay and 600 ms minimum.
- **Oil colors** `#D9BE86 → #8C7444` go into `BmPalette` as the two oil roles, in the handoff
  values file.

## R14. Keep screen on, copy, share image

- **Keep screen on**: one more method on the app's own `better_muslim/system` channel: iOS
  `isIdleTimerDisabled`, Android `FLAG_KEEP_SCREEN_ON`, set when the reader opens and cleared when
  it closes. No package.
- **Copy**: `Clipboard.setData` with the Arabic, the translation and "Al-Fatiha 1:5".
- **Share image**: the card is built off screen at 1080 x 1080 or 1080 x 1920 logical pixels in a
  `RepaintBoundary`, `toImage` to png, sent with `share_plus` (already in). The text size goes down
  in steps until the ayah fits whole; under the smallest step, story size.

## R15. Where the code lives

- The four enums stored in settings (`PageColor`, `QuranLayout`, `PageTurn`, `RibbonColor`) live in
  `lib/core/settings/quran.dart` beside the other settings enums, because core can't import the
  feature.
- `core/quran/`: the assets reader (surahs, pages, ayah to page) and last read, because Home's
  Continue reading and verse card need them and features can't import each other.
- `features/quran/`: clean (constitution), with data (assets source, downloads, bookmarks and notes
  store, recitation handler), domain (page, line, word, ayah, bookmark, note, the recitation queue
  rules) and presentation.
