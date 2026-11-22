# 01: Glyph data

**What to build:** `tool/quran/build_quran.dart` gives every word of the 1421H pages its QCF V2 glyph
code, and builds the 1405H pages with their QCF V1 codes.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] The codes come from api.quran.com v4 (`code_v1`, `code_v2`, `v1_page`, `line_v1`, `line_v2`),
      fetched once into `tool/quran/.cache/` like the other sources. The app never calls it.
- [x] Each 1421H word gets its V2 code, the ayah end marker too. The build fails if a page's lines
      don't hold the same words as the api's `line_v2`. Built as: the api's lines are repaired by
      the glyph widths, then checked against QUL, and only 254:6/7 differs, where the widths win.
- [x] The 1405H pages go to `assets/quran/pages_v1/`, 15 lines each, with the same line types and
      centered flags as the 1421H ones, each word with its text and V1 code.
- [x] `index.json` gets the 1405H start of every page, surah and juz next to the 1421H ones.
- [x] A rebuild with the same sources gives the same bytes. `contracts/quran-assets.md` in
      `specs/003-milestone-7-quran/` says the new fields.
