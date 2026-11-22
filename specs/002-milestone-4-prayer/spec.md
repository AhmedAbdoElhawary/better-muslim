# Feature Specification: Milestone 4, Prayer

**Feature Branch**: `feature/milestone-4`, cut from `feature/milestone-2` once milestone 2 is
committed

**Created**: 2026-10-17

**Status**: Clarified

**Input**: User description: "milstone 4"

Milestone 4 is the Prayer tab (4.04 in English, 4.17 in Arabic): today's prayers with a way to log
each one, the summary ring, the week strip, the qada (make-up) list and the calculation method
sheet. The screen itself is built straight from the handoff specs. This spec covers what the
handoff doesn't: when a prayer is open or passed, what logging and undo do, how qada works, and how
the log is kept. Logging is private and gentle, no streaks and no guilt, a missed prayer leads to a
path, never a warning.

## Clarifications

### Session 2026-10-17

- Q: A passed prayer I did pray but didn't log, how do I fix it? → A: "Add to qada" opens a small
  sheet with "I prayed it" and "Add to qada". After adding, the row shows "In qada" (outline chip
  like "Add to qada"), after making it up "Made up" (green chip like "Prayed").
- Q: When does a prayer count as passed, and where does Isha after midnight go? → A: Each prayer is
  open until the next period starts, Isha until the next Fajr. The tab keeps showing the day until
  Fajr, so at 00:30 Isha still shows NOW with Mark.
- Q: What is the qada list? → A: One row per prayer with how many are left, "Made one up" (oldest
  first, toast with Undo) and + for prayers missed before using the app.
- Q: The new copy? → A: The FR-028 table as written.
- Q: How far back does the week strip go? → A: Swipe back to earlier weeks, down to the week of
  first use. Never past the current week.
- Q: What is in the method sheet? → A: "By country", the 11 methods, and the Asr calculation (By
  country, Standard, Hanafi). No per prayer minute shifts.
- Q: The location pin? → A: First "does nothing until milestone 10". Changed the same day, since
  milestone 3's spec moves the location sheet with city search up to milestone 3: the pin opens
  that sheet, kept in core so Home and Prayer share it.
- Q: Order and branch? → A: Plan and tasks now, built after milestone 3 (Home), on
  `feature/milestone-4` cut once milestone 2 is committed.
- Q: When I tap another day in the week strip, which day cell gets the filled highlight? → A: The
  fill follows the shown day. At 00:30 that is the prayer day (yesterday). Future days keep their
  grey numbers.
- Q: Should + on the qada list add many older prayers at once? → A: Yes. + opens a small sheet with
  − count + (hold to go faster) and "Add".
- Q: What happens when someone taps the "Made up" chip on a day's row? → A: Nothing, it is a label.
- Q: Should "I prayed it" in the passed-prayer sheet show a toast with Undo? → A: No, like Mark.
  The row turns "Prayed" and tapping "Prayed" undoes it as usual.

### Session 2026-10-18

- Q: What does the toast say when a prayer leaves qada from "In qada"? → A: "{prayer} removed from
  qada" / "أُزيلت صلاة {prayer} من القضاء".
- Q: How does the "By country" row of the method sheet read? → A: Title "By country", subtitle
  "Chosen for your country", and the country's method as its value at the end, like the
  components' list row.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Mark the prayer I just prayed (Priority: P1)

I pray Asr, open the Prayer tab and tap Mark on the Asr row. The chip turns into "Prayed", the ring
and the count go up and today's dot in the week strip fills. If I tapped by mistake, I tap "Prayed"
again and undo it.

**Why this priority**: Logging is the reason the Prayer tab exists beyond showing times. Home,
the adhan screen, notifications and widgets all read the same log.

**Independent Test**: In the design scenario (Thu 15 Oct 2026 16:32 Makkah, Fajr and Dhuhr
logged), tap Mark on Asr: "3 of 5 prayed today", the ring at 3/5, Thursday shows 3 dots. Tap
"Prayed": back to 2 of 5, a toast with Undo shows for 4 s, Undo brings it back.

**Acceptance Scenarios**:

1. **Given** Asr is the current prayer and not logged, **When** I tap Mark, **Then** it is logged,
   the chip morphs to "Prayed" (Motion 07 with its haptic), the ring animates 300 ms, the count and
   today's week dot update.
2. **Given** a logged prayer, **When** I tap "Prayed", **Then** it is unlogged at once and a toast
   with Undo shows for 4 s. **When** I tap Undo, **Then** it is logged again exactly as before.
3. **Given** four prayers logged today, **When** I mark the fifth, **Then** Day complete plays
   (Motion 08 with its haptic), or its reduce motion fallback.
4. **Given** Maghrib is next, **When** I look at its row, **Then** it shows "in h:mm" and can't be
   marked yet. Later prayers show the adhan icon. Sunrise shows its time only, never an action.
5. **Given** the app in Arabic, **When** I mark a prayer, **Then** the same log changes, digits are
   Eastern Arabic, the week reads from Sunday on the right, and the ring and dots don't mirror.

---

### User Story 2 - A prayer that passed without being logged (Priority: P1)

Dhuhr passed and I didn't log it. Either I prayed it and forgot to tap, or I missed it. The row
gives me both paths: log it as prayed, or put it on my qada list to make up later.

**Why this priority**: Forgetting to tap is the most common case, and without a path every
forgotten tap looks like a missed prayer. The design asks that a missed prayer offer a path,
never a warning.

**Independent Test**: Freeze the clock at 16:32 with Dhuhr unlogged: Dhuhr shows "Add to qada".
Log it as prayed from there, the row turns "Prayed". Do it again and add it to qada, the row shows
"In qada" and the summary count goes up by 1.

**Acceptance Scenarios**:

1. **Given** a prayer whose window closed without a log, **When** I see its row, **Then** it shows
   "Add to qada".
2. **Given** that row, **When** I tap "Add to qada", **Then** a small sheet titled "Dhuhr has
   passed" offers "I prayed it" and "Add to qada".
3. **Given** a prayer in qada, **When** I see its row, **Then** it shows "In qada", and once that
   entry is made up it shows "Made up".
4. **Given** a prayer in qada, **When** I tap "In qada", **Then** it leaves the qada list, the row
   shows "Add to qada" again, and a toast with Undo shows for 4 s.

---

### User Story 3 - My qada list (Priority: P2)

I tap the summary card and see how many prayers I have to make up, per prayer. After I pray one, I
take it off. Prayers I missed before I had the app can go on the list too.

**Why this priority**: The summary card ("3 missed this month to make up") leads here, and making
up missed prayers is the path the app promises instead of a warning.

**Independent Test**: In the design scenario the list holds 3 open entries. Mark one made up: the
count drops, the summary card drops with it, a toast with Undo shows. Add 2 older Fajr from the +
sheet: the Fajr count goes up by two, the summary card's month count doesn't.

**Acceptance Scenarios**:

1. **Given** open qada entries, **When** I open the qada list, **Then** I see the total left and
   one row per prayer with how many are left, "Made one up" and +.
2. **Given** Fajr has entries left, **When** I mark one made up, **Then** the oldest open Fajr
   entry is made up, the counts drop and a toast with Undo shows for 4 s.
3. **Given** a prayer with nothing left, **When** I look at its row, **Then** "Made one up" can't
   be tapped and the count never goes below 0.
4. **Given** prayers I missed before using the app, **When** I tap + on a prayer, set the count
   and tap "Add", **Then** that many entries with no date are added and a toast with Undo shows.
   They count in the list total, not in "this month".

---

### User Story 4 - Other days of the week (Priority: P2)

I tap Tuesday in the week strip and see Tuesday's prayers with what I logged. I forgot to log
Tuesday's Isha, so I fix it there. Thursday and the rest of the week ahead show times only.

**Why this priority**: The strip is how the week's log is read and the only way to fix a day after
it has passed.

**Independent Test**: In the design scenario tap Tuesday: 4 prayed, Isha in qada. Tap Saturday:
times only, no actions. The summary card keeps showing today.

**Acceptance Scenarios**:

1. **Given** the week strip, **When** I tap a past day, **Then** the rows show that day's times
   and log, and I can change them like today's.
2. **Given** the week strip, **When** I tap a future day, **Then** the rows show its times with no
   action.
3. **Given** any day selected, **When** I look at the summary card, **Then** it shows today, not
   the selected day.
4. **Given** it is Sunday, **When** I swipe the strip back, **Then** last week shows and I can fix
   Saturday's Isha. Swiping stops at the week of first use and never goes past this week.

---

### User Story 5 - Change the calculation method (Priority: P3)

My mosque uses a different method than the one picked for my country. I tap the sliders icon, pick
the method and the Asr calculation, and every time on the screen changes at once. I can go back to
"By country" any time.

**Why this priority**: The method is picked by country (milestone 2), which fits most people. The
rest need a way to change it, and the design puts that entry on this screen.

**Independent Test**: In Makkah open the sheet: "By country · Umm al-Qura" is selected. Pick Muslim
World League: the subtitle and the times change. Pick "By country" again: back to Umm al-Qura, and
moving to Cairo later gives the Egyptian method.

**Acceptance Scenarios**:

1. **Given** the Prayer tab, **When** I tap the sliders icon, **Then** the method sheet opens with
   the current method and Asr calculation selected.
2. **Given** the sheet, **When** I pick a method or an Asr calculation, **Then** it is kept as my
   pick (milestone 2 FR-012), the subtitle, the rows and the countdown update at once, with the
   selection haptic.
3. **Given** a picked method, **When** I pick "By country", **Then** the pick is cleared and the
   method follows the location's country again.

---

### Edge Cases

- Isha after midnight: at 00:30 Isha is still open and belongs to the day it started on. The tab
  keeps showing that day, with Isha as NOW, until Fajr.
- Duha (sunrise to Dhuhr): no row is current. Fajr shows its log or "Add to qada", Dhuhr shows its
  countdown.
- Ramadan with Umm al-Qura: Isha starts 120 minutes after Maghrib, so Maghrib stays open 30 minutes
  longer.
- Above the polar circle, a prayer with no time that day shows no time and no action.
- Double tap on Mark: one log, never two.
- Unmarking the fifth prayer: the ring goes back, Day complete never plays in reverse. Marking it
  again plays it again.
- The prayer day changes while the screen is open: the screen moves to the new day, a toast still
  showing applies its Undo to the day it came from.
- Location, method, Asr or time zone change: logged prayers and qada entries stay on their day and
  prayer, only the shown times change.
- Days before first use: in reach of the strip they can be logged, nothing is counted against them.
- "Made one up" on a prayer with both dated entries and entries from before the app: the dateless
  ones count as the oldest and go first.
- The + sheet's count starts at 1 and stays between 1 and 999 per add. Undo on its toast removes the
  whole batch.
- A store reset (milestone 2 FR-024) loses the log and qada with everything else, the "Restore from
  backup" offer covers them.
- Text scale above 1.4: the rows use their stacked layout, chips stay readable, nothing is cut.
- 12 hour phones: "5:56 PM" fits the rows like "17:56".
- Arabic counts: 1, 2, 3 to 10 and 11 or more each use their own plural form.

## Requirements *(mandatory)*

### Functional Requirements

**The screen**

- **FR-001**: The Prayer tab MUST match 4.04 (English) and 4.17 (Arabic) as specified in the
  handoff: title, place · method, week strip, summary card and the six rows, in dark and light.
  The large title collapses into the compact bar on scroll.
- **FR-002**: Each row MUST show one state, from the time and the log:

  | State | When | Trailing |
  | --- | --- | --- |
  | Current | its window is open | row filled, "NOW", "Mark" or "Prayed" |
  | Prayed | logged | "Prayed" chip |
  | Next | the next prayer (milestone 2 FR-015) | "in h:mm" chip |
  | Later | after the next one | adhan icon |
  | Passed | window closed, not logged, not in qada | "Add to qada" chip |
  | In qada | in qada, not made up yet | "In qada" chip |
  | Made up | its qada entry made up | "Made up" chip |

  Sunrise shows its time only. "In qada" uses the outline look of "Add to qada", "Made up" the
  green look of "Prayed".
- **FR-003**: A prayer MUST be open from its time until the next period starts: Fajr until
  sunrise, Dhuhr until Asr, Asr until Maghrib, Maghrib until Isha, Isha until the next Fajr. Only
  the current prayer and passed prayers can be logged.
- **FR-004**: The day the Prayer tab shows by default MUST run from Fajr to the next Fajr, so
  between midnight and Fajr it is still yesterday with Isha current. In this spec "today" means
  that prayer day, for the summary card and the month count too.

**Logging**

- **FR-005**: Mark on the current prayer MUST log it with Motion 07 and the Mark prayed haptic. The
  ring (300 ms), the count and the day's week dot MUST update with it.
- **FR-006**: Tapping "Prayed" MUST unlog the prayer at once and show a toast with Undo, at the
  bottom above the tab bar, for 4 s or until Undo. Undo MUST restore the exact state before.
- **FR-007**: When a day's fifth prayer gets logged, Day complete (Motion 08) MUST play with its
  haptic, or its reduce motion fallback.
- **FR-008**: "Add to qada" MUST open a small sheet with two paths: "I prayed it" logs the prayer
  with no toast, like Mark (tapping "Prayed" undoes it). "Add to qada" adds a qada entry for that
  prayer and day, with a toast with Undo.
- **FR-009**: "In qada" MUST remove the entry from qada, with the "{prayer} removed from qada"
  toast with Undo.
- **FR-010**: A prayer MUST be logged once at most per day. The log is kept by date and prayer, not
  by clock time, so a change of location, method, Asr or time zone never moves or drops it.

**Week strip**

- **FR-011**: The strip MUST show the Sunday to Saturday week of the shown day, with the shown day
  filled (the design's highlighted cell) and future days with grey numbers. Each day has 5 dots
  filled in prayer order for the prayers logged as prayed. In Arabic the week
  reads from Sunday on the right and the dots don't mirror.
- **FR-012**: Tapping a past day or today MUST show that day's rows with that day's times at the
  current location, and allow every change today allows. Future days MUST show times only.
- **FR-013**: The strip MUST reach earlier weeks back to the week of first use, never weeks after
  the current one, by swiping the strip.
- **FR-014**: The summary card MUST always show today, whatever day is selected.

**Summary card**

- **FR-015**: The ring and the number MUST show today's prayed count out of 5, with "{count} of 5
  prayed today".
- **FR-016**: The second line MUST count the open qada entries whose prayer was missed in the
  current month, with "Nothing to make up this month" at 0. Entries from before the app don't count
  here.
- **FR-017**: Tapping the card MUST open the qada list.

**Qada list**

- **FR-018**: The qada list MUST be a pushed page with the compact app bar, showing the total left
  and one row per prayer with how many are left, "Made one up" and +.
- **FR-019**: "Made one up" MUST make up the oldest open entry of that prayer, dateless ones first,
  and show a toast with Undo. It MUST be disabled at 0.
- **FR-020**: + MUST open a small sheet titled "Add missed {prayer}" with − count + (hold to go
  faster, 1 to 999, starting at 1) and "Add". "Add" adds that many entries with no date for that
  prayer (missed before using the app), with the "{prayer} added to qada" toast whose Undo removes
  the batch.
- **FR-021**: A made up entry MUST keep when it was made up. A dated one shows "Made up" on its
  day's row, as a label that does nothing when tapped.
- **FR-022**: The qada list has no PNG, so it MUST be built only from parts in
  `03 Components.dc.html` (compact app bar, grouped list rows, chips, toast) and I check it in
  the app before it is called done. The same goes for the passed prayer choice of FR-008 and
  the + sheet of FR-020.

**Method sheet**

- **FR-023**: The sliders icon MUST open a bottom sheet built from the sheet and picker row
  components: "By country" first, with "Chosen for your country" under it and the country's
  method as its value at the end, then the 11 methods, then the Asr calculation (By country, Standard, Hanafi). No per prayer
  minute shifts.
- **FR-024**: A pick MUST be kept and follow milestone 2 FR-012. "By country" MUST clear the pick.
  Times, rows and the countdown MUST update at once, with the selection haptic.

**Location pin**

- **FR-025**: The pin MUST open the same location sheet with city search as Home's location pill
  (milestone 3 FR-021 to FR-023). The sheet lives in core so both tabs open the one sheet.

**Storage and privacy**

- **FR-026**: The log, the qada entries and the date of first use MUST be kept only in the encrypted
  store on the phone, survive restarts and updates, and never leave the phone or reach crash
  reports.
- **FR-027**: The log MUST be the one source for every place that shows logged prayers: this tab,
  the Home strip checks (milestone 3), the adhan screen's Mark prayed and the notification action
  (milestone 5), and the widgets (milestone 11).

**Copy and access**

- **FR-028**: Every new string MUST exist in English and Arabic with this wording:

  | Where | English | Arabic |
  | --- | --- | --- |
  | toast after unmark | {prayer} unmarked | أُلغي تسجيل {prayer} |
  | toast action | Undo | تراجع |
  | passed choice title | {prayer} has passed | انتهى وقت {prayer} |
  | passed choice body | You can add it to your qada list whenever you're ready. | يمكنك إضافتها إلى قائمة القضاء متى شئت. |
  | passed choice option | I prayed it | صلّيتها |
  | toast after add | {prayer} added to qada | أُضيفت صلاة {prayer} إلى القضاء |
  | toast after removing | {prayer} removed from qada | أُزيلت صلاة {prayer} من القضاء |
  | row chip | In qada | في القضاء |
  | row chip | Made up | قُضيت |
  | summary at 0 | Nothing to make up this month | لا صلوات للقضاء هذا الشهر |
  | qada list title | Qada list | قائمة القضاء |
  | qada list total | {count} to make up | {count} صلوات للقضاء |
  | qada row | {count} left | بقي {count} |
  | qada action | Made one up | قضيت واحدة |
  | toast after made up | {prayer} made up | قُضيت صلاة {prayer} |
  | + for screen readers | Add one missed before | أضف صلاة فائتة سابقة |
  | + sheet title | Add missed {prayer} | أضف صلوات {prayer} الفائتة |
  | + sheet action | Add | أضف |
  | method sheet option | By country | حسب البلد |
  | under it | Chosen for your country | مُختارة حسب بلدك |
  | sheet section | Asr calculation | حساب العصر |

- **FR-029**: Counts MUST read correctly in Arabic for 1, 2, 3 to 10 and 11 or more: the existing
  "{count} missed this month to make up" and the new "{count} to make up". "{count} of 5 prayed
  today" counts out of 5 and already reads right for every number.
- **FR-030**: Every action MUST be at least 44 x 44, and a screen reader MUST hear each row's
  prayer, time and state, and what Mark, "Prayed" and "Add to qada" will do.

**Design scenario**

- **FR-031**: "Dev · design scenario" MUST open with this week's log as in 4.04: Sun 11, Mon 12
  and Wed 14 all five prayed, Tue 13 four prayed with Isha in qada, Thu 15 Fajr and Dhuhr prayed,
  and 3 open qada entries missed in October 2026, so the screen shows the 4.04 week before and after
  Mark on Asr.

### Key Entities

- **Prayer log entry**: one prayer prayed on one prayer day. Date and prayer.
- **Qada entry**: one prayer to make up. The prayer, the date it was missed (none for prayers
  missed before the app), when it was made up (none while open).
- **First use**: the date the app was first used, the strip's earliest week.
- **Prayer day**: a date, its five prayers with their windows and their state from the log and qada.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In the design scenario the Prayer tab is built from the 4.04 and 4.17 trees, in dark
  and light, before and after Mark on Asr ("3 of 5 prayed today", ring at 3/5, Thursday with 3 dots).
- **SC-002**: Marking or unmarking a prayer takes one tap, and the chip, ring and dot start moving
  within 100 ms.
- **SC-003**: Every Undo within 4 s restores the exact state before, in every test.
- **SC-004**: One minute before and one minute after every window boundary (sunrise, each prayer,
  midnight, Fajr), every row shows the right state, including Ramadan, daylight saving days and a
  time zone change.
- **SC-005**: The log and qada survive a restart and an update, work in airplane mode, and nothing
  is sent off the phone.
- **SC-006**: With a year of logs the Prayer tab opens and changes days with no visible delay on a
  mid-range phone.
- **SC-007**: At text scale 2.0 nothing is cut, every action is at least 44 x 44, contrast meets
  WCAG AA in both modes.

## Assumptions

- The "Reset prayer journey?" dialog in `03 Components.dc.html` belongs to More (milestone 9). It
  clears the log and qada.
- Milestone 5 adds Mark prayed on the adhan screen and the notification, both write to this log.
  The adhan icon on later rows stays static until milestone 5 ties it to each prayer's sound.
- No "excused" state. Qada is opt-in, so a prayer not owed simply stays unlogged.
- Friday's Dhuhr stays "Dhuhr", the design has no Jumu'ah label.
- No streaks, no counts of days in a row, no reminders about missed prayers (the handoff's voice).
- "This month" is the Gregorian month, like the dates in the week strip.
- A past day's times are computed for the current location and method. The log doesn't keep where
  a prayer was prayed.
- The app's backup file (milestone 10) carries the log and qada with the rest.
- Home's strip checks look as milestone 3 builds them, this milestone feeds them from the log.
- The week starts on Sunday in both languages, as designed.
