# 07: Tabari and Qurtubi

**What to build:** Tafsir al-Tabari and Tafsir al-Qurtubi download like Ibn Kathir and As-Sa'di:
picked in the tafsir chip, downloaded once, checked before use and read offline after.

**Blocked by:** None (can start immediately)

**Status:** waiting for the tafsir-v2 upload

- [x] The build tool's tafsir list has Tabari (quran.com id 15) and Qurtubi (id 90), each built
      into one gzip like the others.
- [ ] A new release `tafsir-v2` on `better-muslim-content` holds both files, uploaded with `gh`.
      `tafsir-v1` is untouched.
- [x] The tafsir files list has both with their url, size and sha256. `tafsir_files_test` covers
      them.
- [x] The picker shows them with their names in both languages. Download, check and offline
      reading work as for the other two.
- [x] The credits name both and quran.com as their source.
