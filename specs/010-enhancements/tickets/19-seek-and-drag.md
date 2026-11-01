# 19: ±10 s and a draggable ayah bar

**What to build:** While a surah plays, −10 and +10 jump through the audio and cross into the next
or previous ayah when they run past either end. The bar shows which ayah of the range is playing.
Dragging it shows "Ayah n" under my finger and jumps there on release. The controls read repeat,
previous, −10, play, +10, next, speed.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] Per ADR 0001 the audio stays one file per ayah.
- [x] +10 past an ayah's end goes into the next one by the seconds left over, −10 before its start
      goes back into the previous one the same way. With ayah repeat on, each repeat counts as its
      own play.
- [x] On the range's first ayah −10 stops at its start. On the last, +10 ends like the range
      ending.
- [x] The bar reads "ayah n of total". Dragging shows "Ayah n" under the finger with the
      selection haptic on each change, and seeks to that ayah's start on release.
- [x] The controls row is repeat, previous, −10, play, +10, next, speed. Never mirrored in
      Arabic, every target at least 44.
- [x] The −10 and +10 icons come from `BmIcon`, added in the set's style if missing.
- [x] `recitation_queue_test` covers crossing ayahs and the drag. `recitation_sheet_test` covers
      the row.
