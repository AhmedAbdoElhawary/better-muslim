# Feature Specification: Milestone 7a, Quran Mushaf Reader

**Feature Branch**: `feature/milestone-7`, cut when the build starts

**Created**: 2026-10-17, rewritten 2026-10-21 for the new design

**Status**: Draft

**Input**: User description: "Quran reader, 09 Quran.dc.html"

The Quran design is now `design_handoff_better_muslim/design/09 Quran.dc.html` (4.18 to 4.31). It
replaces the first version of this spec, which was built on 4.07 alone. The reader is page first: one
page of the 604 page Madinah Mushaf (Hafs) at a time, turned like paper. The translation view (4.07)
becomes the second layout and shares the same position.

Milestone 7 is split in two:

- **7a (this spec)**: Quran home (4.18), the Mushaf page on paper and night (4.19, 4.20), page
  controls (4.21), the page turn, ayah actions (4.22), tafsir and translation (4.23), the recitation
  (4.25), bookmarks and notes (4.29), share as image (4.30), display settings (4.31) and the
  translation layout (4.07).
- **7b (later spec)**: word by word (4.24), memorise (4.26), search (4.27), khatmah plan (4.28),
  highlights and tajweed colors.

7a starts with a motion phase from `11 Motion v2.dc.html`: only the parts the reader needs and the app
doesn't have yet, built in `core/` so Zakat and the rest reuse them. The oil drop loader (00, L3,
L4), the container transform (04), the list entrance (06) and skeletons (07). Push and swipe back,
the toast, the dialog and press feedback already exist from milestone 12 and stay. The rest of
Motion v2 (fade through tabs, the mode reveal, pull to refresh on Home, the launch handoff, count up)
is its own milestone later.

The screens have no `specs/screens/*.md` tree and no PNG yet. They are built from the `.dc.html`
file itself (its `_gen/quran.js` source in `Living Sky prayer app branding 2/` has the exact
markup), with the 4.07 tree for the translation layout. The Quran text is never animated,
overlapped, cropped or used as decoration.

## User Scenarios & Testing *(mandatory)*

### User Story 0 - Wait and open the way Motion v2 does (Priority: P1)

When something takes longer than a moment, the logo becomes a lamp: a drop of oil gathers at the
star, falls through the sun arc and ripples into a pool. When the app knows how far along it is, the
pool rises with it. A card opens into its own screen by growing out of itself, and a list's first
appearance rises in row by row out of skeletons of its own shape.

**Why this priority**: The reader opens with the container transform and waits on downloads, so
these pieces come first, and building them in core keeps the next features from copying them.

**Independent Test**: In Dev, the motion page from More shows the loader looping, at 16 pt with
only the pool and sun, and with a progress slider that the pool follows. Open a surah row: it grows
into the page. Open the Quran tab the first time: skeletons, then the rows rise in. Turn on reduce
motion: the loader is a sun pulse and the open is a crossfade.

**Acceptance Scenarios**:

1. **Given** a wait with no known progress, **When** it passes 400 ms, **Then** the oil drop loader
   shows, and once shown it stays at least 600 ms and ends on a completed ripple, never mid fall.
   A wait under 400 ms shows nothing.
2. **Given** a known progress (a recitation download), **When** it moves, **Then** the pool level
   springs to it and at 100% the oil reaches the horizon and the sun lights.
3. **Given** a loader under 32 pt (in a button or row), **When** it runs, **Then** only the pool
   moves and the sun pulses, and the button keeps its width.
4. **Given** a card or row that opens its own screen, **When** I tap it, **Then** its bounds grow to
   the screen in 520 ms (radius to 0) with its content crossfading in the middle 40%, and back
   shrinks it into place. A tap mid flight reverses it from where it is.
5. **Given** a list's first appearance on a screen, **When** it loads, **Then** skeletons of its
   final shape shimmer (1200 ms), the content replaces them in one 150 ms crossfade with no layout
   shift, and the rows rise 12 pt and fade in 30 ms apart, the eighth and later together.
6. **Given** reduce motion, **Then** the loader has no drop or wave and the sun fades between 45% and
   100% on the same 1600 ms cycle, the container transform is a 150 ms crossfade, the rows appear at
   once.
7. **Given** the app in Arabic, **Then** the loader, the sun and the pool are not mirrored.

---

### User Story 1 - Read the Mushaf page by page (Priority: P1)

I open the Quran tab, tap a surah or Continue reading, and the page grows out of its thumbnail into
the whole screen. I read the Madinah page as it is printed and turn it like paper, dragging it or
tapping its edge. After Isha the page turns to night by itself.

**Why this priority**: Reading is what the tab is for. Every other story sits on top of the page.

**Independent Test**: In the design scenario open Al-Fatiha from the Quran tab: page 1 shows with
its illuminated frame, the "سُورَةُ الفَاتِحَةِ" cartouche, 7 ayahs with their markers and the page
number "١" in the star. Drag the page to the right: page 2 opens with Al-Baqarah. Set the scenario
time after Isha: the page is the night page.

**Acceptance Scenarios**:

1. **Given** the Quran tab, **When** I tap Continue reading or a surah row, **Then** the page opens
   with a container transform from the thumbnail or row (520 ms), the tab bar hidden. Back reverses
   it into the same place.
2. **Given** a page, **When** I drag it to the right or tap its left edge, **Then** the leaf turns
   on the spine with live shading and settles with my release velocity. Dragging back returns it.
   Page 1 has no previous page and page 604 no next.
3. **Given** display settings at Slide, **When** I turn a page, **Then** it is a plain 300 ms slide.
   With reduce motion on it is always a 150 ms crossfade.
4. **Given** page color at Follow the sky, **When** Isha comes in while I read, **Then** the page
   crossfades to night over 1.8 s (sacred curve), and back to paper at Fajr.
5. **Given** a page, **When** I tap its margin, **Then** the controls arrive on glass and the page
   springs back to a card (spring.gentle), so no control ever sits over the text. Tapping again
   hides them.
6. **Given** the controls, **When** I drag the scrubber, **Then** it runs right to left with juz
   ticks, shows "Page {n} · Juz {j}" as I go, and opens that page on release.
7. **Given** the app in Arabic, **When** I read, **Then** the page is the same page, the chrome
   follows RTL, and the scrubber and page turn keep the Mushaf's direction.

---

### User Story 2 - Act on an ayah (Priority: P1)

I tap an ayah. It takes a soft gold wash and a sheet rises with its translation and actions: Play
from here, Tafsir, Bookmark, Note, Share and Copy. Tafsir opens the large sheet where I read the
tafsir, the translation and my notes, and move to the next ayah without closing.

**Why this priority**: The ayah sheet is the door to everything the reader offers beyond reading.

**Independent Test**: Tap ayah 5 of Al-Fatiha: it is washed in gold, the sheet shows "Al-Fatiha ·
Ayah 5", "Juz 1 · Page 1 · Meccan", "It is You we worship and You we ask for help." and "Sahih
International". Tap Tafsir: the page recedes, the Al-Muyassar text shows. Tap the forward arrow: ayah
6 with its tafsir.

**Acceptance Scenarios**:

1. **Given** a page, **When** I tap an ayah, **Then** it takes the gold wash in 150 ms, the sheet
   springs to its medium detent, and the page lifts only as far as needed to keep the ayah 24 pt
   above the sheet.
2. **Given** a page, **When** I long-press a word, **Then** its ayah is selected the same way (word
   by word itself comes in 7b).
3. **Given** the ayah sheet, **When** I tap Tafsir, **Then** the sheet goes to its large detent, the
   page recedes behind it (card stack), with the ayah on top and the tabs Tafsir, Translation and
   Notes.
4. **Given** the large sheet, **When** I tap the back or forward arrow, **Then** the previous or next
   ayah shows, its wash moves on the page, and the sheet stays open.
5. **Given** the ayah sheet, **When** I tap Copy, **Then** the Arabic, the translation and the
   reference ("Al-Fatiha 1:5") are copied and a "Copied" toast shows.
6. **Given** the ayah sheet, **When** I close it or tap outside, **Then** the wash fades and the
   page settles back.

---

### User Story 3 - Listen and follow along (Priority: P1)

Play from here starts Mishary Alafasy at that ayah. The mini player rises, the playing ayah takes
the emerald follow wash and the reader turns the page with the recitation. The full sheet lets me
repeat each ayah, pick a range, pause between ayahs and set a sleep timer. It keeps playing with
the phone locked, and a surah I played once plays again offline.

**Why this priority**: Recitation that follows the page is the second promise of the reader.

**Independent Test**: Play from ayah 1 of Al-Fatiha: ayah 1 takes the follow wash, the mini player
reads "Al-Fatiha · Ayah 1", and when the recitation reaches ayah 3 the wash is on ayah 3. Lock the
phone: it keeps playing with lock screen controls. In airplane mode play it again: it plays to the
end.

**Acceptance Scenarios**:

1. **Given** the ayah sheet or the Listen control, **When** I tap Play from here or Listen, **Then**
   the recitation starts at that ayah or the first ayah on the page, the mini player rises and the
   follow wash sits on the playing ayah.
2. **Given** a recitation, **When** it reaches the next ayah, **Then** the wash moves to it. **When**
   it reaches the next page, **Then** the reader turns the page.
3. **Given** a recitation, **When** I turn the page myself, **Then** the reader stays where I put it.
   Following starts again when I come back to the playing page or tap next or previous.
4. **Given** the mini player, **When** I tap it, **Then** the recitation sheet (4.25) opens with the
   reciter, "Al-Fatiha · Ayah 3 of 7", the time, previous, play or pause, next, the speed, repeat
   each ayah, range, pause between ayahs and sleep timer. The page lifts so the playing ayah stays
   clear of the sheet.
5. **Given** repeat each ayah at 3 times, **When** an ayah ends, **Then** it plays 3 times before the
   next. **Given** a range, **When** its last ayah ends, **Then** the recitation stops (or starts the
   range again when repeat covers the range).
6. **Given** pause between ayahs at 2 s, **When** an ayah ends, **Then** the next starts 2 s later.
7. **Given** a sleep timer, **When** it runs out, **Then** the recitation fades out and stops.
8. **Given** a recitation, **When** I leave the reader, switch tabs or lock the phone, **Then** it
   keeps playing with lock screen and notification controls, and opening the reader brings me to the
   playing ayah.
9. **Given** an ayah not downloaded and no internet, **When** I play it, **Then** a toast says so and
   reading keeps working.

---

### User Story 4 - Pick up where I left off (Priority: P2)

I stop on page 42 and close the app. Next time Continue reading, on the Quran tab or on Home, opens
the same page with the ayah I was on.

**Why this priority**: Most reading happens a few pages at a time, so coming back to the right page
matters more than any list.

**Independent Test**: Read to page 42, leave the reader, kill the app and open it again: Continue
reading shows the first ayah of page 42, "Page 42 · Juz 3 · Today {time}" and its thumbnail, and
opens page 42.

**Acceptance Scenarios**:

1. **Given** I read without audio, **When** a page settles or I leave the reader, **Then** the first
   ayah of that page is kept as last read, with the time.
2. **Given** a recitation, **When** it moves on, **Then** the playing ayah is last read.
3. **Given** a last read, **When** I tap Continue reading, **Then** the reader opens at that page.
4. **Given** a fresh install, **When** I see Continue reading, **Then** it shows Al-Fatiha, Ayah 1,
   Page 1.

---

### User Story 5 - Bookmark and note (Priority: P2)

Bookmark hangs a ribbon on the page itself. I can keep several bookmarks with a name and one of
three colors, write a private note on an ayah, and find them all on the Saved page.

**Why this priority**: Bookmarks and notes are how a reader returns to what mattered to them.

**Independent Test**: Tap ayah 3, tap Bookmark: a ribbon hangs on page 1 and "Al-Fatiha 1:3 · Page
1" is listed on Saved. Long-press it, rename it "Reflect" and pick accent: the ribbon changes color.
Write a note on ayah 5, restart the app: it shows under Notes and in the ayah's Notes tab.

**Acceptance Scenarios**:

1. **Given** the ayah sheet or the top bar, **When** I tap Bookmark, **Then** a ribbon hangs on the
   page in the bookmark's color and the ayah or page is saved. Tapping it on a bookmarked ayah
   removes it with a toast with Undo for 4 s.
2. **Given** Saved (4.29), **When** I open it, **Then** Last read (marked AUTO) is first, then my
   bookmarks newest first, each with its name, "{surah} {s}:{a} · Page {p}" and date. The Notes tab
   lists my notes the same way.
3. **Given** a bookmark, **When** I long-press it, **Then** I can rename it, recolor it (primary,
   accent or neutral) or move it to the ayah I'm on.
4. **Given** the ayah sheet, **When** I tap Note or Add note, **Then** I can write, change or delete
   one private note on that ayah. Deleting shows a toast with Undo.
5. **Given** a bookmark or note, **When** I tap it, **Then** the reader opens on its page with the
   ayah washed.
6. **Given** nothing saved, **When** I open Saved, **Then** the empty state shows.

---

### User Story 6 - Share an ayah as an image (Priority: P3)

Share makes a clean still image of the ayah on one of four brand backgrounds, square or story size,
with or without the translation and the app name.

**Why this priority**: Sharing an ayah is common, but reading and listening come first.

**Independent Test**: Tap ayah 5, tap Share: the preview shows ayah 5 on Paper with its marker "﴿٥﴾",
"Al-Fatiha · 5" and "Better Muslim". Pick Night and turn off the translation: the preview changes.
Share: the system share sheet opens with a 1080 x 1080 image.

**Acceptance Scenarios**:

1. **Given** the ayah sheet, **When** I tap Share, **Then** the share sheet (4.30) opens with a
   preview, the backgrounds Paper, Night, Emerald and Sky, the size square or story, Include
   translation and Show app name.
2. **Given** my picks, **When** I tap Share, **Then** a 1080 x 1080 or 1080 x 1920 image is made with
   the whole ayah, never cropped or overlaid, and the system share sheet opens with it.
3. **Given** an ayah too long for the chosen size, **When** the preview is made, **Then** the text
   gets smaller to fit whole, and above a limit the story size is chosen for me.

---

### User Story 7 - Set the page up for me (Priority: P3)

Display opens one sheet for every page choice: page color, layout (Mushaf, Translation or Both),
page turn, keep screen on and text size for the translation layout.

**Why this priority**: The defaults fit most readers. The rest is for comfort.

**Independent Test**: Open Display, pick Night: every page is night until I pick another. Pick
Translation: the 4.07 layout opens on the same ayah. Turn on Keep screen on: the screen doesn't dim
while the reader is open.

**Acceptance Scenarios**:

1. **Given** the reader, **When** I tap Display, **Then** the display sheet (4.31) opens: Page (Follow
   sky, Paper, Cream, Night), Layout (Mushaf, Translation, Both), Page turn (Book, Slide), Keep screen
   on and "Madinah · Hafs".
2. **Given** a page color, **When** I pick it, **Then** the page and the reader chrome take the page
   palette (not the app mode) at once, and it applies to every page.
3. **Given** Layout, **When** I switch it, **Then** the ayah I'm on stays on screen. Translation is
   the 4.07 verse cells; Both shows each ayah's translation under the Mushaf page as the same cells.
4. **Given** the controls, **When** I tap Translation, **Then** the layout switches between Mushaf and
   Translation the same way.
5. **Given** the translation layout, **When** I change the text size, **Then** the cells change at
   once with the selection haptic and the ayah stays in view.

---

### Edge Cases

- Page 1 and page 2 are the illuminated openings, with the frame. Every other page has the plain
  15 line grid.
- At-Tawbah has no Bismillah. Al-Fatiha's Bismillah is ayah 1. Every other surah shows its cartouche
  and the Bismillah line before ayah 1.
- A page with several surahs (most of Juz 30): each surah gets its cartouche, the header shows the
  surah at the top of the page.
- An ayah that runs over two pages: tapping it on either page selects the whole ayah, the wash shows
  on the part on this page, and the follow wash crosses the page with the recitation.
- Hit areas are whole line-height bands, never under 44 pt tall.
- The selection and follow washes sit behind the glyphs and never recolor them.
- Ayah markers and the page number are Eastern Arabic in both languages, as printed. Chrome text
  follows the app's digits setting.
- Text scale 2.0: the Mushaf page doesn't scale (it is the printed page), the chrome, sheets and
  translation cells do, and nothing covers the text.
- Small phones and tablets: the page keeps the Mushaf's ratio and fits the width or height, never
  cropped.
- Double tap on play: one recitation, never two.
- A phone call, another app's audio or headphones unplugged: the recitation pauses and waits.
- Prayer time while reciting: the adhan (milestone 5) wins, the recitation pauses and waits.
- The connection drops mid-download: the half file never plays and is fetched again next time.
- Storage full: the download fails with a toast, reading is untouched.
- A downloaded file that isn't the expected recitation: thrown away, never played.
- Fast page turns: no stutter, nothing half drawn, a turn interrupted mid-flight retargets from
  where it is.
- Follow the sky with no location yet: the page is paper until prayer times exist.
- Theme, mode or language changes while reading: the page and ayah stay.
- The app is killed while playing: nothing plays on next launch, the last played ayah is last read.
- A bookmark or note belongs to the ayah, so it survives every layout and size change.
- Reduce motion: the container transform and page turn become 150 ms crossfades, the sheets and
  washes appear without springs, the night change is a plain crossfade.

## Requirements *(mandatory)*

### Functional Requirements

**Quran home (4.18)**

- **FR-001**: The Quran tab MUST be 4.18: the large title "Quran", "Madinah Mushaf · Hafs", search
  and bookmark in the bar, the Continue reading card with the page thumbnail, the tools row and the
  index with Surah, Juz and Page.
- **FR-002**: Continue reading MUST show "{surah} · Ayah {n}", "Page {p} · Juz {j} · {when}" and the
  page thumbnail, and open that page with the container transform.
- **FR-003**: The tools row MUST hold Listen, Bookmarks and Notes. Memorize and the Khatmah card are
  hidden until 7b. Listen starts the recitation at last read.
- **FR-004**: The index MUST switch between Surah (114 rows: number in the star, English name,
  "{Meccan|Medinan} · {n} ayahs · p. {page}", Arabic name), Juz (30 rows with their first surah,
  ayah and page) and Page (604 rows). A row opens its page.
- **FR-005**: The bar's search waits for 7b and is hidden until then. The bar's bookmark opens Saved.

**Mushaf page (4.19, 4.20, 4.21)**

- **FR-006**: Each page MUST hold exactly the lines of that page of the 604 page Madinah Mushaf
  (Hafs), 15 lines, with ayah markers, surah cartouches and Bismillah lines where they fall, the
  header with the surah and juz, and the page number in the star. Pages 1 and 2 are the openings of
  4.19. The design has no regular page, so every other page puts 15 equal line bands inside the same
  frame, with one font size for the page that fits its widest line, until the designer sends one.
- **FR-007**: The page MUST be immersive by default: only the page, with the gutter shadow on the
  spine side and the fore-edges on the other, as in 4.19.
- **FR-008**: Tapping the margin MUST toggle the controls (4.21): the glass top bar (back, surah,
  "Juz {j} · Hizb {h} · Page {p}", search and bookmark), the glass dock (the scrubber with juz
  ticks, Index, Listen, Translation and Display), the page springing to a card with the next page
  peeking on the left. Memorize in the dock and search in the bar wait for 7b.
- **FR-009**: Page turn MUST be Book (a 3D leaf on the spine, live shading, release with velocity)
  or Slide (300 ms), as picked, and a 150 ms crossfade with reduce motion.
- **FR-010**: Page color MUST be Follow sky (default: paper from Fajr, night after Isha, 1.8 s sacred
  crossfade at the change), Paper, Cream or Night. The reader chrome takes the page palette.
- **FR-011**: The Arabic MUST use Amiri Quran laid out to the Mushaf's lines until the QCF V2
  per-page fonts are licensed, with a `TODO(ahmed)` where the font is chosen.
- **FR-012**: The text, the line layout, the surah details and the page, juz and hizb boundaries
  MUST ship in the app and work with no internet.
- **FR-013**: The text MUST be the source's text unchanged, checked ayah by ayah in tests.

**Ayah (4.22, 4.23)**

- **FR-014**: Tap MUST select the ayah under the finger. Long-press MUST select it too and is kept
  for word by word in 7b.
- **FR-015**: The selection MUST be the gold wash (26% on paper, 22% on night, radius 9) in 150 ms,
  and the follow wash primary 10% on paper or accent 16% on night. Both sit behind the glyphs.
- **FR-016**: The ayah sheet MUST be 4.22: "{surah} · Ayah {n}", "Juz {j} · Page {p} · {Meccan|
  Medinan}", close, the translation with its name, and the actions Play from here, Tafsir, Bookmark,
  Note, Share and Copy. Word by word and Memorize wait for 7b.
- **FR-017**: The page MUST lift only as far as needed to keep the ayah 24 pt above the sheet, and
  settle back when it closes.
- **FR-018**: Tafsir MUST open the large detent (4.23): the page recedes, the ayah on top with back,
  forward and close, the tabs Tafsir, Translation and Notes. Words waits for 7b.
- **FR-019**: The Tafsir tab MUST show Al-Muyassar in full for every ayah, with its credit. Ibn Kathir
  and As-Sa'di chips show sample Al-Fatiha content with a `TODO(ahmed)` until their text is
  provided, and say "Coming soon" on other ayahs.
- **FR-020**: The Translation tab MUST show Sahih International in full. Clear Quran (Khattab) shows
  sample Al-Fatiha content with a `TODO(ahmed)` (it is copyrighted). In Arabic, the translation slot
  everywhere is the Al-Muyassar summary.
- **FR-021**: Copy MUST copy the Arabic, the translation and the reference, and show the "Copied"
  toast.

**Recitation (4.25)**

- **FR-022**: The recitation MUST be Mishary Rashid Alafasy (Murattal, Hafs), one file per ayah over
  https from EveryAyah, with a `TODO(ahmed)` at the source address.
- **FR-023**: Play MUST start at the chosen ayah, and play the ayahs back to back with no gap unless
  a pause is set. The follow wash MUST move when each ayah's file starts.
- **FR-024**: While following, the reader MUST turn the page when the recitation moves to the next
  one. Following stops when I turn the page myself and starts again when I come back to the playing
  page or tap next or previous.
- **FR-025**: The mini player MUST rise over the dock with "{surah} · Ayah {n}", "{reciter} ·
  {rate}×", play or pause and next. Tapping it opens the recitation sheet.
- **FR-026**: The recitation sheet MUST be 4.25: reciter and "Murattal · Hafs · downloaded" when the
  surah is downloaded, "{surah} · Ayah {n} of {total}", the time, repeat count, previous, play or
  pause, next, the speed (0.75, 1.0, 1.25, 1.5), Repeat each ayah (off, 2, 3, 5, 10 times), Range (from ayah
  to ayah), Pause between ayahs (off, 1, 2, 3, 5 s) and Sleep timer (off, 5, 10, 15, 30, 60 min,
  end of surah).
- **FR-027**: Leaving the reader, switching tabs and locking the phone MUST keep it playing, with
  lock screen and notification controls (play or pause, next, previous) and the surah and ayah as
  the title.
- **FR-028**: A call, another app's audio or unplugged headphones MUST pause it, and it MUST NOT start
  again on its own. The adhan MUST pause it.
- **FR-029**: Media controls MUST stay left to right in Arabic.
- **FR-030**: Cast and AirPlay are out of this milestone.

**Downloads**

- **FR-031**: An ayah's recitation MUST download the first time it's needed, and while it plays the
  rest of the surah downloads ahead so playback doesn't stop. Everything is kept to play offline
  after. "downloaded" in 4.25 shows once every ayah of the surah is on the phone. A downloads page
  (per surah or the whole Quran) is out of 7a.
- **FR-032**: Downloads MUST be https only. A file MUST play only after it is checked complete and the
  expected recitation. A partial or wrong file never plays and is fetched again.
- **FR-033**: Offline with an ayah not downloaded, a toast MUST say so. A failed download MUST show a
  toast with Try again. Reading keeps working in both cases.
- **FR-034**: A download request MUST carry nothing about me, only which file it wants.

**Last read**

- **FR-035**: Last read MUST be the playing ayah while a recitation plays, otherwise the first ayah of
  the page that settled or that I left, with the time.
- **FR-036**: Continue reading on Home MUST open the same page as on the Quran tab, and Home's verse
  card, bookmarks and notes MUST open the reader on their page with the ayah washed.

**Bookmarks and notes (4.29)**

- **FR-037**: Bookmark MUST save the ayah (from the ayah sheet) or the page (from the top bar) and
  hang a ribbon in its color on that page. Removing shows a toast with Undo for 4 s.
- **FR-038**: Saved MUST be 4.29 with the Bookmarks and Notes tabs: Last read first (AUTO), then
  bookmarks newest first with name, reference, page and date, and the recent note. Highlights waits
  for 7b.
- **FR-039**: Long-press on a bookmark MUST offer Rename, Color (primary, accent, neutral only) and
  Move here.
- **FR-040**: Each ayah MUST hold at most one private note, written, changed or deleted from the
  Notes tab or Add note. Deleting shows a toast with Undo.

**Share (4.30)**

- **FR-041**: Share MUST render a still image (1080 x 1080 or 1080 x 1920) of the whole ayah on Paper,
  Night, Emerald or Sky, with its marker and reference, optional translation and optional app name,
  never cropped or overlaid, and open the system share sheet with it.

**Display (4.31)**

- **FR-042**: The display sheet MUST hold Page (Follow sky, Paper, Cream, Night), Layout (Mushaf,
  Translation, Both), Page turn (Book, Slide), Keep screen on and "Madinah · Hafs". Tajweed colors
  waits for 7b.
- **FR-043**: The translation layout MUST be 4.07 as specified in the handoff, on the same position
  as the Mushaf page. Both MUST show the Mushaf page with the verse cells of that page under it.
- **FR-044**: The translation layout's Arabic and translation sizes MUST change from the display
  sheet with the selection haptic, at once and kept.
- **FR-045**: Keep screen on MUST stop the screen dimming only while the reader is open.

**Motion**

- **FR-046**: The container transform, the sheets, the washes, the page turn, the controls and the
  night change MUST follow the timings in 09 Quran and `11 Motion v2.dc.html`, be interruptible, and
  have their reduce-motion fallback.
- **FR-047**: The page turn haptic MUST be off by default (MOTION.md). Selecting an ayah MUST give the
  light haptic.
- **FR-060**: The page as a whole MAY turn, open from a card, recede behind the large sheet and peek
  beside the controls, as the design shows. The glyphs themselves MUST never be animated, recolored,
  decorated or overlaid while being read (constitution III, amended in T001).

**Storage and privacy**

- **FR-048**: Last read, bookmarks, notes and every reader choice MUST be kept only in the encrypted
  store on the phone, survive restarts and updates, and never leave the phone or reach crash
  reports.
- **FR-049**: The app's backup file (milestone 10) MUST carry last read, bookmarks, notes and the
  reader choices. Downloaded recitations stay out of it and out of iCloud and Android auto backup.

**Content and credits**

- **FR-050**: Every source (text, line layout, Sahih International, Al-Muyassar, the recitation, the
  font) MUST get the credit its license asks for, on the Acknowledgements page.

**Copy and access**

- **FR-051**: Every new string MUST exist in English and Arabic. The English is the copy in 09 Quran;
  the Arabic follows the tone of the existing arb entries. These are the main ones:

  | Where | English | Arabic |
  | --- | --- | --- |
  | home subtitle | Madinah Mushaf · Hafs | مصحف المدينة · حفص |
  | card label | Continue reading | تابع القراءة |
  | card | {surah} · Ayah {n} | {surah} · الآية {n} |
  | card | Page {p} · Juz {j} · {when} | صفحة {p} · الجزء {j} · {when} |
  | tool | Listen | استماع |
  | tool | Bookmarks | العلامات |
  | tool | Notes | الملاحظات |
  | index | Surah | سورة |
  | index | Juz | جزء |
  | index | Page | صفحة |
  | surah row | {place} · {n} ayahs · p. {page} | {place} · {n} آية · ص {page} |
  | place | Meccan | مكية |
  | place | Medinan | مدنية |
  | bar | Juz {j} · Hizb {h} · Page {p} | الجزء {j} · الحزب {h} · صفحة {p} |
  | dock | Index | الفهرس |
  | dock | Translation | الترجمة |
  | dock | Display | العرض |
  | ayah action | Play from here | شغّل من هنا |
  | ayah action | Tafsir | التفسير |
  | ayah action | Bookmark | علامة |
  | ayah action | Note | ملاحظة |
  | ayah action | Share | مشاركة |
  | ayah action | Copy | نسخ |
  | toast | Copied | تم النسخ |
  | toast | Bookmark removed | أُزيلت العلامة |
  | toast | Note deleted | حُذفت الملاحظة |
  | toast action | Undo | تراجع |
  | notes | Add note | أضف ملاحظة |
  | notes | Private | خاصة |
  | tafsir | Coming soon | قريبًا |
  | recitation | Murattal · Hafs · downloaded | مرتل · حفص · محمّلة |
  | recitation | Ayah {n} of {total} | الآية {n} من {total} |
  | recitation | Repeat each ayah | كرّر كل آية |
  | recitation | {n} times | {n} مرات |
  | recitation | Range | النطاق |
  | recitation | Ayah {from} – {to} | الآية {from} – {to} |
  | recitation | Pause between ayahs | توقف بين الآيات |
  | recitation | Sleep timer | مؤقت النوم |
  | recitation | End of surah | نهاية السورة |
  | saved | Saved | المحفوظات |
  | saved | Last read | آخر قراءة |
  | saved | Auto | تلقائي |
  | bookmark menu | Rename | إعادة تسمية |
  | bookmark menu | Color | اللون |
  | bookmark menu | Move here | انقل إلى هنا |
  | empty title | No bookmarks yet | لا علامات بعد |
  | empty body | Tap Bookmark on any ayah to keep your place. | اضغط علامة على أي آية لتحفظ موضعك. |
  | share | Share ayah | مشاركة الآية |
  | share | Include translation | أضف الترجمة |
  | share | Show app name | أظهر اسم التطبيق |
  | share background | Paper / Night / Emerald / Sky | ورق / ليل / زمردي / سماء |
  | display | Applies to every page | ينطبق على كل الصفحات |
  | display | Follow sky | اتبع السماء |
  | display | Cream | كريمي |
  | display | Layout | التخطيط |
  | display | Mushaf | المصحف |
  | display | Both | كلاهما |
  | display | Page turn | قلب الصفحة |
  | display | Book / Slide | كتاب / انزلاق |
  | display | Keep screen on | أبقِ الشاشة مضاءة |
  | offline toast | Connect to the internet to download this recitation. | اتصل بالإنترنت لتنزيل هذه التلاوة. |
  | download failed toast | The recitation couldn't download. | تعذّر تنزيل التلاوة. |
  | toast action | Try again | حاول مرة أخرى |
  | loader label | Loading | جارٍ التحميل |

- **FR-052**: Every control MUST be at least 44 x 44. A screen reader MUST read each ayah as its
  surah, number, Arabic and translation, label every action and player button, and announce play,
  pause and the page number on each turn.
- **FR-053**: The new icons (index, translate, words, copy, memorize, prev, spread, timer,
  chevron_down) MUST come from the icon paths in `_gen/kit.js` and go through `BmIcon`.

**Design scenario**

- **FR-054**: "Dev · design scenario" MUST show the Quran tab as 4.18 (Continue reading "Al-Fatiha ·
  Ayah 3", "Page 1 · Juz 1 · Today 14:10"), the paper page at 16:32, and no audio or network needed.

**Motion v2 pieces**

- **FR-055**: The oil drop loader MUST follow 11 Motion v2 section 00: a 1600 ms loop in four beats
  (form 0 to 560 ms decelerate, hang to 800 breathe, fall to 1170 gravity, ripple to 1600
  decelerate), the star in primary, the oil from #D9BE86 to #8C7444 as in the design, the sun from
  the sky, the pool's surface always moving, stroke weight thicker as the mark shrinks, no drop under
  32 pt, and a "Loading" label for screen readers with the percent when known.
- **FR-056**: The loader MUST wait 400 ms before it shows, stay at least 600 ms once shown, and be the
  only one on screen. Lists use skeletons, buttons the inline size.
- **FR-057**: The container transform MUST be 520 ms, standard curve, radius 20 to 0, content
  crossfading in the middle 40%, interruptible, and a 150 ms crossfade with reduce motion. 7a uses it
  for Continue reading and the index rows into the page.
- **FR-058**: The list entrance MUST be 300 ms per row, 30 ms stagger, 12 pt rise, at most 8 steps,
  only on a list's first appearance on its screen. Skeletons MUST shimmer at 1200 ms and hand over in
  one 150 ms crossfade with no layout shift.
- **FR-059**: The dev page from More MUST get a loader section: the loop at 48, 24 and 16 pt and a
  progress slider.

### Key Entities

- **Surah**: number, Arabic and English name, Meccan or Medinan, ayah count, first page.
- **Ayah**: surah and number, Arabic text, Sahih International, Al-Muyassar, page, juz, hizb.
- **Page**: one of the 604 Mushaf pages, its 15 lines and which ayah each part of a line belongs to,
  its juz and hizb.
- **Recitation**: reciter and style, one audio file per ayah.
- **Downloaded ayah**: one ayah's audio kept on the phone, checked before it plays.
- **Last read**: surah, ayah, page and when.
- **Bookmark**: an ayah or a page, name, color (primary, accent, neutral), when it was made.
- **Note**: one ayah, its text, when it was last changed.
- **Reader choices**: page color, layout, page turn, keep screen on, translation layout sizes,
  speed, repeat and pause. Range and sleep timer last only for the session.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Every page of the 604 shows its lines and ayahs as in the printed Madinah Mushaf, and
  all 6,236 ayahs match the source text exactly.
- **SC-002**: A page opens from the Quran tab in under 1 second, and turning 20 pages in a row shows
  no visible stutter on a mid-range phone.
- **SC-003**: Across a full surah (Al-Mulk, 30 ayahs) the follow wash lands on each new ayah within
  100 ms of its recitation starting, every time.
- **SC-004**: A surah played once plays from start to end in airplane mode, and keeps playing with
  the phone locked for 30 minutes.
- **SC-005**: In tests with a cut connection, a wrong file and full storage, a broken file never plays
  and the reader never stops working.
- **SC-006**: Last read, bookmarks and notes survive a restart, an update and a backup and restore,
  and the only thing the app ever sends is the request for an audio file.
- **SC-007**: No control, sheet, toast or wash ever covers the selected or playing ayah or recolors
  the Quran text, and the rest of the page is covered only by a sheet I opened, at text scale
  1.0 and 2.0, in both languages and modes.
- **SC-008**: Every control is at least 44 x 44 and contrast meets WCAG AA on paper, cream and night.

## Assumptions

- Hafs 'an 'Asim, the Madinah 604 page layout, with the text and line layout from an openly licensed
  source (Tanzil text, KFGQPC page layout). The exact files are picked in the plan.
- Until QCF V2 is licensed, Amiri Quran on the Mushaf's lines can differ slightly in width from
  print; lines are justified to the page so nothing reflows.
- Sahih International and Al-Muyassar ship in full. The app grows by the text, layout and these two,
  well under the design's 40 MB.
- Background play and lock screen controls need `audio_service` (`just_audio_background` supports
  only one player and the app has two), and the container transform needs `animations`. Both are
  added in this milestone.
- Until 7b, the khatmah card, Memorize and search are hidden.
- Picking Home's verse of the day stays with milestone 3. This milestone opens the reader at any
  ayah.
- Clearing downloaded recitations and the page turn haptic switch live in More.
- No streaks, no reading goals in 7a.
