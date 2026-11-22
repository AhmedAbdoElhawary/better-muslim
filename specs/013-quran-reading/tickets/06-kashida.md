# 06: Kashida

**What to build:** Justified mushaf lines cap their gaps at 1.5 spaces and give the rest of the width
to kashidas. ADR 0003.

**Blocked by:** 01

**Status:** done

- [x] A kashida goes at the word's last joining point, after the letter's marks, never inside لا,
      the name of Allah or across a small waw or yeh.
- [x] One at a time across the line's words, longest first, at most 3 a word, until the gaps are
      at most 1.5 spaces. If that isn't enough the gaps take the rest.
- [x] Centered lines, squeezed lines and the opening pages have none.
- [x] Bigger mushaf sizes get them on their rewrapped lines.
- [x] Only the painted page has them: labels, copy, share and search use the stored text.
- [x] Unit tests cover where a kashida goes and how a line shares them out.
