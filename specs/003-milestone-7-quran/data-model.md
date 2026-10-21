# Data Model: Milestone 7a, Quran Mushaf Reader

## Shipped content (read only, assets)

From contracts/quran-assets.md, read through `core/quran/quran_assets.dart`.

- **Surah**: `number` 1..114, `nameEn`, `nameAr`, `place` (meccan, medinan), `ayahCount`,
  `firstPage`.
- **Juz**: `number` 1..30, first `surah`, `ayah`, `page`.
- **Page**: `number` 1..604, `juz`, `hizb`, `lines` (exactly 15). Each **Line**: `type` (ayah,
  surahName, basmallah), `centered`, `surah` for surahName lines, `words` for ayah lines. Each
  **Word**: `surah`, `ayah`, `text`, `end` (true on the ayah's marker word).
- **AyahText**: per surah file: `translation` (Sahih International), `tafsir` (Al-Muyassar).
- **Ayah key**: `(surah, ayah)`, the identity everything else points at.

Validation, checked in tests: 114 surahs, 604 pages, 15 lines on every page, 6,236 ayahs, every
ayah's words appear in order across one or two pages, every ayah has a translation and a tafsir.

## Stored in drift, schema 10

### `settings` new columns

| Column | Type | Default | Note |
| --- | --- | --- | --- |
| `lastReadSurah` | int | 1 | with ayah and page, FR-035 |
| `lastReadAyah` | int | 1 | |
| `lastReadPage` | int | 1 | check 1..604 |
| `lastReadAt` | datetime, nullable | null | null = never read, the card shows no time |
| `pageColor` | text enum `PageColor` | `followSky` | followSky, paper, cream, night |
| `quranLayout` | text enum `QuranLayout` | `mushaf` | mushaf, translation, both |
| `pageTurn` | text enum `PageTurn` | `book` | book, slide |
| `keepScreenOn` | bool | false | |
| `quranArabicSize` | int | 0 | steps -2..3 around 4.07's size |
| `quranTranslationSize` | int | 0 | steps -2..3 |
| `reciteSpeed` | real | 1.0 | 0.75, 1.0, 1.25, 1.5 |
| `reciteRepeat` | int | 1 | 1 (off), 2, 3, 5, 10 |
| `recitePause` | int | 0 | seconds: 0, 1, 2, 3, 5 |

Range and sleep timer live only for the session, a new recitation starts with the whole surah and
the timer off.

### `quran_bookmarks`

| Column | Type | Note |
| --- | --- | --- |
| `id` | int, auto | |
| `surah`, `ayah` | int, nullable | null for a page bookmark |
| `page` | int | always set, 1..604 |
| `name` | text, nullable | null shows the reference |
| `color` | text enum `RibbonColor` | primary, accent, neutral |
| `createdAt` | datetime | newest first |

Unique on `(surah, ayah)` for ayah bookmarks and on `page` where `surah` is null.

### `quran_notes`

| Column | Type | Note |
| --- | --- | --- |
| `surah`, `ayah` | int | primary key, one note per ayah |
| `text` | text | not empty, trimmed |
| `updatedAt` | datetime | |

### Migration v9 → v10

Add the settings columns, create both tables. `drift_schemas/app_database/drift_schema_v10.json`
and a step in `test/drift/app_database/migration_test.dart`.

### Backup file

`copyTables` already copies every table, so both new tables and the settings columns ride along.
Downloaded recitations are files, never in the store, never in the backup (FR-049).

## In memory

- **Selection**: `(surah, ayah)` or none. Washes the ayah, opens the sheet.
- **ReaderChrome**: shown or hidden.
- **Recitation state**: `idle`, `loading` (the loader gate runs), `playing`, `paused`; the queue
  (range, repeat, pause, speed), the playing ayah, `following` (true until I turn the page myself).
- **Download state per ayah**: `missing`, `downloading`, `ready`. A surah is "downloaded" when
  every ayah is ready.
- **AudioUse** (core): `none`, `recitation`, `adhan`.

## State changes

```text
recitation: idle ──play──▶ loading ──file ready──▶ playing ──pause / call / adhan──▶ paused
                                      │                     │
                                      └──offline, missing──▶ idle (toast)
playing ──range ends / end of surah / sleep timer──▶ idle
following: true ──I turn the page──▶ false ──back on the playing page / next / previous──▶ true
last read: page settles or reader closes (not playing) → first ayah of the page
           playing ayah changes                       → the playing ayah
```

## Enums (core)

`lib/core/settings/quran.dart`: `PageColor { followSky, paper, cream, night }`,
`QuranLayout { mushaf, translation, both }`, `PageTurn { book, slide }`,
`RibbonColor { primary, accent, neutral }`, stored by name.

## Palette additions (handoff values file)

`BmPagePalette.paper` and `.night` from `K.PAGE` in `_gen/kit.js`; `cream` = paper with a
`TODO(ahmed)`. New `ThemeEnum`: `page`, `ink`, `ink2`, `ornament`, `ornamentSoft`, `selectionWash`,
`followWash`, `pageHidden`, `gutter`, `pageGlass`, `oilLight`, `oilDark`.
