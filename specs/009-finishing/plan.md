# Implementation Plan: Finishing pass

**Branch**: `feature/enhancements-2` | **Date**: 2026-10-27 | **Spec**: [spec.md](spec.md)

## Summary

- **Reader speed**:
  - `PageTurner` builds the shown page first and adds one neighbour per frame;
  - `_Laid.of` finds the page's scale from one painter per line, then measures the words once;
  - `QuranAssets` keeps the last three surahs instead of one.
- **Translation**: `QuranLayout.both` is removed. Translation is today's Both. Schema 12 turns a
  saved `both` into `translation`.
- **Mushaf size**: `mushafSize` in settings, steps −2 to 5 (80% to 150%), schema 12. Below 100%
  the text area narrows. Above it `reflowMushaf` (domain, pure) turns the page into more lines
  and the render object takes the height they need, inside a scroll view.
- **Font**: `assets/fonts/KfgqpcHafs.ttf` (v18), `kfgqpcShipped` on, `kfgqpc` the default.
- **Calendar**: `DayDots` moves to `core/widgets`. `_Day` reads `prayedProvider` and passes a
  `prayed` count to `DayCell`. `_DateLine` shows the dots for today and before. The Prayer header
  gets a calendar button.
- **TODOs**: the Listen tile, the iOS last notification, the scrims, the tafsir release, the
  azkar and duas Arabic from Hisn al-Muslim.

## Constitution check

- I: only core and the features named, no feature imports another (`DayDots` goes to core).
- II: new sizes go in the managers, new strings in both arbs.
- III: the reflow is an approved break. Quran glyphs never move on their own.
- IV: no new package.
- V: the point of the reader work.
- VI: unit tests for `reflowMushaf` and the migration, widget tests for the size row, the
  calendar colors and the Listen tile.
- VIII: the font ships in the app. Hisn al-Muslim text ships in the app.

## Data

- `settings.mushaf_size` int, default 0, check −2 to 5.
- `settings.quran_font` default becomes `kfgqpc`.
- `settings.quran_layout`: `both` is gone, rows move to `translation`.
