# Feature Specification: Milestone 3, Home

**Feature Branch**: `feature/milestone-3`

**Created**: 2026-10-17

**Status**: Draft

**Input**: User description: "milstone 3"

Milestone 3 is the Home screen: 4.01 (dark), 4.02 (light) and 4.16 (Arabic), with the Living Sky,
the live countdown and the next-prayer glow. Its layout, copy, colors and motion are in the
handoff (`specs/screens/4.01-home.md`, `4.02-home-light.md`, `4.16-home-ar.md`, `SCREENS.md`,
`MOTION.md`) and are not repeated here. This spec only holds what the handoff leaves open and the
rules behind the live values. The data comes from milestone 2.

## Clarifications

### Session 2026-10-17

- Q: A spec for Home, when the constitution keeps speckit for logic the handoff doesn't spec?
  → A: A short one, only for what the handoff leaves open. The constitution went to 2.2.0 so
  every milestone gets a spec this way.
- Q: Home shows things from later milestones (logged prayers in 4, reminder minutes in 5, verse
  and reading position in 7, azkar count in 8). What shows until then? → A: The handoff's sample
  content, marked for the milestone that replaces it. Outside the design scenario the strip shows
  no logged prayers yet, the scenario shows Fajr and Dhuhr logged as fixed values. Taps open the
  tab until the deeper screen exists.
- Q: When does the row say morning azkar and when evening? → A: Morning azkar from Fajr until Asr,
  evening azkar from Asr until the next Fajr.
- Q: The PNG shows the glow 84 minutes before Maghrib, MOTION 05 says the final 10 minutes. → A:
  The glow is always there and still, and breathes only in the final 10 minutes. Reduce motion
  keeps it still.
- Q: The location pill opens a "location sheet" that has no design, and Home without a location
  has no design. → A: A small sheet with "Use my location" and the offline city search, built from
  existing parts. Without a location Home shows the sky with no sun, the pill says "No location
  yet" and one card offers the same two choices. This moves the city search from milestone 10 up
  to here.
- Q: The stacked layouts above text scale 1.4 aren't drawn. → A: In the next-prayer card the
  countdown goes under the prayer name, aligned to the start. The strip becomes five full-width
  rows: name at the start, time at the end, then the check or dot, the current prayer still
  highlighted.
- Q: Stars in a daytime sky? → A: In the live sky, stars show only in the Fajr, Maghrib and Isha
  states and fade with the sky change. The design scenario keeps the mockup's sky with its stars.
- Q: What does the strip show between midnight and Fajr? → A: The prayer day as milestone 4
  defines it, Fajr to the next Fajr: last night's prayers and marks with Isha highlighted, until
  Fajr. The date line still changes at midnight.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Where am I in the day (Priority: P1)

I open the app and see which prayer time it is now, which prayer is next and exactly how long
until it, ticking every second, with today's five times and the ones I already prayed.

**Why this priority**: This is why the app gets opened many times a day. Everything else on Home
is a shortcut.

**Independent Test**: Run "Dev · design scenario": Home shows the 4.01 values in dark, light and
Arabic, with the countdown at 1:24:00. The scenario's clock stands still, so the tick is checked in a normal dev run.

**Acceptance Scenarios**:

1. **Given** 16:32 in Makkah on the scenario day, **When** Home opens, **Then** it shows NOW Asr,
   "Until Maghrib at 17:56", next prayer Maghrib with 1:24:00 left, the bar at 44% and Asr
   highlighted in the strip.
2. **Given** Home is open, **When** a second passes, **Then** the countdown drops by one and only
   the digits that changed slide.
3. **Given** Home is open at 17:55:59, **When** Maghrib comes, **Then** NOW becomes Maghrib, the
   next prayer becomes Isha, the bar starts over, the highlight moves to Maghrib and the sky
   changes to the Maghrib state.
4. **Given** a time between sunrise and Dhuhr, **When** Home shows, **Then** NOW is Duha and the
   next prayer is Dhuhr.
5. **Given** a time after Isha, **When** Home shows, **Then** NOW is Isha and the next prayer is
   tomorrow's Fajr with the time left to it.
6. **Given** the app in Arabic, **When** Home shows, **Then** the layout is mirrored, digits are
   Eastern Arabic unless the user picked western, and the arc, clock times, countdown and bar are
   not mirrored.

---

### User Story 2 - The sky follows the real sun (Priority: P1)

The header is a sky that matches the time of day where I am. Its colors follow the prayer periods,
the sun sits on the arc where it really is between sunrise and Maghrib, and it changes softly when
a prayer time comes.

**Why this priority**: The Living Sky is the signature of the app, and the first thing seen on
every open.

**Independent Test**: Set the clock to a time in each of the six periods. The sky shows the
matching state, and the sun sits at the share of the day passed between sunrise and Maghrib.

**Acceptance Scenarios**:

1. **Given** a time between sunrise and Maghrib, **When** Home shows, **Then** the sun sits on the
   arc at the share of time passed between sunrise and Maghrib, and the arc is solid up to the
   sun.
2. **Given** a time before sunrise or after Maghrib, **When** Home shows, **Then** no sun shows,
   the arc is dotted only, and Isha and Fajr sit under it in place of sunrise and Maghrib.
3. **Given** Home is visible, **When** a prayer time passes, **Then** the sky moves to the next
   state over 1.8 s, or a 0.3 s crossfade with reduce motion.
4. **Given** Home is visible and reduce motion is off, **When** time passes, **Then** the sky
   drifts, the stars twinkle and the sun pulses. With reduce motion on, all of it stays still in
   the current state.
5. **Given** light mode, **When** Home shows, **Then** the sky keeps its own palette and the text
   on it keeps the same contrast as in dark mode.
6. **Given** the live sky in the sunrise, Dhuhr or Asr state, **When** Home shows, **Then** no
   stars show.

---

### User Story 3 - One tap to what I need (Priority: P2)

From Home I get to the prayers, the Quran and the azkar in one tap, and I see the verse of the
day.

**Why this priority**: Home is the hub. The targets themselves are built in later milestones, so
for now the taps only need to land on the right tab.

**Independent Test**: Tap every card and row on Home and check where each one lands.

**Acceptance Scenarios**:

1. **Given** Home, **When** I tap the next-prayer card or a strip cell, **Then** the Prayer tab
   opens.
2. **Given** Home, **When** I tap the verse card or Continue reading, **Then** the Quran tab
   opens.
3. **Given** Home in English, **When** I tap the azkar row, **Then** the Azkar tab opens.
4. **Given** a time from Fajr until Asr, **When** Home shows in English, **Then** the row reads
   "Morning azkar · After Fajr". From Asr until the next Fajr it reads "Evening azkar · After
   Asr".
5. **Given** Home in Arabic, **When** it shows, **Then** there is one shortcut row only, Continue
   reading, as in 4.16.

---

### User Story 4 - Set or change my location from Home (Priority: P2)

I tap the place name and switch to my current location or search for a city, offline. If the app
has no location yet, Home says so and offers the same two choices instead of times.

**Why this priority**: Without it there is no way to pick a city in the app before onboarding
(milestone 10), and a user who denied location sees nothing useful.

**Independent Test**: Deny location, open Home: no times, "No location yet", a card with both
choices. In airplane mode search "Tanta", pick it, Home shows Tanta's times.

**Acceptance Scenarios**:

1. **Given** a saved location, **When** I tap the location pill, **Then** a sheet opens with "Use
   my location" and a city search.
2. **Given** the sheet, **When** I pick a city, **Then** the location becomes manual, the sheet
   closes, and Home shows that city's name, times and sky.
3. **Given** the sheet, **When** I tap "Use my location" and location is allowed, **Then** the
   location goes back to auto and Home updates.
4. **Given** the sheet, **When** I tap "Use my location" and location is denied or off, **Then**
   the sheet says so and the city search stays open. The saved location doesn't change.
5. **Given** no location, **When** Home shows, **Then** it has the sky with no sun and no arc
   labels, the pill reads "No location yet", the date line, a card with the two choices in place
   of the next-prayer card, and no NOW block and no strip. The verse and the shortcuts still
   show.

---

### User Story 5 - Readable for everyone (Priority: P3)

Home works with large text, a 12-hour clock, a screen reader and reduce motion.

**Why this priority**: Required by the constitution for every screen. It doesn't change what Home
shows, only how it fits.

**Independent Test**: Go through Home at text scale 1.0, 1.5 and 2.0, on a 12-hour phone, with a
screen reader and with reduce motion on.

**Acceptance Scenarios**:

1. **Given** text scale above 1.4, **When** Home shows, **Then** the countdown sits under the
   prayer name and the strip is five full-width rows.
2. **Given** text scale 2.0, **When** Home shows, **Then** nothing is clipped or overlapping and
   Home scrolls.
3. **Given** a 12-hour phone, **When** Home shows, **Then** times like "5:56 PM" fit everywhere at
   text scale 1.0 and 2.0.
4. **Given** a screen reader, **When** the countdown is focused, **Then** it reads the next prayer
   and the hours and minutes left, and it isn't announced on every tick.

---

### Edge Cases

- Midnight with Home open: the date and the Hijri date change. The strip keeps the prayer day,
  so last night's prayers and marks stay until Fajr.
- Between midnight and Fajr: NOW is Isha, the Isha cell is highlighted, the bar runs from last
  night's Isha to today's Fajr, and the labels under the arc are that Isha and that Fajr.
- At Fajr the strip moves to the new prayer day and its marks start empty.
- During Duha no strip cell is highlighted, and the bar runs from sunrise to Dhuhr.
- A polar day with a time that isn't available: that cell shows a dash and the next prayer is the
  next one that has a time. Without sunrise or Maghrib the arc has no sun and no labels.
- The phone's clock or time zone changes while Home is open: the times and the countdown follow at
  once.
- The app comes back from the background: the countdown is right at once, it never carries on from
  where it stopped.
- Home hidden (another tab, app in the background, Low Power Mode or Battery Saver): the ambient
  animation pauses, and comes back with a 0.3 s fade.
- Long nights where the time left is 10 hours or more: two-digit hours fit.
- A manual city in another time zone than the phone: NOW, the times, the date and the countdown
  all use the city's local time.
- Tablets and foldables: the phone layout stretched to at most 480 pt.

## Requirements *(mandatory)*

### Functional Requirements

**Screen**

- **FR-001**: Home MUST match 4.01 (dark), 4.02 (light) and 4.16 (Arabic) as the handoff gives
  them, with the live values below in place of the mockup's.
- **FR-002**: The temporary dev readout from milestone 2 MUST be removed.

**Live values**

- **FR-003**: The NOW block MUST show the current period (Fajr, Duha, Dhuhr, Asr, Maghrib, Isha),
  its Arabic name beside it in English, and "Until {next prayer} at {time}".
- **FR-004**: The next-prayer card MUST show the next prayer, the time left as h:mm:ss ticking in
  step with the clock's seconds, a bar for the time passed since the current period started out of
  the whole time until the next prayer, and the adhan line with the next prayer's time and the
  reminder minutes.
- **FR-005**: The strip MUST show the five times of the prayer day (Fajr to the next Fajr), a
  check on each logged prayer, and the current prayer highlighted, with a dot while it isn't
  logged.
- **FR-006**: The header MUST show the place name, the date line with the Hijri date after the
  user's adjustment (English: weekday, day, month, Hijri date; Arabic: weekday and Hijri date, as
  4.16), and the sunrise and Maghrib times under the arc, or Isha and Fajr from Maghrib until
  sunrise.
- **FR-007**: Without leaving Home, the screen MUST update every second (countdown), at every
  prayer time (NOW, next prayer, bar, highlight, sky), at midnight (date line), at Fajr (strip
  and marks), and
  whenever the location, method, Asr, Hijri adjustment or digits change.

**Living Sky**

- **FR-008**: The sky MUST follow the current period through the six states and change at each
  prayer time with the sky change (1.8 s, a 0.3 s crossfade with reduce motion).
- **FR-009**: The sun MUST sit at its real share of the day between sunrise and Maghrib, and not
  show outside it. The arc and the sun are never mirrored in Arabic, the arc sits on the side away
  from the text.
- **FR-010**: In the live sky, stars MUST show only in the Fajr, Maghrib and Isha states and fade
  in and out with the sky change.
- **FR-011**: The ambient loop (sky drift, twinkle, sun pulse) MUST follow MOTION.md and run only
  while Home is visible, the app is in front and the phone is not in Low Power Mode or Battery
  Saver. With reduce motion it is still in the current state.
- **FR-012**: Every text on the sky MUST meet WCAG AA in every sky state, in both modes.
- **FR-013**: The design scenario MUST show the theme's base sky, as the mockups do. Every other run uses the live sky.

**Glow and countdown**

- **FR-014**: Only the next-prayer card glows. The glow MUST be there and still at all times, as
  in the PNG, and breathe (3 s each way) in the final 10 minutes before the next prayer. With
  reduce motion it stays still.
- **FR-015**: Each digit of the countdown that changes MUST slide in 300 ms. With reduce motion
  the digits swap at once.

**Content from later milestones**

- **FR-016**: Until their milestone, Home MUST show the handoff's sample content: reminder 10 min
  before (5), verse of the day Al-Fatiha 1:5 (7), Continue reading Al-Fatiha · ayah 3 of 7 (7),
  azkar 0 of 24 (8). Each one is marked so its milestone replaces it.
- **FR-017**: Outside the design scenario no prayer shows as logged until milestone 4. The design
  scenario MUST show Fajr and Dhuhr logged.
- **FR-018**: The azkar row MUST read "Morning azkar · After Fajr" from Fajr until Asr and
  "Evening azkar · After Asr" from Asr until the next Fajr. Arabic has no azkar row, as in 4.16.

**Navigation**

- **FR-019**: The next-prayer card and every strip cell MUST open the Prayer tab, the verse card
  and Continue reading the Quran tab, the azkar row the Azkar tab, the location pill the location
  sheet. Scrolling to a prayer comes with milestone 4, the reader at an ayah or the last position
  with milestone 7.
- **FR-020**: Every tap target MUST be at least 44 x 44.

**Location sheet and no location**

- **FR-021**: The location sheet MUST have "Use my location" and a search field with results while
  typing, in English or Arabic, offline, each result with its region and country. It opens and
  closes with the bottom sheet motion (MOTION 15).
- **FR-022**: Picking a result MUST make the location manual, close the sheet and update Home.
- **FR-023**: "Use my location" MUST ask for "while using" permission when needed. Allowed: the
  location goes back to auto. Denied or off: the sheet says so and the saved location stays.
- **FR-024**: Without a location, Home MUST show the sky with no sun and no arc labels, the pill
  "No location yet", the date line, a card with the sheet's two choices in place of the
  next-prayer card, no NOW block and no strip. The verse and the shortcuts stay.

**Sizes, languages, accessibility**

- **FR-025**: Above text scale 1.4 the next-prayer card and the strip MUST use the stacked layouts
  from the clarifications. Text scale stops at 2.0, and Home scrolls when it is taller than the
  screen.
- **FR-026**: Times MUST follow the phone's 12 or 24 hour setting and fit everywhere at text scale
  1.0 and 2.0.
- **FR-027**: In Arabic the layout MUST be mirrored with Eastern Arabic digits unless the user
  picked western. The arc, clock times, countdown and bar are not mirrored.
- **FR-028**: A screen reader MUST read the countdown as the next prayer and the hours and minutes
  left, without announcing every tick.
- **FR-029**: On tablets and foldables Home MUST use the phone layout stretched to at most 480 pt.

### Key Entities

- **Home state**: the current period, the next prayer and its time, the time left, the bar's
  share, today's six times, the logged prayers (none until milestone 4), the place name, the date
  and the Hijri date, and whether there is a location at all.
- **Sky state**: one of six states with its colors, whether stars show, and where the sun is, if
  it shows.
- **Location choice**: auto (the current position) or a place from the list (manual), as in
  milestone 2.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In the design scenario, Home is built from the 4.01, 4.02 and 4.16 trees and shows
  their values (NOW Asr, Maghrib in 1:24:00) in dark, light and Arabic.
- **SC-002**: After Home has been open for an hour, the time left it shows equals the real time
  left, to the second.
- **SC-003**: When a prayer time comes, Home shows the next prayer within 1 second without leaving
  the screen.
- **SC-004**: With a saved location, Home shows the times within 1 second of the app opening.
- **SC-005**: In all 16 mixes of dark or light, English or Arabic, text scale 1.0 or 2.0 and reduce
  motion on or off, plus a 12-hour phone, no text on Home is clipped, cut or overlapping.
- **SC-006**: Every text on the sky meets WCAG AA contrast in all six sky states, in both modes.
- **SC-007**: Home scrolls and animates with no visible stutter on a mid-range phone, and the sky
  animation does no work while Home is hidden or the app is in the background.
- **SC-008**: In airplane mode, picking a city in the sheet updates Home in under 1 second.

## Assumptions

- The handoff's layout trees, copy and motion are the source of truth. This spec doesn't repeat
  them.
- Only Qiyam Emerald exists until the theme picker in milestone 9. Until then light and dark
  follow the phone, the stored "follow sky" mode is applied in milestone 9.
- The adhan screen (4.03) at prayer time comes in milestone 5. In this milestone Home only moves to
  the next prayer.
- The status bar sits on the sky with light icons in every state, the top of every sky state is
  dark.
- The location sheet and the no-location card are built from existing parts and existing copy
  where it fits ("Use my location", "No location yet"). The few new lines go into both languages.
  Nothing new is designed.
- How the verse of the day is picked comes with the Quran data in milestone 7.
- No haptics on Home besides the sheet detent, as in the MOTION.md haptics table.
- Low Power Mode and Battery Saver are read when Home's sky starts and when the app comes back to
  the front. Switching one on while Home stays open takes effect the next time either happens.
- Constitution 2.2.0: every milestone gets a speckit spec, short where the handoff specs the screen.
