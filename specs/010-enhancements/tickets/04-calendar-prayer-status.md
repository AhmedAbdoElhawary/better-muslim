# 04: Prayer status in the calendar

**What to build:** In the Hijri calendar's day details, the Prayer times tab shows each prayer's
status beside its time, with the same marks as the Home strip. Tapping a prayer opens the Prayer
tab at that day and prayer. When all five of the selected day are prayed or made up, a ✓ follows
"Prayer times" in the tab title.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] Prayed or made up shows ✓, in qada shows a muted "In qada", a future or unlogged prayer
      shows nothing, Sunrise never shows a mark.
- [x] The mark comes from the prayer row state the Home strip uses, not a copy of it.
- [x] Tapping any of the five prayers opens the Prayer tab at that day and prayer.
- [x] The ✓ after "Prayer times" is in the success color, only when all five are prayed or made
      up. The five dots under the date stay.
- [x] Marks and the ✓ appear with the app's usual state change, with its reduce motion fallback.
- [x] Works in both languages and at text scale 2.0.
- [x] `hijri_calendar_page_test` covers the marks, the tap and the ✓.
