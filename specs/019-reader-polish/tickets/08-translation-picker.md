# 08: Translation picker

**What to build:** Display's Translation row picks the translation, from six shipped in the app.

**Status:** done

- [x] Sahih International, Pickthall, Yusuf Ali, Hilali & Khan, al-Muyassar and al-Jalalayn ship
      in the app, from Tanzil.
- [x] A `translation` settings column, null until picked: al-Muyassar in Arabic, Sahih
      International in English. Its migration step.
- [x] The row shows the picked one and opens a sheet with one row each, in both languages.
- [x] The cells, the ayah sheet, copy, the share card and the screen reader use it.
- [x] Credits list each one. Strings in `StringsManager` and both arb files.
- [x] Tests: the default per language, a pick changes the cell's text.
