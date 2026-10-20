# Feature Specification: Milestone 12, Polish and Motion

**Feature Branch**: `feature/milestone-12`, cut when the build starts, after milestone 11 is reviewed

**Created**: 2026-10-20

**Status**: Clarified

**Input**: User description, my notes after running milestones 3 to 10:

```text
* i want to edit some stuff (don't fill any gap ask me for anything)
* i want everything and every transition qwith smooth, elegent, and optimised animations (make the app feels it paid for it 100K$ to develop it, make it feels premium like apple design)
For Hijri calendar:
- i want when tap on title "hijri calender" make it allowed to switch to normal calender and change everything below according to it
- change the calender icon to today text, and when we are toaday selcted make it a little transparent and when change the date and selcted another one make it tappable
- i want when tap on slider time show months and when tap on it again show years (in the place of days calander itself)
- i want when tap on a day, don't show a bottom sheet, i want to appear below the calander, so remove bottom sheet
    - under the calander show three tabs prayer time + coming up + events, in same order:
    - prayer time => just show the list of times
    - coming up tab => this tab appear all the next event for this hijri year, next events starting from the current select day to the end of the year (and appear text in the tab like "This year (1448)")
        - it's changed based on the selected day, calcualte the next starting from the current select
        - if nothing in coming up, means there is a few days for starting new hijri year, and in this case just appear the new year and "Islamic new year", and after that appear all coming up events normally
        - devide it to this month and every month, means show "this month" + "Rajab" etc..
        - show a decrement count along to every coming up event from the selected day
        - when tap on any coming up event, jump to and select the day of it in the calander
    - events => show the current event for selected day, if there is no events for seldcted day just show no events and make the title of event text a little transparent and show x icon alnoside the title
- i don't understand why you set date adjusment (is'nt you automtaiclly adjust and fine tuning the date, so we don't need it, right?)

For Home:
- the color of the sky not adaptive with themes it almost keeps show green one

for azkar:
- i want when tap and complete automtically move to the next not wait for another tap to move (complete then move to next atomutically)
- when changing tap for tasbih it's rest all, no i want when changing the tab keep the current state for it, even when popup from the page, only rest if user tap on rest
- i want the sbih circle has begin and end, make it 99 ones not infinite

animation and transitions:
- i don't see animation while moving to another pages or dialog etc. i want to make hereo animation and transitions (i want everything in the app not suddenly jump, i want it with animated move or state changing)
- i want to make the app feel premium and professional, so i want to make the app feel like it's paid for 100K$ to develop it, make it feel premium like apple design
- connect the animation with reduce motion

colors and gradient:
- there is pages not have the top gradient, i want to apply it for all, and add switch in settings if want to disable for user

in general:
- for app bar and title, i want to move the title with transition animation from the page to app bar when it shown for all pages that have title in the page and in the app bar, i think it's in prayer, azkar, and more
and make the background of the app bar also in greident mode

- remove credits, it's not proffesinoal to set it in production app
- set developer contact section in settings
```

Milestone 12 is a polish pass over what is built. It changes the Hijri calendar (4.13) the most: the
day sheet goes, the day's details live under the grid in three tabs, the calendar can show Gregorian
months, and its header opens a month and a year picker. Home's sky follows the theme. Azkar and
Tasbih move on by themselves, and Tasbih keeps a count per dhikr on a 99 bead string with a start
and an end. Every page push, dialog and state change moves instead of jumping, the large titles move
into the bar, and the top glow is on every page with a switch to turn it off. More loses Credits and
gets a contact section. Several of these break the handoff on purpose, they are listed at the end
under Approved breaks.

## Clarifications

### Session 2026-10-20

- Q: Order and branch? → A: Spec now, built after milestone 11 is reviewed, as milestone 12 on
  `feature/milestone-12`.
- Q: Gregorian mode? → A: The title switches Hijri and Gregorian, a small chevron shows it can be
  tapped. Gregorian: big Gregorian day, small Hijri day, header "October 2026" over "Rabi II –
  Jumada I 1448", events stay on their Hijri days. The mode is remembered.
- Q: The Today button? → A: The word "Today". Dimmed only when today is selected and today's month
  shows, a tap goes back to today's month and selects today.
- Q: Months and years? → A: Header tap gives the 12 months in place of the days, again gives a page
  of 12 years. A year opens its months, a month opens its days. Arrows step a month, a year or 12
  years. Range 1356 to 1500 AH.
- Q: The area under the calendar? → A: Today is selected on open. The three tabs are a segmented
  control with the content sliding and crossfading, Prayer times first, the tab stays across days.
- Q: "This year (1448)"? → A: The segment says "Coming up", "This year (1448)" heads the list.
- Q: Where Coming up starts? → A: The day after the selected day, the selected day's own events are
  in Events.
- Q: What Coming up lists? → A: Every event to the end of the year including each month's white
  days, grouped by month. No "{month} begins" rows, no 3 item limit.
- Q: The countdown? → A: A pill at the row's end, "12 days", "1 day", from the selected day.
- Q: The year end? → A: Only when nothing is left: "Next year (1449)", Islamic New Year first, then
  that year's events by month.
- Q: Coming up in Gregorian mode? → A: Follows the Gregorian year and months, "This year (2026)",
  and the next Gregorian year when empty.
- Q: Tapping a Coming up row? → A: The calendar goes to that month, selects the day and switches to
  Events.
- Q: A day with no events? → A: "No events on this day", the Events segment dimmed with an x icon,
  still tappable.
- Q: The date adjustment? → A: It stays, the app can't know each country's moon sighting offline.
  It moves to More › Prayer as "Hijri date adjustment".
- Q: Home's sky in other themes? → A: Each theme gets its own six sky states made from its own sky
  colors, the same way Qiyam Emerald's move through the day. Widgets and the Live Activity stay
  Qiyam Emerald. This replaces milestone 9's "Qiyam Emerald's sky in every theme".
- Q: Where auto-advance applies? → A: The morning and evening cards and Tasbih.
- Q: The wait before moving on? → A: After the completion moment, about 1 s. A tap in the wait moves
  at once, in Tasbih it also counts 1 on the next dhikr, on the azkar cards it doesn't count.
- Q: Tasbih Reset? → A: All three to 0 and SubhanAllah, with Undo.
- Q: All three done? → A: The round shows "Set complete", the next tap starts a new round.
- Q: The bead string? → A: One string for the round like a real misbaha: 33 + 33 + 33 beads, marker
  beads after 33 and 66, the head bead at the end. It starts at its start and stops at its end, the
  34th Allahu Akbar lands on the head bead, picking a dhikr slides it to its place.
- Q: Page transitions? → A: Apple's push on iOS and Android, edge swipe back on iOS, Android's back
  gesture plays it in reverse, mirrored in Arabic. Dialogs scale from 1.08 to 1 with a fade.
- Q: Hero pairs? → A: All five: More's tiles, the Azkar tab's rows, Home's azkar shortcuts, a dua
  category row, More's Theme and Adhan and reminders rows, each into its page's title. (Home's
  shortcuts were dropped in the plan, see below.)
- Q: "Nothing jumps"? → A: Every screen checked, each sudden change listed here (FR-036).
- Q: Reduce motion? → A: The phone's setting and the existing Reduce motion switch in More, nothing
  new. Every new animation has its fallback.
- Q: Which pages get the top glow? → A: Every page with a top bar, Qibla too. Not Home, the adhan
  screen, onboarding, sheets or dialogs.
- Q: The bar's gradient? → A: The glow stays pinned at the top behind a see-through glass bar.
- Q: The switch? → A: "Top glow" in More › Appearance, on by default, Home's sky not affected.
- Q: The large title into the bar? → A: Follows the finger like iOS: it shrinks and slides into the
  bar, takes the bar's font at the end, the subtitle fades, it snaps open or closed.
- Q: Credits? → A: The page and its row go. One "Acknowledgements" row at the bottom of About opens
  the licenses page with the data and font credits on top, the licenses ask for it.
- Q: Developer contact? → A: A CONTACT section: Send feedback, Rate, Share and Developer, values I
  don't have yet as `TODO(ahmed)`.
- Q: One build or two? → A: Two parts, each stopping for my review: part 1 the calendar, the sky,
  azkar, Tasbih and More (US1 to US5, US8), part 2 the motion, heroes, titles and glow (US6, US7).
- Q: Home's azkar shortcuts open a page in another tab, the flight can't cross tabs cleanly? → A:
  If the plan finds it needs a workaround, that one pair is dropped, the push stays.
- Q: Contrast of the new skies? → A: Checked first, a test on the text over all 48 skies (8 themes ×
  6 states) before any motion work.
- Q: Per dhikr counts change the stored settings? → A: A database migration with its test, like
  the earlier schema changes.
- Q: Can Home's azkar shortcuts fly into the set's title? (plan) → A: No, they open the set in the
  Azkar tab's own navigator and no flight sees both ends. The pair is dropped, the push stays
  (research R9).
- Q: The dimmed Events label is still tappable, so it must meet AA? (analyze) → A: It takes the
  segmented control's muted look (text2, already AA) with the x icon, not the disabled opacity.
- Q: Reduce motion turned on mid animation? (analyze) → A: What is running finishes, the next
  change uses the fallback.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - The day under the calendar (Priority: P1)

I open the Hijri calendar and today's prayer times are already under the grid. I tap Friday and its
times show in place, no sheet covers the month. I switch to Coming up and see everything left this
year by month, with how many days each is away. I tap Ramadan and the calendar jumps there and shows
me the event.

**Why this priority**: It is what I open the calendar for, and the sheet hid the month I was looking
at. Coming up with only three rows never reached the events I care about.

**Independent Test**: In the design scenario open the calendar: 4 Jumada I is selected, Prayer times
shows its six times. Tap 13: the times change, Events shows Ayyam al-Bid. Tap Coming up: "This year
(1448)", "This month" has nothing before 13 is over, later months are listed, each with a day pill.
Tap the start of Ramadan: Ramadan 1448 shows, 1 Ramadan selected, Events open.

**Acceptance Scenarios**:

1. **Given** the calendar opens, **When** it shows, **Then** today is selected, the date line shows
   today's Hijri and Gregorian dates, and Prayer times lists today's six times.
2. **Given** a day, **When** I tap it, **Then** the selection moves to it with an animation, the
   date line and the open tab change to that day, and no sheet opens.
3. **Given** Coming up, **When** a day is selected, **Then** every event from the next day to the
   end of that year is listed, grouped by month, each with a pill counting the days from the selected
   day.
4. **Given** Coming up, **When** nothing is left in the year, **Then** "Next year (1449)" heads the
   list, Islamic New Year first.
5. **Given** a Coming up row, **When** I tap it, **Then** the calendar slides to its month, selects
   its first day and opens Events.
6. **Given** a day with no event, **When** it is selected, **Then** Events shows "No events on this
   day" and its segment is dimmed with an x icon, but still opens.

---

### User Story 2 - Move around the calendar (Priority: P2)

I want the Gregorian view, so I tap the title. Later I look up next year's Ramadan: I tap the month
name, then again, pick 1449, pick Ramadan. "Today" brings me back.

**Why this priority**: Most people plan in Gregorian dates and stepping twelve months with the arrows
is slow, but the calendar works without both.

**Independent Test**: Tap the title: "Gregorian calendar", October 2026 with 15 selected, small Hijri
days. Tap the header twice: years. Pick 1449 (in Hijri mode), then Ramadan: Ramadan 1449. Today is
full strength, tap it: today's month and day again, Today dimmed.

**Acceptance Scenarios**:

1. **Given** Hijri mode, **When** I tap the title, **Then** the page switches to Gregorian, keeps
   the selected day, and the next launch opens in Gregorian.
2. **Given** the days view, **When** I tap the header title, **Then** the months of that year replace
   the days, and a second tap shows a page of 12 years.
3. **Given** the years view, **When** I tap a year and then a month, **Then** that month's days show.
4. **Given** today selected in today's month, **When** the page shows, **Then** Today is dimmed and
   does nothing.
5. **Given** another day or month, **When** I tap Today, **Then** the days view slides to today's
   month and selects today.

---

### User Story 3 - Home's sky in my theme (Priority: P1)

I picked Iznik but Home's sky stayed green. Now the sky is Iznik's blue at night and Iznik's own
morning, noon and dusk through the day.

**Why this priority**: The sky is the first thing I see, and a green sky on a blue theme looks
broken.

**Independent Test**: In Dev with a place (real times, the design scenario keeps each theme's base
sky) pick each theme: the sky changes to that theme's own sky for the current state, Qiyam
Emerald's is the same as today. Set the phone's clock to each prayer: each theme's sky changes state
with the 1800 ms sky change.

**Acceptance Scenarios**:

1. **Given** any theme, **When** Home shows, **Then** the sky is that theme's sky for the current
   sky state.
2. **Given** Qiyam Emerald, **When** any state shows, **Then** the colors are exactly today's.
3. **Given** a theme change, **When** I apply it, **Then** the sky crossfades to the new theme's
   sky.
4. **Given** any theme and state, **When** text sits on the sky, **Then** it stays readable (AA).

---

### User Story 4 - Azkar that move on by themselves (Priority: P1)

I read the morning azkar. When a card is done, the next one slides in on its own after the check, I
don't tap again just to move.

**Why this priority**: The extra tap breaks the flow on every card of every set, twice a day.

**Independent Test**: Open the morning set, tap a card with count 1: the check shows, about 1 s
later the next card slides in. Tap a card with count 3 three times, then tap again at once: it moves
without counting.

**Acceptance Scenarios**:

1. **Given** a card that isn't the last, **When** it reaches its count, **Then** the next card
   slides in after the completion moment.
2. **Given** the wait, **When** I tap, **Then** the next card shows at once and the tap isn't
   counted.
3. **Given** the wait, **When** I swipe, **Then** the automatic move is cancelled.
4. **Given** the last card, **When** it is done, **Then** nothing moves and the set shows complete.

---

### User Story 5 - A tasbih that remembers and ends (Priority: P1)

After prayer I count SubhanAllah, Alhamdulillah, Allahu Akbar without touching the chips, each moves
on by itself. If I check another chip, nothing is lost. The beads are a real string with a start and
an end.

**Why this priority**: Losing a count by tapping a chip, or having to tap once more between each
dhikr, is the opposite of a tasbih.

**Independent Test**: Reset, tap 100 times: SubhanAllah 33, Alhamdulillah 33, Allahu Akbar 34, each
moving on by itself, the string ends on its head bead, "Set complete". Tap: a new round at
SubhanAllah 1. Count 10, pick Alhamdulillah, pick SubhanAllah: still 10. Leave and restart: still 10.

**Acceptance Scenarios**:

1. **Given** a dhikr, **When** it reaches its target and another isn't done, **Then** the next one
   that isn't done shows after the completion moment.
2. **Given** that wait, **When** I tap, **Then** the next dhikr shows at once at 1.
3. **Given** counts on several dhikr, **When** I pick a chip, **Then** it shows its own count and
   nothing resets.
4. **Given** counts, **When** I leave the page, switch tabs or restart the app, **Then** all three
   counts and the shown dhikr come back.
5. **Given** Reset, **When** I tap it, **Then** all three go to 0, SubhanAllah shows, the string
   rewinds, and Undo brings everything back.
6. **Given** the round complete, **When** I tap, **Then** a new round starts at SubhanAllah 1.
7. **Given** the string, **When** it reaches either end, **Then** it never moves past it.

---

### User Story 6 - Nothing jumps (Priority: P1)

Every page slides in like on an iPhone, the title I tapped flies to the new page, dialogs grow in,
and on every screen what changes moves to its new state. With Reduce motion on, it all calms down to
fades.

**Why this priority**: This is what makes the app feel finished. Right now pages and many states
change in one frame, on Android pages barely move at all.

**Independent Test**: On Android and iOS push every page from the FR-031 list and go back: each
slides, the page under it moves aside and dims. Tap More › Hijri calendar: "Hijri calendar" flies
into the bar. Open a dialog: it scales in. Walk the FR-036 list: nothing swaps in one frame. Turn
Reduce motion on: pushes, flights and dialogs are short fades, nothing slides or scales.

**Acceptance Scenarios**:

1. **Given** any pushed page, **When** it opens or closes, **Then** it uses Apple's push on both
   platforms, mirrored in Arabic.
2. **Given** iOS, **When** I swipe from the edge, **Then** the page follows my finger back.
3. **Given** a hero pair, **When** I push or go back, **Then** the text flies between the row and
   the page's title.
4. **Given** a dialog, **When** it opens, **Then** it scales from 1.08 to 1 while fading in.
5. **Given** any change in the FR-036 list, **When** it happens, **Then** it animates by the FR-035
   rule.
6. **Given** Reduce motion (phone or app), **When** any of these plays, **Then** its fallback plays.
7. **Given** any animation running, **When** I tap, swipe or go back, **Then** it responds at once.

---

### User Story 7 - Titles and the glow (Priority: P2)

On Prayer, Azkar and More the big title slides up into the bar as I scroll. Every page has the same
warm glow at the top, also behind the bar. I can turn the glow off.

**Why this priority**: The pages without the glow look unfinished next to Prayer and More, but the
app works without it.

**Independent Test**: Scroll More slowly: the title shrinks and moves into the bar with my finger,
stop halfway: it snaps. Open each FR-040 page: the glow is at the top and stays behind the bar when
scrolling. Turn Top glow off: gone everywhere, the bar is plain glass, Home's sky unchanged.

**Acceptance Scenarios**:

1. **Given** Prayer, Azkar or More, **When** I scroll, **Then** the large title moves into the bar
   following my finger and the subtitle fades.
2. **Given** a scroll stopped halfway, **When** I let go, **Then** the title snaps open or closed.
3. **Given** any FR-040 page, **When** it shows or scrolls, **Then** the glow stays at the top
   behind a see-through bar.
4. **Given** Top glow off, **When** any page shows, **Then** no glow shows and the bar is plain
   glass.

---

### User Story 8 - A cleaner More (Priority: P3)

More doesn't show a Credits page any more, the credits sit quietly under Acknowledgements. I can
email the developer, rate and share the app. The date adjustment is with the prayer settings.

**Why this priority**: It is what a published app has, but nothing else depends on it.

**Independent Test**: More: CONTACT above ABOUT, ABOUT has Acknowledgements and Version, no Credits.
Send feedback: the mail app opens with the address, subject and version. Acknowledgements: the
credits then the licenses. PRAYER has Hijri date adjustment, changing it moves Home's date.

**Acceptance Scenarios**:

1. **Given** More, **When** it shows, **Then** there is no Credits row and ABOUT ends with
   Acknowledgements and Version.
2. **Given** Send feedback, **When** I tap it, **Then** the mail app opens ready to write, nothing
   is sent by the app.
3. **Given** a contact row whose value isn't set yet, **When** More shows, **Then** that row is
   hidden.
4. **Given** Hijri date adjustment in PRAYER, **When** I change it, **Then** the calendar and Home's
   date move with it.

---

### Edge Cases

- The selected day is the year's last day, or the last event is behind it: Coming up shows the next
  year.
- The selected day is in 1500 AH and nothing is left: "No more events", the table ends there.
- A Gregorian month the table doesn't fully cover: not reachable, the arrows and the picker stop
  before it.
- The adjustment changes while the calendar is open: the grid, the dates and the events move, the
  selected Gregorian day stays selected.
- Midnight with the calendar open: the shown month stays (milestone 9 FR-021), the today look and
  the Today button follow the new day.
- Switching mode in the months or years view: the same view in the new mode, around the selected
  day.
- Text scale 2.0: the three segments still fit, a Coming up pill goes under the name when the row
  is too narrow.
- Arabic: the segments read from the right, slides and pushes mirror, the pill's digits follow the
  digits setting.
- An event that covers several days (Ayyam al-Bid, Tashreeq) with its first day before the selected
  day: not in Coming up, in Events on each of its days.
- Leaving the azkar set or Tasbih during the wait: nothing moves, every count is saved.
- The app killed during the Tasbih wait: it opens on the finished dhikr, the next tap moves on.
- A saved Tasbih state from before milestone 12 (one dhikr and one count): that dhikr keeps its
  count, the other two start at 0.
- Fast taps at the head bead: the string doesn't pass its end, the new round starts it from the
  beginning.
- A hero source scrolled off screen: no flight, the plain push.
- Reduce motion turned on mid animation: what is running finishes, the next change uses the
  fallback.
- Top glow off and a large title collapsing: the bar is plain glass.
- No mail app on the phone: a toast shows the address to write to.
- A sky state unknown (no location, polar day or night): the theme's base sky, as today.

## Requirements *(mandatory)*

### Functional Requirements

**Hijri calendar (4.13)**

- **FR-001**: The calendar MUST have a Hijri and a Gregorian mode. Tapping the bar's title switches
  them, the title reads "Hijri calendar" or "Gregorian calendar" with a small chevron after it and
  crossfades when it changes. The mode is saved, a fresh install opens in Hijri.
- **FR-002**: Hijri mode MUST stay the 4.13 grid and header: big Hijri day, small Gregorian day,
  "Jumada I 1448" over "October – November 2026".
- **FR-003**: Gregorian mode MUST show one Gregorian month, the week from Sunday: big Gregorian day,
  small Hijri day with the short Hijri month on the first cell and on each Hijri day 1. The header
  reads "October 2026" over the Hijri months it spans ("Rabi II – Jumada I 1448", across years
  "Dhu al-Hijjah 1447 – Muharram 1448"). Today, the selected day, the white days, the fasting days
  and the events keep milestone 9's looks (FR-019), on their Hijri days with the adjustment.
- **FR-004**: Switching mode MUST keep the selected day and show the month that holds it, the grid
  crossfading.
- **FR-005**: Hijri mode MUST span 1356 to 1500 AH as now, Gregorian mode the first to the last
  Gregorian month that table fully covers. Arrows and picker entries past either end are disabled.
- **FR-006**: The bar's end button MUST be the word "Today" in place of the calendar icon. When
  today is selected and today's month shows in the days view it is dimmed (the disabled opacity)
  and does nothing, otherwise it is full strength. A tap goes back to the days view, slides to
  today's month and selects today. Screen readers hear "Today" and its disabled state. The change
  between dimmed and full animates.
- **FR-007**: Tapping the month header's title MUST replace the days with the 12 months of the
  shown year (in the current mode), the header showing the year. A second tap shows a page of 12
  years holding it, the header showing "1440 – 1451". A tap in the years view goes back to the
  days. A year opens its months, a month opens its days. The arrows step a month, a year or 12
  years. The current month or year is marked like today, the shown one like the selected day. Days
  to months to years zoom out with a crossfade, back zooms in, a crossfade only with reduce motion.
- **FR-008**: A change of shown month (arrows, picker, Today, a Coming up tap) MUST slide the grid
  the way it travels, mirrored in Arabic, and a change between 5 and 6 rows animates its height.
- **FR-009**: Tapping a day MUST select it with no sheet, the day sheet is removed. The selected look
  moves to the new day with an animation. The page opens with today selected, and the selection
  stays while I browse other months.
- **FR-010**: Under the grid MUST come the selected day's date line (its Hijri and Gregorian dates,
  as the old sheet's title and subtitle), a segmented control with Prayer times, Coming up and
  Events, and the open tab's content. Prayer times is open on arrival, the open tab stays when
  another day is selected. A tab change slides the content toward the tapped side with a crossfade,
  mirrored in Arabic, and the area's height animates. The date line crossfades when the day
  changes.
- **FR-011**: Prayer times MUST list Fajr, Sunrise, Dhuhr, Asr, Maghrib and Isha of the selected day
  at the current place and method, as the old sheet did. With no place yet it shows the no location
  line and a button that opens the location sheet.
- **FR-012**: Coming up MUST list every event from the day after the selected day to the last day of
  its year, the Hijri year in Hijri mode and the Gregorian year in Gregorian mode, under "This year
  (1448)" or "This year (2026)".
- **FR-013**: Coming up MUST group the events by month: the selected day's month under "This month",
  then each later month that has an event under its name ("Rajab", in Gregorian mode "December").
  Months with no event are skipped.
- **FR-014**: The events MUST be milestone 9's FR-020 table: the white days each month (14 and 15 in
  Dhu al-Hijjah), Islamic New Year, Tasu'a, Ashura, Ramadan, the last ten nights, Eid al-Fitr, the
  Day of Arafah, Eid al-Adha and the days of Tashreeq. No "{month} begins" rows and no 3 item limit.
  Each event shows once on its first day, an event that starts on or before the selected day isn't
  listed.
- **FR-015**: A Coming up row MUST keep 4.13's row look: the day and short month on the start side
  (Hijri in Hijri mode, Gregorian in Gregorian mode), the event's name, and under it its note and
  its dates in the other calendar ("White days, fasting recommended · 24–26 Oct"). An event in a
  later Hijri month than today's says "Estimated" before its date, the month start depends on the
  moon sighting. A pill at the end counts the days from the selected day to the event's first day:
  "1 day", "12 days".
- **FR-016**: When nothing is left in the selected day's year, Coming up MUST show the next year
  instead: "Next year (1449)", Islamic New Year first, then that year's events by month. In
  Gregorian mode "Next year (2027)" and its events from 1 January. Past the table's last year it
  shows "No more events".
- **FR-017**: Tapping a Coming up row MUST slide the calendar to the event's month in the days view,
  select its first day and open Events, with the selection haptic.
- **FR-018**: Events MUST list each event that covers the selected day with its name and note, a
  several day event on each of its days. With none it shows "No events on this day", and the Events
  segment's label is dimmed (the segmented control's muted text2 look, which meets AA) with a small
  x icon after it, still tappable. The dimmed and full label animate between days.
- **FR-019**: The date adjustment MUST leave the calendar page and move to More › PRAYER as "Hijri
  date adjustment", with the same value and sheet (−2 to +2 days). It still moves the calendar,
  Home's date and every other Hijri date.

**Home's sky**

- **FR-020**: The Living Sky MUST follow the theme. Each of the 8 themes gets six sky states (Fajr,
  Sunrise, Dhuhr, Asr, Maghrib, Isha) made from its own dark sky colors: Isha is the theme's night
  sky, and the other five move from it the way Qiyam Emerald's move from its Isha (lighter and
  warmer by day, the dusk tones at Maghrib), so each theme keeps its own hue. Qiyam Emerald's six
  states stay exactly as they are. The same sky in light and dark. This replaces milestone 9's
  FR-014.
- **FR-021**: Text on the sky MUST meet WCAG AA in every theme and state, with milestone 3's white
  text and scrim on the bright states. A test checks the text over all 48 skies, built before any
  motion work.
- **FR-022**: The theme page's preview and the welcome screen MUST show the same theme sky. The
  adhan screen and the system surfaces keep the handoff's Qiyam Emerald colors. A theme change
  crossfades the sky.

**Azkar sets**

- **FR-023**: When a card reaches its count and it isn't the last card, the set MUST move to the
  next card by itself once the completion moment is over (the check and the haptic, about 1 s). A
  tap in that wait moves at once and isn't counted, a swipe cancels the move. The last card stays
  and the set shows complete.
- **FR-024**: A tap on a done card I swiped back to MUST still move to the next card, as now.

**Tasbih (4.08)**

- **FR-025**: Each of the three dhikr MUST keep its own count. A chip shows its dhikr with its own
  count and ring and never resets anything. The three counts and the shown dhikr are saved and come
  back after leaving the page, switching tabs or restarting the app. The stored settings change
  with a database migration and its test.
- **FR-026**: When a dhikr reaches its target and another isn't done, Tasbih MUST move to the next
  one that isn't done (SubhanAllah, Alhamdulillah, Allahu Akbar, then around) once the completion
  moment is over (the ring fill and the burst, about 1 s). A tap in that wait moves at once and
  counts 1 on the next dhikr, a chip tap cancels the move and shows that chip. The chips, the
  Arabic line and the ring change with animation.
- **FR-027**: When all three are done the round MUST be complete: the ring stays full, "Set
  complete" shows and nothing moves. The next tap starts a new round: all three at 0, SubhanAllah
  at 1, the string back at its start.
- **FR-028**: A tap on a done dhikr while another isn't done MUST move to the next one that isn't
  done and count 1 there.
- **FR-029**: Reset MUST set all three counts to 0 and show SubhanAllah, the string rewinding to its
  start, with the existing toast whose Undo brings back the three counts and the shown dhikr.
- **FR-030**: The bead strip MUST be one finite string for the round, like a real misbaha: 33 beads
  for SubhanAllah, a marker bead, 33 for Alhamdulillah, a marker bead, 33 for Allahu Akbar, then the
  head bead with its tassel. The bead in focus is the shown dhikr's place on the string (its start
  plus its count), the 34th Allahu Akbar lands on the head bead. At the start the string's free end
  shows before the first bead, and it never moves past either end. Each count steps one bead on the
  Motion 11 spring, stepping over a marker. A chip or an automatic move slides the string to that
  dhikr's place on the same spring, it jumps with reduce motion. Never mirrored in Arabic. The marker
  and head beads use the theme's colors.

**Pages, heroes and dialogs**

- **FR-031**: Every pushed page MUST use Apple's push on iOS and Android: it slides in from the end
  edge while the page under it moves a third of the way toward the start edge and dims, back plays
  it in reverse, mirrored in Arabic. On iOS the edge swipe back follows the finger, on Android the
  back gesture plays it in reverse. This covers Qada, the azkar sets, Tasbih, Duas and a category,
  Qibla, Theme, Adhan and reminders, the Hijri calendar, Acknowledgements and a license, and the dev
  page. A 150 ms crossfade with reduce motion.
- **FR-032**: These MUST keep their own motion: the onboarding steps (milestone 10), the adhan reveal
  (Motion 06), Home fading in after Apply theme, the tab switch (Motion 16) and the sheets (Motion
  15).
- **FR-033**: A shared element flight MUST play on push and back for: More's Qibla, Hijri calendar
  and Duas tiles (the label into the page's title), the Azkar tab's Morning, Evening and Tasbih rows
  (the title into the page's title), a dua category row (its name into the category's title), and
  More's Theme and Adhan and reminders rows (the title into the page's title). The text changes size
  and weight smoothly in flight, the rest of the page dims and moves aside with the push. Home's
  azkar shortcuts get no flight, the plan found it can't cross the tabs without a workaround. No
  flight with reduce motion, the page's crossfade only.
- **FR-034**: Dialogs MUST come in like Apple's alerts, scaling from 1.08 to 1 while fading in with
  the scrim, and leave with a fade. A 150 ms fade only with reduce motion.

**State changes**

- **FR-035**: With reduce motion off, a state change on any screen MUST NOT swap in one frame. The
  rules, all in the Responsive tier (150 to 380 ms, the standard curve or the snappy spring),
  interruptible, never blocking input, with no haptic beyond MOTION.md's table:

  | Change | Motion |
  | --- | --- |
  | a number or short value changes | the new value crossfades in, a count rolls its digits like Home's countdown |
  | content is replaced (tabs, modes, empty and filled, loading and loaded) | a crossfade with a short slide from where it comes |
  | a block changes size (a row opens, a line appears) | the size animates and the content fades in |
  | items join or leave a list | they slide and fade in or out, the rest move to their place |
  | a selection moves (segments, chips, day cells, swatches) | the highlight slides to its new place |
  | something turns on, off, enabled or disabled | its color and opacity animate |

- **FR-036**: These swap in one frame today and MUST follow FR-035 (every screen read on
  2026-10-20, the plan checks again and adds what this missed):

  | Screen | Change |
  | --- | --- |
  | Home | the no location card and the next prayer card; the sky labels appearing with a place; the strip's current and logged marks; the location pill's text; the bright state scrim |
  | Prayer | a row opening and closing; the state chip's check; the week strip jumping to a linked day; the day dots filling; Qada rows joining and leaving |
  | Azkar sets | the card's counter |
  | Tasbih | the chip selection; the Arabic line, name and meaning changing dhikr; the count area appearing after loading |
  | Duas | the chip selection; results, saved and empty states swapping; search results changing |
  | Hijri calendar | covered by FR-006 to FR-018 |
  | Theme | the selection ring moving between swatches; the preview restyling; the Dark, Light and Follow sky selection |
  | Adhan and reminders | the notifications off line appearing; the recording row appearing when a prayer is set to Adhan; the segment selections |
  | More | the values changing after a sheet closes |
  | Sheets | the location sheet's results; the method sheet's check; the picker rows' check; backup and restore going from working to done |
  | Shared | the segmented control's highlight; a row's value; toasts sliding and fading in from the bottom and fading out |

- **FR-037**: Every animation in this spec MUST have its reduce motion fallback (a crossfade or
  instant, MOTION.md's rule) and follow both the phone's setting and the Reduce motion switch in
  More › Appearance, which stays as it is.
- **FR-038**: Every animation MUST be interruptible: a new tap, swipe or back retargets it from where
  it is and never waits for it to end.

**Titles, the bar and the glow**

- **FR-039**: On Prayer, Azkar and More the large title MUST move into the bar as I scroll, following
  the finger: it shrinks and slides from its place to the bar's center, takes the bar's title font in
  the last part of the move, the subtitle under it fades out and the bar's glass fades in. A scroll
  stopped between open and closed snaps to the nearer one, scrolling back reverses it. With reduce
  motion the current crossfade at the collapse point.
- **FR-040**: The sky3 glow behind Prayer's and More's titles MUST be on every page with a top bar
  or a page title:
  Azkar, the azkar sets, Tasbih, Duas and a category, the Hijri calendar, Theme, Adhan and
  reminders, Qada, Qibla, Acknowledgements and a license, the Quran placeholder and the dev page. Not
  on Home, the adhan screen, onboarding, sheets or dialogs.
- **FR-041**: The glow MUST stay pinned at the top while the page scrolls, and the bar MUST be
  see-through glass over it (blurred, with less surface tint), so the top keeps its gradient after
  the title moves into the bar.
- **FR-042**: More › Appearance MUST have a "Top glow" switch, on by default and saved. Off removes
  the glow from every page and the bar is today's plain glass, Home's sky doesn't change. The change
  crossfades.

**More (4.09)**

- **FR-043**: The Credits page and its row MUST be removed. ABOUT ends with an "Acknowledgements"
  row and Version. Acknowledgements opens one page: the data and font credits on top (source, use,
  license and link, milestone 9's FR-033 list with its two `TODO(ahmed)`), then the open source
  licenses, each opening its license as now.
- **FR-044**: A CONTACT section MUST sit above ABOUT with: Send feedback (the phone's mail app with
  the developer's address, the subject "Better Muslim feedback" and the app version, phone model and
  OS version in the body, nothing sent by the app), Rate Better Muslim (the app's store page), Share
  Better Muslim (the system share sheet with a short line and the store link) and Developer (the
  developer's name, opening the developer's website). Each value is a `TODO(ahmed)` until I set it,
  and a row whose value isn't set is hidden.
- **FR-045**: More › PRAYER MUST have the Hijri date adjustment row of FR-019, after Adhan and
  reminders.

**Copy**

- **FR-046**: Every new string MUST exist in English and Arabic with this wording, and keys nothing
  uses any more (Credits, the calendar's COMING UP label, "{month} begins", Date adjustment) are
  removed from `StringsManager` and both arb files:

  | Where | English | Arabic |
  | --- | --- | --- |
  | calendar title | Gregorian calendar | التقويم الميلادي |
  | header, for screen readers | Show months, Show years, Show days | عرض الأشهر، عرض السنوات، عرض الأيام |
  | arrows, for screen readers | Previous year, Next year, Previous years, Next years | السنة السابقة، السنة التالية، السنوات السابقة، السنوات التالية |
  | years header | {first} – {last} | {first} – {last} |
  | tabs | Prayer times, Coming up, Events | مواقيت الصلاة، القادم، المناسبات |
  | Coming up heading | This year ({year}), Next year ({year}) | هذا العام ({year})، العام القادم ({year}) |
  | Coming up group | This month | هذا الشهر |
  | day pill | 1 day, 12 days (the existing days key) | ١ يوم، ١٢ يوم |
  | Coming up end | No more events | لا مناسبات بعدها |
  | Events empty | No events on this day | لا مناسبات في هذا اليوم |
  | More row | Hijri date adjustment | تعديل التاريخ الهجري |
  | More toggle | Top glow | التوهج العلوي |
  | About row | Acknowledgements | شكر وتقدير |
  | section | CONTACT | التواصل |
  | contact rows | Send feedback, Rate Better Muslim, Share Better Muslim, Developer | أرسل ملاحظاتك، قيّم مسلم أفضل، شارك مسلم أفضل، المطوّر |
  | feedback subject | Better Muslim feedback | ملاحظات على مسلم أفضل |
  | feedback body | Version {version} · {device} · {os} | الإصدار {version} · {device} · {os} |
  | share line | Prayer times, Quran, azkar and qibla, on your phone and offline. {link} | مواقيت الصلاة والقرآن والأذكار والقبلة، على هاتفك وبلا إنترنت. {link} |
  | no mail app | No mail app. Write to {email} | لا يوجد تطبيق بريد. اكتب إلى {email} |

### Key Entities

- **Calendar mode**: Hijri or Gregorian, saved with the settings.
- **Calendar view**: days, months or years, the shown month, year or year page, and the selected
  day. Lives while the page is open.
- **Coming up list**: its year and whether it is this year or the next, the month groups, and each
  event's first day, name, note, dates in the other calendar, estimated or not, and days away.
- **Theme sky**: for each theme, six sky states of three colors, Qiyam Emerald's being today's
  table.
- **Tasbih round**: three counts, one per dhikr, and the shown dhikr, saved with the settings. It
  replaces the single dhikr and count.
- **Top glow**: on or off, saved with the settings.
- **Contact details**: the developer's email, name and website, the App Store and Play links. Set
  in the code by me, not by the user.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Everything the day sheet showed (both dates, six times, events) is visible under the
  grid one tap after choosing a day, with the month still on screen.
- **SC-002**: Any event left in the year is reached from the calendar in 2 taps (Coming up, the
  row).
- **SC-003**: Any Hijri or Gregorian month in the range is reached in at most 4 taps from the days
  view.
- **SC-004**: All 8 themes show a sky in their own hue at each of the 6 states, and Qiyam Emerald's
  18 colors are unchanged.
- **SC-005**: A full Tasbih round takes exactly 100 taps, with no tap spent only to move on, and the
  morning set takes one tap less per card than before.
- **SC-006**: Tasbih counts survive leaving the page, switching tabs and restarting the app every
  time.
- **SC-007**: Walking every screen of FR-031 to FR-036 with reduce motion off, nothing swaps in one
  frame. With reduce motion on, nothing slides, scales or flies.
- **SC-008**: Pushes, flights, the title move and the calendar's slides run without visible stutter
  at the phone's full refresh rate on a mid-range phone three years old.
- **SC-009**: No animation delays a tap: a tap, swipe or back during any animation responds in the
  same frame.
- **SC-010**: Every new string is in English and Arabic, Arabic mirrors every slide and push, and
  text scale 2.0 cuts no segment, pill or title.

## Assumptions

- The date line above the tabs keeps what the old sheet's title showed, so removing the sheet loses
  nothing.
- With no place yet, Prayer times shows the existing no location line with a button to the location
  sheet, the old sheet showed nothing.
- A tap on the header in the years view goes back to the days view, so the title cycles days,
  months, years.
- "Estimated" is counted from today's Hijri month, not the selected day's, it is about what is known
  now.
- Home's Quran shortcut switches tabs, it has no page to fly into, so it gets no flight.
- Home's azkar shortcuts open a page in another tab, the flight can't cross the tabs without a
  workaround, so that pair is dropped and the push alone stays (plan, research R9).
- The theme skies are made from each theme's dark sky colors because the sky is the same in light
  and dark.
- Send feedback only opens the mail app with the text filled in, I decide to send it, so nothing
  leaves the phone without me (principle VII).
- The contact values (email, name, website, store links) are constants I set, rows stay hidden until
  then, so the build never shows a dead link.
- The existing Reduce motion switch already joins the phone's setting, no new setting is needed.
- No new package is assumed, the plan checks pub.dev and asks me before adding one.

## Approved Breaks

The constitution says the handoff is built as it is (principle III). These change it on my
instruction of 2026-10-20:

- 4.13: the day sheet becomes the area under the grid, the calendar icon becomes "Today", the title
  switches to Gregorian, the header opens months and years, the Date adjustment row moves to More,
  Coming up lists the year instead of three rows, without the "{month} begins" rows.
- SCREENS.md 4.13 "Day tap → day sheet" and "Date adjustment → stepper sheet" on the calendar.
- 4.08 and SCREENS.md: "Next tap after done → next dhikr" becomes the automatic move, a chip no
  longer resets the count, Reset clears all three, the endless bead strip becomes a 99 bead string
  with a head bead.
- The azkar set's "the tap after a done card moves on" becomes the automatic move.
- Milestone 9 FR-014 (Qiyam Emerald's sky in every theme) is replaced by FR-020.
- The sky3 glow, on 4.04 and 4.09 only in the handoff, goes on every page with a bar, and the bar's
  tint is lowered over it.
- The compact bar's fade in on large title pages becomes the title moving into the bar.
- 4.09: no Credits row (milestone 9 FR-033), a CONTACT section, the Hijri date adjustment and Top
  glow rows.
- Page pushes use Apple's push on Android too.
- Principle VIII's credits stay met under Acknowledgements.
