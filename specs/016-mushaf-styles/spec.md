# Feature Specification: Mushaf styles

**Feature Branch**: `feature/quran-reading`

**Created**: 2026-11-09

**Status**: Clarified (grilled, Q1 to Q10, all recommendations, terms in `GLOSSARY.md`, ADR 0004)

**Input**: my note:

```text
i want to add another styles for mushaf for text, i want to add
QCF V2
Closest to the printed book
Madinah Mushaf, 1421H print
+
QCF V4 Tajweed
Same 1421H page, color-coded
+
QCF V1
Madinah Mushaf, 1405H print
```

## What I want

- The mushaf page drawn exactly like the printed book, word for word, in the print I read from.
- The tajweed colors of the same page when I want them.
- Text stays the default, on the phone and offline, with the fonts and kashida it has now.

## What I know

- The app's pages are QUL's 1421H lines, the same lines QCF V2 draws. V4 Tajweed uses V2's glyph
  codes and lines.
- In the 1405H print 56 ayahs sit on another page than in 1421H, 36 pages in all (120 to 123, 144,
  145, 531 to 534, 564 to 600). V1 needs its own pages.
- Each style is 604 page fonts. Flutter reads ttf, not woff2: about 93 MB for V1, 210 MB for V2
  and 165 MB for V4, gzipped about 55, 140 and 70 MB.
- Flutter can't unload a font, each page read stays in memory until the app restarts, about 150
  to 350 KB a page.
- V4 is a COLRv1 font with light, dark and sepia palettes. Flutter can't pick a palette, and COLRv1
  on iOS is unproven.
- QUL lists V4 as waiting for proofreading, quran.com has shown the same fonts since September 2024.

## Decisions

### Display

- The Mushaf row ("Madinah · Hafs" today) becomes a picker. Its sheet has one row a style:
  - Text: Your font, on the 1421H lines. Always on the phone.
  - QCF V2: Closest to the printed book. Madinah Mushaf, 1421H print.
  - QCF V4 Tajweed: Same 1421H page, color-coded.
  - QCF V1: Madinah Mushaf, 1405H print.
- Each QCF row shows its size until it's on the phone. The row's value in Display is the picked
  style's name.
- Text is the default. The Font tiles stay as they are.

### Download

- Each QCF style is one file in a `better-muslim-content` release, checked by its sha256, like the
  tafsirs. Uploading it is mine.
- Picking a style that isn't on the phone downloads it in the sheet with its progress. The page
  keeps its style until the download is done, then switches.
- Downloads lists the styles on the phone with their size, and deletes them. Deleting the picked
  style goes back to Text.
- The file stays on the phone as it came, each page's font is unzipped when the page opens. It
  stays out of iCloud and Android backup.

### The page

- A QCF style draws only the mushaf page. The Translation layout and the share card keep the Font.
  Copied, shared and searched text stays the Unicode text.
- QCF lines have no kashida, the glyphs are the print's widths.
- The surah name and basmallah lines stay the app's own drawing in every style.
- At 100% the lines are the print's. Above 100% the words flow into wider lines like Text does now,
  each word keeping its print glyph.
- Selection, recitation, highlight and Ribbon washes stay behind the words and centered on the ink.
- Turning stays only painting: the page's font loads before the page shows, the next and previous
  pages' fonts with it.

### Tajweed

- V4's palette follows the page color: Night and Navy take its dark palette, Sepia its sepia one,
  the others its light one. The tajweed colors are the font's own, the app theme never tints them.
- The first V4 ticket is a spike on my iPhone and my Android phone. Where a phone can't draw the
  colors, QCF V4 Tajweed is not in the picker.

### V1

- V1 has the 1405H print's own pages and lines. Its page numbers, surah starts, juz starts and the
  scrubber are the 1405H ones.
- What is saved by ayah (last read, ayah bookmarks, notes, recitation) follows the ayah.
- The database keeps 1421H page numbers. In V1 a stored page opens the 1405H page with that page's
  first ayah, and a page saved in V1 is stored as the 1421H page of its first ayah.

## Tickets

`tickets/`, in order:

1. `01-glyph-data.md`
2. `02-font-files.md`
3. `03-style-picker.md`
4. `04-qcf-v2-page.md`
5. `05-tajweed-spike.md`
6. `06-tajweed.md`
7. `07-v1-pages.md`
