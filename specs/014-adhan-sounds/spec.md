# Feature Specification: Adhan sounds

**Feature Branch**: `feature/quran-reading`

**Created**: 2026-11-08

**Status**: Clarified (grilled, Q1 to Q8, all recommendations)

## What I want

- The Takbir is a heads-up before the prayer, not a shorter adhan. It plays with the Reminder only.
- At the prayer time there is only the Full adhan, a tone or silence.
- The volume keys change the adhan while it plays.

| Prayer sound | Reminder | Prayer time |
| --- | --- | --- |
| Adhan | the Takbir | the Full adhan |
| Tone | the tone | the tone |
| Silent | no sound, the countdown shows | no sound, the notification shows |

## Decisions

### Adhan sound sheet

- The Full / Takbir switch goes. The sheet lists the recordings with their full length, a tap
  previews the Full adhan.
- One line under the list: "The takbir plays with the reminder, the full adhan at the prayer time."
- The Adhan sound row shows only the recording's name.
- A prayer saved as "Takbir only" becomes Adhan. The five length columns are dropped in db v26.

### Reminder

- With "Reminder before each prayer" off there is no Takbir anywhere, an Adhan prayer only plays
  the Full adhan at its time.
- Android: the countdown posts on the prayer's own channel, which already carries the Takbir, the
  tone or no sound. `prayer_reminders` is deleted, the phone's settings keep one entry per prayer.
  The Takbir follows the notification volume and a swipe stops it.
- iOS: the reminder sounds like the prayer (the Takbir clip, the tone or nothing) and is a time
  sensitive banner, no longer the quiet entry in the list. This replaces FR-035.

### Prayer time

- Android plays the Full adhan when it can. Without exact alarms, or on silent, vibrate or Do Not
  Disturb, the notification comes with no sound, never the Takbir.
- iOS can't play more than 30 s from a notification. With the app closed an Adhan prayer gets the
  phone's own sound, with the app in front the adhan screen plays the Full adhan. iOS ties the sound
  in front to the one in the background, so the phone's sound also plays as the adhan screen opens.

### Volume

- The Android Full adhan plays on the media volume, like the adhan screen and the Quran. The volume
  keys change it while it plays.
- No forced minimum: with the media volume at 0 the adhan is silent, with Bluetooth on it plays
  there.
