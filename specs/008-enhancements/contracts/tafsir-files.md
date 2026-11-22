# Contract: tafsir files

## Build (tool)

```bash
dart run tool/quran/build_quran.dart --tafsir
```

- Downloads Ibn Kathir (Arabic, id 14) and As-Sa'di (id 91) from quran.com's api, one surah per
  request, into `tool/quran/.cache/` once. The same texts QUL exports, with no login.
- Writes `build/tafsir/ibn_kathir.json.gz` and `build/tafsir/saadi.json.gz`.
- Format: `{"1": [ayah 1, ayah 2, ...], ..., "114": [...]}`. Plain text, with HTML tags removed
  and footnote markers dropped. An ayah grouped with the one before it repeats that group's text.
  quran.com leaves out some grouped ayahs (31 in Ibn Kathir, 59 in Sa'di), they repeat the ayah
  before.
- Prints each file's size and sha256.
- Checks: 114 surahs, each with exactly as many entries as its ayah count in
  `assets/quran/index.json`.

## Host

- A GitHub release of the public repo `AhmedAbdoElhawary/better-muslim-content`, tag
  `tafsir-v1`, holding both files. This repo is private, and a private release needs a token. The
  URL is `https://github.com/AhmedAbdoElhawary/better-muslim-content/releases/download/tafsir-v1/{file}`.
- The two sha256 values in `tafsir_files.dart` are the files built on 2026-10-26.

## App

`lib/features/quran/data/tafsir_files.dart`

| Call | Result |
| --- | --- |
| `isReady(source)` | the file exists (validated when it was written) |
| `download(source, {onProgress})` | `Future<void>`. Progress is 0..1, or null without a size header. Throws `TafsirException(offline / failed)` |
| `cancel(source)` | stops the download and deletes `.part` |
| `text(source, AyahKey)` | `Future<String>`, loaded once per source |

- Https only, status 200 only, redirects followed (GitHub sends one to its CDN).
- The sha256 is computed while streaming. The file is renamed from `.part` only on a match.
- `muyassar` is always ready, read from the shipped surah files.
