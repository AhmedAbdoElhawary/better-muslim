# Feature Specification: Milestone 7, Quran Reader

**Feature Branch**: `feature/milestone-7` [NEEDS CLARIFICATION: Q11, cut when, and built before or
after milestones 3 to 6?]

**Created**: 2026-10-17

**Status**: Draft

**Input**: User description: "milstone 7"

Milestone 7 is the Quran reader (4.07): a surah read ayah by ayah with its translation, a mushaf page
at a time, and a recitation that highlights and follows the ayah being recited. The reader screen is
built straight from the handoff spec. This spec covers what the handoff doesn't: the Quran tab that
leads to the reader, where the text and the recitation come from, how the audio follows and keeps
going, downloads and offline, bookmarks and notes, the ayah actions, the text size sheet and the last
read position. The Quran text is never animated, overlapped, cropped or used as decoration.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Open a surah and read it (Priority: P1)

I open the Quran tab, tap a surah and read it ayah by ayah with the translation under each. I swipe
to turn the page in the mushaf's order, and the title follows the surah and page I'm on.

**Why this priority**: Reading is what the tab is for. Audio, bookmarks, notes and the last position
all sit on top of it.

**Independent Test**: Open Al-Fatiha from the Quran tab: the header card shows "سورة الفاتحة" and
"The Opening · Meccan · 7 ayahs", then 7 verse cells, the title "Al-Fatiha", "Juz 1 · Page 1". Swipe
to the next page: Al-Baqarah 1 to 5, the title "Al-Baqarah", "Juz 1 · Page 2".

**Acceptance Scenarios**:

1. **Given** the Quran tab, **When** I tap a surah, **Then** the reader opens at that surah's first
   ayah with the tab bar hidden, the surah's header card at its start.
2. **Given** a page, **When** I swipe to the next page, **Then** it comes in from the left in both
   languages like a printed mushaf (Motion 13), or crossfades with reduce motion on.
3. **Given** a page longer than the screen, **When** I scroll it, **Then** every ayah can be read in
   full and the last one ends above the mini player, never under it.
4. **Given** a page where a new surah starts, **When** I reach it, **Then** that surah's header card
   and the Bismillah line show before its first ayah, and the title changes to it.
5. **Given** the app in Arabic, **When** I read, **Then** the title is the surah's Arabic name, the
   subtitle uses the app's digits, the page order is the same, and the media controls stay left to
   right.

---

### User Story 2 - Listen and follow along (Priority: P1)

I tap play and the recitation starts at the ayah in front of me. The ayah being recited is filled and
stays in view, and when the page ends the reader turns the page with the recitation. I can pause,
repeat the ayah or skip to the next one from the mini player. A surah I played once plays again with
no internet.

**Why this priority**: Recitation that highlights as it plays is the second promise of the reader
(store listing: "Ayah-by-ayah audio that highlights as it plays").

**Independent Test**: In Al-Fatiha tap play: ayah 1 fills, the progress line moves, and when the
recitation reaches ayah 3 the highlight is on ayah 3 and the mini player reads "Al-Fatiha · ayah 3".
Turn on airplane mode and play it again: it plays to the end.

**Acceptance Scenarios**:

1. **Given** nothing playing, **When** I tap play in the mini player, **Then** the recitation starts
   at the selected ayah, or the first ayah fully on screen, and that ayah fills (Motion 14).
2. **Given** a recitation playing, **When** it reaches the next ayah, **Then** the highlight moves to
   it and it scrolls into view if needed. **When** it reaches the next page, **Then** the reader
   turns the page.
3. **Given** a recitation playing, **When** I scroll away or turn the page myself, **Then** the
   reader stays where I put it. Following starts again when I scroll back to the playing ayah, play
   an ayah or tap next.
4. **Given** a recitation playing, **When** I tap next, **Then** it jumps to the next ayah. **When**
   I turn repeat on, **Then** the playing ayah repeats until I turn it off.
   [NEEDS CLARIFICATION: Q5, repeat, speed, full player and the end of a surah]
5. **Given** an ayah already downloaded, **When** I'm offline, **Then** it plays. **Given** one not
   downloaded and no internet, **Then** a toast says so and reading keeps working.
6. **Given** a recitation playing, **When** I leave the reader. [NEEDS CLARIFICATION: Q4, does it
   keep playing on other tabs and with the phone locked?]

---

### User Story 3 - Pick up where I left off (Priority: P2)

I stop in the middle of Al-Baqarah and close the app. Next time "Continue reading", on the Quran tab
or on Home, brings me back to the same ayah.

**Why this priority**: Most reading happens a few pages at a time, so coming back to the right ayah
matters more than any list.

**Independent Test**: Read to Al-Baqarah 40, leave the reader, kill the app and open it again:
Continue reading shows "Al-Baqarah · ayah 40 of 286", tapping it opens page 7 with ayah 40 at the
top.

**Acceptance Scenarios**:

1. **Given** I read without audio, **When** I leave the reader or a page settles, **Then** the ayah
   at the top of the screen is kept as my last position.
2. **Given** a recitation playing, **When** it moves on, **Then** the playing ayah is my last
   position.
3. **Given** a last position, **When** I tap Continue reading on the Quran tab or on Home, **Then**
   the reader opens with that ayah at the top.
4. **Given** a fresh install, **When** I see Continue reading, **Then** it shows Al-Fatiha, ayah 1
   of 7, and opens there.

---

### User Story 4 - Save, note and share an ayah (Priority: P2)

I tap an ayah and get Play, Tafsir, Save, Note and Share. Save keeps it in my bookmarks, Note lets me
write a private note on it, Share sends it as text. The bookmark in the top bar marks the page. All of
it is on the Quran tab to come back to.

**Why this priority**: The store listing promises bookmarks and notes, and the reader's top bar and
actions row are designed for them.

**Independent Test**: Tap ayah 2 of Al-Fatiha, tap Save: the cell shows the bookmarked state and it
is listed on the Quran tab. Tap Save again: removed, a toast with Undo shows for 4 s. Write a note on
ayah 4, restart the app: the note is there.

**Acceptance Scenarios**:

1. **Given** the reader, **When** I tap an ayah, **Then** its actions row opens under it (selected
   state), and tapping it again or another ayah closes or moves it.
   [NEEDS CLARIFICATION: Q7, tap or long press, and edge taps]
2. **Given** the actions row, **When** I tap Play, **Then** the recitation starts at that ayah.
3. **Given** the actions row, **When** I tap Save, **Then** the ayah is bookmarked. **When** I tap
   Save on a bookmarked ayah, **Then** it is removed with a toast with Undo for 4 s.
4. **Given** the actions row, **When** I tap Note, **Then** a sheet lets me write, change or delete
   my note on that ayah. [NEEDS CLARIFICATION: Q6, bookmarks and notes]
5. **Given** the actions row, **When** I tap Share, **Then** the phone's share sheet opens with the
   Arabic text, the translation and the reference.
6. **Given** the reader, **When** I tap the bookmark in the top bar, **Then** the page is bookmarked
   and the icon fills. Tapping it again removes it with a toast with Undo. [NEEDS CLARIFICATION: Q6]
7. **Given** the actions row, **When** I tap Tafsir. [NEEDS CLARIFICATION: Q8, where the tafsir comes
   from]

---

### User Story 5 - Make the text fit me (Priority: P3)

Aa opens a sheet where I change the Arabic size and the translation size. The page changes as I go
and stays that way next time.

**Why this priority**: The default sizes fit most people, the rest need bigger Arabic to read it at
all.

**Independent Test**: Open Aa, make the Arabic one step bigger: the verse cells grow at once, the
ayah I was reading stays in view. Restart: the size is kept.

**Acceptance Scenarios**:

1. **Given** the reader, **When** I tap Aa, **Then** the text size sheet opens (Motion 15).
   [NEEDS CLARIFICATION: Q9, what the sheet holds and whether Arabic shows a translation]
2. **Given** the sheet, **When** I change a size, **Then** the page changes at once with the
   selection haptic, and the ayah I was reading stays in view.
3. **Given** a size I picked, **When** I come back later, **Then** it is kept.

---

### Edge Cases

- Al-Fatiha has no separate Bismillah line, it is ayah 1. At-Tawbah has no Bismillah. Every other
  surah shows it before ayah 1, unnumbered.
- When a recitation starts a surah with the Bismillah, the Bismillah line is the highlighted one
  while it plays.
- A page with several surahs (most of Juz 30): each surah gets its header card, the title shows the
  surah at the top of the screen.
- An ayah longer than the screen (Al-Baqarah 282 at the biggest size and text scale 2.0): it scrolls,
  is never cut, and following scrolls to its start.
- Medallion numbers are Eastern Arabic in both languages, as designed. The title, subtitle and mini
  player follow the app's digits setting.
- Double tap on play: one recitation, never two.
- A phone call, another app's audio or headphones unplugged: the recitation pauses and waits for me.
- Prayer time while reciting: the adhan (milestone 5) wins, the recitation pauses and waits.
- The connection drops mid-download: the half file never plays and is fetched again next time.
- Storage full: the download fails with a toast, reading is untouched.
- A downloaded file that isn't the expected recitation: thrown away, never played.
- Fast swipes across many pages: no stutter, nothing shown half drawn.
- Reduce motion: the page turn is a 150 ms crossfade, the highlight jumps.
- The page turn haptic is off by default (MOTION.md).
- The app is killed while playing: nothing plays on next launch, the last played ayah is my last
  position.
- Theme, mode or language changes while reading: the page and the ayah I'm on stay.
- A bookmark or note survives every size change, it belongs to the ayah, not to a spot on screen.
- Text scale above 1.4: the mini player and header card stay readable, nothing overlaps the text.

## Requirements *(mandatory)*

### Functional Requirements

**Quran tab**

- **FR-001**: The Quran tab MUST lead to the reader with a Continue reading card, the list of the
  114 surahs and my bookmarks and notes. [NEEDS CLARIFICATION: Q1, what else the tab holds]
- **FR-002**: The tab has no PNG, so it MUST be built only from parts in `03 Components.dc.html`
  (large app bar, Continue reading card, chips, list rows, empty state) and shown to me in
  screenshots before it is called done.
- **FR-003**: Each surah row MUST show its number, name in English and Arabic, and ayah count, and
  open the reader at its first ayah.

**Reader**

- **FR-004**: The reader MUST match 4.07 as specified in the handoff in dark and light: compact bar
  with back, title, "Juz {juz} · Page {page}", Aa and bookmark, the verse cells and the mini player.
  The tab bar is hidden. Back returns to where I came from.
- **FR-005**: Each reader page MUST hold the ayahs of one page of the standard 604 page Madani
  mushaf, as verse cells with the translation under the Arabic.
- **FR-006**: The next page MUST come in from the left in both languages (Motion 13), the reduce
  motion fallback is a 150 ms crossfade. Page 1 has no previous page, page 604 no next.
- **FR-007**: The title MUST show the surah of the ayah at the top of the screen, the subtitle its
  juz and page.
- **FR-008**: Each surah start MUST show its header card (Arabic name, meaning · Meccan or Medinan ·
  ayah count) and the Bismillah line as in the Edge Cases.
- **FR-009**: The ayah area MUST end above the mini player and scroll within the page. No control,
  sheet or toast ever covers or cuts the Arabic text.

**Content**

- **FR-010**: The Quran text, the translation, the surah details and the page and juz boundaries
  MUST be on the phone and work with no internet. [NEEDS CLARIFICATION: Q2, the whole Quran now or
  Al-Fatiha only]
- **FR-011**: The Arabic MUST use Amiri Quran until KFGQPC Hafs and QCF V2 are licensed, with a
  `TODO(ahmed)` where the font is chosen.
- **FR-012**: The text MUST be the source's text unchanged, checked ayah by ayah against it in
  tests.
- **FR-013**: Every source (text, translation, recitation) MUST get the credit its license asks
  for.

**Recitation**

- **FR-014**: Play MUST start at the selected ayah, or the first ayah fully on screen.
- **FR-015**: The ayah being recited MUST fill with primaryContainer, a still fill that fades in over
  300 ms and never pulses (Motion 14). With reduce motion it jumps.
- **FR-016**: The recitation MUST come from: [NEEDS CLARIFICATION: Q3, reciter and source]
- **FR-017**: While following, the playing ayah MUST scroll into view (300 ms) and the reader MUST
  turn the page when the recitation moves to the next one. Following stops when I scroll or turn the
  page myself, and starts again when the playing ayah is back on screen, I play an ayah or tap next.
- **FR-018**: The mini player MUST show play or pause, repeat and next, "{surah} · ayah {n}",
  "Murattal · {rate}×", and a 2 pt line with how far the recitation is through the surah.
- **FR-019**: Repeat, playback speed, the full player and the end of a surah MUST work as decided.
  [NEEDS CLARIFICATION: Q5]
- **FR-020**: Leaving the reader, switching tabs and locking the phone MUST behave as decided.
  [NEEDS CLARIFICATION: Q4]
- **FR-021**: A call, another app's audio or unplugged headphones MUST pause the recitation, and it
  MUST NOT start again on its own.
- **FR-022**: Media controls MUST stay left to right in Arabic.

**Downloads**

- **FR-023**: An ayah's recitation MUST download the first time it's needed, together with the next
  ayahs so playback doesn't stop between them, and MUST be kept so it plays offline after.
- **FR-024**: Downloads MUST be https only. A file MUST play only after it is checked complete and
  the expected recitation. A partial or wrong file never plays and is fetched again.
- **FR-025**: Offline with an ayah not downloaded, a toast MUST say so. A failed download MUST show a
  toast with Try again. Reading keeps working in both cases.
- **FR-026**: A download request MUST carry nothing about me, only which file it wants.

**Bookmarks and notes**

- **FR-027**: Save MUST bookmark the ayah and show the bookmarked verse cell state. Save on a
  bookmarked ayah MUST remove it with a "Bookmark removed" toast with Undo for 4 s.
- **FR-028**: The top bar bookmark MUST toggle a bookmark on the page, filled while the page is
  bookmarked. Removing it shows the same toast with Undo. [NEEDS CLARIFICATION: Q6]
- **FR-029**: Note MUST open a sheet to write, change or delete one private note on that ayah.
  Deleting shows a toast with Undo. [NEEDS CLARIFICATION: Q6]
- **FR-030**: Bookmarks and notes MUST be listed on the Quran tab, newest first, each with its surah
  and ayah (or page), opening the reader there. With none, the empty state from the components shows
  ("No bookmarks yet").

**Ayah actions**

- **FR-031**: The actions row MUST hold Play, Tafsir, Save, Note and Share, open for one ayah at a
  time. [NEEDS CLARIFICATION: Q7]
- **FR-032**: Share MUST send the Arabic text, the translation when shown, and the reference like
  "Al-Fatiha 1:3", through the phone's share sheet, nothing else.
- **FR-033**: Tafsir MUST work as decided. [NEEDS CLARIFICATION: Q8]

**Text size**

- **FR-034**: The Aa sheet MUST change the reader's text as decided, at once and kept, built from
  the sheet and control components and shown to me in screenshots before it is called done.
  [NEEDS CLARIFICATION: Q9]

**Last position**

- **FR-035**: The last position MUST be the playing ayah while a recitation plays, otherwise the ayah
  at the top of the screen when a page settles or I leave the reader.
- **FR-036**: Continue reading, on the Quran tab and on Home, MUST show "{surah} · ayah {n} of
  {total}" and open the reader with that ayah at the top. Before anything is read it is Al-Fatiha,
  ayah 1.
- **FR-037**: The reader MUST open at any surah, page or ayah, so Home's verse card, bookmarks, notes
  and Continue reading all land on the right ayah.

**Storage and privacy**

- **FR-038**: The last position, bookmarks, notes and reader choices MUST be kept only in the
  encrypted store on the phone, survive restarts and updates, and never leave the phone or reach
  crash reports.
- **FR-039**: Downloaded recitations MUST stay out of iCloud and Android auto backup and out of the
  app's backup file, they can always be downloaded again.

**Copy and access**

- **FR-040**: Every new string MUST exist in English and Arabic with this wording:
  [NEEDS CLARIFICATION: Q10]

  | Where | English | Arabic |
  | --- | --- | --- |
  | tab chip | Surah | سورة |
  | tab chip | Juz | جزء |
  | tab chip | Saved | المحفوظات |
  | surah place | Meccan | مكية |
  | surah place | Medinan | مدنية |
  | ayah action | Play | تشغيل |
  | ayah action | Tafsir | التفسير |
  | ayah action | Save | حفظ |
  | ayah action | Note | ملاحظة |
  | empty title | No bookmarks yet | لا محفوظات بعد |
  | empty body | Tap the bookmark on any verse to keep your place. | اضغط العلامة على أي آية لتحفظ موضعك. |
  | toast | Bookmark removed | أُزيلت العلامة |
  | toast action | Undo | تراجع |
  | note sheet hint | Write a note on this ayah | اكتب ملاحظة على هذه الآية |
  | note sheet | Save note | حفظ الملاحظة |
  | note sheet | Delete note | حذف الملاحظة |
  | toast | Note deleted | حُذفت الملاحظة |
  | text size sheet title | Text size | حجم الخط |
  | text size row | Arabic | العربية |
  | text size row | Translation | الترجمة |
  | text size row | Show translation | إظهار الترجمة |
  | offline toast | Connect to the internet to download this recitation. | اتصل بالإنترنت لتنزيل هذه التلاوة. |
  | download failed toast | The recitation couldn't download. | تعذّر تنزيل التلاوة. |
  | toast action | Try again | حاول مرة أخرى |
  | full player | Verse {n} of {total} · {reciter} | الآية {n} من {total} · {reciter} |

- **FR-041**: Every control MUST be at least 44 x 44. A screen reader MUST read each ayah as its
  number, Arabic and translation, label every action and mini player button, and announce play,
  pause and repeat.

**Design scenario**

- **FR-042**: "Dev · design scenario" MUST open the reader at Al-Fatiha with ayah 3 as the playing
  ayah, the progress at 38% and "Murattal · 1.0×", and Home's Continue reading at "Al-Fatiha · ayah
  3 of 7", as in 4.07 and 4.01, with no audio and no network needed.

### Key Entities

- **Surah**: number, Arabic and English name, meaning, Meccan or Medinan, ayah count.
- **Ayah**: surah and number, Arabic text, translation, page, juz.
- **Page**: one of the 604 mushaf pages, its first and last ayah, its juz.
- **Recitation**: the reciter and style, one audio file per ayah.
- **Downloaded ayah**: one ayah's audio kept on the phone, checked before it plays.
- **Last position**: surah and ayah.
- **Bookmark**: an ayah or a page, and when it was made.
- **Note**: one ayah, its text, when it was last changed.
- **Reader choices**: Arabic size, translation size, translation on or off, playback speed, repeat.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In the design scenario the reader matches 4.07 within 1 pt in dark and light.
- **SC-002**: A surah opens from the Quran tab in under 1 second, and swiping through 20 pages in a
  row shows no visible stutter on a mid-range phone.
- **SC-003**: Across a full surah (Al-Mulk, 30 ayahs) the highlight lands on each new ayah within
  100 ms of its recitation starting, every time.
- **SC-004**: A surah played once plays from start to end in airplane mode.
- **SC-005**: In tests with a cut connection, a wrong file and full storage, a broken file never
  plays and the reader never stops working.
- **SC-006**: All 6,236 ayahs match the source text exactly.
- **SC-007**: The last position, bookmarks and notes survive a restart and an update, and the only
  thing the app ever sends is the request for an audio file.
- **SC-008**: At text scale 2.0 and the biggest text size no ayah is cut or under the mini player,
  every control is at least 44 x 44, contrast meets WCAG AA in both modes.

## Assumptions

- Hafs 'an 'Asim, the standard Madani 604 page layout, English translation only.
- The highlight fills the whole verse cell. Motion 14's line rects belong to a mushaf page mode with
  QCF V2, which waits for the licensed fonts.
- No juz, hizb or sajdah marks inside the text in this milestone, 4.07 doesn't show any.
- Picking the verse of the day is Home's job (milestone 3). This milestone gives it a way to open the
  reader at an ayah.
- Credits for the text, translation, recitation and fonts go on the About page in More (milestone 9).
- Clearing downloaded recitations and the page turn haptic switch live in More (milestone 9).
- The app's backup file (milestone 10) carries bookmarks, notes and the last position, not
  downloads.
- No khatmah plans, no reading goals, no streaks.
- Search ("Search surah, verse or dua" in the components) is not part of this milestone unless Q1
  says so.
