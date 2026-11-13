# Feature Specification: More reciters

**Feature Branch**: `feature/quran-reading`

**Created**: 2026-11-13

**Status**: Clarified (grilled once, Q1 to Q7, all recommendations)

**Input**:

```text
i want to add those reader (if some are already added just ignore them):
أحمد النفيس
 محمد محمود الطبلاوي
ناصر القطامي
حسن محمد صالح
عبد الرحمن مسعد
إسلام صبحي
هيثم الدخين
```

## Decisions

### Who

- Al-Tablawi and Al-Qatami were already in, from EveryAyah.
- Ahmad Al-Nufais, Hassan Mohamed Saleh and Haitham Al-Dukhain come from mp3quran.net: one mp3
  per surah at 128 kbps, with each ayah's start and end (ADR 0005).
- Islam Sobhi is left out: mp3quran has 109 surahs and no timings for him.
- Abdulrahman Mosad is left out: no source with an address, only zips on download sites.

### Playing

- Each ayah plays as its clip of the surah file. Repeat, the ayah bar, ±10 s, follow, the pause
  between ayahs and the sleep timer work as with the ayah files. The bismillah is what comes
  before the first ayah.
- A surah that isn't downloaded streams from mp3quran, nothing of it is kept. Downloading it
  first would mean minutes of silence before Al-Baqarah starts.
- A surah's timings are fetched once, checked (every ayah from 1 in order, each ending after it
  starts) and kept next to the recitation folder.
- Duas with ayahs play in these voices too, as clips.

### Downloads

- A download is the surah file and its timings. The file goes to `.part`, is checked for its
  length and an mp3 start, and renamed. Progress follows the bytes.
- Delete removes both.

### Surahs the check found wrong

- mp3quran's timings are off for some surahs: ayahs a fraction of a second long, files that
  stop minutes after the last ayah. `tool/quran/check_surah_reciters.py` streams every surah
  through ffmpeg and checks the timings against the voice, the wrong ones go in the reciter's
  `missing`. On 2026-11-13: Al-Nufais 104 of 114 (Al-Fatiha and Al-Baqarah among the missing),
  Hassan Saleh 93, Al-Dukhain 107.
- Playing or downloading a missing surah says "This surah isn't in this voice yet, pick another
  reciter." No retry.

### Names

- Arabic as I spelled them, أحمد النفيس, حسن محمد صالح, هيثم الدخين, short النفيس, حسن صالح,
  الدخين. English Ahmad Al-Nufais, Hassan Mohamed Saleh, Haitham Al-Dukhain.
- Credits: `mp3quran.net · <name>` for each, linking mp3quran.net.

## On my phones

- [ ] Al-Nufais from Al-Baqarah 255, Android and iPhone: the right ayah starts, follow moves
      with it, the next ayah comes with no gap.
- [ ] Repeat 3 on one ayah, and ±10 s across two ayahs.
- [ ] Download Al-Mulk in Al-Dukhain, airplane mode, it plays.
