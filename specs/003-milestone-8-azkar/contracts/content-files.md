# Contract: the azkar and duas content files

The shape my dataset has to follow to replace the samples with no code change (FR-028, R2). Both
files are UTF-8 JSON in `assets/`, listed in `pubspec.yaml`. A test loads the shipped files and
checks every rule below.

## `assets/azkar/azkar.json`

```json
{
  "morning": {
    "minutes": 3,
    "items": [
      {
        "id": "m01",
        "arabic": "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ",
        "transliteration": "Subhan Allahi wa bihamdihi",
        "translation": "Glory be to Allah and praise be to Him.",
        "source": { "en": "Sahih Muslim 2692", "ar": "صحيح مسلم ٢٦٩٢" },
        "grading": { "en": "Sahih", "ar": "صحيح" },
        "count": 100,
        "quran": false,
        "note": "TODO(ahmed): sample from 03 Components, replace with the morning azkar dataset"
      }
    ]
  },
  "evening": { "minutes": 6, "items": [] }
}
```

| Field | Rule |
| --- | --- |
| `morning`, `evening` | both present |
| `minutes` | whole minutes, at least 1, the nudge's "about {minutes} minutes" |
| `items` | at least 1, in reading order. The set's total is their number |
| `id` | unique in the file, never reused for another text: progress is stored by it |
| `arabic` | with its marks. A Quran verse is the mushaf text (constitution: Tanzil) |
| `transliteration`, `translation` | English, shown in the English app only |
| `source` | `en` and `ar`, always shown (Brand: hadith always show source and grading) |
| `grading` | optional, `en` and `ar`, shown after the source as "· Sahih" |
| `count` | times said, at least 1 |
| `quran` | true for a verse: the Quran font and the Quran text rules |
| `note` | optional, a `TODO(ahmed)` on every entry that isn't final |

## `assets/duas/duas.json`

```json
{
  "categories": [
    {
      "id": "leaving-home",
      "name": { "en": "Leaving the home", "ar": "مغادرة المنزل" },
      "chip": "home",
      "duas": [
        {
          "id": "d001",
          "arabic": "بِسْمِ اللَّهِ، تَوَكَّلْتُ عَلَى اللَّهِ، وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ",
          "transliteration": "Bismillah, tawakkaltu ʿala Allah, wa la hawla wa la quwwata illa billah.",
          "translation": "In the name of Allah, I place my trust in Allah, and there is no might nor power except with Allah.",
          "source": { "en": "Abu Dawud 5095", "ar": "أبو داود ٥٠٩٥" },
          "grading": null,
          "audio": null,
          "note": "TODO(ahmed): the 4.14 sample, check the text and its source"
        }
      ]
    }
  ]
}
```

| Field | Rule |
| --- | --- |
| `categories` | in the order All shows them. The first category's first dua is All's card |
| category `id` | unique |
| `name` | `en` and `ar` |
| `chip` | one of `morningEvening`, `home`, `travel`, `sleep` |
| `duas` | at least 1 |
| dua `id` | unique in the file, the same dua in two categories keeps one id |
| `arabic`, `transliteration`, `translation`, `source`, `grading`, `note` | as in `azkar.json` |
| `audio` | null, or an asset path under `assets/duas/audio/` listed in `pubspec.yaml`. Null = Listen does nothing |

## What the app reads

| Read (Dart) | Gives |
| --- | --- |
| `azkarContentProvider` (core) | `AzkarContent` with `setOf(AzkarSet)`: minutes and items |
| `loadAzkarContent()` (core, no Riverpod) | the same, for the background top-up |
| `duasContentProvider` (duas) | the categories with their duas |
