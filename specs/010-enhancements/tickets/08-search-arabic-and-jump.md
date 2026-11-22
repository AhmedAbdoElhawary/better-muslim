# 08: Search the Arabic and jump

**What to build:** Quran home's search slot opens Search in Quran (4.27). Typing Arabic finds
ayahs whatever the diacritics or hamza forms, grouped by surah with the match washed behind its
glyphs. A surah name, "p 50" or "2:255" shows a "Jump to surah" card. A tap opens the reader there.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] Built from the 4.27 tree with the All and Ayah text chips. Translation is 09, Root is 10.
- [x] One plain search function over the Quran text shipped in the app: a query in, the jump card
      and the grouped hits out. Diacritics are stripped and hamza and alef forms folded on both
      sides. No typo guessing.
- [x] The jump card takes a surah name in Arabic or English, "p N" and "S:A". Out of range ("p
      700", "2:300") gives no card.
- [x] Hits are grouped by surah, the matched word washed in `primaryContainer` behind its glyphs.
      The Quran text is never recolored.
- [x] Tapping a hit opens the reader at that ayah. Tapping the card opens that surah, page or
      ayah.
- [x] The empty and no-result states follow 4.27.
- [x] Typing stays smooth on the whole Quran.
- [x] A unit test like `dua_search_test` covers "2:255", "p 50", surah names in both languages,
      no diacritics and every hamza form. The page gets one widget test.
