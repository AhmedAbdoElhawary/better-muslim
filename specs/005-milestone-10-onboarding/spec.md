# Feature Specification: Milestone 10, Onboarding and Backup

**Feature Branch**: `feature/milestone-10`, cut when the build starts, after milestone 9

**Created**: 2026-10-19

**Status**: Clarified

**Input**: User description: "milestone 10 and i want to make the onboarding animated and most like
inpired from this "/Users/ahmedelhawary/Documents/side_projects/flutter_projects/projects/liquid_glass_onboarding""

Milestone 10 is the first launch: the welcome (4.10), location (4.11), notifications (4.12) and the
theme step (4.15 without its back button), plus the app's own backup file that "Restore from backup"
needs. The three screens are built straight from the handoff specs. The motion is new and borrows
from my `liquid_glass_onboarding` project: the sun is a ball of liquid glass. A new first screen
shows it as a big glass dome at the bottom, I drag it up past the horizon and let go, and 4.10
builds out of it. This spec covers what the handoff doesn't: the new first screen, the sunrise
gesture and its choreography, how each step moves to the next, what a refused permission does, the
backup file and the notice after a store reset.

## Clarifications

### Session 2026-10-19

- Q: How does the liquid glass come in? → A: A new first screen before 4.10, like the reference's
  first screen: the sky at the current hour, a headline, the sun as a big glass dome at the bottom
  and "Swipe up to begin". Dragging the sun up past the horizon and letting go builds 4.10 out of
  it. Dragging it back down on 4.10 goes back to the first screen.
- Q: The sun once it settles on 4.10? → A: Glass while held, it fills with the sun's color as it
  settles, so 4.10 ends exactly as designed.
- Q: What comes out of the orb, where the reference has its balls? → A: 4.10's ten stars fly out of
  the sun to their places, then twinkle.
- Q: The steps after 4.10? → A: The sun stays on the welcome. Each step builds in the same order as
  4.10, the step dots slide, Apply on the theme step crossfades into Home in 300 ms. Back goes to
  the previous step.
- Q: The headline on the new screen? → A: "Every prayer, in its time." / "كل صلاة في وقتها". Not the
  Bismillah, it's Quran text and the glass would bend and blur it.
- Q: Restore from backup? → A: The backup file comes in this milestone: Back up and Restore in
  More › YOUR DATA, Restore on 4.10, and the store reset notice over 4.10. The file is locked with a
  password I choose. `file_picker` is approved for picking the file.
- Q: Who sees onboarding? → A: Installs that never finished it. An install from before this
  milestone with a saved location counts as finished. A dev only "Replay onboarding" row on the dev
  page.
- Q: Location refused on 4.11? → A: The city search opens at once, 4.11 can't be left without a
  place.
- Q: Order and branch? → A: Spec, plan and tasks now on `feature/milestone-9`, `feature/milestone-10`
  cut when the build starts.
- Q: Should the launch animation on later cold starts (Motion 01) be built in this milestone? → A:
  No. It stays open, to decide after milestone 11 with real cold start times.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Raise the sun to begin (Priority: P1)

First launch. I see the sky, one line of text, and the sun as a big glass dome at the bottom. I put
my finger on it and pull it up. It follows me, gets smaller as it rises and bends the words behind
it. Past the horizon it says "Let go to begin". I let go, it springs onto the horizon and the
welcome builds out of it: "Better Muslim" sliding out of it, the horizon and the mark, the stars
flying out of the sun, the tagline, then the buttons.

**Why this priority**: It is the first thing anyone sees and the reason for this milestone's
motion. Without onboarding the app opens on Home and throws two system dialogs at a new user.

**Independent Test**: Fresh install of Dev. The first screen shows the dome and "Swipe up to begin".
Drag the sun halfway and let go: it sinks back. Drag it past the horizon: "Let go to begin" shows
with a tick. Let go: 4.10 builds and ends as its tree. Drag the sun down past the line and let go:
the first screen comes back. Turn on Reduce motion and reinstall: tap the hint, 4.10 crossfades in.

**Acceptance Scenarios**:

1. **Given** a first launch, **When** the app opens, **Then** the first screen shows the sky at the
   current hour, the headline, the sun as a glass dome rising from the bottom edge and "Swipe up to
   begin".
2. **Given** I hold the sun, **When** I drag, **Then** it follows my finger anywhere on the screen,
   its size depends only on its height, the glass bends what is behind it, a glow arc in the
   theme's glow color lights while I lift it, and the headline blurs out.
3. **Given** I hold the sun, **When** it crosses the horizon, **Then** "Let go to begin" shows with
   a selection haptic, and hides again if I bring it back below.
4. **Given** the sun above the horizon, **When** I let go, or flick it up, **Then** it springs onto
   the horizon with a light haptic and the welcome builds.
5. **Given** the sun below the horizon, **When** I let go, **Then** it springs back into the dome
   and nothing else changes.
6. **Given** 4.10, **When** I drag the sun down past the line and let go, or flick it down, **Then**
   the welcome fades with my finger, the sun sinks into the dome, the stars fade and the first
   screen comes back. Let go before the line: the sun springs back and the welcome builds again.
7. **Given** a screen reader or a plain tap, **When** I tap the sun or "Swipe up to begin",
   **Then** the welcome builds just as after a drag.
8. **Given** 4.10, **When** I press the system back, **Then** the sun sinks into the dome and the
   first screen comes back. On the first screen back leaves the app.

---

### User Story 2 - Set up where I am and how prayers reach me (Priority: P1)

I tap Get started. Step 1 says why the app needs my location, I use my location or pick a city.
Step 2 shows today's five times there with Adhan, Tone or Silent for each, I keep the defaults,
change the reminder and allow notifications. Step 3 is the theme, I pick one and Apply. I'm on Home
with my times, my sounds and my theme, and the phone asked each permission once, right after a
screen that said why.

**Why this priority**: Without a place there are no times, without the permission no adhan. The
primers replace the bare system dialogs milestones 2 and 5 show at launch now.

**Independent Test**: Fresh install, raise the sun, Get started: 4.11 builds with the first step
dot. Use my location, allow: 4.12 builds with today's times there. Set Dhuhr to Silent, the reminder
to 15, Allow notifications, allow: the theme step builds. Pick Iznik, Apply: Home in Iznik, Adhan
and reminders shows Dhuhr on Silent and 15 min. Restart: Home opens directly.

**Acceptance Scenarios**:

1. **Given** 4.10, **When** I tap Get started, **Then** the welcome fades out in reverse order and
   4.11 builds: icon, title, body, the three rows, then the buttons, with the first dot wide.
2. **Given** 4.11, **When** I tap Use my location and allow it, **Then** the place is found and
   named and 4.12 builds.
3. **Given** 4.11, **When** location is refused or the position can't be found, **Then** the city
   search opens at once with a line saying why. A city goes on to 4.12, closing the search without
   one stays on 4.11.
4. **Given** 4.11, **When** I tap Choose a city instead and pick one, **Then** 4.12 builds.
5. **Given** 4.12, **When** it opens, **Then** each prayer shows today's time at my place and its
   choice, Adhan for Fajr and Maghrib and Tone for the rest by default, and the reminder row shows
   "10 min".
6. **Given** 4.12, **When** I change a segment or the reminder, **Then** it is kept at once, the
   segment with the toggle haptic, the reminder through the reminder sheet.
7. **Given** 4.12, **When** I tap Allow notifications, **Then** the phone asks (and on Android 12 or
   later the alarms page follows once, as in milestone 5), and the theme step builds whatever I
   answer.
8. **Given** 4.12, **When** I tap Not now, **Then** nothing is asked, the choices stay and the theme
   step builds.
9. **Given** the theme step, **When** I tap Apply theme, **Then** the theme and mode are saved,
   onboarding is finished and the app crossfades into Home in 300 ms.
10. **Given** any step, **When** I go back with the system back or the edge swipe, **Then** the
    previous step shows: theme to 4.12 to 4.11 to 4.10 with the sun settled.
11. **Given** onboarding finished, **When** the app opens again, **Then** Home opens directly and no
    system dialog shows at launch.

---

### User Story 3 - Move my data to a new phone (Priority: P2)

Before I change phones I tap Back up in More, choose a password and save the file to Files or
Drive. On the new phone I raise the sun, tap Restore from backup, pick the file and type the
password. My prayer log, qada, settings, azkar progress and saved duas are back, and the steps ask
this phone's permissions with my old choices already picked.

**Why this priority**: The store stays out of iCloud and Android backup (milestone 2), so this file
is the only way data moves to a new phone. Milestones 2, 4, 8 and 9 all point here.

**Independent Test**: Log some prayers, add qada, save a dua, apply Iznik, Back up with "test1234"
and save it to Files. Delete the app and reinstall. Raise the sun, Restore from backup, pick the
file. Wrong password: one line says so. Right password: the steps follow with Iznik and my sounds
picked, Home shows my log and qada, Duas shows the saved one.

**Acceptance Scenarios**:

1. **Given** More › YOUR DATA, **When** I tap Back up, **Then** a sheet asks for a password twice
   and says it can't be recovered. Save backup makes the file and opens the phone's share sheet.
2. **Given** Restore from backup on 4.10 or in More, **When** I tap it, **Then** the phone's file
   picker opens, and after a file is picked a sheet asks for its password.
3. **Given** the right password in More, **When** I tap Restore, **Then** a dialog asks first, and
   Restore replaces the data on this phone, everything updates and a toast says it's restored.
4. **Given** the right password on 4.10, **When** I tap Restore, **Then** the data is restored with
   no dialog and the steps follow with the backup's choices picked.
5. **Given** a wrong password, a file that isn't a backup or a damaged one, **When** I tap Restore,
   **Then** the sheet says which in one line and nothing changes.
6. **Given** a backup made by a newer version of the app, **When** I restore it, **Then** it says
   to update the app first and nothing changes.

---

### User Story 4 - Told once when my data was lost (Priority: P3)

If the app couldn't open its saved data it started fresh (milestone 2). The next time I see the
welcome, it tells me once and offers to restore.

**Why this priority**: Milestone 2 keeps a flag for this since FR-024, waiting for this screen.

**Independent Test**: In Dev, break the store and open the app: onboarding shows. Raise the sun:
when 4.10 has built, the notice shows. Start fresh: it closes and never shows again.

**Acceptance Scenarios**:

1. **Given** a store reset happened, **When** 4.10 has built, **Then** a dialog says the saved data
   couldn't be opened and the app started fresh, with Restore from backup and Start fresh.
2. **Given** the notice, **When** I tap Restore from backup, **Then** the restore goes as from 4.10.
   **When** I tap Start fresh, **Then** it closes. Either way it never shows again.

---

### Edge Cases

- A drag on the sun while the welcome builds: the build stops where it is and the sun follows the
  finger, as in the reference.
- A tap anywhere during a build finishes it at once. Buttons work as soon as they show.
- A second finger while dragging: the first finger keeps the sun.
- The app goes to the background mid drag: the drag ends as a release with no speed, the sun
  springs to its rest spot.
- The app is closed mid onboarding: the next launch starts at the first screen again. What was
  already chosen (the place, the sounds, the theme) is kept and shows picked.
- Location refused before, so the phone no longer asks: Use my location opens the city search at
  once, like a refusal.
- Approximate location (iOS precise location off): it is used. Within 30 km the times differ by
  about a minute.
- The search finds the place but times can't be made for a day (high latitude): milestone 2's
  automatic rule handles it, 4.12 shows its times as Home would.
- Notifications already allowed, as on Android 12 and older: Allow notifications goes on without a
  dialog (and Android 12 still gets the alarms page once).
- Not now, then later turning notifications on: Adhan and reminders shows its "off" line. On a phone
  that never asked, its button asks the system first, after that it opens the phone's settings.
- A sky without stars (daytime): the stars still fly out of the sun and settle at the sky's star
  brightness, so in a day sky they fade as they land.
- Text scale 2.0: the headline, title and tagline wrap, 4.11 and 4.12 scroll with their buttons
  kept at the bottom, nothing is cut. The sun's path and the horizon don't move with text scale.
- Arabic: every screen follows its tree with the RTL rules, the sun's gesture is the same, times use
  the digits setting. Above 1.4 text scale 4.12's rows stack like the prayer rows.
- 12 hour phones: 4.12's times fit "5:56 PM".
- A phone that can't run the glass effect: a frosted glass with the same motion, nothing else
  changes.
- Backup with nothing logged yet: allowed, the file restores the settings.
- A backup from iOS restored on Android or the other way: works, the file is the same on both.
- A backup in auto location mode restored on a new phone: the place stays until this phone finds
  its own position (after the location step).
- A restore while the app has notifications pending: they are all remade from the restored choices.
- Restoring never changes the language, it follows the phone.

## Requirements *(mandatory)*

### Functional Requirements

**Who sees it**

- **FR-001**: Onboarding MUST show at launch until it has been finished once, and never after.
  Finished means Apply on the theme step. An install from before this milestone that has a saved
  location MUST count as finished.
- **FR-002**: The app MUST NOT show the system location or notification dialog at launch any more.
  The primers ask them (this replaces milestone 2 FR-001 and milestone 5 FR-004). Home's no
  location card and the Qibla's ask stay as they are.
- **FR-003**: Leaving the app during onboarding and opening it again MUST start at the first screen,
  keeping what was already chosen.
- **FR-004**: In dev builds the dev page MUST get "Replay onboarding", which shows onboarding again
  from the first screen without clearing anything. Staging and production MUST NOT have it. In the
  design scenario onboarding counts as finished, and Replay shows it with the scenario's values.

**The first screen** (new, no PNG)

- **FR-005**: The first screen MUST show 4.10's sky at the current hour without its stars (they
  come out of the sun later), the headline centred in the display font above the middle, the sun as
  a glass dome rising from the bottom edge (its radius 0.55 of the screen width, its top at 0.745
  of the screen height) and "Swipe up to begin" near the bottom. It is built only from
  4.10's parts and the components board, and I check it in the app.
- **FR-006**: On first launch the first screen MUST enter from the splash within 1200 ms: the sky
  crossfades in, the dome rises into place from below the edge, then the headline and the hint fade
  in.
- **FR-007**: The glass MUST work like the lens in my `liquid_glass_onboarding` project: a magnified
  middle, a rim that bends and flips what is behind it, colour fringes at the edge, a soft shadow, a
  highlight, a bright rim, and squash and stretch along its motion. Its glow arc uses the theme's
  glow color instead of the reference's blue. A phone that can't run the effect, and the tests,
  MUST get a frosted glass with the same size, motion and rim.
- **FR-008**: Holding the sun MUST make it follow the finger anywhere on the screen without a jump
  at the grab (it catches up over the first 180 pt of travel). Its size MUST depend only on its
  height: the dome at its rest spot, smaller as it rises, the size of 4.10's sun at the horizon and
  above. The glass MUST warm toward the sun's color as it rises.
- **FR-009**: While the sun is held, the headline MUST blur and fade out as it rises, "Swipe up to
  begin" fades, and the glow arc lights quickly then fades as the sun gets small. Above the horizon
  "Let go to begin" MUST show under the middle with a selection haptic, and hide below it.
- **FR-010**: Letting go above the horizon, or a flick up faster than 1200 pt/s once the sun has
  left the dome, MUST start the welcome with a light haptic. Letting go anywhere else MUST spring
  the sun back into the dome. The springs carry the release speed and overshoot softly.
- **FR-011**: Tapping the sun or "Swipe up to begin" MUST start the welcome too. A screen reader
  MUST hear the sun with its hint and a tap action.

**The welcome (4.10)**

- **FR-012**: 4.10 MUST end exactly as its tree: the Living Sky at the current hour with its stars,
  the horizon, the dotted sun arc, the mark, the half risen sun, the title, the tagline, Get started
  and Restore from backup. In the design scenario it shows the theme's base sky.
- **FR-013**: The welcome MUST build within 1800 ms of the sun being let go. Its parts overlap and
  start in this order: the sun springs onto the horizon; "Better Muslim" starts inside the sun,
  bent by it, and slides down to its place as it fades in; the horizon draws out from the middle
  with the dotted arc; the mark fades and scales in; the sun fills with the sun's color and settles
  half below the horizon; from about a third of the way the ten stars fly out of the sun to their
  places and start twinkling; the tagline fades in and goes from faint to full; then Get started
  and Restore from backup fade in rising 14 pt, one after the other.
- **FR-014**: On 4.10 the sun MUST stay draggable. Held, it turns back to glass. Dragged toward the
  bottom, the welcome fades with the finger, with a selection haptic at the commit line (45% into
  the bottom zone). Letting go past the line, or a flick down faster than 900 pt/s, MUST sink the
  sun into the dome with a short glow flash, fade the stars over 1.4 s and bring the first screen
  back. Letting go before the line MUST spring the sun back and build the welcome again.
- **FR-015**: Get started MUST fade the welcome's content out in reverse build order (buttons first)
  while the sky gives way to the step background, both in 300 ms, then build 4.11. Coming back
  from 4.11 fades it in again the other way.

**The steps**

- **FR-016**: 4.11 and 4.12 MUST be built from their trees with the three step dots at the top, the
  current one wide. The theme step MUST be the 4.15 tree without its back button. Arabic follows the
  same trees with the RTL rules.
- **FR-017**: Each step MUST build within 900 ms in reading order: the title rises 14 pt and fades
  in, the body fades in, the cards or rows follow one after another, then the buttons rise 14 pt
  and fade in. The wide dot slides to the new step. Leaving a step fades its content out in 150 ms.
- **FR-018**: The system back and the edge swipe MUST go to the previous step: theme to 4.12 to 4.11
  to 4.10, built, with the sun settled. On 4.10 back sinks the sun to the first screen, as a drag
  past the line does. On the first screen back leaves the app.

**Location step (4.11)**

- **FR-019**: Use my location MUST ask the phone for location "while using", find and name the place
  the milestone 2 way, keep it in auto mode and go on to 4.12. While it looks, the button shows it is
  working and can't be tapped twice.
- **FR-020**: When location is refused, now or before, or the position can't be found, the city
  search (milestone 3's location sheet) MUST open at once with the existing "Couldn't get your
  location" line. A city is kept in manual mode and goes on to 4.12, closing the search without one
  stays on 4.11.
- **FR-021**: Choose a city instead MUST open the same city search, a city goes on to 4.12.

**Notifications step (4.12)**

- **FR-022**: 4.12 MUST show the five prayers with today's times at the chosen place and the saved
  choice for each (by default Adhan for Fajr and Maghrib, Tone for the rest), and the reminder row
  with its value ("10 min" by default, "Off" for 0).
- **FR-023**: A segment change MUST be kept at once with the toggle haptic. The reminder row MUST
  open milestone 9's reminder sheet (0 to 30 minutes in 5 minute steps).
- **FR-024**: Allow notifications MUST show the phone's dialog (then the alarms page once on
  Android 12 and later, milestone 5 FR-005) and go on to the theme step whatever the answer. Where
  notifications are already allowed it shows no notification dialog, and the alarms page still
  comes once where Android needs it.
- **FR-025**: Not now MUST go on to the theme step without any dialog and keep the choices.
- **FR-026**: Adhan and reminders' "off" line (milestone 9 FR-030) MUST show the phone's dialog on
  its first tap when the phone has never asked, and open the phone's settings after that.

**Theme step**

- **FR-027**: The theme step MUST open on the saved theme and mode (by default Qiyam Emerald and
  Follow sky). Apply theme MUST save both, finish onboarding and crossfade into Home in 300 ms, on
  the Home tab.

**Backup file**

- **FR-028**: More › YOUR DATA MUST get "Back up" and "Restore from backup" above Reset prayer
  journey, from the same grouped rows.
- **FR-029**: Back up MUST open a sheet with a password field and a confirm field (03 Inputs) and the
  line that the password can't be recovered. Save backup is enabled once both match and have at
  least 6 characters. It makes one file named with the app and the date and opens the phone's share
  sheet to save or send it.
- **FR-030**: The file MUST hold everything the app keeps: the settings with the place, the prayer
  log, the qada entries, the azkar progress, the tasbih count and the saved duas. What belongs to
  the phone (which permissions were asked, the reset notice, onboarding finished) MUST NOT be in it.
  It MUST be locked with the password, so nothing in it can be read without it. The app sends it
  nowhere by itself.
- **FR-031**: Restore from backup (on 4.10, in More, or from the reset notice) MUST open the phone's
  file picker, then a sheet asking for the password. A wrong password, a file that isn't a Better
  Muslim backup or a damaged one MUST show its own line in the sheet (03 Inputs error) and change
  nothing.
- **FR-032**: From More, the right password MUST first show a dialog ("Restore this backup?", it
  replaces everything on this phone and can't be undone) with Cancel and Restore. Restore MUST
  replace all the data at once, all or nothing, update every screen, remake the notifications and
  show a toast.
- **FR-033**: From 4.10 or the reset notice, the right password MUST restore with no dialog (there is
  nothing to lose yet) and go on to 4.11, with the backup's choices picked on every step.
- **FR-034**: A backup from a newer version of the app MUST be refused with its own line. A backup
  from an older version MUST restore, upgraded the same way the store is on an update.
- **FR-035**: Making and restoring a backup MUST work with no internet.

**Store reset notice**

- **FR-036**: When the store was reset (milestone 2 FR-024), a dialog MUST show once 4.10 has built:
  the saved data couldn't be opened and the app started fresh, with Restore from backup and Start
  fresh. Either one clears the flag, so it shows only once.

**Motion and access**

- **FR-037**: With Reduce motion (the phone's or the app's) the sun MUST still drag, with no squash
  and stretch. The first screen's entrance is a 300 ms fade in place (the dome doesn't rise). The
  welcome and each step crossfade in 300 ms, the stars fade in place in 300 ms with no flight, the
  springs settle in 300 ms with no overshoot, and the haptics still fire. The ambient loops stop:
  the stars stay still at their brightness, the sun doesn't breathe, the sky doesn't drift.
- **FR-038**: Haptics MUST be a selection when the sun crosses the horizon on the first screen and
  the commit line on 4.10, and a light one when the welcome starts and when the sun sinks back. All
  stopped by the Haptics switch in More. None during the builds.
- **FR-039**: The stars twinkle, the sun breathes and the sky drifts on 4.10 as in the handoff's
  ambient table, paused in the background, in Low Power Mode and Battery Saver, and stopped with
  Reduce motion (FR-037).
- **FR-040**: Every button, row, segment and the sun's grab area MUST be at least 44 x 44. A screen
  reader MUST hear the step ("Step 1 of 3"), each row, and each segment's state.
- **FR-041**: Nothing in this milestone uses the network. The place found stays on the phone. The
  backup leaves the phone only where I send it from the share sheet.

**Copy**

- **FR-042**: Every new string MUST exist in English and Arabic with this wording:

  | Where | English | Arabic |
  | --- | --- | --- |
  | first screen headline | Every prayer, in its time. | كل صلاة في وقتها |
  | first screen hint | Swipe up to begin | اسحب للأعلى لتبدأ |
  | while held above the horizon | Let go to begin | أفلت لتبدأ |
  | the sun, screen reader | Sun. Drag it up past the horizon and let go to begin. | الشمس. اسحبها فوق الأفق ثم أفلتها لتبدأ. |
  | the sun on 4.10, screen reader | Sun. Drag it down to go back. | الشمس. اسحبها للأسفل للرجوع. |
  | step dots, screen reader | Step {step} of {total} | الخطوة {step} من {total} |
  | row, sheet title | Back up | نسخ احتياطي |
  | field | Password | كلمة المرور |
  | field | Confirm password | تأكيد كلمة المرور |
  | sheet line | Keep this password safe. Without it the backup can't be opened. | احفظ كلمة المرور جيدًا، فلا يمكن فتح النسخة بدونها. |
  | field error | Use at least 6 characters. | استخدم ٦ أحرف على الأقل. |
  | field error | The passwords don't match. | كلمتا المرور غير متطابقتين. |
  | action | Save backup | حفظ النسخة |
  | restore sheet line | Enter the password you chose for this backup. | أدخل كلمة المرور التي اخترتها لهذه النسخة. |
  | action | Restore | استعادة |
  | restore error | Wrong password. Check it and try again. | كلمة المرور غير صحيحة. تحقق منها وحاول مجددًا. |
  | restore error | This file isn't a Better Muslim backup. | هذا الملف ليس نسخة احتياطية من مسلم أفضل. |
  | restore error | This backup is damaged and can't be opened. | هذه النسخة تالفة ولا يمكن فتحها. |
  | restore error | This backup is from a newer version. Update the app, then restore. | هذه النسخة من إصدار أحدث. حدّث التطبيق ثم استعدها. |
  | dialog | Restore this backup? | استعادة هذه النسخة؟ |
  | dialog body | It replaces everything on this phone. It can't be undone. | ستحل محل كل ما على هذا الهاتف، ولا يمكن التراجع عن ذلك. |
  | dialog actions | Cancel, Restore | إلغاء، استعادة |
  | toast | Backup restored | تمت استعادة النسخة |
  | reset notice | Your saved data couldn't be opened | تعذّر فتح بياناتك المحفوظة |
  | reset notice body | The app started fresh on this phone. If you have a backup, you can restore it now. | بدأ التطبيق من جديد على هذا الهاتف. إن كانت لديك نسخة احتياطية فيمكنك استعادتها الآن. |
  | reset notice actions | Restore from backup, Start fresh | استعادة من نسخة احتياطية، البدء من جديد |

  "Replay onboarding" is on the dev page only and stays English, like the rest of that page.

### Key Entities

- **Onboarding progress**: finished or not. Belongs to the phone, never in a backup.
- **Backup file**: everything the store keeps except what belongs to the phone, plus the app version
  and store version it was made with, locked with a password. One file per backup.
- **Store reset flag**: set by a store reset since milestone 2, cleared once the notice has shown.
- **Permission asked**: whether the phone has shown the notification dialog, since milestone 5.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A new user gets from the first screen to Home with a place, sounds and a theme in under
  one minute by taking the first choice on every step.
- **SC-002**: The drag and the builds run at the phone's full frame rate on a mid range Android from
  2021 (a Galaxy A52 class phone), with no frame over 16 ms in profile mode.
- **SC-003**: Each step ends built from its tree in dark and light, English and Arabic, text scale
  1.0 and 2.0, reduce motion on and off.
- **SC-004**: A backup made on one phone and restored on another gives back every logged prayer,
  qada entry, azkar count, saved dua and setting unchanged, in tests.
- **SC-005**: A wrong password, a foreign file or a damaged file never changes any data, in tests.
- **SC-006**: No prayer, place or date can be read from a backup file without its password, in
  tests.
- **SC-007**: After onboarding, no launch ever shows a system permission dialog.
- **SC-008**: Every step can be finished with a screen reader alone, including starting without the
  drag.

## Assumptions

- The launch animation on later cold starts (Motion 01) is out of this milestone. It ends as soon as
  data is ready, which today is before the first frame, so it is decided after milestone 11 with
  real cold start times. On first launch the first screen's entrance (FR-006) takes its place.
- The theme step keeps the 4.15 tree as it is apart from the back button, so it shows no step dots.
- The city search is milestone 3's location sheet, the reminder sheet milestone 9's, the segmented
  control milestone 9's. Onboarding reuses them, nothing is drawn twice.
- The first screen's layout follows the reference's proportions on a 393 pt phone, scaled like every
  other screen. It has no PNG, I check it in the app.
- The glass effect needs the newer graphics engine on iOS and current Android. Elsewhere the
  frosted glass shows.
- Mode follows the saved light and dark setting (Follow sky by default), so steps can be dark or
  light like the PNGs.
- The password has no recovery and no hint. Forgetting it means the backup can't be used.
- No automatic or scheduled backups and no "last backup" date in More, only Back up when I tap it.
- Downloaded recitations (milestone 7) will stay out of the backup, they can be downloaded again.
- No privacy policy or terms in onboarding until I write them (the constitution says ask me first).
