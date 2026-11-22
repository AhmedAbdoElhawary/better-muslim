# 06: QCF V4 Tajweed

**What to build:** with QCF V4 Tajweed picked, the page draws the V2 lines in the V4 fonts with the
palette of its page color.

**Blocked by:** 04, 05

**Status:** done, the third box waits on 05's result

- [x] Night and Navy load the font with its dark palette, Sepia with its sepia one, the others with
      its light one. A page color change loads the page again in its palette.
- [x] The colors are the font's, never the app theme's. The washes stay behind the words.
- [ ] Where 05 found a phone can't draw the colors, the style isn't in the picker on it, and a
      picked V4 there goes back to Text. Built only if 05 finds such a phone.
- [x] Unit test: the palette rewrite turns palette 1 into palette 0.
