# 05: Open tanween in every font

**What to build:** Wherever the Quran text is drawn in a font other than KFGQPC, U+0657, U+065E and
U+0656 become U+08F0, U+08F1 and U+08F2.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] The mushaf page, the translation cells, the study sheet, search, notes, the share card, the
      verse on Home and Quranic duas all draw the swapped marks in Amiri Quran and Scheherazade.
- [x] KFGQPC draws the text as stored.
- [x] Copied, shared as text and searched text never changes.
- [x] A unit test covers the swap and KFGQPC untouched.
