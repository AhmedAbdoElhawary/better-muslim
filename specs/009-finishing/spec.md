# Feature Specification: Finishing pass

**Feature Branch**: `feature/enhancements-2`

**Created**: 2026-10-27

**Status**: Clarified

**Input**: User description, my notes after running 008:

```text
Mushaf page:
    - the mushaf page it's a has a lot of junk frames, when i initially open the mushaf, it's getting a lot of junk frames,and keeps junky when bottom sheets appear or zoom out and appear mushaf app bar and navigation bar for mushaf
    - i want when tap on translation tab show both main mushaf page and translation under it normally
    - i want to let me make the font of mushaf page verses itself bigger or smaller, let me cosmize it, as maybe the font is to small or bigger for some users and want to make it bigger or smaller. make it in display bottom sheet
    - choose another font rather than KFG hafs as it's the same as amiri quran font

- i want to save and show the praying track in the calander tab in praying time tab (show the status of praying)
    - also if user pray the five prayers, add some color for that day on the calander, if i looked to the previous month i can see what the days i fully prayed for it and what not fully with colors

- just tell me how "Your data" section in more works
- i want to solve all todo, to make the app finished
```

The reader stops dropping frames on open and on every turn, gets a mushaf size and the real
KFGQPC font. Translation shows the page with its translations under it. The calendar shows how
each day was prayed. Every `TODO` I can close without my own files is closed.

## Clarifications

### Session 2026-10-27

- Q: The jank? → A: Measured in profile mode on my phone, the real causes fixed. The phone wasn't
  plugged in, so the build fixes what the code shows: every open lays out three pages in one
  frame, each page measures every word twice, and a surah change decodes its json again.
- Q: The glass over the mushaf? → A: May become a solid see-through tint over the mushaf only, and
  only if the profile shows the blur is the cause. Waits for the profile.
- Q: Translation tab? → A: Display → Layout. Translation is the mushaf page at its full height with
  the translations under it, one normal scroll. Both goes away, a saved Both becomes Translation.
- Q: Mushaf size? → A: A stepper in Display, the translation sizes' control, 80% to 150% in 10%
  steps. 100% is the printed page. Smaller keeps the 15 lines with wider margins. Bigger rewraps
  the same page's ayahs into lines that scroll down inside the page, and the page still turns,
  keeps last read and takes taps.
- Q: Font? → A: The real KFGQPC HAFS Uthmanic Script v18 from the King Fahd Complex (free to use
  and ship unmodified). It becomes the default for new installs, with its credit.
- Q: Prayer calendar? → A: The Hijri calendar in More colors its days and its day details show the
  five prayers. The Prayer tab opens it from a calendar button in its header (it has no month
  title).
- Q: Colors? → A: All five prayed: filled with `primaryContainer`. One to four: a thin primary
  outline. None: nothing. Today and future days: nothing.
- Q: Qada? → A: Doesn't count. Only the day's log, the same as the week strip dots.
- Q: TODOs I can do? → A: Listen on the Quran tab, the dua after the adhan checked against
  Bukhari 614, no `API_BASE_URL` (no backend), EveryAyah Alafasy stays the recitation, a last
  "open the app" notification when the iOS schedule runs out.
- Q: Tafsir release (T081)? → A: Run both `gh` commands, the public `better-muslim-content` repo.
- Q: Azkar and duas? → A: Arabic and sources from Hisn al-Muslim. The English stays a
  `TODO(ahmed)` until I pick a translation I may use.
- Q: Contrast misses? → A: A slightly stronger scrim behind that text, the skipped tests run again.

## User Scenarios & Testing

### US1, a smooth reader

Opening the reader lays out only the shown page in its first frame, its neighbours one per frame
after. A page measures its words once. Turning across a surah boundary doesn't decode a surah
again.

- Opening page 50 builds page 50 first, 49 and 51 in the next frames.
- A page laid out at any size measures each word once.

### US2, Translation with the page

- Translation shows the page at the screen's height, then the cells. Arabic and translation sizes
  stay in Display.
- A store with `both` opens on Translation.

### US3, mushaf size

- Display has Mushaf size with − and +, the value in percent, in every layout.
- 80% and 90% keep the 15 lines, narrower and centered.
- 110% to 150%: the page's words flow into full lines, a surah name and the basmallah keep their
  own lines, the page scrolls down. Taps, the wash, long press and screen readers still find the
  ayahs. The ayah sheet keeps its ayah above it, the recitation scrolls to the playing ayah.

### US4, KFGQPC

- KFGQPC in Display draws the King Fahd font, clearly unlike Amiri Quran.
- A new install starts on it. Credits name it with its license.

### US5, prayer calendar

- A day with all five logged is filled, one to four is outlined, in both Hijri and Gregorian
  mode, back to the first month.
- The day details show the five dots for today and past days.
- The Prayer tab's calendar button opens the calendar.

### US6, TODOs

- Listen plays from the last read ayah.
- No `TODO(ahmed)` left for anything that doesn't need my files, my accounts or the store.

## Approved breaks

- Mushaf size above 100% doesn't keep the printed line breaks.
- The Prayer header gets a calendar button the handoff doesn't draw.
