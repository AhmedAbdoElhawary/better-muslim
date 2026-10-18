# Feature Specification: Milestone 9, More, Theme and Hijri Calendar

**Feature Branch**: `feature/milestone-9` (made when the build starts, after milestones 3 to 8 are
merged) [NEEDS CLARIFICATION: Q1, order and branch]

**Created**: 2026-10-17

**Status**: Draft

**Input**: User description: "milstone 9"

Milestone 9 is the More tab (4.09), the theme picker (4.15) and the Hijri calendar (4.13). More is
where every setting lives, with no account: the method, the adhan and reminders, the location, the
theme, light and dark, reduce motion, haptics and UI sounds, plus the tiles to Qibla, the Hijri
calendar and Duas. The three screens are built straight from the handoff specs. This spec covers
what the handoff doesn't: what each setting changes across the app, what "Follow sky" means, the
pages and sheets More opens that have no PNG, which days the calendar marks, and the rows other
milestones already sent here (credits, downloaded recitations, the page turn haptic, Reset prayer
journey).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Change a setting from More (Priority: P1)

I open More, see what each setting is set to, and change it. Haptics bother me in the mosque, so I
turn them off. Reduce motion goes on for my father's phone. Every change works at once and stays.

**Why this priority**: The settings are stored since milestone 2, but nothing lets me change them.
More is the one place for them, and every other screen reads them.

**Independent Test**: In the design scenario, More matches 4.09. Turn Haptics off: marking a
prayer no longer vibrates. Turn Reduce motion on: Home's sky stops drifting. Restart: both stay.

**Acceptance Scenarios**:

1. **Given** the More tab, **When** it opens, **Then** each row shows the current value: the
   method's name, the reminder minutes, the place with auto or manual, the theme's name, the light
   and dark mode, and the toggles.
2. **Given** a toggle, **When** I flip it, **Then** it changes at once with the toggle haptic and is
   kept after a restart.
3. **Given** Reduce motion on, **When** any animation would play, **Then** its reduce motion
   fallback plays, the same as with the phone's own setting on.
4. **Given** Haptics off, **When** I mark a prayer, count tasbih or align the Qibla, **Then** the
   action works with no vibration.
5. **Given** a tile, **When** I tap Qibla, Hijri calendar or Duas, **Then** that screen is pushed.
6. **Given** the Calculation method row, **When** I tap it, **Then** the method sheet from the
   Prayer tab (milestone 4) opens, and a change shows on both screens.

---

### User Story 2 - Pick a theme (Priority: P1)

I open Theme, tap a few swatches and watch the preview change, try Light, then Apply. The whole app
changes to my theme. If I go back without Apply, nothing changes.

**Why this priority**: The 8 themes and both modes are built since milestone 1, but the app only
shows Qiyam Emerald until this page exists.

**Independent Test**: In the design scenario open Theme and tap Dark: it matches 4.15. Tap Iznik:
only the preview turns Iznik. Go back: the app is still Qiyam Emerald. Open again, tap Iznik, Apply:
the app crossfades to Iznik and More's Theme row says "Iznik".

**Acceptance Scenarios**:

1. **Given** the theme page, **When** it opens, **Then** the current theme and mode are selected and
   the preview shows them.
2. **Given** the page, **When** I tap a swatch or Dark, Light or Follow sky, **Then** only the
   preview restyles, at once, with the toggle haptic.
3. **Given** a picked theme and mode, **When** I tap Apply theme, **Then** both are saved, the whole
   app restyles with a 300 ms crossfade and I'm back on More.
4. **Given** a picked theme, **When** I go back without Apply, **Then** nothing is saved and nothing
   changes.

---

### User Story 3 - Light and dark follow the sky (Priority: P2)

I leave "Follow sky" on. After sunrise the app is light, at Maghrib it goes dark, without me
touching anything.

**Why this priority**: It is the default mode and the idea behind the app's look. Until now the
app followed the phone instead.

**Independent Test**: Freeze the clock one minute before Maghrib with Follow sky: light. Let it run
past Maghrib: the app crossfades to dark while open. One minute before sunrise next day: dark, then
light after it.

**Acceptance Scenarios**:

1. **Given** Follow sky, **When** the time is between sunrise and Maghrib at my location, **Then**
   the app is light, otherwise dark.
2. **Given** Follow sky and the app open, **When** sunrise or Maghrib comes, **Then** the app
   crossfades to the other mode in 300 ms.
3. **Given** Dark or Light, **When** sunrise or Maghrib comes, **Then** nothing changes.
4. **Given** the Light and dark row, **When** I tap it, **Then** I can pick Dark, Light or Follow sky
   and it applies at once.

---

### User Story 4 - The Hijri month at a glance (Priority: P2)

I open the Hijri calendar to see today's Hijri date, when the white days are, and when the next
month starts. I go forward to see when Ramadan begins.

**Why this priority**: Fasting days and the start of the months are what people look the Hijri
calendar up for, and the design gives it a tile on More.

**Independent Test**: In the design scenario the calendar matches 4.13: Jumada I 1448, 4 highlighted
on 15 Oct, dots on 13 to 15, three rows in COMING UP. Forward 4 times: Ramadan 1448, 1 Ramadan
marked. The calendar icon: back to Jumada I.

**Acceptance Scenarios**:

1. **Given** the calendar, **When** it opens, **Then** it shows the current Hijri month with today
   highlighted, the white days dotted and the next three things coming up.
2. **Given** a month, **When** I tap an arrow, **Then** the previous or next Hijri month shows, with
   the Gregorian months it spans under the name.
3. **Given** another month shown, **When** I tap the calendar icon, **Then** the current month
   shows again.
4. **Given** the app in Arabic, **When** the calendar opens, **Then** the week reads from Sunday on
   the right, arrows point the Arabic way, and digits follow the digits setting.

---

### User Story 5 - A day, and my local moon sighting (Priority: P2)

I tap a day to see its prayer times and what falls on it. In my country Jumada II started a day
after the table said, so I set the date adjustment to +1 and every Hijri date in the app moves.

**Why this priority**: The table is an estimate and countries start months on different days. The
adjustment is stored since milestone 2 but has no screen.

**Independent Test**: Tap 13 Jumada I: its sheet shows 24 Oct with its six times and Ayyam al-Bid.
Set +1 and Save: today reads 5 Jumada I on the calendar and on Home, the row says "+1 day".

**Acceptance Scenarios**:

1. **Given** the calendar, **When** I tap a day, **Then** it is selected and a sheet shows its Hijri
   and Gregorian date, its six times at my location and its events.
2. **Given** the Date adjustment row, **When** I tap it, **Then** a sheet lets me step from −2 to +2
   days and shows today's Hijri date as I step.
3. **Given** a new adjustment, **When** I Save, **Then** every Hijri date in the app moves by it at
   once: the calendar, Home, notifications and widgets.

---

### User Story 6 - Adhan and reminders (Priority: P2)

I want the Madinah adhan for Fajr, a tone for Dhuhr and the reminder 15 minutes before. I set it all
on one page and hear each adhan before I pick it.

**Why this priority**: Milestone 5 calls each prayer with stored choices, but the only place to
change them before this is onboarding (milestone 10). More's row leads here.

**Independent Test**: Open Adhan and reminders: Fajr and Maghrib on Adhan, the rest on Tone, reminder
10 min. Set Dhuhr to Silent, Fajr's recording to Madinah, the reminder to 15: More's row says "15 min
before" and the pending notifications change to match.

**Acceptance Scenarios**:

1. **Given** the page, **When** it opens, **Then** each prayer shows its time and its Adhan, Tone or
   Silent choice, and each prayer on Adhan shows its recording.
2. **Given** a prayer, **When** I change its choice, **Then** it is kept at once with the toggle
   haptic and the schedule is remade.
3. **Given** a prayer on Adhan, **When** I tap its recording, **Then** a sheet lists the six
   recordings, tapping one plays it, Save keeps it for that prayer.
4. **Given** the reminder row, **When** I tap it, **Then** I can pick off or 5 to 30 minutes.
5. **Given** notifications refused for the app, **When** I open the page, **Then** it says so and
   offers to open the phone's settings, and the choices still save.

---

### User Story 7 - My data and the credits (Priority: P3)

I want to start my prayer log over, free up space taken by recitations, and see where the app's
data comes from.

**Why this priority**: Milestones 4 and 7 left these to More, and the GeoNames license needs its
credit inside the app before release.

**Independent Test**: Tap Reset prayer journey, then Reset: the Prayer tab and Home show nothing
logged and no qada, every setting stays. Tap Downloaded recitations, Delete: the size reads "None".
Tap Credits: GeoNames and its license are listed.

**Acceptance Scenarios**:

1. **Given** Reset prayer journey, **When** I tap it, **Then** a dialog asks first, Cancel changes
   nothing, Reset clears the log and qada only.
2. **Given** downloaded recitations, **When** I tap the row and confirm, **Then** they are deleted
   and play again by downloading.
3. **Given** Credits, **When** I tap it, **Then** each source the app uses is listed with its
   license and a link.

---

### Edge Cases

- A Hijri month spread over six week rows: COMING UP and Date adjustment move down and the page
  scrolls, the grid never squeezes.
- A Hijri month across two Gregorian years: "December 2026 – January 2027".
- Changing the adjustment while the calendar is open: today's highlight, the white days, the marks
  and COMING UP move at once.
- An adjustment that moves 1 Ramadan: the Umm al-Qura Isha of 120 minutes in Ramadan (milestone 2)
  follows the adjusted date, the times and the notifications change with it.
- Midnight while the calendar is open: the highlight moves to the new today, the shown month stays.
- The first and last month of the Umm al-Qura table: the arrow past it is disabled.
- 13 Dhu al-Hijjah is a day of Tashreeq, when fasting isn't allowed, so it gets no white day dot.
  [NEEDS CLARIFICATION: Q6]
- Follow sky where the sun doesn't rise or set that day: dark all day without a sunrise, light all
  day without a Maghrib.
- Follow sky with no location yet: the app follows the phone's light and dark.
- Follow sky when the location changes: the switch moves to the new place's sunrise and Maghrib.
- Sunrise or Maghrib while the theme page is open: the app switches, the preview keeps what I
  picked there.
- Haptics off: the page turn haptic is off too, its toggle disabled until Haptics is on again.
- UI sounds on with the phone on silent, or while a recitation or the adhan plays: no UI sound.
- A recording preview playing when a prayer's adhan starts: the preview stops, the adhan plays.
- Reset prayer journey while a toast with Undo shows on the Prayer tab: that Undo is dropped.
- Deleting recitations while one plays: the playback stops first.
- Text scale 2.0: a long value ("Egyptian General Authority") goes under its row's title, nothing
  is cut, swatch names wrap.
- 12 hour phones: the times on the Adhan and reminders page and in the day sheet fit "5:56 PM".
- Arabic counts: the date adjustment and the reminder minutes use the right plural forms.

## Requirements *(mandatory)*

### Functional Requirements

**The More tab**

- **FR-001**: The More tab MUST match 4.09 as specified in the handoff: title, "Stored on this
  device · no account needed", the three tiles, PRAYER, APPEARANCE and SOUND AND TOUCH, in dark and
  light. Arabic has no PNG, it follows the same tree with the RTL rules. The large title collapses
  into the compact bar on scroll.
- **FR-002**: The tiles MUST push Qibla (milestone 6), the Hijri calendar and Duas (milestone 8).
- **FR-003**: Each row MUST show its current value and update the moment it changes:

  | Row | Value | Tap |
  | --- | --- | --- |
  | Calculation method | the method's name | the method sheet from milestone 4 |
  | Adhan and reminders | "{minutes} min before", or "Off" | the Adhan and reminders page |
  | Location | "{city} · auto", "{city} · manual" or "No location yet" | nothing until milestone 10 |
  | Theme | the theme's name | the theme page |
  | Light and dark | Dark, Light or Follow sky | the light and dark sheet (FR-016) |

- **FR-004**: The Location row MUST stay as designed and do nothing until milestone 10 builds the
  location sheet and city search. A `TODO:` marks it.
- **FR-005**: Every toggle MUST change at once with the toggle haptic, and be kept on the phone.
- **FR-006**: Reduce motion on MUST give every animation its reduce motion fallback (MOTION.md). The
  app's toggle and the phone's setting each do it alone.
- **FR-007**: Haptics off MUST stop every haptic the app makes. Haptics on still follows the phone's
  own vibration settings.
- **FR-008**: UI sounds on MUST play the Brand board's sounds with their events: Bead on each tasbih
  count, Complete on set complete and day complete, Aligned on Qibla aligned, Page on a page turn.
  They are off by default, never play over a recitation or the adhan, and stay quiet with the phone
  on silent. Until I supply the files they are placeholders with a `TODO(ahmed)`.

**Theme page**

- **FR-009**: The theme page MUST match 4.15: compact bar, live preview, Dark, Light and Follow sky,
  the 8 swatches in the 4.15 order, the Follow sky note and Apply theme.
- **FR-010**: It MUST open with the saved theme and mode selected. A swatch or a mode tap MUST
  restyle only the preview, at once, with the toggle haptic.
- **FR-011**: The preview MUST be the Home snippet (sky, now, next prayer with the live countdown,
  the prayer strip, the verse card, the tab bar) with today's real values, in the picked theme and
  mode, under "Live preview · {name}". Follow sky in the preview shows the mode the sky gives now.
- **FR-012**: Apply theme MUST save the theme and the mode, restyle the whole app with a 300 ms
  crossfade and go back to More. Going back without Apply MUST save nothing.
- **FR-013**: Every screen MUST work in all 8 themes, dark and light. The adhan screen and the system
  surfaces keep their own colors (milestones 5 and 11).
- **FR-014**: Home's Living Sky MUST keep Qiyam Emerald's six sky states in every theme ("the sky is
  the sky"), the theme restyles everything else. The swatches and the preview show each theme's
  base sky as designed. [NEEDS CLARIFICATION: Q7, the sky in the other 7 themes]

**Light and dark**

- **FR-015**: Dark and Light MUST hold at any time. Follow sky MUST be light from sunrise to Maghrib
  and dark from Maghrib to the next sunrise, by the times at the current location, and switch with
  a 300 ms crossfade while the app is open. With no location yet it follows the phone.
- **FR-016**: The Light and dark row MUST open a bottom sheet with three picker rows (Dark, Light,
  Follow sky) and the Follow sky note. A pick applies at once with the toggle haptic.
  [NEEDS CLARIFICATION: Q4, sheet or the theme page]

**Hijri calendar**

- **FR-017**: The calendar MUST match 4.13: compact bar with the calendar icon, the month with its
  arrows, the Hijri month and year, the Gregorian months it spans, the weekday letters, the month
  grid, COMING UP and Date adjustment. Arabic has no PNG, it follows the same tree with the RTL
  rules: Sunday on the right, the arrows mirror, digits per the digits setting.
- **FR-018**: The grid MUST show the Hijri month from the Umm al-Qura table plus my adjustment, one
  cell per day: the Hijri day large, the Gregorian day small, with the short Gregorian month on the
  month's first cell and on each Gregorian 1st. Days of other months are empty cells. The week
  starts on Sunday, with the same weekday letters as the Prayer tab's strip.
- **FR-019**: Each cell MUST show one look, in this order: today (primary fill), selected, Sunnah
  fast, event, white day (accent dot), plain. Selected, Sunnah fast and event use their cell looks
  in `03 Components.dc.html`.
- **FR-020**: The calendar MUST mark these days, the same in every year
  [NEEDS CLARIFICATION: Q6, which days]:

  | Hijri date | Event | Look | Note |
  | --- | --- | --- | --- |
  | 13 to 15 of every month, but 14 and 15 in Dhu al-Hijjah | Ayyam al-Bid | white day | White days, fasting recommended |
  | 1 Muharram | Islamic New Year | event | |
  | 9 Muharram | Tasu'a | Sunnah fast | Fasting recommended |
  | 10 Muharram | Ashura | Sunnah fast | Fasting recommended |
  | 1 Ramadan | Ramadan begins | event | |
  | 21 Ramadan | Last ten nights | event | Seek Laylat al-Qadr |
  | 1 Shawwal | Eid al-Fitr | event | No fasting |
  | 9 Dhu al-Hijjah | Day of Arafah | Sunnah fast | Fasting recommended |
  | 10 Dhu al-Hijjah | Eid al-Adha | event | No fasting |
  | 11 to 13 Dhu al-Hijjah | Days of Tashreeq | event | No fasting |

  Not marked: Mondays and Thursdays, the Mawlid, Isra and Mi'raj, 15 Sha'ban.
- **FR-021**: The arrows MUST move one Hijri month back or forward and stop at the ends of the Umm
  al-Qura table. The calendar icon MUST bring back the current month.
- **FR-022**: COMING UP MUST list the next three items from today on, nearest first, whatever month
  is shown: the white days as one row per month with their Gregorian range, each event, and each
  month start as "{month} begins". The left column shows the Hijri day and the short month name. The
  nearest month start reads "Estimated {date} · confirmed by moon sighting", later items "Estimated
  {date}", items inside the current Hijri month their date only. A month start that is also an
  event shows once, as the event.
- **FR-023**: Tapping a day MUST select it and open the day sheet: its Hijri and Gregorian date, its
  six times at the current location and method, and its events with their note. The selection
  clears when the sheet closes.
- **FR-024**: The Date adjustment row MUST show the adjustment ("0 days", "+1 day", "−2 days") and
  open a sheet with a stepper from −2 to +2 that shows today's Hijri date for each step. Save keeps
  it, closing the sheet without Save changes nothing.
- **FR-025**: A saved adjustment MUST move every Hijri date in the app at once: the calendar, Home,
  the notifications, the widgets, and Ramadan for the Umm al-Qura Isha.

**Adhan and reminders** [NEEDS CLARIFICATION: Q5, the page]

- **FR-026**: The row MUST push a page with the compact bar: the five prayers, each with today's time
  and the Adhan, Tone, Silent control from 4.12, a row under each prayer on Adhan with its
  recording ("Makkah · full adhan"), then "Reminder before each prayer" with its value.
- **FR-027**: A prayer's recording row MUST open the "Adhan sound" sheet for that prayer (as in
  `03 Components.dc.html`) with the Brand board's six recordings and their length: Makkah 3:52,
  Madinah 4:10, Al-Aqsa 3:31, Cairo 3:44, Istanbul 4:02, Takbir only 0:12. Tapping one selects and
  plays it, the sound stops on another tap, on Save or when the sheet closes. Save keeps it for that
  prayer, Fajr always gets the recording's Fajr variant. Default Makkah for every prayer. Files I
  haven't supplied are placeholders with a `TODO(ahmed)`.
- **FR-028**: The reminder row MUST open a sheet with the slider from `03 Components.dc.html`: 0 to
  30 minutes in 5 minute steps, 0 is off, the toggle haptic on each step. This adds 25 minutes to
  milestone 5's list.
- **FR-029**: Every change MUST be kept at once and remake the pending notifications the way
  milestone 5 does for any change of choices.
- **FR-030**: When notifications are off for the app in the phone's settings, the page MUST say so
  at the top with "Open settings", which opens the app's page in the phone's settings. The choices
  still save.

**Below the design** [NEEDS CLARIFICATION: Q2, the extra rows]

- **FR-031**: SOUND AND TOUCH MUST get "Page turn haptic" after Haptics (milestone 7), off by
  default, disabled while Haptics is off.
- **FR-032**: Below SOUND AND TOUCH, More MUST get two sections built from the same grouped rows:
  YOUR DATA (Downloaded recitations, Reset prayer journey) and ABOUT (Credits, Version).
- **FR-033**: Reset prayer journey MUST ask with the dialog in `03 Components.dc.html` ("Reset prayer
  journey?", Cancel, Reset). Reset MUST clear the prayer log and the qada entries only. Settings,
  first use, Quran, tasbih and azkar stay.
- **FR-034**: Downloaded recitations MUST show the space they take ("48 MB", or "None" and disabled)
  and ask with the same dialog look before deleting them all.
- **FR-035**: Credits MUST push a page listing each source with the credit its license asks for and
  a link that opens in the browser: GeoNames (CC BY 4.0), the fonts (SIL Open Font License), the
  Quran text, translation and recitation (milestone 7), the adhan recordings, and the open source
  licenses of what the app is built on. Each credit not final yet gets a `TODO(ahmed)`.
- **FR-036**: Version MUST show the app's version and build ("1.0.0 (12)") and do nothing on tap.

**Arabic digits** [NEEDS CLARIFICATION: Q3, the switch]

- **FR-037**: In Arabic, APPEARANCE MUST get a toggle "Eastern Arabic digits ١٢٣" after Reduce
  motion, on by default. Off shows Western digits everywhere: screens, notifications and widgets.
  In English the row is hidden.

**Pages with no PNG**

- **FR-038**: The light and dark sheet, the day sheet, the date adjustment sheet, the Adhan and
  reminders page with its two sheets, the extra More rows, the two dialogs and the credits page
  have no PNG. They MUST be built only from parts in `03 Components.dc.html` and shown to me in
  screenshots before they count as done.

**Storage and privacy**

- **FR-039**: Every setting here MUST be kept in the encrypted store on the phone with the
  milestone 2 settings, survive restarts and updates, and never leave the phone. The page turn
  haptic (off) and each prayer's recording (Makkah) are new settings with their defaults.

**Copy and access**

- **FR-040**: Every new string MUST exist in English and Arabic with this wording
  [NEEDS CLARIFICATION: Q8, the copy]:

  | Where | English | Arabic |
  | --- | --- | --- |
  | reminder off | Off | إيقاف |
  | reminder value | {minutes} min | {minutes} دقيقة |
  | adjustment value | 0 days, +1 day, +2 days, −1 day, −2 days | ٠ يوم، +١ يوم، +٢ يوم، −١ يوم، −٢ يوم |
  | adjustment sheet body | Move the Hijri date to match the moon sighting where you live. | عدّل التاريخ الهجري ليوافق رؤية الهلال في بلدك. |
  | today, for screen readers | Today | اليوم |
  | arrows, for screen readers | Previous month, Next month | الشهر السابق، الشهر التالي |
  | month span | {first} – {last} {year}, {first} {year} – {last} {year} | {first} – {last} {year}، {first} {year} – {last} {year} |
  | short Hijri months | Muh, Saf, Rab I, Rab II, Jum I, Jum II, Rajab, Sha'b, Ram, Shaw, Dhul Q, Dhul H | محرم، صفر، ربيع ١، ربيع ٢، جمادى ١، جمادى ٢، رجب، شعبان، رمضان، شوال، ذو القعدة، ذو الحجة |
  | event | Islamic New Year | رأس السنة الهجرية |
  | event | Tasu'a | تاسوعاء |
  | event | Ashura | عاشوراء |
  | event | Last ten nights | العشر الأواخر |
  | event | Eid al-Fitr | عيد الفطر |
  | event | Day of Arafah | يوم عرفة |
  | event | Eid al-Adha | عيد الأضحى |
  | event | Days of Tashreeq | أيام التشريق |
  | event note | Fasting recommended | يُستحب صيامه |
  | event note | Seek Laylat al-Qadr | تحرَّوا ليلة القدر |
  | event note | No fasting | لا صيام فيه |
  | day sheet section | EVENTS | المناسبات |
  | adhan sheet | Adhan sound | صوت الأذان |
  | adhan sheet subtitle | For {prayer} | لصلاة {prayer} |
  | recording | Makkah, Madinah, Al-Aqsa, Cairo, Istanbul, Takbir only | مكة المكرمة، المدينة المنورة، المسجد الأقصى، القاهرة، إسطنبول، التكبير فقط |
  | recording length | Full adhan · {length}, Short · {length} | أذان كامل · {length}، قصير · {length} |
  | prayer's recording row | {recording} · full adhan | {recording} · أذان كامل |
  | notifications off | Notifications are off for this app. | الإشعارات متوقفة لهذا التطبيق. |
  | its action | Open settings | فتح الإعدادات |
  | row | Page turn haptic | اهتزاز تقليب الصفحة |
  | section | YOUR DATA | بياناتك |
  | row | Downloaded recitations | التلاوات المُنزَّلة |
  | its values | {size} MB, None | {size} ميغابايت، لا شيء |
  | dialog | Delete downloaded recitations? | حذف التلاوات المُنزَّلة؟ |
  | dialog body | They download again the next time you play them. | ستُنزَّل من جديد عند تشغيلها. |
  | dialog action | Delete | حذف |
  | row | Reset prayer journey | إعادة ضبط رحلة الصلاة |
  | dialog | Reset prayer journey? | إعادة ضبط رحلة الصلاة؟ |
  | dialog body | This clears your private log on this phone. It can't be undone. | سيُمسح سجلك الخاص على هذا الهاتف، ولا يمكن التراجع عن ذلك. |
  | dialog actions | Cancel, Reset | إلغاء، إعادة الضبط |
  | section | ABOUT | حول التطبيق |
  | row | Credits | المصادر والشكر |
  | credits row | Open source licenses | تراخيص البرمجيات المفتوحة |
  | row | Version | الإصدار |
  | toggle, Arabic only | Eastern Arabic digits ١٢٣ | الأرقام المشرقية ١٢٣ |
  | theme names | Qiyam Emerald, Qiyam, Noor, Living Sky, Iznik, Andalus, Moonlight, Qiyam Rose | قيام زمردي، قيام، نور، السماء الحية، إزنيق، الأندلس، ضوء القمر، قيام وردي |

- **FR-041**: Counts MUST read correctly in Arabic, including the existing "{minutes} min before"
  (15 to 30 take the singular) and "{n} days".
- **FR-042**: Every row, toggle, swatch, segment, arrow and calendar day MUST be at least 44 x 44.
  A screen reader MUST hear each row's name and value, each toggle's state, each swatch's name and
  whether it's selected, and each day's full Hijri and Gregorian date with its marks.

**Design scenario**

- **FR-043**: In "Dev · design scenario" More, the theme page and the calendar MUST match 4.09, 4.15
  and 4.13 with the scenario's settings: Qiyam Emerald, Follow sky, reminder 10 minutes, Makkah ·
  auto, Umm al-Qura, adjustment 0, reduce motion off, haptics on, UI sounds off. In the scenario
  Follow sky follows the phone's light and dark, so each PNG is checked in its mode as in
  milestone 3. 4.15 is checked after tapping Dark.

### Key Entities

- **Appearance settings**: theme, light and dark (dark, light, follow sky), reduce motion, haptics,
  page turn haptic, UI sounds, Arabic digits. All but the page turn haptic exist since milestone 2.
- **Hijri adjustment**: −2 to +2 days, since milestone 2.
- **Notification choices**: each prayer's sound and recording, the reminder minutes. Sound and
  reminder exist since milestone 5, the recording is new.
- **Hijri event**: a name, a Hijri day or range of days, a look (event, Sunnah fast, white day) and
  a note. A fixed list in the app, the same every year.
- **Calendar month**: a Hijri month and year, its days with their Gregorian dates and looks.
- **Credit**: a source, what the app uses it for, its license and a link.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In the design scenario More, the theme page (after Dark) and the calendar match 4.09,
  4.15 and 4.13 within 1 pt in dark and light.
- **SC-002**: A toggle, a swatch or a mode tap shows its change within 100 ms. Apply restyles every
  visible part of the app in one 300 ms crossfade, with no flash.
- **SC-003**: For every month from 1440 to 1460 AH, with each adjustment from −2 to +2, the grid's
  first day and length match the Umm al-Qura table moved by the adjustment, in tests.
- **SC-004**: Follow sky switches within a minute of sunrise and Maghrib, also on daylight saving
  days and after a location change.
- **SC-005**: Every setting survives a restart and an update, works in airplane mode, and nothing
  is sent off the phone.
- **SC-006**: After Reset prayer journey no screen shows a logged prayer or a qada entry, and no
  other data changed.
- **SC-007**: At text scale 2.0 nothing is cut, every action is at least 44 x 44, and contrast
  meets WCAG AA in all 8 themes, dark and light.

## Assumptions

- Language follows the phone, More has no language row (milestone 2).
- The method sheet is milestone 4's, More only opens it.
- The 8 themes in the 4.15 order are the final set, as the constitution says.
- In onboarding (milestone 10) the same theme page shows with no back button and Apply goes on to
  Home.
- The app's Reduce motion toggle doesn't show the phone's setting, either one on is enough.
- The 4.15 "Follow sky" segment keeps its designed look, all three segments can be picked.
- Months change with the arrows only, as SCREENS.md says. No swipe, no date search, no converter.
- The day sheet's times are for the current location and method, like the Prayer tab's past days.
- Events follow the adjusted Umm al-Qura dates. The adjustment is how a country's own sighting
  moves Ramadan and the Eids.
- The UI sound files and five of the six adhan recordings aren't in the handoff. They are
  placeholders with a `TODO(ahmed)` until I supply them. UI sounds stay off by default, so nobody
  hears a placeholder.
- Backup and restore rows join YOUR DATA in milestone 10.
- No privacy policy or terms row until I write them (the constitution says ask me first).
- Milestones 3 to 8 are built before this one, so the tiles, the sounds' events and the downloads
  exist.
- Each later milestone adds its own sources to Credits.
