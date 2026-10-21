# Quickstart: Milestone 7a, Quran Mushaf Reader

How I check 7a on the phones. No screenshots, no goldens.

## Before

```bash
dart run tool/quran/build_quran.dart     # once, after the sources are in tool/quran/.cache/
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=dart_define/dev.json
```

## Motion phase

1. More → Dev: the Loader section loops at 48 pt (drop, fall, ripple), at 16 pt only the pool and
   sun. The slider moves the pool, 100% lights the sun.
2. Reduce motion on: the loader is a sun pulse.
3. Quran tab, first open: skeleton rows, then the rows rise in one after the other.

## Reading (US1)

1. Design scenario: the Quran tab is 4.18, Continue reading "Al-Fatiha · Ayah 3".
2. Tap it: the card grows into page 1. Back: it shrinks into the card.
3. Drag page 1 to the right: the leaf turns, page 2. Let go half way slowly: it springs back.
4. Display → Slide, then reduce motion on: the turn is a slide, then a crossfade.
5. Tap the margin: glass bars, the page becomes a card, the next page peeks. Drag the scrubber to
   page 42 and let go.
6. Scenario time after Isha (or Display → Night): the night page.
7. Arabic: the same page, RTL chrome.

## Ayah (US2)

1. Tap ayah 5 on page 1: gold wash, the sheet with the Sahih International line and six actions.
2. Tafsir: the page recedes, Al-Muyassar shows. Forward: ayah 6. Close: the page settles back.
3. Copy: "Copied". Paste in Notes: Arabic, translation, "Al-Fatiha 1:5".

## Recitation (US3)

1. Play from here on ayah 1: the loader in the mini player under 400 ms on a good connection shows
   nothing, then the follow wash moves ayah by ayah, the page turns at its end.
2. Lock the phone: lock screen controls, it keeps going. A call: it pauses and stays paused.
3. Recitation sheet: repeat 3 times, pause 2 s, speed 1.25, sleep 5 min: each one heard.
4. Airplane mode, play Al-Fatiha again: it plays to the end. Play a surah never played: the toast.
5. Dev → adhan now while reciting: the recitation pauses.

## Last read, bookmarks, notes (US4, US5)

1. Read to page 42, kill the app: Continue reading on the Quran tab and Home opens page 42.
2. Bookmark ayah 3: a ribbon on the page, listed on Saved. Long-press: rename "Reflect", accent.
3. A note on ayah 5, restart: it is there. Delete: toast with Undo.
4. More → Back up, then Restore on a reset store: bookmarks, notes and last read come back.

## Share and display (US6, US7)

1. Share ayah 5: Paper, Night, Emerald, Sky, square and story. Share: the image in the share sheet.
2. Share Al-Baqarah 282: smaller text, still whole.
3. Display → Translation: 4.07 on the same ayah. Both: the page with its cells under it.
4. Keep screen on: the screen doesn't dim in the reader, dims again outside it.

## Worst cases

Text scale 2.0, the smallest phone, a tablet, fast turns across 20 pages, theme and language change
while reading, storage full during a download.
