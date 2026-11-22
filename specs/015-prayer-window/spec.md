# Feature Specification: Now window

**Feature Branch**: `feature/quran-reading`

**Created**: 2026-11-08

**Status**: Built (grilled, Q1 to Q12, all recommendations)

## What I want

A prayer is "now" for its first 20 minutes. After that Home and the Prayer tab point at the next
prayer, since that is the one to get ready for. The prayer itself is still on time until the next
one comes, so marking and qada keep the real times.

## Decisions

- Two words in the glossary: **Now window** (the 20 minutes) and **Highlighted prayer** (the prayer
  in its now window, otherwise the next one). The existing period (one start to the next) stays for
  the sky, the azkar set and the adhan screen.
- 20 minutes for all five, no setting. A next prayer that comes sooner ends the window.
- Only the highlight moves. Mark stays on a prayer until the next prayer's time, Add to qada only
  after that.

### Home

- Sky text in the window: "NOW", the prayer, "Until Maghrib at 17:56" (as before).
- After it: "NEXT" ("التالية"), the next prayer, "At 17:56" ("الساعة ١٧:٥٦").
- Duha is never shown, from the end of Fajr's window it is NEXT Dhuhr.
- The strip's highlighted cell is the highlighted prayer. Every cell before it is muted.
- In its window the cell is filled with its dot. As the next prayer it is outlined in full
  primary (1.5 pt), no fill and no dot, its name in primary.
- After Isha's window the next prayer is tomorrow's Fajr, which the strip doesn't have: no cell is
  highlighted until Fajr, all five are muted.
- Unchanged: the sky's colors, stars, arc and sky events, the next prayer card, countdown and Home
  bar.

### Prayer tab

- The highlighted row is the highlighted prayer. NOW shows only in the window.
- In its window the row is filled. As the next prayer it is outlined like the strip, its name and
  icon in primary.
- After the window the next row is highlighted with its "in h:mm" chip and no tag. The passed
  prayer keeps its Mark button.
- After Isha's window no row of the prayer day is highlighted.

### Widgets and the theme preview

- The widgets highlight the same prayer, with a new entry at each window's end. Native code is
  unchanged, it reads `next` as before.
- The theme preview's NOW and strip follow Home, the outlined next cell too. The widgets keep
  their own look.

### Design scenario

- 16:32 stays. It is 65 minutes into Asr, so it shows NEXT Maghrib with Maghrib highlighted, unlike
  the 4.01 and 4.04 PNGs.
