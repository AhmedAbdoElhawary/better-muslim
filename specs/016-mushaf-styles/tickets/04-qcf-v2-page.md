# 04: QCF V2 page

**What to build:** with QCF V2 picked, the mushaf page draws every word in its page's font.

**Blocked by:** 01, 03

**Status:** done

- [x] The page's font is loaded before the page shows, and the next and previous pages' with it.
      A font loaded once isn't loaded again.
- [x] Each word is its V2 glyph, ink in the page's ink color. Lines at 100% are the print's, laid
      out right to left like now, with no kashida.
- [x] Above 100% the words reflow into wider lines like Text, each keeping its glyph.
- [x] The opening pages, the surah name and basmallah lines draw as they do now.
- [x] The washes and Ribbons sit on the ink: V2's ink middle measured over the page text like the
      other fonts'.
- [x] Taps, long press, the Turn strips, the Translation layout's small page and share choosing work
      the same.
- [x] The Translation layout's cells, the share card, copy and search keep the Unicode text.
- [x] Widget test: a page in V2 lays out its words in their lines.
