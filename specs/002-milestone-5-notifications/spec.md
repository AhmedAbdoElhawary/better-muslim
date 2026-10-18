# Feature Specification: Milestone 5, Notifications and Adhan

**Feature Branch**: `feature/milestone-5` (made when the build starts, after milestones 2 to 4 are
merged)

**Created**: 2026-10-17

**Status**: Clarified

**Input**: User description: "milestone 5"

Milestone 5 makes the app call each prayer, even when it is closed: the adhan, a soft tone or
silence, prayer by prayer, plus a reminder before each prayer. When the app is open at prayer time
the full screen adhan (4.03) comes over whatever is on screen. On Android the full adhan also plays
with the app closed, as a media notification (5.2) that can be paused, stopped or used to mark the
prayer. It is built after milestones 3 and 4, since "Mark prayed" writes to the prayer log from
milestone 4.

## Clarifications

### Session 2026-10-17

- Q: Milestones 3 and 4 aren't built and Mark prayed needs the prayer log from 4. Build order?
  → A: Spec now, build after 3 and 4 in the handoff order. The spec moves to
  `feature/milestone-5` when the build starts.
- Q: Which adhan recordings? → A: One adhan in this milestone, Makkah, with its Fajr variant, plus
  a clip of each of 30 seconds or less for iOS notifications. Until I supply the files they are
  placeholders with a `TODO(ahmed)`. Tone is the phone's default notification sound until I supply
  one. The picker for the Brand board's six recordings comes with the "Adhan and reminders" page
  in milestone 9.
- Q: What does tapping an adhan notification later do? → A: While the adhan would still be
  playing, the adhan screen opens and the full adhan goes on from that point. Later than that, the
  app opens on the Prayer tab at that prayer. Both platforms also get a "Mark prayed" action on
  the notification itself.
- Q: Android phone on silent, vibrate or Do Not Disturb? → A: Respected. The notification shows,
  the adhan doesn't sound, the same as iOS.
- Q: On time delivery on Android? → A: Ask for exact alarms ("Alarms & reminders") right after the
  notification permission. If refused, notifications still come, maybe a few minutes late, with the
  clip instead of the full adhan.
- Q: What is Silent? → A: The notification still shows at prayer time, with no sound and no
  vibration, so marking the prayer from it still works.
- Q: Before the notifications primer (4.12) exists? → A: The system dialogs show directly on first
  launch, after location, like location in milestone 2. The choices are stored with the 4.12
  defaults. Reminder options are off, 5, 10, 15, 20 and 30 minutes. The screens to change them
  come in milestones 9 and 10.
- Q: "Read dua" has no designed sheet. → A: A bottom sheet styled like the dua cards in 4.14, with
  the full dua after the adhan (Bukhari 614). Its text and translation get a `TODO(ahmed)` for me
  to check, and I approve the layout from the screenshots.
- Q: How is the milestone checked? → A: Unit tests for the schedule, 4.03 next to its PNG in the
  design scenario, and two dev only buttons, "Open adhan screen" and "Test notification in 1
  min" (on a dev page reached from More, since milestone 3 removes the readout). The design scenario never schedules real notifications.
- Q: The evening azkar nudge and the lock screen widgets in 5.1 and 5.2? → A: Azkar nudges come in
  milestone 8 with their switch in Azkar, widgets and Live Activity in milestone 11. This milestone
  is only adhan and reminder notifications.
- Q: iOS when the app isn't opened for 6 days? → A: Accepted. The schedule tops up on launch, when
  the app comes to the front and on background refresh when iOS allows it. No "open the app"
  notification for now. The place where the window ends gets a `TODO(ahmed)`, I may design that
  last message later.
- Q: 4.03 only shows Maghrib. What sky do the other prayers get on the adhan screen? → A: Each
  prayer gets its own Living Sky state with the sun at its real position. Maghrib matches 4.03
  exactly, the other four I approve from the screenshots.
- Q: What does the adhan icon on the Prayer tab's later rows mean now that each prayer has a
  sound? → A: It stays on every later row whatever the sound. In 4.04 Isha shows it while Isha
  defaults to Tone, so it means "this prayer notifies you".
- Q: What does Home's "Adhan at 17:56 · reminder 10 min before" say with the reminder off or a
  Tone or Silent prayer next? → A: "Adhan at {time}" always, "· reminder {minutes} min before"
  only while the reminder is on.
- Q: A prayer gets marked in the app, does its adhan notification stay in the list? → A: No.
  Marking a prayer anywhere removes its delivered adhan notification, unmarking doesn't bring it
  back.

### Session 2026-10-18 (plan decisions)

- Q: iOS can't read the ring/silent switch. Does the full adhan in the app play with the switch on
  silent? → A: Yes, so it keeps playing with the screen locked. The notification itself follows the
  switch, and Stop is one tap.
- Q: Milestone 3 removes the dev readout, where do the dev buttons go? → A: A dev page reached from
  More, dev builds only.
- Q: What does Mark prayed on the adhan screen show after the tap? → A: "Prayed" with the check,
  like milestone 4's chip, and it can't be tapped again there.
- Q: The dua sheet in Arabic? → A: Only the Arabic and its source, no transliteration or
  translation.
- Q: Android can't run the schedule each time an adhan fires. → A: It tops up in the background at
  least every 12 hours instead.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Each prayer reaches me with the app closed (Priority: P1)

I set nothing, close the app, and at each prayer the phone tells me: the adhan for Fajr and
Maghrib, a soft tone for the others. It works offline and keeps working for the next 6 days even
if I don't open the app.

**Why this priority**: It is the main promise of a prayer app. Without it the app only shows times.

**Independent Test**: Allow notifications (and alarms on Android), turn on airplane mode, kill the
app, wait for the next prayer. The notification arrives at that minute with its sound. Repeat after
restarting the phone.

**Acceptance Scenarios**:

1. **Given** notifications allowed and a saved location, **When** a prayer time comes with the
   app closed, **Then** a notification "Asr · 15:27" with "It is time for Asr in Makkah. Tap to
   mark it prayed." arrives at that minute, with the sound chosen for Asr.
2. **Given** Fajr set to Adhan, **When** Fajr comes, **Then** the Fajr adhan plays, not the
   adhan of the other prayers.
3. **Given** a prayer set to Silent, **When** its time comes, **Then** the notification shows
   with no sound and no vibration.
4. **Given** airplane mode, **When** a prayer time comes, **Then** the notification still
   arrives.
5. **Given** an Android phone restarted or the app updated, **When** the next prayer comes,
   **Then** its notification still arrives without opening the app first.
6. **Given** the app opened today, **When** the next 6 days pass without opening it, **Then**
   every prayer in those 6 days still gets its notification.

---

### User Story 2 - The full adhan, and one tap to stop it (Priority: P1)

When the app is open at prayer time, the adhan screen comes over whatever I am doing and the full
adhan plays. On Android the full adhan plays even with the app closed, as a media notification I
can pause or stop from anywhere. One tap stops it.

**Why this priority**: The adhan is the moment the whole design is built around (4.03, 5.2), and
an adhan that can't be stopped at once is worse than none.

**Independent Test**: With the app open, use "Test notification in 1 min" on a prayer set to
Adhan: the adhan screen opens and the adhan plays, Stop adhan silences it at once. On Android, do
the same with the app closed: the media notification plays the full adhan and its Stop works.

**Acceptance Scenarios**:

1. **Given** the app in front and a prayer set to Adhan, **When** its time comes, **Then** the
   adhan screen opens over any screen with the circle reveal from the sun, and the full adhan plays,
   fading in over 1.5 seconds.
2. **Given** the adhan screen, **When** I tap Stop adhan, **Then** the sound stops at once and the
   screen closes.
3. **Given** an Android phone, the app closed, a prayer set to Adhan, exact alarms allowed and the
   phone not on silent, **When** its time comes, **Then** the full adhan plays and the media
   notification shows "Better Muslim · Adhan", "Maghrib · 17:56", "Adhan of Makkah", the progress
   with elapsed and total time, pause, Mark prayed and Stop.
4. **Given** the media notification, **When** I tap pause, **Then** the adhan pauses and play
   resumes it. **When** I tap Stop, **Then** the adhan stops and the notification goes.
5. **Given** an Android phone on silent, vibrate or Do Not Disturb, **When** a prayer set to Adhan
   comes, **Then** no adhan sounds and the notification shows quietly.
6. **Given** the app in front and a prayer set to Tone or Silent, **When** its time comes, **Then**
   no adhan screen opens, only the notification shows.
7. **Given** reduce motion on, **When** the adhan screen opens, **Then** it fades in over 300 ms
   with no circle reveal.

---

### User Story 3 - Mark the prayer from the adhan (Priority: P2)

Logging the prayer is one tap away from the adhan: on the adhan screen and on the notification,
without opening the app. Tapping the notification later takes me to where I can log it.

**Why this priority**: The handoff puts Mark prayed on every adhan surface. It needs the prayer
log from milestone 4 and is worth less than the adhan itself arriving.

**Independent Test**: Use the Mark prayed action on an adhan notification with the app closed, open
the app, the prayer shows as prayed on Home and Prayer.

**Acceptance Scenarios**:

1. **Given** the adhan screen, **When** I tap Mark prayed, **Then** the prayer is logged with the
   Mark prayed haptic and the adhan keeps playing.
2. **Given** an adhan notification or the Android media notification, **When** I use its Mark
   prayed action, **Then** the prayer is logged without opening the app and the adhan, if
   playing, keeps playing.
3. **Given** a prayer set to Adhan, **When** I tap its notification while the full adhan would
   still be playing (less than its length after the prayer time), **Then** the adhan screen opens
   and the full adhan goes on from that point.
4. **Given** any other tap on an adhan notification (a Tone or Silent prayer, or later than the
   adhan's length), **When** the app opens, **Then** it shows the Prayer tab at that prayer on that
   day.
5. **Given** a prayer already logged, **When** Mark prayed is used again, **Then** it stays logged
   once, nothing is added twice.

---

### User Story 4 - A reminder before each prayer (Priority: P2)

Ten minutes before each prayer, a quiet reminder: "Maghrib in 10 minutes", "17:56 · Makkah". I can
change the minutes or turn it off, and the schedule follows.

**Why this priority**: The handoff shows it on Home, More, 4.12 and 5.2, but the prayer itself
matters more than the reminder.

**Independent Test**: With the default 10 minutes, the reminder arrives 10 minutes before the next
prayer. Set it off, no reminder comes.

**Acceptance Scenarios**:

1. **Given** the reminder at 10 minutes, **When** it is 10 minutes before Maghrib, **Then**
   "Maghrib in 10 minutes" with "17:56 · Makkah" arrives.
2. **Given** the reminder off, **When** prayer times pass, **Then** no reminders arrive.
3. **Given** an iPhone, **When** a reminder arrives, **Then** it goes to the notification list
   without lighting the screen or making a sound.
4. **Given** the reminder minutes changed, **When** the next prayer comes, **Then** its reminder
   uses the new minutes.

---

### User Story 5 - The schedule stays right when things change (Priority: P2)

When I travel, change the method, the language or the time zone, or change a sound, every coming
notification follows at once. Nothing ever fires at an old time or for an old place.

**Why this priority**: A notification at a wrong time is worse than none, and the schedule is set 6
days ahead.

**Independent Test**: Schedule for Makkah, switch to Cairo by hand, check every pending notification
is for Cairo's times. Change the app language, the pending texts are in the new language.

**Acceptance Scenarios**:

1. **Given** pending notifications, **When** the location changes (by hand or by 30 km or more on
   auto), **Then** all of them are replaced with the new place's times and name.
2. **Given** pending notifications, **When** the method, Asr, a prayer's sound or the reminder
   minutes change, **Then** all of them follow the new choice.
3. **Given** pending notifications, **When** the phone's time zone or clock changes, **Then** they
   are rescheduled for the right moments.
4. **Given** pending notifications, **When** the app language or Arabic digits change, **Then**
   their texts follow.
5. **Given** the app opens, comes to the front, or the phone gives it a background refresh,
   **When** the schedule is checked, **Then** it covers the next 6 days again.
6. **Given** an iPhone, **When** the schedule is made, **Then** no more than 64 notifications are
   pending.

---

### User Story 6 - Asked once, at the right moment (Priority: P2)

On first launch, after location, the phone asks me to allow notifications, and on Android also
alarms. If I say no, the app works without nagging, and if I allow it later in the phone's
settings, notifications start.

**Why this priority**: Without the permission nothing in this milestone reaches the user, and a
refused permission must never break the app.

**Independent Test**: Fresh install, refuse notifications, the app works and asks nothing more.
Allow them in the phone's settings, bring the app to the front, notifications are scheduled.

**Acceptance Scenarios**:

1. **Given** first launch, **When** location has been handled, **Then** the system dialog for
   notifications shows.
2. **Given** an Android 12 or later phone and notifications allowed, **When** the dialog closes,
   **Then** the app asks once for alarms (the "Alarms & reminders" page).
3. **Given** notifications refused, **When** the app is used, **Then** it works, keeps the
   choices, schedules nothing and doesn't ask again.
4. **Given** alarms refused on Android, **When** a prayer comes, **Then** the notification still
   arrives, maybe a few minutes late, with the clip instead of the full adhan.
5. **Given** notifications allowed later in the phone's settings, **When** the app opens or comes
   to the front, **Then** the schedule is made.

---

### User Story 7 - Read the dua after the adhan (Priority: P3)

On the adhan screen, "Read dua" opens the full dua after the adhan, while the adhan keeps playing.

**Why this priority**: The screen already shows its first line. The full text is a nice to have
next to the adhan itself.

**Independent Test**: Open the adhan screen, tap Read dua, the sheet shows the full dua with its
source, the adhan keeps playing, closing the sheet returns to the adhan screen.

**Acceptance Scenarios**:

1. **Given** the adhan screen, **When** I tap Read dua, **Then** a sheet opens with the title,
   the source (Bukhari 614), the Arabic, the transliteration and the translation, like a dua card
   in 4.14.
2. **Given** the sheet open, **When** the adhan plays, **Then** it keeps playing, and closing the
   sheet returns to the adhan screen.

---

### User Story 8 - Checking it against the design (Priority: P3)

As the developer, I can open the adhan screen in the design scenario and put it next to 4.03, and
send myself a test notification without waiting for a prayer.

**Why this priority**: Every screen is checked against its PNG within 1 pt, and waiting hours for a
real prayer makes testing notifications slow.

**Independent Test**: Run "Dev · design scenario", tap "Open adhan screen", compare with 4.03. In a
normal dev run tap "Test notification in 1 min", it arrives a minute later.

**Acceptance Scenarios**:

1. **Given** the design scenario, **When** I tap "Open adhan screen", **Then** it shows Maghrib
   17:56, "ADHAN · MAKKAH" and the progress at 0:42 of 2:56, matching 4.03.
2. **Given** a dev build, **When** I tap "Test notification in 1 min", **Then** a notification for
   the next prayer, with that prayer's sound, arrives one minute later.
3. **Given** the design scenario, **When** the app runs, **Then** no real notifications are
   scheduled.
4. **Given** a staging or production build, **When** the app runs, **Then** neither button
   exists.

---

### Edge Cases

- No saved location: nothing is scheduled. The schedule is made as soon as a location is saved.
- A prayer with no time that day (above the polar circle): no notification and no reminder for it.
- Daylight saving switch days: notifications fire at the right local time on both sides.
- A manual city in another time zone than the phone's: notifications fire at the city's prayer
  moment and show the city's local time, the same time the app shows.
- The app opens 5 minutes before Asr with a 10 minute reminder: that reminder is skipped, the Asr
  notification is still scheduled.
- The app is opened, not from a notification, a minute after a prayer: no adhan screen. It opens
  only at the moment of the prayer or from the notification.
- Another app is playing music at prayer time: it pauses while the adhan plays.
- A phone call comes during the adhan: the adhan stops.
- The adhan ends on its own: the adhan screen stays open with Mark prayed and Read dua until I close
  it. On Android the media notification turns into the plain adhan notification with Mark prayed.
- The app goes to the background or the screen turns off during the adhan: it keeps playing until
  it ends or is stopped.
- Tapping a notification from an earlier day: the Prayer tab opens at that prayer on that day.
- Mark prayed on Isha's notification after midnight: it is logged on the day Isha started, the
  prayer day runs from Fajr to the next Fajr (milestone 4 FR-004).
- Mark prayed on a notification after its prayer has passed: it is logged as prayed, the same as
  "I prayed it" in the Prayer tab (milestone 4 FR-008).
- A prayer marked in the Prayer tab while its adhan notification is still in the list: the
  notification is removed.
- The store is reset (milestone 2, FR-024): pending notifications are cleared and made again from
  the defaults.
- The phone's 12 or 24 hour setting changes: pending notifications follow it the next time the app
  opens.
- The 6 day window runs out on iOS because the app wasn't opened and iOS gave no background
  refresh: notifications stop until the app is opened. Accepted for now (see Assumptions).

## Requirements *(mandatory)*

### Functional Requirements

**Choices**

- **FR-001**: The app MUST keep a sound for each of the five prayers, one of Adhan, Tone or Silent.
  Defaults: Adhan for Fajr and Maghrib, Tone for Dhuhr, Asr and Isha.
- **FR-002**: The app MUST keep one reminder setting for all five prayers: off, 5, 10, 15, 20 or 30
  minutes before. Default 10.
- **FR-003**: The choices MUST be kept with the other settings, encrypted, and survive restarts and
  updates. This milestone has no screen to change them, the notifications primer (4.12) comes in
  milestone 10 and the "Adhan and reminders" page in milestone 9.

**Permissions**

- **FR-004**: On first launch, right after location is handled, the app MUST show the system
  dialog for notifications directly, until the primer (4.12) replaces it in milestone 10. After a
  refusal the app MUST NOT ask again.
- **FR-005**: On Android 12 and later, after notifications are allowed, the app MUST ask once for
  exact alarms through the system's "Alarms & reminders" page.
- **FR-006**: When a permission is granted later in the phone's settings, the app MUST make the
  schedule the next time it opens or comes to the front.

**Schedule**

- **FR-007**: The app MUST schedule, on the phone and without internet, the adhan notification of
  each of the five prayers and its reminder for the next 6 days.
- **FR-008**: On iOS no more than 64 notifications MUST be pending at once.
- **FR-009**: The app MUST top the schedule up to 6 days when it opens, when it comes to the front,
  on background refresh when the phone allows it (on Android at least every 12 hours), and on
  Android after the phone restarts and after an app update.
- **FR-010**: The app MUST replace every pending notification at once when the location, method,
  Asr, a prayer's sound, the reminder minutes, the app language or the Arabic digits change. A
  change of the phone's time zone, clock or 12/24 hour setting made while the app was closed MUST
  be picked up the next time it opens or comes to the front.
- **FR-011**: No pending notification MUST ever be for a time already passed, an old location or
  old choices.
- **FR-012**: Nothing MUST be scheduled without a saved location or without notification
  permission, and no notification MUST be scheduled for a prayer that has no time that day.
- **FR-013**: The design scenario MUST NOT schedule any real notification.

**Adhan notification**

- **FR-014**: At each prayer the app MUST show a notification titled "{prayer} · {time}" with "It
  is time for {prayer} in {city}. Tap to mark it prayed.", in the app's language, with the time in
  the phone's 12 or 24 hour format and Arabic digits per the setting.
- **FR-015**: The sound MUST follow the prayer's choice. Adhan: on iOS a clip of 30 seconds or less
  of the adhan, on Android the full adhan (FR-020). Fajr uses the Fajr variant. Tone: a soft tone.
  Silent: no sound and no vibration, the notification still shows.
- **FR-016**: On iOS adhan notifications MUST be time sensitive.
- **FR-017**: On Android each prayer MUST have its own notification category in the phone's
  settings, at high importance, and reminders their own category at default importance.
- **FR-018**: Every adhan notification MUST have a "Mark prayed" action that logs the prayer in the
  prayer log without opening the app.
- **FR-019**: Tapping an adhan notification for a prayer set to Adhan, less than the full adhan's
  length after the prayer time, MUST open the adhan screen with the full adhan going on from that
  point. Any other tap MUST open the Prayer tab at that prayer on that day.

**Full adhan**

- **FR-020**: On Android, with the app closed or in the background, a prayer set to Adhan, exact
  alarms allowed and the phone not on silent, vibrate or Do Not Disturb, the full adhan MUST play
  with a media notification as in 5.2: "Better Muslim · Adhan", "{prayer} · {time}", "Adhan of
  Makkah", the progress with elapsed and total time, pause and play, Mark prayed and Stop.
- **FR-021**: When the app is in front at a prayer set to Adhan, the adhan screen MUST open over any
  screen and the full adhan MUST play. The notification's own sound MUST NOT play on top of it.
- **FR-022**: On Android with the phone on silent, vibrate or Do Not Disturb, the adhan MUST NOT
  sound. The notification shows quietly.
- **FR-022a**: On iOS the full adhan in the app MUST play even with the ring switch on silent, iOS
  gives no way to read it. The adhan notification itself follows the switch.
- **FR-023**: On Android without exact alarms, the adhan notification MUST play the clip instead of
  the full adhan.
- **FR-024**: The adhan MUST fade in over 1.5 seconds. Only one adhan MUST play at a time. The
  adhan screen and the media notification MUST show the same playback.
- **FR-025**: Once playing, the adhan MUST keep playing with the app in the background or the screen
  off, until it ends or is stopped. Other audio MUST pause while it plays, and a phone call MUST
  stop it.
- **FR-026**: Stop, on the adhan screen or the media notification, MUST silence the adhan at once.
  On the screen it also closes the screen, on the notification it also removes the notification.
- **FR-027**: When the adhan ends on its own, the adhan screen MUST stay open until closed, and on
  Android the media notification MUST turn into the plain adhan notification with Mark prayed.

**Adhan screen (4.03)**

- **FR-028**: The adhan screen MUST match 4.03: the sky with the sun on the horizon and its halo,
  the star mark, "ADHAN · {city}", the prayer name in Arabic and English, the prayer time, the
  progress (elapsed and total time of the adhan), the "After the adhan" card with the first line
  of the dua and its translation, Mark prayed and Stop adhan.
- **FR-029**: For the prayers other than Maghrib, the sky MUST be that prayer's own Living Sky state
  (Fajr, Dhuhr, Asr, Isha) with the sun at its real position. Maghrib matches 4.03 exactly.
- **FR-030**: The screen MUST enter with Motion 06 (circle reveal from the sun, 520 ms decelerate,
  the text 300 ms later), and with a 300 ms fade when reduce motion is on. The halo breathes as in
  MOTION.md and stands still with reduce motion.
- **FR-031**: Mark prayed MUST log the prayer with the Mark prayed haptic and keep the adhan
  playing. The button then shows "Prayed" with the check and can't be tapped again there.
- **FR-032**: Read dua MUST open a bottom sheet (Motion 15) with the full dua after the adhan, laid
  out like a dua card in 4.14: title, source (Bukhari 614), Arabic, transliteration, translation.
  In Arabic only the Arabic and the source show. The adhan keeps playing.
- **FR-033**: The adhan screen MUST follow the 4.03 colors in every theme and mode, it is an always
  dark surface. Its texts follow the app language, and the time and progress are never mirrored.

**Reminder**

- **FR-034**: When the reminder is on, the app MUST show "{prayer} in {minutes} minutes" with
  "{time} · {city}" that many minutes before each of the five prayers, whatever the prayer's sound.
- **FR-035**: On iOS reminders MUST be passive: into the list, no sound, no lit screen. On Android
  they use the reminder category at default importance.

**Home, Prayer tab and the log**

- **FR-036**: Home's adhan line MUST read "Adhan at {time} · reminder {minutes} min before" while
  the reminder is on and "Adhan at {time}" while it is off, whatever the next prayer's sound. It
  replaces milestone 3's sample. The new string is "Adhan at {time}" / "الأذان {time}".
- **FR-037**: The adhan icon on the Prayer tab's later rows MUST stay as designed on every prayer,
  whatever its sound.
- **FR-038**: Mark prayed, on the adhan screen or a notification, MUST make the same log entry as
  Mark or "I prayed it" in the Prayer tab: on the prayer's own prayer day (Fajr to the next Fajr),
  once at most, whether the prayer is still open or has passed.
- **FR-039**: When a prayer is logged anywhere, its delivered adhan notification MUST be removed
  from the notification list. Unlogging MUST NOT bring it back.
- **FR-040**: Scheduling errors MUST be reported without personal data: no location, place or
  prayer times.

**Checking it**

- **FR-041**: In dev builds only, a dev page reached from More (milestone 3 removes the dev
  readout) MUST have "Open adhan screen" (the adhan screen
  for the next prayer, Maghrib in the design scenario) and "Test notification in 1 min" (the next
  prayer's notification with its sound, one minute from now). Staging and production builds MUST
  NOT have them.
- **FR-042**: In the design scenario the adhan screen MUST show 4.03's progress, 0:42 of 2:56, as
  fixed values, so it can be put next to the PNG.

### Key Entities

- **Prayer sound**: for each of the five prayers, Adhan, Tone or Silent.
- **Reminder**: off or the minutes before each prayer.
- **Scheduled notification**: one adhan or reminder at a moment, for a prayer on a date at a place,
  with its texts and sound. Made from the day times of milestone 2.
- **Adhan recording**: the full adhan, its Fajr variant, and the clip of each for iOS, with the
  name shown on the media notification ("Adhan of Makkah").
- **Prayer log entry** (from milestone 4): a prayer on a date marked prayed, written by Mark
  prayed.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: With notifications and alarms allowed, every adhan notification arrives within 1
  minute of its prayer time, with the app closed and in airplane mode, on iOS and Android.
- **SC-002**: After the app is opened once, every prayer of the next 6 days gets its notification
  without opening the app again.
- **SC-003**: After a change of location, method, sound, reminder, language or time zone, 100% of
  pending notifications match the new times and texts, none is left from before.
- **SC-004**: Stop silences the adhan within half a second, on the adhan screen and the media
  notification.
- **SC-005**: Marking a prayer from a notification takes one tap and no app launch, and the prayer
  shows as prayed the next time Home or Prayer opens.
- **SC-006**: The adhan screen in the design scenario matches 4.03 within 1 pt, in English and
  Arabic, text scale 1.0 and 2.0, reduce motion on and off.
- **SC-007**: A refused permission never causes an error or a crash, and the rest of the app works
  the same.
- **SC-008**: On iOS no more than 64 notifications are ever pending.

## Assumptions

- Milestones 3 and 4 are built first. Mark prayed writes to the prayer log from milestone 4, the
  Prayer tab at a prayer and day is reached the way milestone 4 builds it.
- None of the audio is in the handoff. The Makkah adhan, its Fajr variant, their iOS clips (30
  seconds or less), the Tone sound and the reminder sound (Brand: an unpitched breath, 500 ms) are
  placeholders with a `TODO(ahmed)` until I supply licensed files. Until then Tone and the Android
  reminder use the phone's default notification sound.
- The full dua after the adhan is not in the handoff either. Its text, transliteration and
  translation get a `TODO(ahmed)` for me to check. The sheet has no exact design, I approve it from
  the screenshots.
- The design scenario shows 4.03's fixed progress (0:42 of 2:56) only for the PNG check. The real
  progress comes from the recording, and the Brand board lists the Makkah adhan at 3:52.
- System surfaces (the notifications in 5.1 and the media notification in 5.2) are drawn by the
  phone. They match the design in what an app controls (texts, actions, icon, sound, order), not
  pixel for pixel.
- When the app is in front at a Tone or Silent prayer, the notification shows as a banner like
  any other, with no adhan screen.
- Reminders come for all five prayers whatever their sound, since 4.12 has one reminder for every
  prayer. There is no notification for sunrise, and no Jumu'ah wording on Friday.
- No "open the app" notification when the 6 day window runs out on iOS. The code that ends the
  window gets a `TODO(ahmed)`, I may design that last message later.
- The recording picker (Makkah, Madinah, Al-Aqsa, Cairo, Istanbul, Takbir only) comes with the
  "Adhan and reminders" page in milestone 9. Azkar nudges come in milestone 8, widgets, Live
  Activity and Dynamic Island in milestone 11.
- No full screen alarm over the lock screen on Android. Google Play allows that only for calling
  and alarm apps, the media notification covers it.
- The plan names the packages. Starting the full adhan in the background on Android probably needs
  one package outside the constitution's list, it gets checked on pub.dev and asked about in the
  plan.
- No network in this milestone. Notifications, sounds and texts are all on the phone.
