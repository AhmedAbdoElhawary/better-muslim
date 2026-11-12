# Note field, delete and Saved scroll

**What to build:** the note field grows from Add note's height, Delete note asks first, and Saved's cards stop taking the list's drags.

**Status:** done

- [x] The open field starts at 52 pt like Add note, grows a line at a time, stops at 300 and scrolls inside.
- [x] Delete note opens the dialog: "Delete this note?", "It can't be undone.", Cancel and Delete.
- [x] Saving a note empty with Highlight off asks the same, a Highlights long press stays as it was.
- [x] After the dialog the toast says Note deleted, with no Undo.
- [x] Saved's Notes and Highlights cards cut the note at 6 lines with an ellipsis and have no scroll inside, so every drag scrolls the list. The whole note is in the Study sheet.
