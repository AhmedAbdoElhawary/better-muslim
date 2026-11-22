# Feature Specification: Milestone 2, Data

**Feature Branch**: `feature/milestone-2`

**Created**: 2026-10-16

**Status**: Draft

**Input**: User description: "milestone 2. Extra requirements: offline-first app using drift for storage and flutter_secure_storage for sensitive data; no paid APIs, everything free as much as possible; discuss with me what will be used for every service to make it a fully live app, not only UI."

Milestone 2 is the data every later screen stands on: where the user is, the prayer times for that
place, the Hijri date, and the settings, all kept on the phone. It works with no internet and costs
nothing to run. Screens come in later milestones, this one ends with tests and a temporary readout
in dev builds.

## Clarifications

### Session 2026-10-16

- Q: Where do place names and the city search come from? → A: A list of places shipped inside the
  app (every country, places over 1,000 people plus capitals and region seats, about 130k), so
  search and naming work offline. No online geocoder.
- Q: What counts as sensitive and how is it kept? → A: The whole local store is encrypted. Its key
  is made on the phone on first launch and kept in the phone's secure store. The data does not go
  into the phone's cloud backup, a new phone gets it only from the app's own backup file.
- Q: Which calculation method outside Saudi Arabia? → A: The method of the country the location
  is in, so the times match the local mosques. The user can still change it.
- Q: How does the app notice that the user travelled more than 30 km? → A: It checks the position
  when the app opens or comes back to the front (and later when the background top-up runs). Only
  "while using" location permission, no background tracking.
- Q: How is milestone 2 checked when it has no designed screen? → A: Unit tests, plus a temporary
  readout on the Home placeholder in dev builds only, replaced by the real Home in milestone 3.
- Q: How is the design scenario switched on? → A: A separate dev run entry, "Dev · design
  scenario", with the clock frozen at Thu 15 Oct 2026 16:32 Makkah.
- Q: Constitution? → A: Amended to 2.1.0 for offline-first and free, the place list, the encrypted
  store and speckit for this milestone.
- Q: Branch? → A: `feature/milestone-2` from `feature/shipping-setup`, so its two unmerged commits
  go in with this milestone.
- Q: Between Fajr and Dhuhr, what is "now" and what is "next"? → A: "Now" is Fajr until sunrise,
  then Duha until Dhuhr. "Next" is always one of the five prayers, so after Fajr it is Dhuhr.
- Q: Can each prayer time be shifted by a few minutes to match a local mosque? → A: Not in this
  milestone. If wanted it comes with the method sheet in milestone 4.
- Q: Is the high latitude rule automatic or a setting? → A: Always automatic by latitude, nothing
  stored.
- Q: 12 or 24 hour times? → A: Follow the phone's 12/24 hour setting, nothing stored.
- Q: What happens when the saved data can't be opened? → A: Start fresh, report it without
  personal data, and remember it happened, so the app tells the user once and offers "Restore from
  backup" (that screen comes in milestone 10).
- Q: Real calculation gives Fajr 05:00, Sunrise 06:16, Dhuhr 12:06 for the scenario day, the
  handoff shows 04:58, 06:15, 12:05. Which does the design scenario show? → A: The handoff's six
  times as fixed values, since the scenario only exists for the PNG checks. Real calculation
  everywhere else.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Prayer times for where I am (Priority: P1)

I allow location once, and the app knows where I am, names the place, picks the method my local
mosques use and gives me today's five prayers and sunrise, plus which prayer is next and how long
until it. It works in airplane mode.

**Why this priority**: Prayer times are the reason the app exists. Every other screen (Home,
Prayer, notifications, widgets) reads them.

**Independent Test**: Grant location on a phone with internet off, open the dev readout, compare the
six times with the official timetable of that country for that day.

**Acceptance Scenarios**:

1. **Given** no location is saved and the user allows location, **When** the position is found,
   **Then** the place, its country, the method for that country and today's six times are saved
   and shown, without internet.
2. **Given** a saved location, **When** the app starts, **Then** times for the saved location show
   at once, without waiting for a new position.
3. **Given** the time is after Isha, **When** the next prayer is asked for, **Then** it is
   tomorrow's Fajr with the right time left.
4. **Given** the location is in Pakistan, **When** times are computed, **Then** the Karachi method
   and the Hanafi Asr are used.
5. **Given** the user picked a method by hand, **When** the location moves to another country,
   **Then** the user's method stays.

---

### User Story 2 - Choose a city instead (Priority: P1)

I don't want to share my location, so I search my city by name, in English or Arabic, and the
times use that city, in that city's own time zone. GPS never overrides my choice.

**Why this priority**: The design makes choosing a city an equal option to GPS, not a fallback.
People who refuse location still need correct times.

**Independent Test**: With location permission denied and internet off, search "Tanta" and
"طنطا", pick it, check the times against the Egyptian timetable.

**Acceptance Scenarios**:

1. **Given** the user types part of a place name in English or Arabic, **When** results are
   asked for, **Then** matching places appear, biggest first, each with its region and country
   so places with the same name can be told apart.
2. **Given** Arabic input with or without diacritics or different alef and hamza forms,
   **When** searching, **Then** the same places are found.
3. **Given** the user picks a city in another time zone than the phone's, **When** times are
   computed, **Then** they are in the city's local time.
4. **Given** a chosen city, **When** the app opens elsewhere with location allowed, **Then** the
   location stays the chosen city.

---

### User Story 3 - My settings stay on this phone, protected (Priority: P2)

What I set (location, method, Asr, Hijri adjustment, theme, light and dark, reduce motion,
haptics, UI sounds, digits) is still there after I close the app or update it, and nobody can read
it by copying the app's files.

**Why this priority**: Without saved settings every launch starts over. The privacy promise on the
location screen ("Stays on this phone, never sent to us or anyone else") has to be true.

**Independent Test**: Change every setting, kill the app, reopen, all values are back. Copy the
store file off a debug build, it can't be opened without the key.

**Acceptance Scenarios**:

1. **Given** changed settings, **When** the app restarts or updates to a version with a newer
   store layout, **Then** every value is kept.
2. **Given** the store file copied off the phone, **When** someone opens it without the key,
   **Then** nothing in it is readable.
3. **Given** the key is gone or the store can't be opened, **When** the app starts, **Then** it
   starts fresh with default settings instead of crashing, and the error is reported without any
   personal data.

---

### User Story 4 - The Hijri date (Priority: P2)

I see today's Hijri date from the Umm al-Qura calendar, and I can shift it by up to two days either
way to match the moon sighting where I live.

**Why this priority**: Home, the Hijri calendar and the widgets show it, and months like Ramadan
start on different days in different countries.

**Independent Test**: For 15 Oct 2026 the date is 4 Jumada I 1448. With +1 it is 5 Jumada I 1448,
in English and Arabic.

**Acceptance Scenarios**:

1. **Given** no adjustment, **When** the Hijri date for a day is asked for, **Then** it is the Umm
   al-Qura date, with month names in English and Arabic.
2. **Given** an adjustment of -2 to +2, **When** the date is asked for, **Then** it is shifted by
   that many days and the adjustment is saved.

---

### User Story 5 - Times follow me when I travel (Priority: P3)

When I travel more than 30 km with location on auto, the place and times update by themselves the
next time I open the app.

**Why this priority**: Travellers would otherwise pray by the times of the city they left. It only
matters for auto location.

**Independent Test**: Save a position, open the app with a mocked position 31 km away, the place
and times change. 29 km away, nothing changes.

**Acceptance Scenarios**:

1. **Given** auto location, **When** the app opens or comes back to the front 30 km or more
   from the saved position, **Then** the place, the method (unless the user picked one) and the
   times update.
2. **Given** auto location, **When** the new position is under 30 km away, **Then** nothing
   changes.
3. **Given** the day changes while the app is open, **When** midnight passes, **Then** the times
   switch to the new day.

---

### User Story 6 - Design scenario for checking screens (Priority: P3)

As the developer, I run "Dev · design scenario" and the app acts as if it is Thursday 15 Oct 2026
at 16:32 in Makkah, so every screen can be put next to its PNG.

**Why this priority**: Every later milestone is checked against the PNGs within 1 pt, which needs
the same moment the designer used.

**Independent Test**: Run the scenario entry, the readout shows the handoff's six times, Maghrib
next in 1:24:00 and 4 Jumada I 1448, and the time doesn't move.

**Acceptance Scenarios**:

1. **Given** the scenario run entry, **When** the app starts, **Then** the clock is frozen at
   Thu 15 Oct 2026 16:32 Makkah time, the location is Makkah with Umm al-Qura, and no location
   permission is asked.
2. **Given** a normal dev, staging or production build, **When** the app starts, **Then** the
   scenario can't be switched on.

---

### Edge Cases

- Location permission denied, denied forever, or GPS off: the last saved location stays. With
  nothing saved, the app has no location and says so, it never makes one up, since wrong prayer
  times are worse than none.
- No position within a reasonable time (indoors, weak signal): the saved location stays, no error
  for the user.
- A position far from any listed place (sea, desert): the nearest listed place names it, the times
  still use the exact position.
- Places with the same name in different countries or regions: results show region and country.
- Daylight saving switch days: times are right on both sides of the change.
- Crossing a time zone in auto mode: times follow the phone's time zone.
- The user changes the phone's clock or time zone by hand: times recompute for the new zone.
- High latitudes (UK, Nordics in summer) where the sky doesn't get dark enough for Fajr or Isha:
  a high latitude rule still gives both a time.
- Above the polar circle on days with no sunrise or sunset: the affected times show as not
  available for that day.
- Ramadan with Umm al-Qura: Isha is 120 minutes after Maghrib instead of 90.
- A Hijri adjustment outside -2 to +2 is never stored.
- Dates outside the Umm al-Qura table: not needed, the table covers far beyond the app's life.

## Requirements *(mandatory)*

### Functional Requirements

**Location**

- **FR-001**: The app MUST ask for location only "while using", never "always". In this milestone
  the system dialog shows directly when no location is saved; the primer screen (4.11) comes in
  milestone 10.
- **FR-002**: The app MUST find the current position without internet.
- **FR-003**: The app MUST name a position with the nearest place in its place list, in the app's
  language (Arabic name when the list has one, otherwise the Latin name).
- **FR-004**: The place list MUST cover every country: all places over 1,000 people plus capitals
  and region seats, each with English and Arabic names where they exist, region, country,
  coordinates, population and time zone.
- **FR-005**: The user MUST be able to search the place list offline by part of a name in English
  or Arabic, ignoring case, Arabic diacritics and alef, hamza, taa marbuta and alef maqsura forms,
  biggest places first.
- **FR-006**: The user MUST be able to choose a place by hand. The location is then manual: times
  use the place's coordinates and time zone, and GPS never replaces it until the user switches
  back to auto.
- **FR-007**: On start the app MUST use the saved location at once and refresh the position after,
  so times never wait for GPS.
- **FR-008**: With auto location, when the app opens or comes back to the front and the position
  is 30 km or more from the saved one, the app MUST update the place, the method (unless the user
  picked one) and the times. Under 30 km nothing changes.

**Prayer times**

- **FR-009**: The app MUST compute Fajr, Sunrise, Dhuhr, Asr, Maghrib and Isha for any date and
  location on the phone, without internet.
- **FR-010**: The method MUST follow the location's country unless the user picked one:

  | Country | Method |
  | --- | --- |
  | Saudi Arabia | Umm al-Qura |
  | Egypt | Egyptian General Authority of Survey |
  | United Arab Emirates | Dubai |
  | Qatar | Qatar |
  | Kuwait | Kuwait |
  | Turkey | Diyanet |
  | Singapore, Malaysia, Indonesia | Singapore |
  | Pakistan, India, Bangladesh | University of Islamic Sciences, Karachi |
  | Iran | Tehran |
  | United States, Canada | ISNA |
  | everywhere else | Muslim World League |

- **FR-011**: Asr MUST default to Hanafi in Pakistan, India and Bangladesh, and to the majority
  opinion everywhere else, unless the user picked one.
- **FR-012**: A method or Asr picked by the user MUST stay when the location changes, until the
  user changes it again.
- **FR-013**: Where the sky doesn't get dark enough, a high latitude rule MUST be picked by
  latitude and applied by itself so Fajr and Isha always have a time. It is not a setting.
- **FR-014**: With Umm al-Qura, Isha MUST be 90 minutes after Maghrib, and 120 minutes during
  Ramadan.
- **FR-015**: The app MUST give the next prayer and the time left until it, counting only the five
  prayers (sunrise is a time, not a prayer). After Fajr the next prayer is Dhuhr, after Isha it is
  tomorrow's Fajr.
- **FR-015a**: The app MUST give the current period: Fajr from Fajr to sunrise, Duha from sunrise
  to Dhuhr, then Dhuhr, Asr, Maghrib, and Isha until the next Fajr.
- **FR-016**: Times MUST be in the location's local time: the phone's time zone for auto, the
  place's time zone for manual, with daylight saving handled.
- **FR-017**: Times MUST recompute when the date changes (midnight), the location changes, the
  method or Asr changes, or the phone's time zone changes.
- **FR-017a**: Times MUST show in the phone's 12 or 24 hour format. The app stores no format
  setting.

**Hijri date**

- **FR-018**: The app MUST give the Hijri date for any day from the Umm al-Qura calendar, plus the
  user's adjustment (-2 to +2 days, default 0), with month names in English and Arabic.
- **FR-019**: The Hijri day MUST change at midnight, together with the Gregorian day.

**Settings and storage**

- **FR-020**: The app MUST keep these settings on the phone, with these defaults:

  | Setting | Default |
  | --- | --- |
  | location (position, place, region, country, time zone, auto or manual) | none |
  | method, and whether the user picked it | by country |
  | Asr, and whether the user picked it | by country |
  | Hijri adjustment | 0 |
  | Arabic digits (eastern or western) | eastern |
  | theme | Qiyam Emerald |
  | light and dark (dark, light, follow sky) | follow sky |
  | reduce motion | off |
  | haptics | on |
  | UI sounds | off |

- **FR-021**: All stored data MUST be encrypted. The key MUST be made on the phone on first launch
  and kept only in the phone's secure store.
- **FR-022**: Stored data MUST survive restarts and app updates, including updates that change the
  store layout.
- **FR-023**: Stored data MUST NOT go into the phone's cloud backup.
- **FR-024**: If the store can't be opened (lost key, broken file), the app MUST start fresh with
  defaults, report the error without any personal data, and remember that it happened until the
  user has been told once and offered "Restore from backup" (the screen comes in milestone 10).
- **FR-025**: This milestone MUST NOT use the network. Crash reports MUST never contain the
  location.

**Checking it**

- **FR-026**: Dev builds MUST have a "Dev · design scenario" run entry that freezes the clock at
  Thu 15 Oct 2026 16:32 Makkah time with the location set to Makkah and Umm al-Qura, asking no
  permission, and shows the handoff's six times as fixed values. Staging and production builds
  MUST NOT have it.
- **FR-027**: In dev builds only, the Home placeholder MUST show a temporary readout: place and
  auto or manual, method, Asr, today's six times, the next prayer with the time left ticking, and
  the Hijri date, in English and Arabic. It follows the design system rules and is removed when
  milestone 3 builds Home.

### Key Entities

- **Place**: one entry of the place list. Names in English and Arabic, region, country,
  coordinates, population, time zone.
- **Location**: where times are computed for. Position, the place that names it, time zone, auto
  or manual.
- **Prayer settings**: method and Asr, each with whether the user picked it, the Hijri
  adjustment.
- **Day times**: the six times for one date at one location, the current period and which prayer
  is next.
- **Hijri date**: day, month, year for a Gregorian date after the adjustment.
- **App settings**: digits, theme, light and dark, reduce motion, haptics, UI sounds, and whether
  a store reset still has to be told to the user.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The design scenario gives exactly Fajr 04:58, Sunrise 06:15, Dhuhr 12:05, Asr 15:27,
  Maghrib 17:56, Isha 19:26, Maghrib next in 1:24:00, and 4 Jumada I 1448. Any difference from
  the handoff is found and explained before the milestone is done.
- **SC-002**: For Makkah, Cairo, Karachi, Istanbul, Jakarta, Dubai, London, New York and Oslo,
  the times are within 1 minute of an independent calculator using the same method for the same
  dates, and within 1 minute of the official timetable where the country publishes one (Saudi
  Arabia, Turkey). Any gap is written down with its reason.
- **SC-003**: Prayer times, the Hijri date, place naming and place search all work in airplane
  mode.
- **SC-004**: Search results appear while typing with no noticeable delay (under 100 ms per key) on
  a mid-range phone.
- **SC-005**: With a saved location, times are ready within 1 second of the app starting.
- **SC-006**: Every setting survives a restart and an update to a newer store layout.
- **SC-007**: A copy of the store file taken off the phone can't be read without the key.
- **SC-008**: The place list adds no more than 10 MB to the installed app.

## Assumptions

- No account, no backend and no network in this milestone. Recitation audio, the only planned
  download, comes in milestone 7.
- The location primer (4.11) and the city search list come in milestone 10, the method sheet with
  Prayer (milestone 4) and More (milestone 9). The handoff names a "searchable city list" but has
  no design for it, that needs a decision in milestone 10.
- Notification choices come in milestone 5, the prayer log and qada in 4, Quran and tasbih data in
  their own milestones. Each adds its own data to the same encrypted store.
- Language follows the phone. The More screen has no language row.
- No per-prayer minute shifts in this milestone. If wanted they come with the method sheet in
  milestone 4.
- The design is all 24 hour. Every screen from milestone 3 on has to fit "5:56 PM" as well as
  "17:56", the PNG check uses a 24 hour phone.
- GPS times are exact anywhere. The place list only names the position and powers the search, so a
  village missing from it still gets exact times by GPS, or picks a town near it by hand (within
  about 30 km the times differ by about a minute).
- Moving to a new phone keeps data only through the app's own backup file (milestone 10).
- The place list is built once from GeoNames (CC BY 4.0). The app has to credit GeoNames, the
  credit line goes into More in milestone 9.
- When the Umm al-Qura table and the mockup disagree on a date, the table wins and the mismatch is
  reported. The handoff already asks to check 1 Jumada I 1448 = 12 Oct 2026.
