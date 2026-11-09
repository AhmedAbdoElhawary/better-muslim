# Feature Specification: Quran reading

**Feature Branch**: `feature/quran-reading`

**Created**: 2026-11-08

**Status**: Clarified (grilled, Q1 to Q15, all recommendations, terms in `GLOSSARY.md`, ADR 0003)

**Input**: my notes after reading in the app:

```text
- i want rather than add bookmark before the ayah, i want to colored the ayah with the bookmark color, and make the coloring like the shape of bookmark
- when i add a note for ayah, the hint color for the ayah, not set the text of ayah at the center of the hint coloring
- i want to change the taping for the quran: i want when tap on the left side of quran page (outside the the text of quran), move to next, and same when tap on right (outside the the text of quran), move to previous,
    and when tap on the page show the app bar and navigation bar, and when long tap or double tap on ayah, show the actions for this ayah, and also make a vibration
- and when tap on tranlsation, i want to scroll to the middle of page, and make the full quran page at the top of page center, and make the tanslation at the bottom of center of page
- i notice that, there is a lot of words that end with ة like بقرة make بقر aligned at the top of line and the ة at the bottom of it, means make the final line for the ayah broked
- there is a lot of white spaces between some words in quran, i want to not have a big gap between words in the whole quran, even the line not have a lot of words, you can streach alittle some words but not have a big gap between words
```

## What I want

- A bookmarked ayah reads as saved at a glance, in its category's color, without anything squeezed
  into the line.
- A highlight sits around the ayah's letters, not under them.
- Reading is taps: the sides turn, the middle shows the Reader controls, and the ayah's actions
  come from a long press or a double tap I can feel.
- The translation shows next to the whole page, not under it.
- Every font draws every mark of the text.
- No wide gaps between words anywhere in the mushaf.

These change the handoff's 4.19, 4.07 and 4.22 on purpose.

## Decisions

### Ribbon

- A bookmarked ayah gets a Ribbon: a band behind its words and its marker, in its category's
  color at the highlight's strength (20%).
- On the ayah's last line the band's left end, past the marker, gets the ribbon's V cut. Lines
  before it are plain bands with the wash's rounded corners. A page the ayah only starts on has no
  cut.
- The small ribbon between the last word and the marker goes. Lines no longer make room for it, so
  a bookmark never moves a word.
- The Page ribbon on the page's top edge stays.
- An ayah with a bookmark and a highlighted note shows only the Ribbon. The note still shows on the
  Ayah sheet's Note tile.
- The selection and the recitation washes paint over a Ribbon, as over a highlight.

### Washes

- The highlight is a full height band like the selection, no longer the lower half.
- Every band (selection, recitation, highlight, Ribbon) is centered on the line's ink, not on the
  font's text box. Measured over the page text: KFGQPC is 0.3 pt off today, Scheherazade 0.8 pt,
  Amiri Quran about 4 pt too high.

### Taps

- A tap on a Turn strip turns the page with the same turn as a swipe: left is the next page, right
  the previous, in both languages. Each strip is 44 pt from the screen's edge, the margin plus a few
  points of the text.
- Any other tap (words, header, footer) shows or hides the Reader controls, and the page springs to
  the card as before.
- A long press or a double tap on an ayah opens its Ayah sheet with a medium impact.
- While a sheet is open a tap only closes it. While choosing ayahs to share a tap checks or
  unchecks one, and the strips still turn.
- The strips work with the Reader controls shown.
- A tap over the words waits about 300 ms to know it isn't a double tap. Taps on the strips don't
  wait.
- Share on the Ayah sheet starts choosing with this ayah checked. "Share (n)" makes the card.

### Translation

- The Translation layout is a fixed split: the whole page, printed 15 lines, shrunk into the top
  half and centered, and the translation cells scrolling in the bottom half.
- The empty space beside the small page is the Turn strips. A tap on the small page or a cell shows
  or hides the Reader controls. A long press or a double tap on an ayah on either half opens its
  Ayah sheet.
- The selected or playing ayah keeps its wash on both halves. Nothing else links them.

### Open tanween

- The text writes open tanween as U+0657, U+065E and U+0656, which only KFGQPC reads that way. Amiri
  Quran has no U+065E (1,807 places, like بَقَرَةٞ) and Scheherazade draws other marks.
- Wherever the text is drawn in a font other than KFGQPC, these three become U+08F0, U+08F1 and
  U+08F2. The stored, copied and searched text never changes.
- In KFGQPC, بَقَرَةٗ is the font's own calligraphy and stays. If I find a word that is really
  broken in KFGQPC, it comes back with its page and line.

### Kashida

- Every justified line, at print and bigger sizes, caps its gaps at 1.5 spaces. The rest of the width
  goes into kashidas, one at a time across the line's words, longest first, at most 3 a word.
- A kashida goes at the word's last joining point, never inside لا or the name of Allah.
- If a line still isn't full, the gaps take the rest. Centered lines stay centered.
- Only the painted page has kashidas. ADR 0003 has the why.

## Tickets

`tickets/`, in order:

1. `01-ribbon-band.md`
2. `02-washes-on-the-ink.md`
3. `03-reading-taps.md`
4. `04-translation-split.md`
5. `05-open-tanween.md`
6. `06-kashida.md`
