# Feature Specification: Android countdown card

**Feature Branch**: `feature/enhance1`

**Created**: 2026-11-15

**Status**: Built, waiting for my review (grilled once, Q1 to Q8, all recommendations)

**Input**:

```text
the countdown notification before each prayer on android looks exactly like 5.3 Live Activity in
design/07 System surfaces.dc.html, and ios too if it isn't already. I don't like the current
basic one on android at all
```

## Decisions

### Scope

- Android only. The iOS Live Activity already is 5.3: the tile, "Next prayer · city", the name,
  the countdown over "at 17:56", the bar and its two ends. Its bar has no sun, ActivityKit draws
  a timer's progress itself and nothing rides on it. It stays as it is.
- No Dart change, `surfaces.json` already carries every text and color the card needs.

### The card

- Expanded is the whole 5.3 card: the star tile, "Next prayer · Makkah" over the name, the
  countdown over "at 17:56", the bar with the sun and its glow, "Asr 15:27 · prayed" and
  "Maghrib 17:56" under it. No period start, no bar and no labels, as iOS.
- Collapsed is one row: a small star tile, the name and the countdown.
- From Android 12 the system's header (app icon, name, time) stays above it and the collapsed
  height is about 48 dp, nothing can take them away. The same decorated layout below 12.
- Everything but the countdown is one picture in the app's fonts, like the widget. It stretches
  evenly to the width the shade gives it, the system never says the width.
- The countdown is the system's `Chronometer`, so it counts to the second with the app closed.
  "1:23:42", then "23:42" in the last hour. Schibsted from `res/font`, a skin may draw it in its
  own font. Its digits follow the phone's language, not the app's.
- The bar and the sun redraw on the minute tick the widget already has, never with the screen
  off.

### Colors

- No background of its own, a plain notification can't paint one. The theme's dark colors when
  the phone is dark, its light ones when it's light. A switch of the phone's mode shows at the
  next minute.

### Kept

- Tap opens Home, no buttons. Starts at the reminder, the system takes it away at the prayer.
  Silent except its alarm, on its prayer's channel.
- The bar and the countdown are never mirrored, the rest follows the app's language. Sizes are
  dp, the phone's font size doesn't change them.

### Dropped

- The Android 16 Live Update (status bar chip, `ProgressStyle` sun). A promoted notification
  can't have a custom layout, so it goes with its permission.
