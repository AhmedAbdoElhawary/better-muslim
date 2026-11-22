# 11: Highlight from a note

**What to build:** The study sheet's note tab gets a "Highlight in mushaf" checkbox under the note
field. Checked, the ayah gets a soft accent wash behind its glyphs on the mushaf, with or without
note text. Unchecked, the wash goes.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] The checkbox sits under the note field. Saving with only the box checked makes a highlight
      with no note text.
- [x] A note with no text and no highlight is deleted.
- [x] The wash is the accent at low alpha, drawn behind the glyphs like the selection wash and
      clearly different from it. The glyphs are never recolored, and the text on it stays AA in
      every page palette.
- [x] Share images never draw it.
- [x] A database step adds the highlight to notes. `migration_test` covers it.
- [x] The backup file carries highlights, and an older backup restores with none.
      `backup_file_test` and `restore_test` cover both.
- [x] `ayah_sheet_test` covers the checkbox.
