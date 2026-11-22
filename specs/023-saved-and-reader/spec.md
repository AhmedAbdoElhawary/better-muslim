# Feature Specification: Saved and reader

**Feature Branch**: `feature/quran-reading`

**Created**: 2026-11-12

**Status**: Clarified (grilled once, Q1 to Q11, all recommendations)

**Input**:

```text
- morning and evning azkar sounds not working on my android, the notification appear, but not
  the sound
- for bookamark in saved page, make the categories sorted based on numbers of bookmarked
  contains, each category has preview of maxmium 3 bookmarked, see more opens a seperted page
- saved page, _DisplaySheet and _BookmarkPicker as customscrollview
- for searching in quran, add another tab called typical, the exact search results
- rather than the bookmark icon in the app bar in the quran main tab, make it download icon
- when tap on use my location for location bottom sheet, show our loading
- another 5 quran layouts, all available reciters
- index inside the quran page opens a bottom sheet with surah, juz and page
- the note bottom sheet goes into the notes tab of the tafsir sheet, field limited to ~500
- tap on a highlighted ayah opens its note, tap on the bookmarked separator opens the ayah sheet
```

## Decisions

### Azkar voice on Android

- The code was right on paper: same AAC as the tones, kept in release, the channel has its
  sound. The two differences from the tone channels that sound: default importance, and android
  keeping a channel's first settings for good, even after a delete and a new one with its id.
- New ids `azkar_morning_2` and `azkar_evening_2` at high importance, the old ids deleted.
  Still no vibration. The nudge now peeks as a banner.

### Saved

- Categories sorted by their bookmarks, most first, a tie keeps their order. An empty category
  is last and still shows, so it can be edited. The bookmark picker uses the same order.
- Each category shows its 3 newest bookmarks. With more, "See all · 12" under them opens the
  Category page: all of them newest first, the same tap and long press as Saved. Emptied, it
  goes back.
- Saved's tabs, the Category page and the bookmark picker scroll as slivers, built lazily. The
  Display sheet stays as it is, it holds ~8 fixed rows.

### Search

- Exact, the chip after All: the typed words only as whole words, in that order, tashkeel and
  hamza folded as before. Arabic and translation, like All.

### Small ones

- The Quran tab's top bar: the download icon opens Downloads. The Bookmarks tile stays.
- Use my location in the location sheet: the star loader in the pin's place while it looks,
  the text dims.

### Reader

- Index opens the Index sheet: Surah, Juz and Page, the Quran tab's rows, open on Surah at the
  current one. A tap turns this reader there and closes the sheet.
- The note sheet is gone. The Study sheet's Notes tab is the editor: the field with the note,
  Highlight, Save, Delete note when there is one. No Add note, no note card. The field grows to
  500 pt then scrolls inside, no autofocus.
- A single tap on a highlighted ayah's words opens the Study sheet on Notes. A single tap on a
  Bookmarked number (44 pt around it, over the words) opens the Ayah sheet. Any other single
  tap toggles the controls, a double tap or long press still opens the Ayah sheet. Mushaf and
  Translation both.

### Reciters

- Every Hafs reciter in Arabic on EveryAyah, one folder each at the best bitrate up to 128 kbps
  (192 when it's the only one). A folder missing any of the 6,236 files is left out. No Warsh,
  no translations. The picker is a lazy list by name, the current one in view.

### Mushaf styles

- Five more in specs/024-mushaf-layouts, after everything here.

## On my phones

- [ ] The morning and evening test rows on the OPPO, locked and closed: the voice plays.
- [ ] A long category: See all opens the Category page.
- [ ] Tap a highlighted ayah, tap a bookmarked number, both layouts.
