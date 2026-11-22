# Feature Specification: Enhancements after the review

**Feature Branch**: `feature/enhancements`

**Created**: 2026-10-26

**Status**: Clarified

**Input**: User description, my notes after running milestones 1 to 12 and 7a:

```text
i want to edit some stuff (ask me any gaps and don't fill any one by yourself):
- when switching to another language and scroll down for more page the more title it's movd in oppsite way, i think it's still read the old rtl/ltr values, as it works normally when restart the app
- in "lib/features/quran/presentation/view/widgets/share_sheet.dart" the "turnOffTranslation" toast when appear it appears under the bottom sheet, i want it and all others taost appear above any widgets and bottom sheets
- i want to make share dua like aya customizations for colors and others
- make the nvigation bar blured glass for his under widgets like app bar

For Quran page:
- i want to be able to share several aya releated/or not releated to each others in same image share
  - maybe you can make a divider between ayas if it's not belong to each others
  - show waring message if the additional aya not fit the image share
  - if aya/ays with tafseer get overflow and there is no place for both, start to remove tafseer to have some space
- i want to be able to make the ayas customizable fonts
- the ayas get a little glitch and pixels and not clear and less resolution on runing on android device
- i want to make the tranistion between pages like real flip of page, get a little wavy and flip (make it the same physics of real flip page)
- i want to downalod ibn kathir tafseer and as-sa'di tafseer for all qaraun, and can choose between them when i share an aya image (and be carful of overflow text)
- i want to have different fonts for the quran itself
- i want to have a different thems for the quran
- i want to apply a some of Embroider/drwaing background for the ayas and add a switch button to remove it, and also switch button to make a single color rather than gradient

For Home page:
- i want to show times of praying times along around the rounded half circle, means at the left of the half circle shrouk (as current happend) and at the middle of it show duhr time, and at the right of it show asr time, and at the end show normally maghreb (as you did right now)
  - same for night time, show isha and fajir as you did, but also show the last a third of the night
  - i want to make the night circle end with sunrise not fajr, also show fajir time of the half circle
  - for now night half circle we have maghrab (at the beging of the left) + isha + third of the night + fajri + sunrise (at the end of right)
  - for now light half circle we have sunrise at the begining of left + durh + asr + maghrab (at the end of the right)
  - i want the transition between light and night be shooth and like circle transition between them
  - i want to show three starts as trangle shape around the dots of half circle, and that represent the current time the sunrises
  - i want to make the sun keeps a little shining when it's appearing, and also the three stars with thier own different
  - the verse of today, i think it's not realy random, i see it's alwyes show elfatha ayas, i want to make it randomized every day

- the logo when it's appear, it's not clear and less resolution

- make blur glass for popup dialog
```

This is a pass after reviewing everything built so far. It fixes four small things in the shell:
- the More title moving the wrong way after a language switch;
- toasts appearing under sheets;
- a soft splash logo;
- a verse of the day that never changes.

The nav bar and dialogs get the app bar's glass.

The share card becomes one sheet for ayahs and duas. It takes several ayahs, a font, an ornament,
a solid color and a choice of tafsir, including Ibn Kathir and As-Sa'di, which download once.

The reader gets sharp pages on Android, a font setting, more page palettes and a page curl.

Home's arc shows every prayer of the day and of the night, with the last third of the night and a
three star marker, and turns between day and night like a wheel. Several of these break the
handoff on purpose; they are listed at the end under Approved breaks.

## Clarifications

### Session 2026-10-26

- Q: Toasts? → A: Above everything: sheets, dialogs and the nav bar. Same look and spot as today,
  one at a time.
- Q: The glass nav bar? → A: The app bar's glass (blur and surface tint, lighter with the top
  glow). Tab content scrolls under it and ends above it.
- Q: Dialog glass? → A: The backdrop blurs like the sheets do. The card stays solid.
- Q: The soft logo? → A: The launch splash on iOS and Android. The symbol is redrawn bigger so it
  fills about 60% of the splash image instead of a third.
- Q: Dua share? → A: The same sheet as the ayah share: backgrounds, square or story, preview, app
  name, ornament, solid color and font. The dua's arch frame is one of the ornaments.
- Q: Choosing several ayahs? → A: Long press an ayah to start choosing, tap others to add or
  remove them, a bar shows "Share (n)" and Cancel. On the card they are in mushaf order.
- Q: Ayahs that follow each other and ones that don't? → A: Ayahs in a row flow as one block with
  their markers. A gap between them gets an ornament divider. The footer names every range, like
  "Al-Baqarah 255–257 · Āl ʿImrān 18".
- Q: When it doesn't fit? → A: First the text shrinks down to 70%, then the card becomes a story
  (unless I chose square myself), then tafsir drops from the last ayah back with a note "Tafsir
  hidden for n ayahs". If it still doesn't fit, that ayah isn't added and a warning toast says why.
- Q: Fonts? → A: Both the share image and the reader: Amiri Quran (today's), KFGQPC Uthmanic Hafs
  and Scheherazade New. The share sheet starts on the reader's font. KFGQPC ships with a
  `TODO(ahmed)` on its license.
- Q: Blurry pages on Android? → A: Compare on a device with and without the new renderer, at rest,
  turning and with the controls showing, report what shows, then fix it.
- Q: The page flip? → A: A real curl, my own code, no package. The page bends from the corner under
  the finger with a shadow, its back is plain paper a little darker, it settles with today's
  spring. It replaces Book, Slide stays, reduce motion stays the crossfade.
- Q: Ibn Kathir and As-Sa'di? → A: Arabic, built by our tool from QUL's exports, one file each,
  hosted as a release of this repo. Each downloads whole the first time I pick it, with progress,
  checked against a fingerprint and kept on the phone outside backups. The address and
  fingerprints are a `TODO(ahmed)`.
- Q: Where the tafsirs show? → A: The study tabs' Ibn Kathir and Sa'di chips (today "Coming soon")
  and the share sheet's text picker: Translation, Muyassar, Ibn Kathir, Sa'di in both languages.
- Q: A tafsir longer than the card? → A: Cut at a sentence end with "…". The ayah is never cut.
- Q: Quran themes? → A: More page palettes: Paper, Cream, Sepia, Green, Night and Navy, each with
  its own paper, ink and ornament, tinted by the app theme like today, plus Follow sky. I review the
  colors on the phone.
- Q: The ornament background? → A: For the share image. The khatam and star cross patterns already
  in the assets, with an Ornament switch and a Solid color switch (solid takes the gradient's
  middle color).
- Q: Prayer points on the arc? → A: Each at its real time on the arc with a dot and a label outside
  it. Dhuhr is the top. The two ends keep today's place under the horizon. Above text scale 1.4 the
  middle labels show only the time.
- Q: The night arc? → A: Maghrib → Isha → Last third → Fajr → Sunrise. The night for the last third
  runs Maghrib to Fajr.
- Q: The three stars? → A: The night's marker, three stars in a triangle moving along the arc at
  the current time, each twinkling on its own rhythm.
- Q: The sun shining? → A: A stronger glow pulse and faint rays turning slowly. Still with reduce
  motion.
- Q: Day to night? → A: A wheel: at Maghrib the sun sets off the right end, the arc turns half a
  circle under the horizon and the night arc rises with the stars at its left. Sunrise is the same
  the other way. 1800 ms like the sky change, a 300 ms crossfade with reduce motion.
- Q: Verse of the day? → A: The same verse for everyone on a date, from all ayahs of about 6 to 40
  words, so it reads on its own and fits the card. The text comes from the mushaf data.
- Q: Process? → A: Speckit as 008, built in four phases (quick fixes, share, reader, Home arc),
  stopping after each for my review.

### Session 2026-10-26 (after phase D)

Input: the tafsirs never download, the mushaf is still soft on my Android 14 phone, Home needs a
bar with the next prayer when it scrolls, and the splash still shows pixels.

- Q: Why do the tafsirs fail? → A: Nothing was hosted: the release didn't exist, this repo is
  private, the files were never built and the hashes were empty. The tool builds them from
  quran.com's api (the same texts QUL exports, no login), and they go on a release of a new public
  repo `better-muslim-content`, with the sha256 check kept.
- Q: The soft mushaf? → A: I run the four S1 builds (T053) on my Android 14 phone and say which one
  is sharp, then only that cause gets fixed.
- Q: Home's bar? → A: The 56 pt glass compact bar with the next prayer's name and its live
  countdown ("Asr · 1:23:45"). Like Prayer and More: the glass fades in once the card goes under
  the bar, and the name and countdown rise into it with the scroll, back down when scrolling up. A
  crossfade with reduce motion. A tap scrolls to the top. No bar with no location. While it shows,
  the status bar follows the theme.
- Q: The splash? → A: Real vector on both platforms (a vector drawable on Android, the svg kept as
  vector in the iOS asset catalog), the star at 40% of the splash icon instead of 60%.
  `flutter_native_splash` is removed so it can't write the bitmaps back.
- Q: Process? → A: Phase E of 008.
- Q: After the first try? → A: The splash strokes go to about 4 dp (my phone is a 2x OPPO, 2.5 dp
  lines were too thin). The name and countdown fly from the card into the bar like the More title,
  from the top of the scroll until the card reaches the bar or the scroll ends, the card's own copies
  hidden while they fly and the glass in for the last 30%. The mushaf gets a build without its ink
  layer, I run the four builds and the sharpest stays.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - The shell behaves (Priority: P1)

I switch the app to Arabic and scroll More, and the title moves into the bar from the right side
like it does after a restart. I share an ayah that doesn't fit as a square, and the toast shows
above the sheet where I can read it. I scroll Prayer, and the rows pass under a frosted nav bar
the way they pass under the app bar. A reset dialog opens over a blurred page. The splash logo is
sharp.

**Why this priority**: These are bugs or look broken. Each is seen every day.

**Independent Test**:
- Switch English → Arabic in More and scroll: the title travels from its right-side spot to the
  bar's center.
- Open the share sheet on a long ayah and tap Square: the toast is on top of the sheet.
- Scroll any tab: content shows blurred through the bar.
- Tap Reset prayer journey: the page behind blurs.
- Cold start on Android 12+ and iOS: the symbol is crisp and about twice today's size.

**Acceptance Scenarios**:

1. **Given** I switch language with More open, **When** I scroll, **Then** the title moves toward
   the bar's center from its new resting side, with no restart.
2. **Given** a sheet or dialog is open, **When** a toast shows, **Then** it draws above the sheet or
   dialog and its action works.
3. **Given** any tab, **When** content scrolls under the nav bar, **Then** it shows through blurred
   and tinted, and the last row can still scroll fully above the bar.
4. **Given** any app dialog, **When** it opens, **Then** the page behind blurs in with it and blurs
   out as it closes.
5. **Given** a cold start, **When** the splash shows, **Then** the symbol is sharp on both
   platforms.

---

### User Story 2 - A verse for today (Priority: P2)

Each day Home shows a different verse, and it's the same one on my wife's phone. Tapping it opens
the reader on that ayah.

**Why this priority**: The card is the same every day today, so nobody reads it twice.

**Independent Test**: In the design scenario the card shows the verse picked for 15 Oct 2026.
Moving the debug date a day gives a different verse. Tapping opens the reader on it.

**Acceptance Scenarios**:

1. **Given** a date, **When** Home shows, **Then** the verse is the one picked for that date and
   doesn't change during the day.
2. **Given** midnight passes, **When** Home is open, **Then** the next day's verse replaces it.
3. **Given** the verse, **When** I tap it, **Then** the reader opens on its page with it marked.

---

### User Story 3 - Share several ayahs (Priority: P1)

I long press Ayat al-Kursi, tap the two ayahs after it and one in Āl ʿImrān, and tap Share (4).
The card shows 255–257 as one block, a divider, then 3:18, and the footer names both. When I try
to add a fifth long ayah, a toast says it won't fit and it isn't added.

**Why this priority**: Sharing a passage is the common case, and the card took only one ayah.

**Independent Test**:
- Long press 2:255: select mode starts with it checked.
- Tap 2:256, 2:257 and 3:18 (another page). The bar reads "Share (4)".
- Share: the order is mushaf order, there is one divider, and the footer reads
  "Al-Baqarah 255–257 · Āl ʿImrān 18".
- Turn on Muyassar: tafsir drops from 3:18 first and the note shows.

**Acceptance Scenarios**:

1. **Given** the reader, **When** I long press an ayah, **Then** select mode starts with it
   checked, and the ayah sheet doesn't open.
2. **Given** select mode, **When** I tap an ayah, **Then** it is checked or unchecked, and the bar
   shows the count. **When** none is left checked, **Then** select mode ends.
3. **Given** select mode, **When** I turn pages, **Then** the choices stay.
4. **Given** chosen ayahs, **When** I share, **Then** they are in mushaf order. Ayahs in a row are
   one block, and a gap gets a divider.
5. **Given** the card overflows, **When** it's laid out, **Then** it shrinks to 70%, then becomes a
   story unless I chose square, then drops tafsir from the last ayah back with a note.
6. **Given** an ayah that doesn't fit even after all that, **When** I add it, **Then** a toast
   explains and it stays unchecked.
7. **Given** select mode, **When** I tap Cancel or go back, **Then** select mode ends with nothing
   chosen.

---

### User Story 4 - A share card that looks like mine (Priority: P2)

I share an ayah on Sky with the khatam pattern and Scheherazade, then switch off the pattern and
turn on Solid color. I share a dua and get the same sheet and the same choices.

**Why this priority**: The card is what other people see of the app.

**Independent Test**:
- Open share on an ayah: Font, Ornament and Solid color rows exist.
- Each change shows in the preview and in the shared image.
- Share a dua from Duas: the same sheet opens with the dua's arch frame as an ornament.

**Acceptance Scenarios**:

1. **Given** the share sheet, **When** I pick a font, **Then** the preview and the image use it,
   and the fit runs again.
2. **Given** a gradient background, **When** Solid color is on, **Then** it fills with the
   gradient's middle color.
3. **Given** Ornament on, **When** I pick a pattern, **Then** it draws faintly behind the text in
   the ornament color. **When** it's off, **Then** there's none.
4. **Given** a dua, **When** I tap Share, **Then** the same sheet opens with background, size,
   preview, app name, ornament, solid color and font, and the image ignores my text size.

---

### User Story 5 - Ibn Kathir and As-Sa'di (Priority: P2)

I tap Ibn Kathir in the study tabs. It asks to download once, shows progress, and then shows Ibn
Kathir on every ayah, even on a plane. In share I pick Sa'di under the ayah.

**Why this priority**: Muyassar alone is too short for study.

**Independent Test**:
- Tap the Ibn Kathir chip with internet: progress shows, then the tafsir for the open ayah.
- Turn on airplane mode and restart: it still shows.
- Corrupt the file's fingerprint in a test: the download is refused and nothing is kept.

**Acceptance Scenarios**:

1. **Given** a tafsir not downloaded, **When** I pick it, **Then** it downloads whole with
   progress, and I can cancel.
2. **Given** no internet, **When** I pick it, **Then** a toast says it needs internet once, and
   Muyassar stays.
3. **Given** a download whose fingerprint doesn't match, **When** it ends, **Then** nothing is
   kept and a toast says it failed.
4. **Given** a downloaded tafsir, **When** I share, **Then** the text picker offers it, and a
   tafsir longer than the card is cut at a sentence end with "…".
5. **Given** a downloaded tafsir, **When** I restore a backup or reset, **Then** it isn't in the
   backup file.

---

### User Story 6 - Sharp pages on Android (Priority: P1)

On my Android phone the mushaf text is as crisp as on the iPhone at rest, and doesn't shimmer
while it moves.

**Why this priority**: It is the Quran. Soft or broken glyphs are not acceptable.

**Independent Test**: On an Android phone, compare a page at rest, during a turn and with the
controls showing, before and after. No soft edges and no broken marks at rest.

**Acceptance Scenarios**:

1. **Given** a page at rest, **When** I look closely, **Then** the glyphs are as sharp as other
   text in the app.
2. **Given** the controls show, **When** the page shrinks, **Then** the glyphs stay clear without
   shimmering.
3. **Given** a turn ends, **When** the page settles, **Then** it is sharp in the next frame.

---

### User Story 7 - My font and my page (Priority: P2)

In Display I choose KFGQPC and Sepia. The mushaf and the translation view use them, and the share
sheet starts on KFGQPC.

**Why this priority**: People read the mushaf they grew up with, in the light they read in.

**Independent Test**:
- Display → Font → each of the three: the page lays out again, with every line justified and none
  past the frame.
- Display → page color → each palette: paper, ink and ornament change.

**Acceptance Scenarios**:

1. **Given** Display, **When** I pick a font, **Then** the mushaf, the translation view and the
   share sheet's default use it, and it survives a restart.
2. **Given** any font, **When** a page lays out, **Then** every line fits the frame.
3. **Given** Display, **When** I pick a palette, **Then** the page, ink, ornament and gutter change
   with an animation, tinted by my app theme.

---

### User Story 8 - A real page turn (Priority: P3)

I drag the corner of the page and it curls under my finger with its back showing and a shadow on
the next page. I let go past a third and it turns. I let go early and it falls back.

**Why this priority**: It's what makes reading feel like a mushaf, but the reader works without
it.

**Independent Test**: In Book mode drag from the bottom corner slowly: the page curls and follows.
A flick turns. A short drag falls back. Arabic and English turn the same way (the mushaf turns
right to left). Reduce motion gives the crossfade.

**Acceptance Scenarios**:

1. **Given** Book mode, **When** I drag, **Then** the page curls from the corner under my finger,
   the back is plain paper and a shadow falls on the next page.
2. **Given** I let go, **When** past the turn share or fast enough, **Then** it turns with the
   spring. **Otherwise** it falls back.
3. **Given** the first or last page, **When** I drag past it, **Then** it rubber-bands like today.
4. **Given** reduce motion, **When** I turn, **Then** it's the 150 ms crossfade.

---

### User Story 9 - The whole day on the arc (Priority: P1)

At 16:32 Home's arc shows Sunrise at its left foot, Dhuhr at the top, Asr past it and Maghrib at
the right foot, with the sun between Asr and Maghrib. At 23:00 it shows Maghrib, Isha, Last third,
Fajr and Sunrise, with three stars sitting just before Last third.

**Why this priority**: The arc is the first thing on Home, and today it only shows two times.

**Independent Test**: The design scenario shows the four day points with the sun at its real
place. Debug time 23:00 shows the five night points and the stars. At text scale 2.0 no label
overlaps another or leaves the screen.

**Acceptance Scenarios**:

1. **Given** day, **When** Home shows, **Then** Sunrise, Dhuhr, Asr and Maghrib each have a dot at
   their real time on the arc and a label with name and time.
2. **Given** night, **When** Home shows, **Then** Maghrib, Isha, Last third, Fajr and Sunrise show
   the same way, and the night runs to Sunrise.
3. **Given** night, **When** time passes, **Then** the three stars move along the arc at the
   current time, each twinkling on its own.
4. **Given** text scale above 1.4, **When** the arc shows, **Then** the middle labels show only
   their time.
5. **Given** Arabic, **When** the arc shows, **Then** it isn't mirrored (Sunrise left by day,
   Maghrib left by night) and the digits follow the digit setting.
6. **Given** a place where a time doesn't exist (polar), **When** the arc shows, **Then** that
   point is left out.

---

### User Story 10 - Day turns into night (Priority: P3)

At Maghrib the sun slides off the right end, the arc turns half a circle under the horizon, and
the night arc rises with the stars at its left. The sun breathes and its rays turn slowly while
it's up.

**Why this priority**: It's the moment that makes the sky feel alive, but nothing depends on it.

**Independent Test**:
- Debug time 17:55 → 17:57: the wheel turns in 1.8 s and the night points come up.
- 06:14 → 06:16: the same the other way.
- Reduce motion: a 300 ms crossfade, and no rays turning.

**Acceptance Scenarios**:

1. **Given** Maghrib or Sunrise passes, **When** Home is open, **Then** the arc turns over 1800 ms
   with its points and marker. Nothing jumps in one frame.
2. **Given** day, **When** the ambient loop runs, **Then** the sun pulses and its faint rays turn
   slowly.
3. **Given** reduce motion or the loop paused, **When** the sky changes, **Then** it's a 300 ms
   crossfade and the sun and stars are still.

---

### User Story 11 - The next prayer stays in sight (Priority: P2)

I scroll Home down to the verse and the shortcuts, and the next prayer with its countdown is in a
bar at the top. I tap the bar and Home goes back to the top.

**Why this priority**: The countdown is what Home is opened for. Scrolling shouldn't hide it.

**Independent Test**: Scroll Home to the end: the bar shows the next prayer and a ticking
countdown. Tap it: Home is at the top and the bar is gone.

**Acceptance Scenarios**:

1. **Given** a location, **When** the card goes under the bar, or Home is in its last bar height
   of scroll, **Then** the glass fades in and the name and countdown rise into it with the scroll.
2. **Given** the bar is half filled, **When** the scroll stops, **Then** it settles to empty or
   full.
3. **Given** reduce motion, **When** the bar shows, **Then** it only crossfades.
4. **Given** no location, **When** I scroll, **Then** there's no bar.

---

### User Story 12 - A crisp splash (Priority: P2)

I open the app cold on Android 14 and on iOS, and the symbol is sharp at any density and smaller
than before.

**Independent Test**: Cold start on both platforms: no soft or stepped edges on the strokes.

---

### Edge Cases

- **Language switch while More is scrolled halfway**: the title measures again and lands in the
  right place on the next scroll.
- **Toast during a route pop**: it stays above whatever is on top, and a second toast replaces it.
- **Nav bar glass over the Home sky**: the sky shows through. Contrast of the tab labels still
  meets AA in every theme and both modes.
- **Ayahs chosen across many pages**: the bar keeps counting. Long press on an ayah that's already
  chosen does nothing new.
- **One ayah too long alone (2:282) with tafsir**: tafsir drops, and the ayah is still shared as a
  story.
- **2:282 without tafsir, as a story**: it fits at 70% or less. If not, it is shrunk further until
  it fits, because the first ayah is always accepted (FR-018). The ayah is never cut.
- **Tafsir download stopped halfway (app killed)**: the partial file is deleted on the next try.
- **Server sends no size header**: the download still works, and the fingerprint is the check.
- **Tafsir chosen in share but not downloaded**: the picker shows it with a download mark, and
  picking it starts the download.
- **A font missing a glyph**: no font in the list is missing one for the Hafs text. This is checked
  on the phone on pages 1, 2, 50, 300 and 604 in each font (quickstart Phase C).
- **The wheel at Maghrib while Home is offscreen**: when Home comes back it shows the night state
  with no wheel.
- **Last third before Isha (far north summer)**: the points keep their real order, and labels that
  would overlap show only their time.
- **No location**: the arc shows no points, like today.
- **Verse of the day picks an ayah split over two pages**: its words are joined from both pages.

## Requirements *(mandatory)*

### Functional Requirements

**Shell**

- **FR-001**: A large title MUST take its start and end positions from the current text direction,
  measuring again when the language changes, with no restart.
- **FR-002**: Every toast MUST draw above sheets, dialogs and the nav bar, keep today's look,
  place, length and action, and replace a toast already showing.
- **FR-003**: The nav bar MUST be the app bar's glass: blur plus surface tint, lighter with the
  top glow on. Tab content MUST scroll under it, and every list MUST be able to scroll its last
  item fully above it.
- **FR-004**: Every app dialog MUST blur the page behind it, in step with its open and close, like
  the sheets. With reduce motion the blur fades.
- **FR-005**: The launch splash MUST show the symbol at about 60% of the splash image, sharp on iOS
  and Android, including Android 12+.

**Verse of the day**

- **FR-006**: Home's verse MUST be picked from the date alone, the same on every phone for a date,
  from all ayahs of 6 to 40 words, and change at local midnight.
- **FR-007**: Its Arabic MUST come from the mushaf's text, and its translation from the shipped
  translation. Tapping MUST open the reader on it.

**Share sheet (ayah and dua)**

- **FR-008**: One share sheet MUST serve ayahs and duas, with background, square or story, a live
  preview, app name, Ornament, Solid color and Font. Each content type adds its own rows (ayah:
  the text picker).
- **FR-009**: Ornament MUST draw a chosen pattern (khatam, star cross; for duas also the arch
  frame) faintly in the ornament color. Off draws none.
- **FR-010**: Solid color MUST fill a gradient background with its middle color. On a solid
  background the switch is hidden.
- **FR-011**: Font MUST offer Amiri Quran, KFGQPC Uthmanic Hafs and Scheherazade New, starting on
  the reader's font. It applies to the Arabic only.
- **FR-012**: The share image MUST ignore the phone's text size and be 1080 × 1080 or 1080 × 1920.
- **FR-013**: The card MUST use my app theme's tint.
- **FR-014**: The dua share MUST open this sheet instead of sharing straight away.

**Several ayahs**

- **FR-015**: A long press on an ayah MUST start select mode with it checked. In select mode a tap
  toggles an ayah, checked ayahs are marked on the page, a bar shows "Share (n)" and Cancel, and
  choices survive page turns. Unchecking the last one or Cancel or back ends it.
- **FR-016**: The card MUST list the chosen ayahs in mushaf order. Ayahs in a row are one block
  with their markers. A gap MUST get an ornament divider. The footer MUST name each surah and its
  ayahs in ranges.
- **FR-017**: When the card overflows, it MUST first shrink to 70%, then switch to story unless I
  chose square, then drop tafsir from the last ayah back, showing "Tafsir hidden for n ayahs".
- **FR-018**: When ayahs are already chosen, an ayah that can't fit with them after FR-017 MUST
  NOT be added, and a toast MUST say it doesn't fit. The first ayah is always accepted, and if it
  doesn't fit alone even after FR-017, the card shrinks below 70% until it does. The ayah text
  MUST never be cut.

**Tafsir**

- **FR-019**: Ibn Kathir and As-Sa'di (Arabic) MUST be downloadable, each as one file for the whole
  Quran, over https, with progress and cancel.
- **FR-020**: A download MUST be kept only if its fingerprint matches the one built into the app,
  MUST work without a size header, and MUST leave nothing behind when it fails.
- **FR-021**: Downloaded tafsirs MUST stay on the phone, work offline and stay out of iCloud,
  Android auto backup and the app's backup file.
- **FR-022**: The study tabs' Ibn Kathir and Sa'di chips MUST show the tafsir, downloading it on
  the first pick.
- **FR-023**: The share sheet's text picker MUST offer Translation, Muyassar, Ibn Kathir and Sa'di
  in both languages. One not downloaded shows a download mark.
- **FR-024**: A tafsir longer than the space left MUST be cut at a sentence end with "…".

**Reader**

- **FR-025**: Mushaf glyphs MUST be sharp at rest on Android and iOS, and MUST NOT shimmer while
  the page scales for the controls or the study sheet. The cause MUST be found on a device first
  and written in the plan.
- **FR-026**: Display MUST have a Font row (FR-011's three), saved with the settings and used by
  the mushaf and the translation view. Every line MUST fit the frame in every font.
- **FR-027**: Display MUST offer the page palettes Paper, Cream, Sepia, Green, Night, Navy and
  Follow sky, each with its own paper, ink, ornament and gutter, tinted by the app theme.
- **FR-028**: Book turns MUST curl the page from the corner under the finger, show its plain back
  a little darker and cast a shadow on the page under it. They MUST settle with today's spring,
  turn and fall back rules and rubber band. The glyphs MUST only move with the page.
- **FR-029**: Slide mode and the reduce-motion crossfade MUST stay as they are.

**Home arc**

- **FR-030**: By day the arc MUST show Sunrise (left foot), Dhuhr, Asr and Maghrib (right foot),
  each with a dot at its real time on the arc and a label with name and time.
- **FR-031**: By night it MUST show Maghrib (left foot), Isha, Last third, Fajr and Sunrise (right
  foot). The night runs Maghrib to the next Sunrise.
- **FR-032**: The last third MUST start at Fajr minus a third of Maghrib to Fajr.
- **FR-033**: At night three stars in a triangle MUST sit on the arc at the current time, each
  twinkling on its own rhythm, in place of the sun.
- **FR-034**: Above text scale 1.4 the middle labels MUST show only their time. No label overlaps
  another or leaves the screen at 2.0. Points closer than a label's width show only the time.
- **FR-035**: By day the sun MUST pulse more strongly than today and show faint rays turning
  slowly. Both stop with reduce motion, low power or when Home is offscreen.
- **FR-036**: At Maghrib and Sunrise the arc MUST turn half a circle around its center under the
  horizon over 1800 ms on the sacred curve, taking the points and marker with it. With reduce
  motion it MUST be a 300 ms crossfade.
- **FR-037**: The arc MUST never be mirrored in Arabic, and its times MUST follow the digit
  setting. In Arabic the Asr arc label MUST sit inside the arc, and so must any other middle
  arc label the screen edge pushes onto it.

**Everywhere**

- **FR-038**: Every new string MUST be in `StringsManager` and both arb files, in my tone.
- **FR-039**: Every new animation MUST have its reduce-motion fallback, and every new hit target
  MUST be at least 44 × 44.

**Phase E**

- **FR-040**: Both tafsir files MUST be built by the tool from quran.com's api. An ayah the api
  leaves out MUST repeat the ayah before it, as a group does.
- **FR-041**: They MUST be downloaded from the public `better-muslim-content` release over https
  and kept only when their sha256 matches.
- **FR-042**: The card's name and countdown MUST stay in the card until the card's top reaches the
  bottom of the compact glass bar. From there they fly with the scroll, level with the card,
  shrinking and sliding to the bar's title, until the name is on it. The card's own copies hide
  while they fly. A page too short for that gets blank room under the shortcuts, only as much as
  it needs.
- **FR-043**: The glass MUST come in for the last 30% of the flight. A flight halfway MUST settle to
  its start or end when the scroll stops, and before the flight the page rests anywhere. With
  reduce motion nothing flies, the bar crossfades in at the same point. A tap MUST scroll Home to
  the top.
- **FR-044**: While the bar shows, the status bar icons MUST follow the theme. With no location
  there is no bar.
- **FR-045**: The launch splash MUST be vector on Android and iOS, the star 40% of the splash icon,
  strokes about 4 dp.

### Key Entities

- **Ayah selection**: whether select mode is on, and the chosen ayahs. Lives while the reader is
  open.
- **Share options**: background, size, solid color, ornament and its pattern, font, app name, and
  for ayahs the text choice. Live while the sheet is open.
- **Tafsir source**: Muyassar (shipped), Ibn Kathir or Sa'di (downloaded). Each with its address,
  fingerprint and whether it's on the phone.
- **Quran font**: Amiri Quran, KFGQPC Hafs or Scheherazade New, saved with the settings.
- **Page palette**: paper, ink, second ink, ornament and gutter for each of the six, saved as today's
  page color.
- **Arc point**: a name, a time and its place on the arc between the arc's two ends.
- **Verse of the day**: the date and the ayah picked for it.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After a language switch the More title lands in the bar's center on the first scroll,
  in both directions, with no restart.
- **SC-002**: Every toast in the app is readable over any open sheet or dialog.
- **SC-003**: Over 30 days, no verse of the day repeats twice in a row, and every phone shows the
  same one on a date.
- **SC-004**: A passage of 3 ayahs plus one from another surah is shared in under 15 seconds from
  the first long press.
- **SC-005**: No share image ever cuts an ayah. Every overflow ends in a smaller scale, a story,
  hidden tafsir or a warning.
- **SC-006**: Both tafsirs download once on a normal connection, then show offline on every ayah.
- **SC-007**: On a mid-range Android phone the mushaf at rest is as sharp as the app's other text,
  and turns run at the phone's full refresh rate.
- **SC-008**: Every font lays out all 604 pages with no line past the frame.
- **SC-009**: At text scale 1.0 and 2.0, in English and Arabic, the day arc's 4 points and the night
  arc's 5 points are all readable with no overlap.
- **SC-010**: Day to night and night to day never swap anything in one frame.

## Assumptions

- The KFGQPC font is free to ship with the app. The `TODO(ahmed)` is where I confirm the license
  before release.
- Scheherazade New and Amiri Quran are OFL. Their credits go under Acknowledgements.
- quran.com's Ibn Kathir and Sa'di may be redistributed with credit. The credit goes under
  Acknowledgements.
- The release host is the public `better-muslim-content` repo's GitHub releases. Downloading from
  it is the network use principle VIII allows: content that is cached afterwards.
- The page palette colors are my proposal, not the designer's. I review them on the phone.
- The curl's look (shadow strength, back tint) has no design. I review it on the phone.
- The night marker, rays and wheel have no design beyond the brand page's sun and moon loop. I
  review them on the phone.
- The verse candidates skip the disjoined letters alone (like "الم") because they are under 6
  words.
- No new pub package. The curl, glass and toast are our own code.

## Approved Breaks

The constitution says the handoff is built as it is (principle III). These change it on my
instruction of 2026-10-26:

- README "Night: no sun, labels Isha / Fajr" and 4.01/4.16's two labels: the arc shows four points
  by day and five by night, with a three star marker and a wheel between them.
- 4.01 sun: the glow is stronger and gets rays, still within MOTION.md's loop rules.
- The nav bar is glass instead of solid surface, and content runs under it.
- The dialog barrier blurs.
- Milestone 7 FR-041: the share card takes several ayahs, more options and a tafsir choice, and the
  dua share uses the same sheet.
- Milestone 7 FR-011: the mushaf font is a choice of three, Amiri Quran stays one of them.
- Milestone 7 research R7: Book turn is a curl instead of a rotation.
- Page colors: Cream gets its own colors, and Sepia, Green and Navy are added.
- Home's verse card is no longer the handoff's sample verse.
- Home gets a compact bar with the next prayer when it scrolls. The handoff gives Home no bar.
- The splash star is 40% of the splash icon.
