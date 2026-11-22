# Contract: Quran assets

Built by `dart run tool/quran/build_quran.dart` from the sources in `tool/quran/.cache/` (research
R1, R8). The app only reads them. A rebuild with the same sources gives the same bytes.

## Sources

| File in `.cache/` | From | Use |
| --- | --- | --- |
| `madinah_v2_layout.db` | QUL, Mushaf Al Madinah V2 (1421H), 15 lines | headers, checks the lines |
| `qpc_hafs_words.db` | QUL, QPC Hafs word by word text | the words |
| `en.sahih.txt` | tanzil.net/trans, Sahih International, `sura|aya|text` | translation |
| `ar.muyassar.txt` | tanzil.net/trans, Tafsir al-Muyassar, `sura|aya|text` | tafsir |
| `quran-data.js` | tanzil.net/res/text/metadata, Tanzil metadata | surah names, places, juz, hizb |
| `qcf_words_NNN.json` | api.quran.com v4, by chapter | each word's QCF V1 and V2 glyphs, 1405H and 1421H page and line |
| `qcf_v1/`, `qcf_v2/` | verses.quran.foundation, QCF page fonts (ttf) | line widths |

`TODO(ahmed)`: the two QUL files need a sign in, download them by hand.

Tanzil's page starts are the 1405H print's, so no page number comes from it: each print's page
starts, surah pages and juz pages come from its own lines.

quran.com puts 7 words of the 1421H print and a few of the 1405H print a line early or late, and
84:21's end marker a line above its words. The tool moves a word back when its line is wider than
the page's usual line by that word and the neighbour short by the same, measured in the page's QCF
font. On the 1421H print that gives QUL's lines but one: in 13:37 (page 254) QUL has مَا on line 6,
the widths put it on line 7, and the widths win. A centered line is one of a surah's last two lines
under 0.92 of the page's usual line, which gives QUL's 1421H flags exactly, and is how the 1405H
lines get theirs.

## Output, `assets/quran/`

```text
assets/quran/
├── index.json            # surahs, juz, page → juz and hizb
├── pages/001.json … 604.json      # the 1421H print
├── pages_v1/001.json … 604.json   # the 1405H print, same format
├── surahs/001.json … 114.json
└── samples.json          # Ibn Kathir, As-Sa'di, Clear Quran for Al-Fatiha, from 09 Quran
```

### `index.json`

```json
{
  "surahs": [{"n": 1, "en": "Al-Fatiha", "ar": "الفاتحة", "place": "meccan", "ayahs": 7, "page": 1}],
  "juz": [{"n": 1, "surah": 1, "ayah": 1, "page": 1}],
  "pages": [{"surah": 1, "ayah": 1, "juz": 1, "hizb": 1}],
  "v1": {"surahs": [1, 2], "juz": [1, 22], "pages": [{"surah": 1, "ayah": 1, "juz": 1, "hizb": 1}]}
}
```

`pages[i]` is page `i + 1`, `surah` and `ayah` its first ayah. `en` names follow 09 Quran's spelling where it has them ("Aal-'Imran",
"An-Nisa'") and Tanzil's transliteration in the same style for the rest. Juz and hizb of each page
come from Tanzil's metadata. `v1` is the 1405H print: each surah's and juz's page, then its pages
like `pages`.

### `pages/NNN.json`

```json
{
  "lines": [
    {"t": "s", "surah": 1},
    {"t": "a", "c": false, "w": [[1, 1, "بِسْمِ"], [1, 1, "ٱللَّهِ"], [1, 1, "١", 1]], "g": ["ﭑ", "ﭒ", "ﭓ"]},
    {"t": "b"}
  ]
}
```

- `t`: `a` ayah text, `s` surah name, `b` basmallah. `c`: centered.
- each word `[surah, ayah, text]`, a 4th item `1` on the ayah's end marker.
- `g`: each word's glyphs in its page's QCF font, V2 in `pages/`, V1 in `pages_v1/`. Empty for the
  second word of a pair the font draws as one glyph (13:37 in V1).
- always 15 lines.

### `surahs/NNN.json`

```json
{"tr": ["In the name of Allah, ..."], "tafsir": ["..."]}
```

Index `i` is ayah `i + 1`.

## Checks (test/core/quran/quran_assets_test.dart)

- 114 surahs, 30 juz, 604 pages, 15 lines each, 6,236 ayahs, ayah counts per surah equal `index`.
- every ayah's words appear in order, on one page or carried to the next.
- `pages_v1/` has the same words in the same order as `pages/`, a `g` for every word, and the
  `v1` index its own page starts.
- when `tool/quran/.cache/` is present, every word equals its source word byte for byte, and every
  translation and tafsir equals its source line (SC-001).
