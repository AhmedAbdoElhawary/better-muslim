# Feature Specification: Player, downloads and adhan switches

**Feature Branch**: `feature/quran-reading`

**Created**: 2026-11-13

**Status**: Built, waiting for my review (grilled once, Q1 to Q11, all recommendations)

**Input**:

```text
- when tap on play reader, retry to play again, and if anything failed show a message, every time
- in some cases the reader's sound gets echo and glitches. load before playing if needed, but show
  the loading in the play button
- the seconds count while playing goes back one second and then forward, not smooth
- a progress bar notification for every download, static, with pause and cancel, popup on start
- dhuhr, fajr, last third and isha inside the half circle
- everything works when I change the phone clock by hand
- adhan: stop it when the phone is flipped, stop it with any button, silent phone during prayer
```

## Decisions

### Recitation

- After a failure the mini player and the sheet stay up with the play icon. Every tap on play
  tries again from the ayah that failed to the end of the range, every failure shows its toast
  again. ✕ still closes it.
- Loading for 15 s with nothing coming in is a failure too.
- mp3quran timings that start before the last ayah ends are trimmed, so no ayah plays the end
  of the one before (the echo). If the echo is the stream, the surah-file reciters download the
  surah before the first ayah, the play button shows the loader with its progress.
- The shown time never goes back inside one ayah, only a seek, next, previous or repeat resets
  it.

### Download notification (Android)

- Mushaf styles, tafsirs, a reciter's surah and adhan recordings. Not the ayah files while
  playing, not dua clips. iOS keeps the progress in the app.
- A data sync foreground service keeps it going in the background and with the screen off.
  Swiping the app away cancels it.
- Pops up once, then updates quietly: the bar, the percent and "34 / 135 MB". Pause and Cancel,
  paused it has Resume and Cancel and goes on from the part on the phone.
- Clear all never removes it. Android 14 lets a swipe hide it, the next update brings it back.
- Done, it goes. Failed, it turns into a "Couldn't download" one that can be swiped away.

### Home arc

- Dhuhr, asr, isha, last third and fajr sit inside the arc in both languages. Sunrise and
  maghrib stay under the horizon. Two labels that would touch show only their time.

### Phone clock

- The same in every flavor. A clock or zone change sets the adhan alarms again. An alarm more
  than 20 minutes late (the now window) stays quiet and posts nothing. The app redoes the rest
  when it comes back. Reverses 021's "changing the clock by hand stays unsupported".

### Adhan switches (Android)

- A section on Adhan and reminders under the prayers, hidden on iOS. Stop is the Stop adhan
  button: silent at once, the prayer's notification stays to mark.
- Flip to stop the adhan, on by default: face down for half a second, the sensor runs only while
  the full adhan plays.
- Buttons stop the adhan, on by default: volume up or down, or power when it turns the screen
  off, or on more than 2 s after the adhan started.
- Silent during prayer, off by default: the phone's own Do Not Disturb, needs Do Not Disturb
  access. Starts when the prayer's sound is done (the adhan's end or Stop, a minute after the
  time otherwise), ends 20 minutes after the time (10, 15, 20, 30, 45, 60), Friday's dhuhr at
  least 60. Only ends a Do Not Disturb the app turned on, leaves one already on alone.
