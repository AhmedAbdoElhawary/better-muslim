# 14: Saved by category, and editing categories

**What to build:** Saved's Bookmarks are grouped under category headers. A long press on a
category in the picker sheet, or a tap on its header in Saved, opens the same form as New
category, filled in, where I rename it, recolor it or delete it. Saved can make a new one too.

**Blocked by:** 13

**Status:** done

- [x] Bookmarks are grouped under headers with the category's color and name, in category order.
      A category with no bookmarks still has its header.
- [x] Saved has a New category row after the last header, and a tap on a header opens the
      filled form, the same as the picker's.
- [x] A long press on a category row in the picker sheet opens the filled form.
- [x] "Bookmarks" can be renamed and recolored but has no Delete.
- [x] Deleting any other category asks first, then removes it and its bookmarks.
- [x] `saved_page_test` covers the headers. A widget test covers rename, recolor and delete.
