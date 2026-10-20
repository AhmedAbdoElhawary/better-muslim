# Feature Specification: Milestone 11, Widgets and Live Activity

**Feature Branch**: `feature/milestone-11`, cut when the build starts, after milestone 10

**Created**: 2026-10-20

**Status**: Clarified

**Input**: User description: "milestone 11"

Milestone 11 puts the prayer times outside the app: the iOS home screen widgets in small, medium
and large (5.5, 5.6), the lock screen accessories (5.7), the Android widget in 4 x 2, 2 x 2 and
4 x 1 (5.8), and the countdown before each prayer, a Live Activity with its Dynamic Island on iOS
(5.3, 5.4) and an ongoing notification on Android. They are native code fed with the times the app
already works out, so they work offline and agree with Home to the second (handoff 07, section 04).
The layouts are built straight from the surface trees. This spec covers what the handoff leaves
open: when the countdown starts and ends, its switch, what a tap opens, what a surface shows with no
place or old times, the Android countdown, how the data stays private and how I check it.

## Clarifications

### Session 2026-10-20

- Q: Is the countdown on by default, and where is its switch? → A: On by default, one switch
  "Countdown before each prayer" in a new group on Adhan and reminders.
- Q: Which prayers get it? → A: All five, Fajr's too, from 2 hours before or from the previous
  prayer's time when that is later.
- Q: iOS 16.1 to 18 can't start it while the app is closed. → A: Accepted. There it starts when I
  open the app inside the window, on iOS 26 and later by itself.
- Q: What does the Live Activity show at the adhan when the app can't end it at that second? →
  A: "Now" in place of the countdown with the bar full, until the prayer is marked, the app opens
  or the next countdown starts.
- Q: Mark prayed on the widgets or the Live Activity? → A: No, they only show, as designed.
- Q: What does a widget show with no place or old times? → A: Its frame with the mark and "Open
  Better Muslim to set your place" or "Open Better Muslim to update the times".
- Q: How private is the widget data? → A: Only the fields the surfaces show, out of iCloud and
  Android backups, protected by the phone's own file protection, not encrypted with the database
  key.
- Q: How do I review it? → A: Dev with real times, "Start countdown now" and "Refresh widgets" on
  the dev page. The design scenario writes nothing to the surfaces.
- Q: What does a tap open? → A: Home, except a prayer on the medium, large and Android widgets,
  which opens the Prayer tab at that prayer.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - The day on my home screen (Priority: P1)

I add Better Muslim to my home screen. The small widget shows the next prayer, the sun on its arc
and the time left. The medium shows all five with the next one highlighted and a tick on each one I
prayed, the large lists the five with their times and says how many I prayed today. On Android the
4 x 2 widget shows the next prayer over the sky band and the five times under it. They count down
by themselves and move on at each prayer time, with no internet and without me opening the app.

**Why this priority**: The widget is where most people look at prayer times, and the store listing
promises it (screenshot 6.6). Everything else in this milestone reads the same data.

**Independent Test**: Dev on an iPhone: add the small, medium and large widgets. Each shows the
next prayer and the minutes left exactly as Home does. Mark Asr in the app: the medium and large
tick it within seconds. Turn on airplane mode, close the app and wait past the next prayer: every
widget moves on to the one after. On Android add the 4 x 2, then resize it to 2 x 2 and 4 x 1.

**Acceptance Scenarios**:

1. **Given** a place is set, **When** I add the small widget, **Then** it shows "NEXT", the next
   prayer, "in h:mm" and "{time} · {city}", with the sun on its arc where Home's sun is, as the 5.6
   tree.
2. **Given** the medium widget, **Then** it shows the next prayer, "{hijri date} · {city}", the h:mm
   countdown and the five prayers of the day with their times, the next one highlighted and a tick
   under each logged one, as the 5.6 tree.
3. **Given** the large widget, **Then** it shows "NEXT · {CITY}", the next prayer, the h:mm
   countdown and "at {time}", the five rows with a tick or an empty ring, "{n} of 5 prayed today" and the
   short date with the Hijri date, as the 5.6 tree.
4. **Given** any widget, **When** a prayer time passes, **Then** it moves on to the next prayer
   within a minute, with the app closed and the phone offline.
5. **Given** the medium or large widget, **When** I mark or unmark a prayer anywhere (the Prayer
   tab, the adhan screen, Mark prayed on a notification), **Then** its tick shows or goes.
6. **Given** the Android widget, **When** it is 4 x 2, **Then** it shows the 5.8 tree: the sky band
   with the next prayer and the countdown, the five times under it, past times dimmed and the next
   one highlighted. At 2 x 2 it shows only the sky band, at 4 x 1 only the times row.
7. **Given** any widget, **When** I tap it, **Then** the app opens on Home, and a prayer on the
   medium, large or Android widget opens the Prayer tab at that prayer.

---

### User Story 2 - A countdown before each prayer (Priority: P1)

Two hours before a prayer a countdown shows on my lock screen: the next prayer, the time left to
the second, and the sun moving along a bar from the last prayer. On an iPhone with the Dynamic
Island it sits there too, and a long press shows the reminder time and the method. On Android it is
an ongoing notification with the same countdown. At the adhan it goes.

**Why this priority**: It is the second half of the milestone and the reason for the Dynamic
Island design. It covers the hours just before a prayer, when people check the time most.

**Independent Test**: Dev on an iPhone with the Dynamic Island, iOS 26. Countdown on, app closed:
2 h before the next prayer the Live Activity shows on the lock screen and in the island. Or tap
"Start countdown now" on the dev page. Lock the phone: the 5.3 layout. Long press the island: the
expanded view. Start a timer in the Clock app: the minimal view. Mark the last prayer: its label
ends in "· prayed". At the prayer time it goes. On Android the same with the ongoing notification.

**Acceptance Scenarios**:

1. **Given** the countdown is on and a place is set, **When** it is 2 hours before a prayer, or the
   previous prayer's time when that is later, **Then** the countdown starts with no sound and no
   vibration, by itself on Android and on iOS 26 and later, and on iOS 16.1 to 18 when I open the
   app inside that window.
2. **Given** the Live Activity on the lock screen, **Then** it shows the 5.3 card: the mark, "Next
   prayer · {city}", the prayer, the h:mm:ss countdown, "at {time}", the bar from the last prayer to
   this one with the sun where Home's bar is, and the two times under it, the last one ending in
   "· prayed" when it is logged.
3. **Given** the Dynamic Island, **Then** compact shows the star and the h:mm countdown, minimal the
   star alone, and expanded the 5.4 layout with "{city} · {method}" and the "Reminder {time}" chip,
   the chip only while the reminder is on.
4. **Given** Android, **Then** an ongoing, silent notification shows the prayer and its time, "Next
   prayer · {city}", the countdown to the second and the bar, and on Android 16 and later the
   countdown also sits in the status bar.
5. **Given** a running countdown, **When** the last prayer gets marked anywhere, **Then** its label
   ends in "· prayed".
6. **Given** a running countdown, **When** the prayer time comes, **Then** it ends. On iOS, if the
   app isn't running then, it shows "Now" with the bar full until it can end.
7. **Given** a running countdown, **When** I turn off Countdown before each prayer, **Then** it ends
   at once and no other starts.

---

### User Story 3 - The next prayer on my lock screen (Priority: P2)

I add the lock screen accessories. The circular one is a ring filling from the last prayer to the
next, with the star and the time left. The rectangular one says the next prayer and its time, the
time left and the Hijri date. The inline one sits above the clock with the next prayer and its time.

**Why this priority**: Small and quick to build once the widgets exist, they share their data and
their extension.

**Independent Test**: Dev on an iPhone: add the three to the lock screen. They show the next prayer
and the time left as Home, tinted like the clock. Change the lock screen color: they follow it.

**Acceptance Scenarios**:

1. **Given** the circular accessory, **Then** it shows the ring at Home's bar share, the star and
   the h:mm countdown, as the 5.7 tree.
2. **Given** the rectangular accessory, **Then** it shows the star with "{prayer} {time}", "in h:mm"
   and the Hijri date, as the 5.7 tree.
3. **Given** the inline accessory, **Then** it shows the star with "{prayer} {time}".
4. **Given** any accessory, **Then** it is monochrome and the system tints it.

---

### User Story 4 - Right even when I don't open the app (Priority: P2)

I change my city, the method, the language or the digits, and every widget and the countdown follow
within seconds. I don't open the app for days, they keep going. If they can't be right, they say
so instead of showing wrong times.

**Why this priority**: A widget with yesterday's times or the wrong city is worse than none.

**Independent Test**: Dev: with all widgets added, switch from Makkah to Istanbul, Umm al-Qura to
Turkey, Western digits on, 12 hour time on: every surface follows within seconds. Clear the place
from the dev page: they show the empty state. Set the phone's date 8 days ahead: they show the
out of date state.

**Acceptance Scenarios**:

1. **Given** any surface, **When** the place, method, Asr method, Hijri adjustment, digits,
   language, 12/24 hour setting or reminder changes, **Then** it shows the new values within seconds.
2. **Given** the app not opened for days, **When** the background top-up runs (milestone 5),
   **Then** the surfaces get 7 days from that moment again.
3. **Given** no place yet (onboarding not finished, or after a store reset), **Then** each widget
   shows "Open Better Muslim to set your place" and no countdown starts.
4. **Given** the last written day has passed, **Then** each widget shows "Open Better Muslim to
   update the times" instead of old times.
5. **Given** Reset prayer journey or Restore from backup, **Then** the ticks and every value follow.

---

### Edge Cases

- The place is in another time zone than the phone: times show in the place's zone, as Home does.
- After midnight and before Fajr: the surfaces show the same prayer day as Home's strip (Isha's
  day), with Fajr next.
- Dhuhr's bar starts at sunrise like Home's bar, so its label is "Sunrise 06:15" with no
  "· prayed". Fajr's bar starts at last night's Isha.
- Maghrib to Isha is under 2 hours: Isha's countdown starts the moment Maghrib's ends.
- The reminder notification comes while the countdown runs: both show, the countdown stays.
- A day the method can't give a time for (high latitude): milestone 2's rule, the surfaces show what
  Home shows.
- Friday: Dhuhr stays Dhuhr, no Jumu'ah wording (as milestone 5).
- Notifications not allowed on Android: there is no countdown, the widget still works.
- Live Activities turned off in iOS Settings: no countdown, the switch in the app stays as it is.
- An iPhone without the Dynamic Island: the Live Activity shows on the lock screen and as a banner
  only.
- iOS tinted or clear home screen, and StandBy: the system draws them its way, the sun, the
  highlight and the countdown are the parts it accents.
- Several copies of the same widget: all show the same.
- Low Power Mode and Battery Saver: the countdowns are drawn by the system so they stay exact, the
  move at a prayer time may come a little late if the system holds it back.
- An app update: the surfaces keep the data already written until the app opens, or show the out
  of date state if they can't read it.
- 12 hour phones: "5:56 PM" fits every cell and row in both languages.
- Arabic with the longest names ("المغرب", "العشاء") and a long city: names fit, a long city is cut
  with an ellipsis, never the time or the countdown.
- The design scenario: the surfaces keep what Dev wrote last, the scenario writes nothing to them.

## Requirements *(mandatory)*

### Functional Requirements

**The data the surfaces read**

- **FR-001**: The app MUST give the surfaces the next 7 prayer days already worked out: each day's
  five times, sunrise, where each period starts (for the bar), the Hijri date with my adjustment,
  plus the place name, the method name, the reminder minutes, the logged prayers of the current
  prayer day, and the language, digits and 12/24 hour setting. No surface works out a prayer time
  by itself.
- **FR-002**: The data MUST be written again within seconds whenever one of its inputs changes: the
  place, method, Asr method, Hijri adjustment, digits, language, 12/24 hour setting, reminder, the
  countdown switch, a prayer marked or unmarked anywhere (also from a notification with the app in
  the background), Reset prayer journey and Restore from backup. It MUST also be written on every
  launch, every resume and every background top-up (milestone 5).
- **FR-003**: Every surface MUST show the same prayer day, next prayer, countdown, bar share, sun
  position and Hijri date as Home at the same moment.
- **FR-004**: The data MUST hold only what the surfaces show, stay on the phone, and be kept out of
  iCloud and Android backups. It is readable by the surfaces without the database key, since the
  lock screen draws them while the phone is locked, so the phone's own file protection covers it
  and it is not encrypted with the database key.
- **FR-005**: Nothing in this milestone uses the network. No server, no push.

**Home screen widgets, iOS**

- **FR-006**: The small widget MUST follow the 5.6 small tree. The sun sits on its arc at Home's sun
  share (sunrise to Maghrib), and by night the arc shows what Home's arc shows.
- **FR-007**: The medium widget MUST follow the 5.6 medium tree: the next prayer highlighted, a tick
  under each logged prayer of the shown day, nothing under the others.
- **FR-008**: The large widget MUST follow the 5.6 large tree: a tick on each logged row, an empty
  ring on the others, the next one highlighted, "{n} of 5 prayed today" and the short date with
  the Hijri date at the bottom.
- **FR-009**: The h:mm countdowns MUST update every minute by themselves, rounded as the Prayer
  tab's short countdown, and every widget MUST move on to the next prayer within a minute of its
  time, all without the app running.

**Lock screen accessories, iOS**

- **FR-010**: The circular, rectangular and inline accessories MUST follow the 5.7 tree,
  monochrome, tinted by the system. The circular ring fills at Home's bar share.

**Android widget**

- **FR-011**: The Android widget MUST follow the 5.8 tree at 4 x 2, its default size. Resized to
  2 x 2 it shows only the sky band, to 4 x 1 only the times row, and a size in between takes the
  closest of the three.
- **FR-012**: Its countdown MUST update every minute by itself and it MUST move on at each prayer
  time without the app, past times dimmed and the next one highlighted as in 5.8.

**The countdown before each prayer** (Live Activity on iOS, ongoing notification on Android)

- **FR-013**: A "Countdown before each prayer" switch MUST be in a new group on Adhan and reminders,
  under the reminder row, from the same grouped rows, on by default.
- **FR-014**: The countdown MUST start 2 hours before each of the five prayers, or at the previous
  prayer's time when that is later, with no sound and no vibration. Fajr's starts in the night too.
- **FR-015**: On Android and on iOS 26 and later the countdown MUST start by itself, for as long as
  the schedule lasts (the 6 days of milestone 5, topped up the same way). On iOS 16.1 to 18 it
  starts when I open the app inside the window, since iOS lets an app start one only while it is
  open there.
- **FR-016**: The Live Activity MUST follow the 5.3 card: the mark, "Next prayer · {city}", the
  prayer, the h:mm:ss countdown, "at {time}", the bar from the period's start to the prayer with
  the sun at Home's bar share, the start label ("{prayer} {time}", ending in "· prayed" when that
  prayer is logged) and "{prayer} {time}" at the end.
- **FR-017**: The Dynamic Island MUST follow 5.4: compact with the star and the h:mm countdown,
  minimal with the star, expanded with the 5.3 content plus "{city} · {method}" and the "Reminder
  {time}" chip, shown only while the reminder is on.
- **FR-018**: On Android the countdown MUST be an ongoing, silent notification on its own low
  importance channel ("Prayer countdown"): the prayer and its time as the title, "Next prayer ·
  {city}" as the text, the countdown to the second and the bar. On Android 16 and later it MUST also
  be a Live Update, with the countdown in the status bar.
- **FR-019**: At the prayer time the countdown MUST end. Android removes it at that second. On iOS,
  where the app isn't running at that second, the Live Activity MUST show "Now" in place of the
  countdown with the bar full, and end as soon as the app can: the prayer gets marked, the app
  opens, or the next countdown starts. It MUST never show a countdown below zero or stuck at
  0:00:00.
- **FR-020**: Only one countdown MUST run at a time, the next prayer's. Turning the switch off MUST
  end it at once and start no other.
- **FR-021**: No countdown starts without a place, on Android without the notification permission,
  or on iOS with Live Activities turned off for the app in Settings.

**What the surfaces don't do**

- **FR-022**: The surfaces only show, as designed. Mark prayed stays on the notifications and in
  the app.

**Taps**

- **FR-023**: The small widget, the accessories, the Live Activity, the Dynamic Island and the
  Android countdown MUST open Home. A prayer on the medium, large and Android widgets MUST open the
  Prayer tab at that prayer, like Home's strip. The rest of those widgets opens Home.

**No place or old times**

- **FR-024**: With no place, each widget MUST show its frame and background with the mark and "Open
  Better Muslim to set your place". When the last written day has passed, it MUST show "Open Better
  Muslim to update the times" instead of old times. The inline accessory shows "Open Better Muslim",
  the circular one the mark alone.

**Look, language and access**

- **FR-025**: Every surface MUST use the dark Qiyam Emerald values, whatever theme and mode I picked
  (TOKENS.md).
- **FR-026**: Every surface MUST be in the app's language. In Arabic the trees mirror with the RTL
  rules, the five prayers run in the same direction as Home's strip, and the arc, the bar, the ring
  and clock times are never mirrored. The names use Reem Kufi where the trees use Marcellus, and
  Noto Sans Arabic for the rest, as in the app.
- **FR-027**: Every number MUST follow the digits setting and every time the 12/24 hour setting, the
  countdowns the system draws too.
- **FR-028**: The surfaces MUST use the design's fonts.
- **FR-029**: The surfaces keep the design's sizes at every text size, since their boxes don't grow.
  Nothing is cut except a long city name, with an ellipsis.
- **FR-030**: With VoiceOver and TalkBack each surface MUST read as one line in reading order (the
  prayer, the time left, its time, the place). The arc, the sun, the bar and the star are hidden
  from them.
- **FR-031**: Every text MUST meet WCAG AA against its background on the dark values.

**Platforms**

- **FR-032**: The home screen widgets MUST work on every iOS the app supports, the accessories from
  iOS 16, the Live Activity from iOS 16.1, the Dynamic Island on iPhones that have it. The Android
  widget and countdown MUST work on every Android the app supports, the Live Update from Android 16.

**Checking it**

- **FR-033**: In dev builds the dev page MUST get "Start countdown now" (the next prayer's countdown
  starts at once, whatever the 2 hours) and "Refresh widgets". Staging and production MUST NOT have
  them. The design scenario MUST NOT write the surfaces, as it schedules no notifications.

**Copy**

- **FR-034**: Every new string MUST exist in English and Arabic with this wording:

  | Where | English | Arabic |
  | --- | --- | --- |
  | small widget label | NEXT | التالية |
  | large widget label | NEXT · {city} | التالية · {city} |
  | bar start, logged | {prayer} {time} · prayed | {prayer} {time} · صلّيت |
  | island chip | Reminder {time} | تذكير {time} |
  | switch row | Countdown before each prayer | العد التنازلي قبل كل صلاة |
  | switch row line | Starts 2 hours before, ends at the adhan | يبدأ قبل الصلاة بساعتين وينتهي عند الأذان |
  | Android channel | Prayer countdown | العد التنازلي للصلاة |
  | no place | Open Better Muslim to set your place | افتح مسلم أفضل لتحديد مكانك |
  | old times | Open Better Muslim to update the times | افتح مسلم أفضل لتحديث المواقيت |
  | inline, no data | Open Better Muslim | افتح مسلم أفضل |
  | iOS widget gallery, small | Next prayer · Next prayer with the sun on its arc. | الصلاة القادمة · الصلاة القادمة والشمس على قوسها. |
  | iOS widget gallery, medium and large | Today's prayers · All five, with the ones you prayed ticked. | صلوات اليوم · الصلوات الخمس، وما صلّيته عليه علامة. |
  | iOS widget gallery, lock screen | Next prayer · The next prayer and the Hijri date. | الصلاة القادمة · الصلاة القادمة والتاريخ الهجري. |
  | Android widget picker | Prayer times · The next prayer and today's five times. | مواقيت الصلاة · الصلاة القادمة ومواقيت اليوم الخمسة. |

  Reused as they are: "Next prayer", "Next prayer · {city}", "in {duration}", "at {time}",
  "{count} of 5 prayed today", "Now", "{time} · {city}", the prayer, sunrise and Hijri month
  names. The gallery and picker texts live with the native code, the system reads them before the
  app ever runs. The dev page buttons stay English, like the rest of that page.

### Key Entities

- **Surface data**: the 7 prayer days of FR-001 and when they were written. Made from the store,
  belongs to the phone, never in a backup.
- **Countdown switch**: on or off, a setting like the reminder, kept in the store and in the backup.
- **Countdown**: one at a time, for the next prayer, from its start (FR-014) to the prayer time.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: At any moment of the 7 days, every surface shows the same next prayer and the same
  minute left as Home, in tests over the written data and on a phone.
- **SC-002**: Offline and with the app closed, every widget moves on within 1 minute of each prayer
  time for 7 days.
- **SC-003**: A prayer marked in the app shows ticked on the medium and large widgets within 5
  seconds, and within 1 minute when marked from a notification.
- **SC-004**: The countdown starts within 1 minute of its start time where it starts by itself,
  and at the prayer time it is gone or shows "Now", never a countdown below zero, in tests and on a
  phone.
- **SC-005**: Each surface ends built from its tree in English and Arabic, with both digit settings
  and with 12 and 24 hour time, checked in the app.
- **SC-006**: The surface data holds only the FR-001 fields and stays out of the phone's backups,
  in tests.
- **SC-007**: Marking a prayer, changing a setting and launching the app feel as fast as before:
  writing the surface data never blocks a frame.

## Assumptions

- The surfaces always use the dark Qiyam Emerald night sky (TOKENS.md, OVERVIEW.md). So Motion 03's
  sky change doesn't reach the widgets, they move on with the system's own transition.
- "cd" is h:mm:ss (the Live Activity and the expanded island), "cdS" is h:mm (the widgets, the
  compact island and the accessories), as in the handoff's 07 script.
- 5.5 and 5.1 show the surfaces in place. The status bar, the other apps, the flashlight and camera
  buttons are the system's, nothing to build from them.
- iOS 26 needs an alert to start a Live Activity ahead of time. It is made silent. If iOS still
  lights the screen for it (Fajr's starts in the night), the plan comes back to me.
- iOS ends a Live Activity after at most 8 hours and limits how many an app can have. One at a time
  fits inside that.
- The Android countdown uses milestone 5's notification permission, and its moves at prayer times
  use milestone 5's exact alarms.
- The handoff names Jetpack Glance for Android. If Glance can't draw the app's fonts, the plan says
  how close it gets and what it uses instead before anything is built.
- The App Group and the widget extension ids for dev, staging and production need my Apple developer
  account. They get a `TODO(ahmed)` where the ids go.
- No widget settings (no choice of prayer or place per widget). Every widget shows the app's place.
- No Android lock screen widgets (not open to other apps), no Apple Watch or Wear OS.
- No Quran "Continue reading" on the surfaces, the Quran reader comes after this milestone.
- The background top-up already runs every 12 hours on Android and when iOS allows it. Writing the
  surface data rides on it, nothing new runs in the background.
