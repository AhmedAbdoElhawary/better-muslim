# Contract: Quran assets

Built by `dart run tool/quran/build_quran.dart` from the sources in `tool/quran/.cache/` (research
R1, R8). The app only reads them. A rebuild with the same sources gives the same bytes.

## Sources

| File in `.cache/` | From | Use |
| --- | --- | --- |
| `madinah_v2_layout.sqlite` | QUL, Mushaf Al Madinah V2 (1421H), 15 lines | pages and lines |
| `qpc_hafs_words.sqlite` | QUL, QPC Hafs word by word text | the words |
| `en.sahih.txt` | tanzil.net/trans, Sahih International, `sura|aya|text` | translation |
| `ar.muyassar.txt` | tanzil.net/trans, Tafsir al-Muyassar, `sura|aya|text` | tafsir |
| `quran-data.js` | tanzil.net/res/text/metadata, Tanzil metadata | surah names, places, juz, hizb |

`TODO(ahmed)`: the two QUL files need a sign in, download them by hand.

## Output, `assets/quran/`

```text
assets/quran/
├── index.json            # surahs, juz, page → juz and hizb
├── pages/001.json … 604.json
├── surahs/001.json … 114.json
└── samples.json          # Ibn Kathir, As-Sa'di, Clear Quran for Al-Fatiha, from 09 Quran
```

### `index.json`

```json
{
  "surahs": [{"n": 1, "en": "Al-Fatiha", "ar": "الفاتحة", "place": "meccan", "ayahs": 7, "page": 1}],
  "juz": [{"n": 1, "surah": 1, "ayah": 1, "page": 1}],
  "pages": [{"surah": 1, "ayah": 1, "juz": 1, "hizb": 1}]
}
```

`pages[i]` is page `i + 1`, `surah` and `ayah` its first ayah. `en` names follow 09 Quran's spelling where it has them ("Aal-'Imran",
"An-Nisa'") and Tanzil's transliteration in the same style for the rest. Juz and hizb of each page
come from Tanzil's metadata.

### `pages/NNN.json`

```json
{
  "lines": [
    {"t": "s", "surah": 1},
    {"t": "a", "c": false, "w": [[1, 1, "بِسْمِ"], [1, 1, "ٱللَّهِ"], [1, 1, "١", 1]]},
    {"t": "b"}
  ]
}
```

- `t`: `a` ayah text, `s` surah name, `b` basmallah. `c`: centered.
- each word `[surah, ayah, text]`, a 4th item `1` on the ayah's end marker.
- always 15 lines.

### `surahs/NNN.json`

```json
{"tr": ["In the name of Allah, ..."], "tafsir": ["..."]}
```

Index `i` is ayah `i + 1`.

## Checks (test/core/quran/quran_assets_test.dart)

- 114 surahs, 30 juz, 604 pages, 15 lines each, 6,236 ayahs, ayah counts per surah equal `index`.
- every ayah's words appear in order, on one page or carried to the next.
- when `tool/quran/.cache/` is present, every word equals its source word byte for byte, and every
  translation and tafsir equals its source line (SC-001).
