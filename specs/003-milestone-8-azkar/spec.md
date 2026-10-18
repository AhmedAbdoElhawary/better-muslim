# Feature Specification: Milestone 8, Azkar, Tasbih and Duas

**Feature Branch**: `feature/milestone-8`, built in the handoff's order after milestone 7

**Created**: 2026-10-17

**Status**: Draft

**Input**: User description: "milstone 8"

Milestone 8 is the Azkar tab and the Duas page: Tasbih (4.08), the morning and evening azkar, and
Duas (4.14) reached from More. Tasbih and Duas are built straight from the handoff specs. This spec
covers what the handoff doesn't: the Azkar tab itself, how a morning or evening set is read and
counted, when a set starts over, what Tasbih keeps, and how duas are filtered, searched, saved,
heard and shared. Everything works offline and stays on the phone, and like the rest of the app it
counts without pressure: no streaks, no totals, no "you haven't done your azkar".

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Count my tasbih after prayer (Priority: P1)

I finish Asr, open Azkar, tap Tasbih and count without looking: I tap anywhere in the lower half
and feel each count. At 33 the ring fills, and the next tap moves me to Alhamdulillah. If I leave
halfway and come back, my count is still there.

**Why this priority**: Tasbih is the one part of this milestone with a finished design, the most
used action in the tab, and what the store listing promises ("tasbih with haptics").

**Independent Test**: In the design scenario open Tasbih: SubhanAllah, 16 of 33, as in 4.08. Tap
17 times: 33, "Set complete", ring full with its glow, the set complete haptic. Tap once more:
Alhamdulillah, 1 of 33. Close the app and open it again: still Alhamdulillah, 1 of 33.

**Acceptance Scenarios**:

1. **Given** Tasbih is open, **When** I tap anywhere in the lower area, **Then** the count goes up
   by 1, the beads spring one step (Motion 11) with the bead haptic and the ring follows in 300 ms.
2. **Given** the count is one below the target, **When** I tap, **Then** the ring fills, glows,
   "Set complete" replaces "of 33", and Motion 12 plays with the set complete haptic, or its reduce
   motion fallback (ring fills, no burst).
3. **Given** a finished dhikr, **When** I tap, **Then** the next dhikr is selected at 1. After
   Allahu Akbar the next tap goes back to SubhanAllah at 1. [NEEDS CLARIFICATION: Q4]
4. **Given** any count, **When** I tap a chip, **Then** that dhikr is selected from 0 with the
   selection haptic. [NEEDS CLARIFICATION: Q4]
5. **Given** any count, **When** I tap reset, **Then** the count is 0 on the first dhikr and a
   toast with Undo shows for 4 s. [NEEDS CLARIFICATION: Q4, Undo or instant reset as designed?]
6. **Given** I count 20 times in 2 seconds, **When** I stop, **Then** the count went up by exactly
   20, every tap was felt and the beads settle without catching up on a backlog.
7. **Given** I leave Tasbih, switch tabs or close the app, **When** I come back, **Then** the same
   dhikr and count are there.

---

### User Story 2 - Read my evening azkar (Priority: P1)

After Asr, Home shows "Evening azkar · After Asr · 0 of 24". I tap it and read them one by one,
tapping the card for the ones said more than once. If I stop halfway, next time I continue where I
stopped. Tomorrow after Asr the set starts over.

**Why this priority**: Home (4.01), the evening nudge (5.1, 5.2) and the store listing all lead to
the morning and evening azkar, but the handoff has no screen for them. Without it Home's row and
the nudge go nowhere.

**Independent Test**: In the design scenario (16:32, after Asr) the Azkar tab shows Evening azkar
at 0 of 24. Open it: card 1 of 24. Count it to its number, the next tap moves to card 2, Home now
shows 1 of 24. Move the clock to the next Fajr: Morning azkar at 0 of 12 is current. Move it to
Asr: Evening azkar is back at 0 of 24.

**Acceptance Scenarios**:

1. **Given** the Azkar tab, **When** I open it, **Then** I see Morning azkar and Evening azkar
   with their progress, and Tasbih. [NEEDS CLARIFICATION: Q1]
2. **Given** a set is open, **When** I tap the card, **Then** its count goes up with the bead
   haptic. At its number the card shows done with the set complete haptic, and the next tap moves
   to the next card. [NEEDS CLARIFICATION: Q3]
3. **Given** a set is open, **When** I swipe, **Then** I move to the previous or next card without
   counting. [NEEDS CLARIFICATION: Q3]
4. **Given** the last card is done, **When** I look at the set, **Then** it shows "Set complete"
   and Home's row shows 24 of 24.
5. **Given** I left a set halfway, **When** I open it again in the same window, **Then** it opens
   at the first card not done with every count kept.
6. **Given** a set's window opens again, **When** I open the set, **Then** it starts from 0.
   [NEEDS CLARIFICATION: Q2]
7. **Given** Home, **When** I tap the azkar row, **Then** the current set opens at the first card
   not done.

---

### User Story 3 - Find the dua for this moment (Priority: P2)

I'm about to leave the house and want the dua. I open More › Duas, tap Home or type "leaving", and
read it in Arabic with the transliteration, the translation and its source.

**Why this priority**: Duas is a designed screen (4.14) and one of the three tiles on More.

**Independent Test**: In the design scenario open Duas: it matches 4.14. Type "tawakkaltu":
Leaving the home shows. Type "توكلت" without diacritics: the same dua. Type "zzz": the no results
state. Clear the search and tap "Before sleeping": a page with its 3 duas.

**Acceptance Scenarios**:

1. **Given** Duas, **When** it opens, **Then** I see the search field, the chips with All
   selected, the dua card and the category rows as in 4.14. [NEEDS CLARIFICATION: Q5]
2. **Given** the chips, **When** I tap one, **Then** the card and the rows show only that chip's
   categories. [NEEDS CLARIFICATION: Q5]
3. **Given** the search field, **When** I type, **Then** matching duas show as I type, found by
   their Arabic, transliteration, translation or category name.
4. **Given** a search with no match, **When** I look, **Then** I see "No duas found" with a hint
   to try another word.
5. **Given** a category row, **When** I tap it, **Then** a page opens with that category's duas as
   cards and the category name in the app bar. [NEEDS CLARIFICATION: Q5]

---

### User Story 4 - Keep the duas I use (Priority: P3)

I tap Save on "Leaving the home" so I can find it fast next time.

**Why this priority**: Save is on every dua card in the design, and the components already have
its empty state.

**Independent Test**: Tap Save on the 4.14 card: the icon fills and the label reads "Saved". Open
the Saved chip: the dua is there. Tap "Saved" again: it's removed, a toast with Undo shows, Undo
brings it back. With nothing saved, the Saved chip shows the empty state.

**Acceptance Scenarios**:

1. **Given** a dua, **When** I tap Save, **Then** it's kept, the bookmark icon fills and the label
   reads "Saved".
2. **Given** a saved dua, **When** I tap "Saved", **Then** it's removed at once and a toast with
   Undo shows for 4 s.
3. **Given** saved duas, **When** I open the Saved chip, **Then** I see them as cards, newest
   saved first. [NEEDS CLARIFICATION: Q5, Saved as a chip or as a row?]
4. **Given** nothing saved, **When** I open the Saved chip, **Then** I see "No duas saved yet" and
   "Tap Save on any dua to keep it here."

---

### User Story 5 - Listen to a dua and share it (Priority: P3)

I tap Listen to learn how a dua is said. I tap Share to send it to my family.

**Why this priority**: Both actions are on every dua card, but neither has its content (audio)
or its design (the share card) in the handoff.

**Independent Test**: Tap Listen on a dua with a clip: it plays and the action reads "Stop". Tap
Listen on another dua: the first stops, the second plays. Leave the page: it stops. Tap Share: the
phone's share sheet opens with the dua. [NEEDS CLARIFICATION: Q6, Q7]

**Acceptance Scenarios**:

1. **Given** a dua with a clip, **When** I tap Listen, **Then** it plays offline, the action reads
   "Stop", and tapping it again stops it.
2. **Given** a clip playing, **When** I tap Listen on another dua, leave the page or the adhan
   starts, **Then** the clip stops.
3. **Given** a dua without a clip, **When** I see its card, **Then** Listen follows Q6.
   [NEEDS CLARIFICATION: Q6]
4. **Given** a dua, **When** I tap Share, **Then** the phone's share sheet opens with the dua.
   [NEEDS CLARIFICATION: Q7, image card or text?]

---

### Edge Cases

- Tasbih: taps on the chips, the dhikr text or the top bar never count, only the lower area does.
- Tasbih: a new tap during the bead spring retargets it from where it is, never queues.
- Tasbih at text scale 2.0: the chips scroll sideways instead of being cut, the count stays inside
  the ring.
- A zikr said once: one tap makes it done, the next tap moves on.
- A set window changes while a set is open (Asr comes while I read the morning set): the open set
  stays as it is and keeps counting to its own window. The next time I open the tab the new set is
  current.
- Between midnight and Fajr the evening set is still current and belongs to the day it started on,
  like Isha in milestone 4.
- Location, time zone or method change: progress stays on its set and day, only the window times
  move.
- Daylight saving days: the switch follows that day's Fajr and Asr.
- A day with no Fajr or Asr time (above the polar circle): the switch uses the times milestone 2
  gives for that day.
- A cleared count never goes below 0 and a zikr never counts past its number.
- Search ignores case, Arabic diacritics, tatweel and letter forms (أ إ آ ا, ة ه, ى ي), and finds a
  source by its number in either digit set ("5095" or "٥٠٩٥").
- A dua in two categories shows in both and counts in both rows. Saving it once saves it
  everywhere.
- A long dua: the card grows, the Arabic is never cut.
- Morning and evening sets contain Quran verses: those cards use the Quran font and rules, and the
  count tap never animates their text.
- When my dataset replaces the sample content, progress and saved duas whose item is gone are
  dropped quietly.
- Reduce motion: the beads step instantly, the counter swaps, the ring fills without the burst,
  card moves in a set crossfade.
- Haptics turned off in More (milestone 9): counting works the same with no haptics.
- Arabic counts: 1, 2, 3 to 10 and 11 or more each use their own plural form ("{count} duas").

## Requirements *(mandatory)*

### Functional Requirements

**Azkar tab**

- **FR-001**: The Azkar tab MUST open on a page with a large title "Azkar" and a grouped list:
  Morning azkar ("After Fajr · {done} of {total}"), Evening azkar ("After Asr · {done} of
  {total}") and Tasbih ("After prayer"), each row built like Home's azkar row (icon tile, title,
  subtitle, chevron). It has no PNG, so it MUST be built only from parts in
  `03 Components.dc.html` and 4.01, and shown to me in screenshots before it is called done.
  [NEEDS CLARIFICATION: Q1]
- **FR-002**: The Azkar tab in the bottom bar MUST show the designed badge ("Badge · new azkar
  set") once the current set's window has started and the set hasn't been opened in it, and drop
  it once the set is opened. [NEEDS CLARIFICATION: Q1]

**Morning and evening sets**

- **FR-003**: The morning set MUST be current from Fajr until Asr, the evening set from Asr until
  the next Fajr, on the prayer day of milestone 4 (between midnight and Fajr it is still the day
  before). [NEEDS CLARIFICATION: Q2]
- **FR-004**: Each set's progress MUST belong to its latest window and start from 0 when its window
  opens again. Either set can be opened and counted at any time.
- **FR-005**: Home's azkar row (built in milestone 3) MUST show the current set with its subtitle
  and progress, and open that set at the first card not done.
- **FR-006**: A set MUST be a pushed page with the compact app bar (the set's name), showing one
  zikr per card using the azkar card in `03 Components.dc.html`: "{set} · {index} of {total}",
  "{n} / {count}", the Arabic in Amiri, the transliteration, the translation, and a footer with the
  source, the grading and the progress bar. It has no PNG, screenshots before done.
  [NEEDS CLARIFICATION: Q3]
- **FR-007**: A tap on the card MUST count 1 with the bead haptic. At its number the card MUST show
  done with the set complete haptic, and the next tap MUST move to the next card. A swipe MUST move
  between cards without counting. [NEEDS CLARIFICATION: Q3]
- **FR-008**: When every card is done the set MUST show "Set complete" with the set complete
  haptic once, and no praise, streak or score.
- **FR-009**: Opening a set again in the same window MUST continue at the first card not done,
  with every count kept.

**Tasbih**

- **FR-010**: Tasbih MUST match 4.08 in dark and light: the back chevron, "Tasbih · After prayer",
  reset, the three chips (SubhanAllah 33, Alhamdulillah 33, Allahu Akbar 34), the dhikr, the ring,
  the count, the bead strip and "Tap anywhere to count", with the tab bar.
- **FR-011**: The lower area MUST be the tap target: count + 1, Motion 11 with the bead haptic,
  ring in 300 ms. A tap during the spring MUST retarget it, never queue, never drop a count.
- **FR-012**: At the target the ring MUST fill and glow, "Set complete" MUST replace "of
  {target}", and Motion 12 MUST play with the set complete haptic, or its reduce motion fallback.
- **FR-013**: The tap after a finished dhikr MUST select the next one at 1, and after Allahu Akbar
  SubhanAllah at 1. [NEEDS CLARIFICATION: Q4]
- **FR-014**: A chip MUST select its dhikr from 0, with the selection haptic.
  [NEEDS CLARIFICATION: Q4]
- **FR-015**: Reset MUST set the count to 0 on the first dhikr and show a toast with Undo for 4 s
  that restores the exact state before. [NEEDS CLARIFICATION: Q4]
- **FR-016**: The current dhikr and count MUST survive leaving the screen, switching tabs, closing
  and updating the app.
- **FR-017**: The three dhikr and their targets are fixed in this milestone, no custom dhikr or
  target. [NEEDS CLARIFICATION: Q4]

**Duas**

- **FR-018**: Duas MUST match 4.14 in dark and light: compact app bar "Duas", the search field,
  the chips (All, Morning and evening, Home, Travel, Sleep), the dua card and the category rows
  with "{count} duas" and a chevron. No tab bar, as in the PNG.
- **FR-019**: A chip MUST filter the page: the card shows the first dua of the chip and the rows
  show the chip's other categories. The chip row scrolls sideways. [NEEDS CLARIFICATION: Q5]
- **FR-020**: A category row MUST open a pushed page with the compact app bar (the category name)
  and that category's duas as dua cards with Listen, Save and Share. It has no PNG, screenshots
  before done. [NEEDS CLARIFICATION: Q5]
- **FR-021**: While the search field has text, the chips' content MUST give way to the matching
  duas as cards across all categories, updated as I type. Matching covers the Arabic, the
  transliteration, the translation and the category name, ignoring case, diacritics, tatweel and
  letter forms. Clearing the search MUST return to the chip I had.
- **FR-022**: A search with no match MUST show the empty state from `03 Components.dc.html` with
  "No duas found" and "Try another word in English or Arabic."
- **FR-023**: Every dua MUST show its source, and its grading where the content has one ("Sahih
  Muslim 2692 · Sahih"). The 4.14 sample shows its source only.

**Save**

- **FR-024**: Save MUST toggle: saved shows the filled bookmark and "Saved". Removing MUST happen at
  once with a toast "Removed from saved" and Undo for 4 s.
- **FR-025**: A "Saved" chip MUST come last in the chip row (off screen in 4.14) and list the saved
  duas newest first, with the empty state "No duas saved yet" / "Tap Save on any dua to keep it
  here." when there are none. [NEEDS CLARIFICATION: Q5]

**Listen**

- **FR-026**: Listen MUST play the dua's clip from inside the app, so it works offline. While it
  plays the action reads "Stop". One clip plays at a time, and it stops when I leave the page or
  the adhan starts. [NEEDS CLARIFICATION: Q6, what Listen does until the clips exist]

**Share**

- **FR-027**: Share MUST open the phone's share sheet with the dua as an image card: the Arabic,
  the transliteration, the translation and the source in the arch frame from `01 Brand.dc.html`,
  with the app's wordmark. A long dua makes the card taller, never cut. The card has no design, so
  it is shown to me in screenshots before done. [NEEDS CLARIFICATION: Q7]

**Content**

- **FR-028**: All azkar, the tasbih dhikr and the duas MUST ship inside the app and work with no
  internet, each with a stable id so progress and saved duas survive a content update.
- **FR-029**: Until I provide the dataset, the content MUST be the handoff's sample content, and
  every entry that isn't final MUST be marked for me to replace. [NEEDS CLARIFICATION: Q9, how the
  designed counts (12, 24, 1, 3, 2, 2) are filled until then]
- **FR-030**: Category names, dua texts and their sources MUST come with the content in both
  languages. The chip names are already in the strings.

**Storage and privacy**

- **FR-031**: The tasbih state, the set progress and the saved duas MUST be kept only in the
  encrypted store on the phone, survive restarts and updates, and never leave the phone or reach
  crash reports. The app's backup file (milestone 10) carries them.

**Copy and access**

- **FR-032**: Every new string MUST exist in English and Arabic with this wording:
  [NEEDS CLARIFICATION: Q10]

  | Where | English | Arabic |
  | --- | --- | --- |
  | Azkar tab row | Morning azkar | أذكار الصباح |
  | under it | After Fajr · {done} of {total} | بعد الفجر · {done} من {total} |
  | set card header | {set} · {index} of {total} | {set} · {index} من {total} |
  | category row | {count} duas | {count} أدعية |
  | chip | Saved | المحفوظة |
  | Save once saved | Saved | محفوظ |
  | toast after removing | Removed from saved | أُزيل من المحفوظات |
  | saved empty title | No duas saved yet | لا أدعية محفوظة بعد |
  | saved empty body | Tap Save on any dua to keep it here. | اضغط «حفظ» على أي دعاء ليبقى هنا. |
  | no results title | No duas found | لا توجد أدعية مطابقة |
  | no results body | Try another word in English or Arabic. | جرّب كلمة أخرى بالعربية أو الإنجليزية. |
  | Listen while playing | Stop | إيقاف |
  | toast after reset | Count reset | أُعيد العدّ |
  | reset for screen readers | Reset count | إعادة العدّ |
  | tasbih area for screen readers | {dhikr}, {count} of {target}. Tap to count | {dhikr}، {count} من {target}. اضغط للعدّ |

  The existing "Evening azkar", "After Asr · {done} of {total}", "Set complete" and milestone 4's
  "Undo" are reused.
- **FR-033**: Counts MUST read correctly in Arabic for 1, 2, 3 to 10 and 11 or more ("{count}
  duas", "{done} of {total}").
- **FR-034**: Every action MUST be at least 44 x 44. A screen reader MUST hear the tasbih area as
  one button with the dhikr and the count, hear "Set complete" when it happens, hear each set
  card's zikr and count, and hear what Listen, Save and Share will do.
- **FR-035**: In the Arabic app, duas and azkar MUST show the Arabic and the source only, without
  the transliteration and the English translation. Tasbih's chips show the Arabic names and the
  two lines under the dhikr are hidden. [NEEDS CLARIFICATION: Q8]

**Design scenario**

- **FR-036**: "Dev · design scenario" MUST open with Tasbih at SubhanAllah 16 of 33, the evening
  set current at 0 of 24, the morning set with 12 items, nothing saved, and Duas on All as in 4.14,
  so Tasbih, Duas and Home's row match their PNGs.

### Key Entities

- **Zikr**: one item of a set. The Arabic, the transliteration, the translation, the source, the
  grading, how many times it is said, whether it is a Quran verse.
- **Azkar set**: Morning or Evening, its zikr in order, its window.
- **Set progress**: a set, the window it belongs to, the count of each zikr.
- **Tasbih dhikr**: the Arabic, the name, the meaning, the target.
- **Tasbih state**: the current dhikr and its count.
- **Dua**: the Arabic, the transliteration, the translation, the source, the grading, its
  categories, its audio clip.
- **Dua category**: its name in both languages, its chip, its duas in order.
- **Saved dua**: a dua and when it was saved.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In the design scenario Tasbih and Duas match 4.08 and 4.14 within 1 pt in dark and
  light, and Tasbih after 17 taps shows the full ring, the glow and "Set complete".
- **SC-002**: 20 taps in 2 seconds count exactly 20, each tap's haptic and bead start on the next
  frame, and the screen is at rest within 400 ms of the last tap.
- **SC-003**: The tasbih count, the set progress and the saved duas survive a restart and an
  update in every test, work in airplane mode, and nothing is sent off the phone.
- **SC-004**: One minute before and one minute after Fajr and Asr, including after midnight, on
  daylight saving days and after a time zone change, the right set is current and its progress
  belongs to the right window.
- **SC-005**: Search results show while typing with no visible delay, and every dua is found by a
  word from its Arabic (typed without diacritics), its transliteration and its translation.
- **SC-006**: The dua for leaving home is reached from Duas in one chip tap or one search word.
- **SC-007**: At text scale 2.0 nothing is cut, every action is at least 44 x 44, contrast meets
  WCAG AA in both modes, and every animation has its reduce motion fallback.

## Assumptions

- This milestone is built in the handoff's order after milestone 7, on `feature/milestone-8`.
  The spec, plan and tasks can be written before that.
- Milestone 3 builds Home's azkar row, milestone 4 the toast with Undo, milestone 7 the audio
  player. This milestone feeds and reuses them.
- The evening nudge (5.1, 5.2) is scheduled by milestone 5. From this milestone its tap opens the
  evening set, and its "24 remembrances" comes from the set.
- The adhan screen's "Read dua" sheet belongs to milestone 5 and can reuse the dua card.
- UI sounds (Bead, Complete) wait for the sound files and More's UI sounds toggle (milestone 9).
  Haptics follow More's Haptics toggle once it exists.
- "Reset prayer journey" (milestone 9) clears the prayer log and qada only, not tasbih, azkar
  progress or saved duas.
- No streaks, totals, history or reminders inside the tab, in the handoff's voice.
- The tasbih ring and the bead strip don't mirror in Arabic, like the other progress rings.
- Duas and its category page hide the tab bar, as 4.14 does. Tasbih and the set pages keep it, as
  4.08 does.
- The screen isn't kept awake while counting, and the volume buttons don't count.
- Dua clips are short and ship inside the app, unlike recitation audio, which is downloaded.
- Duas inside a category keep the order of the content.
- The copy on the components' empty state says "Tap the heart", but the design's Save is a
  bookmark, so the new copy says "Tap Save".
