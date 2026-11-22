# 01: Ribbon band

**What to build:** A bookmarked ayah gets a Ribbon behind its words and marker in its category's
color, cut like a ribbon past the marker on its last line. The small ribbon in the line goes.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] The band covers the ayah's words and marker on every line it sits on, at 20% of the
      category's color, behind the glyphs.
- [x] Only the line the ayah ends on gets the V cut, on its left end past the marker. A page the
      ayah only starts on has none.
- [x] Lines no longer keep room for a ribbon: adding or removing a bookmark only repaints.
- [x] A bookmarked and highlighted ayah shows only the Ribbon. Selection and recitation washes
      paint over it.
- [x] The Page ribbon stays.
- [x] Widget tests cover a bookmarked ayah's band and cut, a page it only starts on, and the
      highlight giving way. Every printed page ends on an ayah's end, so no real page has an ayah
      it only starts on, the code keeps the case for a page that would.
