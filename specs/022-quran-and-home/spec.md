# Feature Specification: Quran and Home

**Feature Branch**: `feature/quran-reading`

**Created**: 2026-11-11

**Status**: Built, waiting for my review (grilled once, Q1 to Q14, all recommendations, the surah info dropped)

**Input**:

```text
- i want to make small qubla in home page above the countdown
- is when i open the quran page, is it load all quran pages or the single one for tapped one?
  and how we can improve it as it's feel so slow
- when tap on ayah it's open the quran page and the ayah bottom sheet, almost at the same, so
  make it seperated, open the quran and wait 2 seconds then show the bottom sheet
- make the share bottom sheet for quran follow the quran theme not the app
- only move to the next/previous page only if tapped area in the 40 px
- the flipping of pages, get a little glitch, if you can imporve it make it
- the display bottom sheet, remove the blur for this
- add third option 4:5 for shared ayah or dua
```

The reader loads one page, not the Quran: the tapped page, then two each side one per frame
once it is open.

## Decisions

### Home qibla

- A small live dial in the Next prayer card's top end corner, above the countdown. In English
  the arabic prayer name stays in that row, before it.
- The needle points to the Kaaba as the phone turns, primary when aligned, no haptic. A tap
  opens the Qibla page.
- Hidden with no saved place or no compass. The saved place only, never a GPS fix from Home.
- The compass runs only while Home is the shown tab, the card is on screen and the app is in
  front, and redraws only on a move of 1° or more. Constitution III says it, 5.4.0.
- The qibla math and the compass move to `core/qibla/`, Home and Qibla both need them.

### Reader speed

- The page's labels for screen readers, and the translation they read, only while a screen
  reader is on.
- While the Quran tab is on screen, the last read page and its page font load in the
  background.
- A tapped surah, search result or bookmark starts loading its page on the finger down.
- Timeline markers around the page load, the font load and the first layout, for a profile run.

### Opening at an ayah

- The ayah is washed as soon as the page shows. The Ayah sheet rises 500 ms after the reader is
  open, on its own spring. A tap or a turn in between and it doesn't come. The same for a result
  of search from the reader.

### Share sheet

- The ayah share sheet opened from the reader is drawn in the page color, like the Display
  sheet. The card keeps its own backgrounds. Dua share stays in the app's theme.
- A third size, Portrait (4:5, 1080 x 1350), between Square and Story, for ayahs and duas. The
  fit grows Square, Portrait, Story. A size picked by hand stays.

### Turning

- The Turn strips are 40 pt from the screen's edge in both layouts, the whole height in Mushaf,
  the top half in Translation.
- A swipe turns on its speed only after it went 40 pt, a sloppy tap never turns.
- The leaf's picture is taken while the reader is idle after a landing, never in a turn's first
  frame, and the page two away is laid out only while no turn runs.

### Display sheet

- No blur behind it, the light scrim stays. The Mushaf style and Translation sheets opened from
  it are clear too.
