# 06: Study sheet opens at 400 and grows to 720

**What to build:** The ayah's study sheet (Tafsir, Translation, Notes) opens at 400. Scrolling its
text up first grows it to 720, and only then does the text scroll. Dragging down steps back from
720 to 400 and from 400 to closed. No other sheet changes.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] Opens at 400. Dragging it, or scrolling the text up, grows it to 720 before the text
      scrolls.
- [x] With the text scrolled, dragging down scrolls it back to the top before the sheet shrinks.
- [x] Dragging down goes 720, 400, closed.
- [x] On short phones 720 is capped to what fits under the status bar.
- [x] Both heights are named entries in the size manager.
- [x] The snap follows the sheet motion in `MOTION.md`, reduce motion included.
- [x] Every other sheet in the app is unchanged.
- [x] `study_tabs_test` or `ayah_sheet_test` covers the heights and the drag.
