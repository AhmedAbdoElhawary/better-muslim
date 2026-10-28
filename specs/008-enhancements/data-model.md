# Data Model: Enhancements after the review

## Stored

### Settings (drift, schema 10 → 11)

| Column | Type | Default | Notes |
| --- | --- | --- | --- |
| `quranFont` | text | `amiri` | `QuranFont.name`: `amiri`, `kfgqpc`, `scheherazade` (R9) |
| `pageColor` | text | as today | gains `sepia`, `green`, `navy`, old values unchanged (R12) |

- Migration `from10To11`: add `quranFont`. Schema dump `drift_schemas/app_database/drift_schema_v11.json`.
- The backup file carries `quranFont` like the other settings. An older backup restores without it
  (default).

### Tafsir files (on disk, not in the database)

- Path: Application Support `tafsir/{source}.json.gz`, excluded from backup.
- Content: `{"1": ["...", ...], ..., "114": [...]}`, one plain-text entry per ayah.
- Valid only when its sha256 equals `TafsirSource.sha256`. `.part` files are deleted on start and on
  any failure.

## In memory

### Selection (reader, autoDispose)

| Field | Type | Notes |
| --- | --- | --- |
| `sheet` | `AyahKey?` | the ayah the ayah sheet is open on, as today |
| `chosen` | `Set<AyahKey>` | ayahs chosen for sharing |
| `choosing` | `bool` | select mode, true while `chosen` isn't empty |

Transitions: long press → `choosing`, `chosen = {key}`. Tap while choosing → toggle, and an empty set
ends choosing. Cancel, back or sharing → cleared.

### ShareOptions (share sheet state)

| Field | Type | Default |
| --- | --- | --- |
| `background` | `ShareBackground` | `paper` |
| `size` | `ShareSize` | `square` |
| `sizeLocked` | `bool` | false, true once the user taps a size |
| `solid` | `bool` | false |
| `ornament` | `ShareOrnament?` | null (off) |
| `font` | `QuranFont` | the reader's `quranFont` |
| `appName` | `bool` | true |

### AyahShare (quran feature, not core)

`AyahShare(keys, textSource)`. `ShareTextSource { none, translation, muyassar, ibnKathir, saadi }`,
which defaults to `translation` in English and `muyassar` in Arabic. The text picker row changes it
and rebuilds the content, so the core sheet never knows about it.

### Share layout result (ayah)

`(size, scale, hiddenTafsir: int, fits: bool)` from the fit steps in R10.

### ArcPoint (Home)

| Field | Type | Notes |
| --- | --- | --- |
| `name` | `String` | a `StringsManager` key |
| `time` | `DateTime` | |
| `share` | `double` | 0 to 1 between the arc's ends |

`ArcPoints(kind: day | night, start, end, points)`, where a null time leaves its point out.

### Verse of the day

`(key: AyahKey, arabic: String, translation: String, surah: String)` for `todayProvider`'s date.

## Assets

- `assets/quran/index.json`: each surah gains `words: [int per ayah]` (R6).
- `assets/fonts/ScheherazadeNew-Regular.ttf`, and `assets/fonts/KfgqpcHafs.ttf` from Ahmed.
- `assets/ornaments/pattern_*.svg`, `frame_arch.svg`, `divider_section.svg` with their metadata
  stripped.
- `shaders/page_curl.frag`.
- `assets/app_icon/png/splash_symbol.png` re-rendered.
