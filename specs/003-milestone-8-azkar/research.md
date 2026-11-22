# Research: Milestone 8, Azkar, Tasbih and Duas

Checked on 2026-10-19 against the code on `feature/milestone-6`, the handoff (4.01, 4.08, 4.14,
5.1, 5.2, `03 Components.dc.html`, `01 Brand.dc.html`, MOTION.md), milestone 5's plan (the iOS
budget) and pub.dev (share_plus 13.3.1).

## R1. Where the code lives

- **Decision**:
  - `core/azkar/`: the morning and evening sets, their content loader, the windows and the
    progress. Home's row, the Azkar tab, the nudges (notifications feature, also in the background)
    and the tab badge (core shell) all read them, so they are core (constitution I).
  - `features/azkar/` (MVVM, as listed): the Azkar tab, the set page and Tasbih.
  - `features/duas/` (MVVM, as listed): Duas, the category page, save, listen and share.
  - `features/notifications/`: the nudges join the schedule there, reading `core/azkar/`.
  - Moved to core because a second feature now uses them (constitution IV, never two copies):
    Home's `HomeCard` and `ShortcutRow` (the Azkar tab rows), Home's `isMorningAzkar` (core
    windows), the prayer ring's painter (Tasbih's ring), the dua text block of milestone 5's
    `DuaSheet` (dua cards and zikr cards). See R15.
- **Rationale**: no feature imports another. Everything shared sits in core once.
- **Alternatives**: the sets inside `features/azkar/` (Home, the shell and the notifications would
  import a feature), one `features/azkar/` for duas too (the constitution lists duas on its own).

## R2. Content files

- **Decision**: two JSON assets, shapes in `contracts/content-files.md`:
  - `assets/azkar/azkar.json`: the morning and evening sets, each with its minutes and its items.
  - `assets/duas/duas.json`: the categories in order, each with its chip and its duas.
  - Every item has a stable `id`. Counts and saved duas are stored by it (FR-028).
  - A `note` field carries `TODO(ahmed): ...` on every sample entry, so
    `grep -rn "TODO(ahmed)"` finds them (JSON has no comments).
  - Loaded with `rootBundle` once and kept: `azkarContentProvider` (core) and
    `duasContentProvider` (duas). The background top-up loads `azkar.json` the same way,
    `rootBundle` already works there (it reads the arb files).
  - The three tasbih dhikr are the handoff's final content and live as consts in
    `features/azkar/model/tasbih_dhikr.dart`.
- **Rationale**: my dataset drops in as files with no code change. A JSON shape is easy to check
  and to fill from a source.
- **Alternatives**: Dart consts like `HomeSamples` (a dataset of hundreds of duas as code, and
  replacing it means editing Dart), drift tables seeded on first launch (a migration for every
  content update).

## R3. Sample content up to the designed counts (FR-029)

- **Decision**:
  - Morning (12) and evening (24): the components' zikr ("سُبْحَانَ اللَّهِ وَبِحَمْدِهِ", Sahih Muslim
    2692 · Sahih, 100 times) and the 4.14 dua (Abu Dawud 5095, once), taking turns, so a set has
    both a long count and a single one to check. Minutes: 3 morning, 6 evening (the 5.1 copy).
  - Duas: Leaving the home (1, the 4.14 dua) with chip Home, Waking up (1) chip Morning and
    evening, Before sleeping (3) chip Sleep, Entering and leaving the mosque (2) chip Home, Before
    and after eating (2) chip Home. Each entry repeats the 4.14 dua or milestone 5's dua after the
    adhan (Bukhari 614). Travel has no category yet.
  - Category names in both languages are mine to check: مغادرة المنزل، الاستيقاظ، قبل النوم، دخول
    المسجد والخروج منه، قبل الطعام وبعده.
  - No clip on any dua (R11).
- **Rationale**: no religious text beyond the handoff's (Q9). Under All the card is Leaving the
  home and the rows are the four designed ones with 1, 3, 2, 2 (FR-019).
- **Alternatives**: placeholder text ("Sample dua 2"), not text the design scenario can show.

## R4. Set windows and progress

- **Decision**:
  - `AzkarSet { morning, evening }`. `currentAzkarSet(period)`: morning in the Fajr, Duha and Dhuhr
    periods, evening otherwise (Home's existing rule, moved to core).
  - A window is named by its prayer day (milestone 4: Fajr to the next Fajr). The morning window
    of day D runs from Fajr(D) to Asr(D), the evening one from Asr(D) to Fajr(D+1).
  - The latest window of a set (`azkarWindowDay(set, prayerDay, period)`): morning → the prayer
    day. Evening → the prayer day once Asr has come, the day before during the morning periods.
    So at 10:00 the evening set shows last night's progress, at Asr it starts from 0 (FR-004).
  - Without a location: no period, both sets use today.
  - Old windows are deleted when a set is first counted in a new window. Nothing reads them, so the
    table stays a few dozen rows.
- **Rationale**: the same prayer day as the log, the strip and the notifications, so after midnight
  the evening set belongs to the day it started (edge case).
- **Alternatives**: calendar days (the evening would split at midnight), keeping every window
  (nothing reads them).

## R5. Storage, schema 4

- **Decision** (data-model.md):
  - `settings`: `tasbihDhikr` (0 to 2), `tasbihCount`, `morningOpenedOn`, `eveningOpenedOn` (the
    badge), `azkarNudges` (on by default).
  - `azkar_counts`: set, window day, zikr id, count. Primary key on the first three.
  - `saved_duas`: dua id, saved at.
  - One step `from3To4`, the v4 schema exported to `drift_schemas/`, the generated test schema and
    a v3 → v4 migration test.
- **Rationale**: tasbih is one dhikr and one count, two columns on the one row is the least code.
  A tap writes it, and the settings stream watchers all read through `.select()`, so nothing
  rebuilds for it. Set counts and saved duas are lists, so they get tables.
- **Alternatives**: a one row `tasbih` table (more code for two values), shared_preferences (not
  allowed).

## R6. A tap is felt at once

- **Decision**: Tasbih and the set page keep their state in a Riverpod `Notifier` that changes on
  the tap, in the same frame, and writes to the store without waiting (write through). The
  notifier loads from the store once when the page opens.
- **Rationale**: SC-002 asks for the haptic and the bead on the next frame. A round trip through
  the store's isolate and its stream can take a frame or two.
- **Alternatives**: reading the count back from the stream (a lag on fast taps).

## R7. Tasbih motion and layout

- **Decision**:
  - Layout from the 4.08 tree at text scale 1.0. Above it the page is a column: the chips (a
    sideways scroll), the dhikr block, then the counter area filling the rest as the tap target.
    The count's font stays inside the ring (its size doesn't follow text scale past what fits).
  - Ring: core `RingPainter` (R15), 240 box, r 114, stroke 5, from 12 o'clock, 300 ms standard
    (MOTION `ring`). Done: the radial glow behind (glow 35% to transparent at 62%).
  - Motion 11 (MOTION `d_tasbih`): the 11 beads move −44 pt with `BmMotion.snappy` through a
    `SpringSimulation`. A new tap retargets from the current position and velocity. Once settled
    the offset wraps by 44, so the strip never runs out. The count scales 1.06 → 1 in 150 ms.
  - Motion 12: the ring fills, then an 8 particle burst (`CustomPainter`, 700 ms decelerate).
    Reduce motion: beads step, the count swaps, the ring fills, no burst.
  - The ring, the beads and the count's digits sit in `Directionality(ltr)` (constitution II).
- **Rationale**: the tree's absolute positions break at text scale 2.0, a column keeps the lower
  area the tap target.
- **Alternatives**: an `AnimationController` per tap (queues, MOTION says retarget).

## R8. The set page

- **Decision**:
  - Compact bar with the set's name. A `PageView` of zikr cards (it reads right to left in Arabic
    by itself). The page opens at the first card not done.
  - The card: the components' azkar card. `DuaText` (R15) for the header, Arabic, transliteration
    and translation, then the footer with source · grading and the 90 pt progress bar. A Quran
    item uses the Quran font, its text never scales or moves on a tap.
  - A tap on the card: count + 1 (bead haptic, the bar 300 ms). At its number: the bar full, the
    count in primary with the check, the set complete haptic. The next tap moves to the next card
    (300 ms standard, a crossfade with reduce motion). Taps never count past the number.
  - The last card done: the header reads "Set complete", the set complete haptic plays once (not
    twice with the card's).
  - Opening the page writes the window to `morningOpenedOn` or `eveningOpenedOn`.
- **Rationale**: the same "tap after done moves on" as Tasbih (Q3).
- **Alternatives**: a list with every card (Q3 B).

## R9. The Azkar tab and the badge

- **Decision**:
  - `LargeTitleScrollView` (core) titled "Azkar". `SurfaceCard` with three `ShortcutRow`s:
    Morning (sunrise icon), Evening (night icon), Tasbih (tasbih icon). Then a second card with the
    toggle row (FR-041).
  - Routes `/azkar/morning`, `/azkar/evening`, `/azkar/tasbih` inside the Azkar branch, so the tab
    bar stays (4.08). Home's row and the nudge go there with `context.go`.
  - Badge: `azkarBadgeProvider` (core) is true when a location exists and the current set's window
    differs from its opened day. `AppShell` becomes a `ConsumerWidget` and passes it to `NavBar`,
    which draws the components' dot (7 pt, accent, a 2 pt surface ring).
  - The toggle row goes into `core/widgets/toggle_row.dart` (the components' toggle). More's
    settings in milestone 9 use the same one.
- **Rationale**: the shell is core and imports no feature. The badge is a core value.
- **Alternatives**: the toggle row in the feature and moved by milestone 9 (one move later for a
  component already drawn once).

## R10. Duas: chips, rows, search, saved

- **Decision**:
  - `duasViewFor(chip, content)` (pure): the card is the first dua of the chip's first category,
    the rows are the chip's categories, without the card's own unless it holds more than that dua
    (FR-019). All = every category. An empty chip gives nothing, the page shows "No duas found".
  - Search: `normalize()` folds case, Arabic diacritics (U+064B to U+065F, U+0670, U+06D6 to
    U+06ED), tatweel, أ إ آ ٱ → ا, ة → ه, ى → ي, Eastern digits → Western, and the
    transliteration marks (ā ī ū ḥ ṣ ḍ ṭ ẓ ʿ ’ and friends). A dua matches when every word of the
    query is in its normalized Arabic, transliteration, translation, source or category names.
    In memory, a few hundred duas take well under a millisecond.
  - Saved: a stream of `saved_duas` newest first. The "Saved" chip comes last.
  - Duas and its category page are routes outside the shell, like Qibla, since 4.14 has no tab
    bar. More gets a temporary button until milestone 9's tile.
- **Rationale**: one pure function for FR-019 that the tests cover on every chip.
- **Alternatives**: a search package (nothing to gain at this size), sqlite FTS (content isn't in
  the store).

## R11. Listen

- **Decision**: just_audio is already in (milestone 5). `DuaPlayer` (duas view model) holds one
  `AudioPlayer` and the id of the dua playing. Listen on a dua with a clip plays its asset, on the
  playing one stops it. A second dua stops the first. The pages stop it when they are disposed
  or are no longer the current route (`ModalRoute.isCurrent`), which covers the adhan screen
  coming over them. A dua without a clip: the tap does nothing. The loader names the folder for
  the clips with a `TODO(ahmed)`.
- **Rationale**: the adhan screen is a route on top, so "not current" stops the dua without the
  duas feature knowing about notifications.
- **Alternatives**: a core audio focus provider (more code for the same result).

## R12. Share

- **Decision**:
  - share_plus 13.3.1 (Flutter Community, 4,031 likes, 4.8 M downloads, 150 of 160 pub points,
    BSD 3, current). Approved in Q7.
  - The card: a widget 360 pt wide in the app's current theme and mode: the arch frame
    (`assets/ornaments/frame_arch.svg`), the dua's `DuaText`, the source, the wordmark for the
    language and mode. In Arabic the Arabic and the source only (FR-027). It grows taller with a
    long dua.
  - It is put in an `OverlayEntry` off screen inside a `RepaintBoundary`, painted once,
    `toImage(pixelRatio: 3)`, encoded to PNG, removed, then
    `SharePlus.instance.share(ShareParams(files: [XFile.fromData(png, mimeType: 'image/png')],
    sharePositionOrigin: ...))`.
- **Rationale**: the overlay renders with the app's fonts and theme, no extra package.
- **Alternatives**: a screenshot package (another package), text only (Q7 B).

## R13. Nudges

- **Decision** (contracts/nudges.md):
  - `AlertKind.azkar`, the prayer Fajr (morning) or Asr (evening), at its time + 20 minutes,
    sound silent. `buildNudges(now, days, done)` gives the next 3 that are after now and whose
    window isn't done. `topUp` adds them to the prayer alerts: 60 + 3 = 63, 64 with the dev test.
  - Ids from 2,000,000 (`days * 2 + set`), outside `alertFromId`, so the delivered cleanup leaves
    them alone. The payload uses the existing format with kind `azkar`.
  - Android: channel `azkar` ("Azkar"), default importance, no sound and no vibration. iOS:
    passive, no sound, into the list.
  - Texts: the set's name as title, "After Fajr/Asr · {count} remembrances, about {minutes}
    minutes" from `azkar.json` (count = items in the set).
  - Tap: `AzkarTarget(set)` → `Routes.azkarSet(set)`.
  - The boot's schedule inputs add `azkarNudges` and whether the morning and evening latest
    windows are done, so finishing a set or flipping the switch reschedules (500 ms debounce, as
    now).
- **Rationale**: milestone 5's budget is 61 of 64 on iOS (its research R6). Same rule on both
  phones, one test.
- **Alternatives**: a 5 day prayer schedule (Q2 B), Android getting all 12 (Q2 C).

## R14. Copy and plurals

- **Decision**: the FR-032 keys go into `StringsManager` and both arb files. Counts use ICU plural
  in the arb like `missedToMakeUp`. The nudge body has two counts, so `AppLocalizations.tr` formats
  every `{x, plural,` in a message, not only the first. A core change with its own test.
- **Rationale**: Arabic needs its own forms for both the count and the minutes.
- **Alternatives**: two keys glued together in code (word order breaks in Arabic).

## R15. Pieces moved to core

- **Decision**:
  - `features/home/view/widgets/home_card.dart` → `core/widgets/surface_card.dart` as
    `SurfaceCard` (Home's name doesn't fit the Azkar tab).
  - `features/home/view/widgets/shortcut_row.dart` → `core/widgets/shortcut_row.dart`.
  - `isMorningAzkar` in `home_moment.dart` → `currentAzkarSet` in `core/azkar/azkar_window.dart`.
  - The ring painter in `features/prayer/.../progress_ring.dart` → `core/widgets/ring_painter.dart`
    as `RingPainter`.
  - The block inside milestone 5's `DuaSheet` (title and source row, Arabic, transliteration,
    translation, Arabic only in Arabic) → `core/widgets/dua_text.dart` as `DuaText`. `DuaSheet`,
    the dua card and the zikr card use it.
  - Each move keeps its existing tests green with only the import changed.
- **Rationale**: constitution IV.

## R16. Design scenario

- **Decision**: `designScenarioStore()` also writes `tasbihCount: 16` (SubhanAllah). Nothing in
  `azkar_counts` or `saved_duas`. At 16:32 Asr has come, so the evening set is current at 0 of 24
  and the badge shows (never opened). The scenario never schedules (milestone 5).
- **Rationale**: 4.08 shows 16 of 33, Home shows 0 of 24.

## R17. Accessibility

- **Decision**: the tasbih area is one `Semantics(button)` with "{dhikr}, {count} of {target}. Tap
  to count", and `SemanticsService.announce` says "Set complete" at the target. The zikr card reads
  its text and "{n} of {count}". Listen, Save and Share read their labels, Save as "Saved" once
  saved. Every hit 44 x 44 (`SizeManager.hit`).
