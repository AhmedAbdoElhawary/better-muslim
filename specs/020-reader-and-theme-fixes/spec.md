# Feature Specification: Reader and theme fixes

**Feature Branch**: `feature/quran-reading`

**Created**: 2026-11-10

**Status**: Built, waiting for my review (grilled once, Q1 to Q12, all recommendations, terms in `GLOSSARY.md`)

**Input**: my notes after using the app:

```text
- the mushaf style sheet drops frames when the style changes
- the ayah highlight a little shorter
- tafsir and note scale the page down, the page never scales
- the new category sheet glitches when it opens
- every sheet and sub sheet opens smoothly
- playing opens the full recitation sheet, not only the small card
- the bookmarked ayah: a bookmark shape centered on the separator, not an off center circle
- with translation on, follow the page or the translation, whichever I'm looking at
- 10 seconds between ayahs
- the end of a page turn leaves the shadow on the right for a moment
- theme page: follow phone and follow sky colored like dark and light, same padding, no shrinking
- why the hijri adjustment
- a tap on a toast dismisses it
```

## Decisions

### Sheets

- Every sheet opens on the handoff's MOTION 15 alone: spring.gentle in, 300 ms accelerate out,
  one slide. No overshoot and no backdrop blur, the scrim only dims.
- A sheet with a name field shows the keyboard only once it has landed.

### Reader

- A new Mushaf style shows on the page once its sheet has gone, in one step. The pages beside it
  follow one per frame.
- The ayah wash is 3 pt above and below the line's text (`SpaceManager.ayahWashV`), was 5.
- The page stays full size behind the tafsir and notes sheet, only the scrim dims it.
- Starting a recitation, from the reader's Listen, the Ayah sheet's Play or the Quran tab's
  Listen, opens the recitation sheet. Try again after a failure doesn't.
- A Bookmarked number has a ribbon behind it in its category's color, centered on the marker's
  ink in every Mushaf style and in the translation cells.
- In the Translation layout the recitation follows on the mushaf page while only the page is on
  screen, and the cells once any cell is on screen. It's decided at each new ayah.
- The pause between ayahs adds 10 s.
- A page turn's fold shadow fades out with the turn, nothing is left when it lands.

### Theme page

- Every mode not picked is drawn in text2, the picked one in text.
- A full width segmented control gives each segment its label's width and the same padding on both
  sides. Labels never shrink, they wrap to a second line when they can't fit.

### Other

- The Hijri adjustment stays. Umm al-Qura is calculated, a country that starts its months by
  sighting can be a day off, and Muslim Pro has the same setting.
- A tap on a toast dismisses it.
