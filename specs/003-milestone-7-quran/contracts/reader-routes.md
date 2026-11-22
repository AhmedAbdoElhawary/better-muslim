# Contract: Reader routes and entry points

## Routes

| Route | Opens |
| --- | --- |
| `/quran` | Quran home (4.18), in the shell |
| `/quran/page/:page?ayah=S:A` | the reader on that page, the ayah washed when given, outside the shell |
| `/quran/saved` | Saved (4.29) with Bookmarks and Notes, outside the shell |

`Routes.quranPage(page, {AyahKey? ayah})` and `Routes.quranSaved` build them.

## Who opens the reader

| From | How |
| --- | --- |
| Continue reading on 4.18 | `BmContainerTransform` from the card into the page |
| a surah, juz or page row | `BmContainerTransform` from the row |
| Home's Continue reading shortcut | `context.push(Routes.quranPage(lastRead.page))` |
| Home's verse card | `Routes.quranPage(page, ayah: key)`, the page from `QuranAssets.pageOf(key)` |
| a bookmark or note row | `Routes.quranPage(page, ayah: key)` |
| the recitation's notification tap | the playing page |

Home reads `lastReadProvider` and `QuranAssets` from `core/quran/`, never the feature.

## Dev

`/dev/notifications` (the dev page from More) gets a Loader section: the oil drop at 48, 24 and
16 pt and a progress slider (FR-059).
