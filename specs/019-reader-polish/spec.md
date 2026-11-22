# Feature Specification: Reader polish

**Feature Branch**: `feature/quran-reading`

**Created**: 2026-11-09

**Status**: Built (grilled, Q1 to Q6, all recommendations but Q1 and Q5, terms in `GLOSSARY.md`), waiting for my review

**Input**: my notes after reading in the app:

```text
- mushaf size not responsive when the translation is on
- the translation in display is hard set to muyassar, i want to change it
- the three fonts only with Text, removed for any QCF style
- a tap shows the bars over the page, no scaling down
- a white page color next to paper, cream...
- the ayah in the translation follows the tajweed
- with tajweed, a color hint left and right of the page number
- a bookmarked ayah: only its number circle in the bookmark color, not the whole ayah
- search next to the bookmark in the reader's top bar
- in the translation layout, a long press stays on the side it was pressed on
```

## Decisions

### Page

- White is a page color, first in Display's row: a white page, near-black ink, V4's light palette.
- A bookmarked ayah's number circle fills in its category's color, in every style, on the page and
  in the translation cells. The band over the ayah is gone. The Page ribbon stays.
- A note's Highlight, the selection, the recitation and the ayahs chosen for sharing keep their
  wash over the whole ayah.
- With QCF V4 Tajweed, the bottom of the page shows the printed tajweed key: the madd colors right
  of the page number, ghunnah, ikhfa, idgham and qalqalah left of it, a small color mark and a
  short Arabic name each, in both languages. Its colors are the font's palette for the page color.

### Reader controls

- A tap slides the top bar and the dock in over the page at its full size. Nothing scales and the
  next page no longer peeks.
- The top bar has Search beside the bookmark. A result turns this reader to its page and opens the
  ayah, back from Search comes back to the reader as it was.

### Display

- The Font tiles show only with Text. The duas and Home's verse keep the last picked font.
- Mushaf size also sizes the page in the Translation layout. The Translation button scrolls to the
  page's bottom half over the ayahs.
- The Translation row opens a picker: Sahih International, Pickthall, Yusuf Ali and Hilali & Khan
  in English, al-Muyassar and al-Jalalayn in Arabic, each one in both languages. All six ship in
  the app. Until one is picked it is al-Muyassar in Arabic and Sahih International in English.
- The picked translation is the one in the cells, the ayah sheet, copy, the share card and the
  screen reader. Each one is credited.
- Text stays the default Mushaf style.

### Translation layout

- Under a QCF style each cell draws its ayah in the style's page glyphs, V4 in its tajweed colors,
  with the font's own number circle. Text keeps the picked font. Copy, search and the share card
  stay the Unicode text.
- A long press or a double tap on the page keeps the reader on the page, scrolled only as far as
  keeps the ayah above its sheet. On a cell it stays on the cells. The recitation still follows in
  the cells.

## Tickets

`tickets/`, in order:

1. `01-white-page.md`
2. `02-fonts-only-for-text.md`
3. `03-controls-over-the-page.md`
4. `04-reader-search.md`
5. `05-press-stays.md`
6. `06-mushaf-size-in-translation.md`
7. `07-bookmarked-number.md`
8. `08-translation-picker.md`
9. `09-qcf-cells.md`
10. `10-tajweed-key.md`
