# 02: Font files

**What to build:** one download file per QCF style, built by the tool, fetched and checked by the app.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] The tool fetches the 604 ttf of V1, V2 and V4 COLRv1 from quran.foundation's font CDN into
      `tool/quran/.cache/`, and writes `qcf_v1.bin`, `qcf_v2.bin` and `qcf_v4.bin`: a table of
      604 offsets, then each page's ttf gzipped on its own. No new package.
- [x] The app downloads a style once into Application Support, keeps it only when its sha256
      matches, and excludes it from backup, like `tafsir_files.dart`.
- [x] A page's font is read at its offset and unzipped when the page needs it.
- [x] Download progress, cancel and delete, like the tafsirs.
- [x] The three files are in the `mushaf-v1` release of `better-muslim-content`, their sha256
      and sizes in `MushafStyle`.
- [x] Credits: the QCF fonts (King Fahd Glorious Quran Printing Complex) and the quran.com data.
- [x] Unit tests cover reading one page out of a file and a bad sha256.
