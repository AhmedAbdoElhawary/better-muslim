# 29: Azkar font

**What to build:** An "Aa" button on the Azkar page opens a sheet to pick the azkar font: Amiri,
Scheherazade New or Noto Naskh Arabic. It applies to azkar, duas and Tasbih, and never to the
Quran.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] A database step adds the azkar font setting, Amiri by default. `migration_test` covers it.
- [x] Noto Naskh Arabic is added under the OFL with its credit. `font_manager_test` stays green.
- [x] The sheet shows the three fonts, each written in itself.
- [x] The choice changes the azkar, dua and Tasbih text. Verses inside azkar keep the Quran font,
      and the Quran's Display font is untouched.
- [x] `azkar_page_test` covers the button, the sheet and the change.
