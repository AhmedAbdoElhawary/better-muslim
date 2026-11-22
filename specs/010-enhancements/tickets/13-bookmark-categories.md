# 13: Bookmark categories and the picker

**What to build:** Bookmarking an ayah or a page opens a sheet of my categories. I pick one and
the bookmark is saved there, or make a new category with a name and one of 8 colors right in the
sheet. On something already bookmarked its category is ticked and I can remove the bookmark. My
existing bookmarks are in "Bookmarks".

**Blocked by:** None (can start immediately)

**Status:** done

- [x] A category has a name, one of 8 fixed colors and an order. A bookmark is in exactly one
      category and keeps its own optional name.
- [x] A database step creates "Bookmarks" in the primary color and moves every existing bookmark
      into it. The old ribbon colors are dropped. `migration_test` covers it.
- [x] The 8 colors are named entries in the theme system and pass AA for graphics on every
      theme's page in both modes. `contrast_test` covers them.
- [x] The sheet lists categories with their color, name and count, then a "New category" row
      with a name field and the 8 colors. Picking one saves and closes.
- [x] On a bookmarked ayah or page its category is ticked and "Remove bookmark" shows.
- [x] The ayah's bookmark and the top bar's page bookmark open the same sheet.
- [x] Wherever the old ribbon color showed, the category's color shows.
- [x] The backup file carries categories, and an older backup restores into "Bookmarks".
      `backup_file_test` and `restore_test` cover both.
