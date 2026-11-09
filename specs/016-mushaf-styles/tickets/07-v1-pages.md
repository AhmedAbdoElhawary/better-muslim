# 07: QCF V1 pages

**What to build:** with QCF V1 picked, the reader shows the 1405H pages in the V1 fonts, with the
1405H page numbers everywhere.

**Blocked by:** 01, 04

**Status:** done

- [x] The page, its lines, the page number, juz and hizb, the surah index, the juz list and the
      scrubber are the 1405H ones.
- [x] Last read, ayah bookmarks, notes, highlights, Ribbons, recitation follow and search open on
      the ayah's 1405H page.
- [x] A stored page opens the 1405H page with that 1421H page's first ayah. A page bookmark or last
      read page saved in V1 is stored as the 1421H page of its first ayah. Built a little tighter: a
      page bookmark keeps the next 1421H page when only that one shows again as the same 1405H page,
      so only 145, 586, 590 and 600 come back one page early. Last read keeps its ayah, so it opens
      on the ayah's page in either print.
- [x] Switching between V1 and another style keeps the same ayah on screen.
- [x] Unit tests cover the page mapping both ways on a page that moves (121 and 585).
