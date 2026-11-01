# 10: Root chip check

**What to build:** Find out whether a root for every Quran word exists under a license that lets
a free app ship it. If it does, 4.27's Root chip searches by root. If not, the chip stays out and
the reason is written down.

**Blocked by:** 08

**Status:** done

- [x] QUL's word data and any other candidate are checked. Only the Quranic Arabic Corpus has a
      root for every word.
- [x] The corpus' roots ship in `assets/quran/roots.json`, the Root chip searches them, the
      corpus is credited with its GPL and the search unit test covers a root.
- [x] ~~If none is: the chip isn't built.~~ I took the corpus anyway, see the spec's Further Notes.
