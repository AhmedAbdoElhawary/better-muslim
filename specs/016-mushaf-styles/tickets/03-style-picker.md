# 03: Style picker

**What to build:** the Mushaf row in Display picks the Mushaf style, kept in settings.

**Blocked by:** 02

**Status:** done

- [x] A `mushafStyle` settings column (text, qcfV2, qcfV4, qcfV1), Text by default, with its
      migration step.
- [x] Display's Mushaf row shows the picked style and opens a sheet with one row a style, its name
      and description from the spec, and its size while it's not on the phone.
- [x] Picking one that isn't on the phone downloads it in the sheet with its progress, then picks
      it. Leaving the sheet keeps the download going.
- [x] Downloads lists the styles on the phone with their size and deletes them. Deleting the picked
      style picks Text.
- [x] Every string in `StringsManager` and both arb files.
- [x] Widget tests: the picker's rows, a download then the pick, delete back to Text.
