# Feature Specification: Enhancements after 009

**Feature Branch**: `feature/enhancment-4`

**Created**: 2026-10-30

**Status**: Clarified (grilled, Q1 to Q40, terms in `GLOSSARY.md`, ADR 0001)

**Input**: User description, my notes after running 009:

```text
i want to edit some stuff (don't fill any gap and ask me any questions):
- the adhan is so cheep and has echo sounds, i want to remove all of them and add a high and standrad adhan (give me links to listen to them before you apply them)
- in calander i want to check alnogside the prayer if prayed or status of it in prayer times tab, and make right check alongside the title of tab if all five prayed
- for comming up: i want to calc from the current date not the selected date, but show what is after the selected date normally
- i want to make the bottom sheet initially opened with height 400 and when start scroll make it bigger to 720
- add another tasfeer (upload them to github and allow user to donwlaod): like Tafsir al-Tabari, Tafsir al-Qurtubi
- i want to add smart search for quran like 4.27 Search in Quran.do.html "better-muslim/Living Sky prayer app branding 2/09 Quran.dc.html"
- in note tab for quran, make a checkbox for highlight, and if checked, make the selected aya alittle colored in mushaf
    - also add another third tab in saved page for quran called highlights, and show all ayas that checked box while taking notes
    - i want make bookmark categories, means when user tap on bookmark, show dialog with different bookmark categiries he made , and allow him to create more, and let him to choose the colored and name of it.
    - and if user bookmarked aya show the icon of it in the mashaf at the end of the aya

- let user to downalod the surah to be offline
- and alos add four sounds rather than mishary alafasy
- allow to jump 10 seconds or back 10 seconds while playing quran, and also allow user to drag the progress bar while playing to go forward or backward
- also on repeat button, add another option that keeps the current surah on repeat, means when finished start from the begging and etc..

Widgets:
- the widgets not adaptive with the choosing theme
- i want to change and all the widgets like those three ones (promots/widget1,widget2,widget3), in ios and android, again the typicall those images
- i want when close/puase app in the background the app show the fourth image (promots/widget4.png) live activtiy in both ios and android

Home:
- i want to redesign the prayers in home and make it in single row like this image (promots/home-prayers.png)
- i want to make the floasting header in home in glass way and reflected with sun or night color like here (Living Sky prayer app branding 2/01 Brand.dc.html) in echo, not repeat

Theme:
- i want to add all others themes exist here (Living Sky prayer app branding 2/04 Themes - Exploration.dc.html) you are not added

Loading:
- i want to make a custom widget loading like "Self-drawing star, 0.5 pt line · 3.6 s draw, ease-in-out · rests, then fades" that exist in (Living Sky prayer app branding 2/01 Brand.dc.html) in 02 second motif: noor

Azkar:
- make custom of font for azkar seperated from the quaran and appearit in azkar page

Duas:
- i want to add more duas, and add more categories
```

## Problem Statement

After running 009 a lot of small things still feel unfinished or cheap.

The adhan recordings echo and sound like they were taped from a street, so the most important
sound in the app is its weakest part. The calendar's Prayer times tab shows the times but not
whether I prayed them, and Coming up counts days from the day I tapped instead of from today, so
"in 3 days" is wrong as soon as I select another day. The study sheet opens either too small or too
big for long tafsir. There are only two tafsirs, no way to search the Quran, and notes, bookmarks
and highlights are thin: no way to make an ayah stand out on the page, no way to group bookmarks,
and nothing on the page shows that an ayah is bookmarked.

Recitation is one reciter, needs the internet every time, can't skip 10 seconds, can't be dragged,
and can't keep a surah going. The widgets ignore the theme I chose and the Android ones don't match
the iOS ones. The lock screen countdown only shows two hours before a prayer. On a 12-hour phone
the Home strip breaks into five rows. Half of the explored themes never made it in. The loader is
the old oil drop, azkar share the Quran's font, and Duas has 20 duas in 5 categories.

## Solution

One pass over the whole app, in the order of my list:

- **Adhan**: the three downloaded recordings go now, and Madinah with the Malmö Fajr stays only
  until a muezzin gives permission. I email Mishary Alafasy (bundled) and Nasser Al-Qatami
  (downloadable) for their standard and Fajr recordings. A permitted pair replaces Madinah.
- **Calendar**: every prayer in the Prayer times tab shows its prayer status, a ✓ follows the tab
  title when all five are prayed, and Coming up counts from today.
- **Study sheet**: opens at 400 and grows to 720 before its text scrolls.
- **Tafsir**: Tabari and Qurtubi join Ibn Kathir and As-Sa'di as downloads.
- **Search**: 4.27, the Quran search as designed.
- **Notes, highlights, bookmarks**: a note can highlight its ayah on the mushaf, Saved gets a
  Highlights tab, bookmarks live in named and colored categories, and a bookmarked ayah shows a
  ribbon in the page margin.
- **Recitation**: four more reciters, surahs downloaded for offline, ±10 s, a draggable bar, and a
  surah loop.
- **Widgets**: follow the theme and mode, the same three sizes on iOS and Android, and the live
  countdown whenever the app isn't on screen.
- **Home**: the strip stays one row on 12-hour phones, and the compact bar gets the sky's echo.
- **Themes**: the 8 missing themes from the exploration, 16 in all.
- **Loader**: the self-drawing star replaces the oil drop.
- **Azkar**: their own font, picked on the Azkar page.
- **Duas**: all of Hisn al-Muslim and the Quranic duas, in more categories.

## User Stories

### Adhan

1. As someone who prays, I want the adhan to be a clean studio recording with no echo, so that the call to prayer sounds as it should.
2. As someone who prays, I want Fajr to always play the same muezzin's Fajr adhan, so that the voice never switches at Fajr and "as-salatu khayrun min an-nawm" is always there.
3. As someone who prays, I want one recording inside the app, so that the adhan works on the first launch with no internet.
4. As someone who prays, I want one other recording I can download, so that I have a choice without the app getting bigger.
5. As someone who picked a recording that is removed, I want the app to switch me to the bundled one by itself, so that I never get a silent adhan.
6. As someone who downloaded a removed recording, I want its files deleted from my phone, so that they don't take space for nothing.
7. As the developer, I want a permission email ready for each muezzin, so that I can ask for the recordings and their credit line before shipping them.
8. As someone who prays, I want the app never to ship without an adhan, so that the old pair plays until a permitted pair arrives.

### Calendar

9. As someone who prays, I want each prayer in the calendar's Prayer times tab to show its prayer status, so that I can see any day's log next to its times.
10. As someone who prays, I want a ✓ for a prayer that was prayed or made up, so that both read as done.
11. As someone with qada, I want a muted "In qada" on a prayer still in qada, so that I know it's waiting.
12. As someone who prays, I want nothing on a future or unlogged prayer and never anything on Sunrise, so that the tab stays quiet where there's nothing to say.
13. As someone who prays, I want to tap a prayer in that tab and land on the Prayer tab at that day and prayer, so that I can log it right away.
14. As someone who prays, I want a ✓ after "Prayer times" in the tab title when all five of the selected day are prayed or made up, so that a complete day is visible without reading every row.
15. As someone who prays, I want the five dots under the date to stay, so that nothing I already use goes away.
16. As a calendar user, I want Coming up to list the events after the selected day, so that I can look ahead from any day I tap.
17. As a calendar user, I want each event's count to be from today, so that "in 12 days" is always true.
18. As a calendar user, I want "Today" on an event that falls today, so that it reads naturally.
19. As a calendar user, I want a muted "12 days ago" on an event that already passed when I selected a past day, so that I can tell past from coming.

### Study sheet

20. As a Quran reader, I want the study sheet to open at 400, so that I see the start of the tafsir with the page still behind it.
21. As a Quran reader, I want the sheet to grow to 720 when I start scrolling its text, before the text itself scrolls, so that long tafsir gets the room it needs.
22. As a Quran reader, I want dragging down to go from 720 to 400 and from 400 to closed, so that I can step back one height at a time.
23. As a reader on a short phone, I want 720 capped to what fits under the status bar, so that the sheet never runs off the screen.

### Tafsir

24. As a Quran reader, I want to download Tafsir al-Tabari, so that I can read the earliest full tafsir offline.
25. As a Quran reader, I want to download Tafsir al-Qurtubi, so that I can read its rulings next to the ayah.
26. As a Quran reader, I want the new tafsirs downloaded the same way as Ibn Kathir and As-Sa'di, checked before use, so that a broken download never shows wrong text.
27. As a Quran reader, I want the credits to name the new tafsirs and their source, so that their use is clear.

### Search

28. As a Quran reader, I want to search the whole Quran from Quran home's search slot, so that I can find an ayah I half remember.
29. As a Quran reader, I want my search to ignore diacritics and hamza forms, so that typing without tashkeel still finds the ayah.
30. As a Quran reader, I want to choose All, Ayah text or Translation, so that I can search the Arabic or the meaning.
31. As a Quran reader, I want results grouped by surah, so that I can see where a word repeats.
32. As a Quran reader, I want the matched word washed behind its glyphs, never recolored, so that I see the match without the text being changed.
33. As a Quran reader, I want typing a surah name to show a "Jump to surah" card, so that I can open a surah in one tap.
34. As a Quran reader, I want "p 50" to jump to page 50, so that I can open a page I know.
35. As a Quran reader, I want "2:255" to jump to that ayah, so that I can open a reference I know.
36. As a Quran reader, I want to tap a result and land on that ayah in the reader, so that I can read it in its page.
37. As a Quran reader, I want a Root chip only if the roots come from a source we may use, so that the app never ships data it has no right to.

### Notes and highlights

38. As a Quran reader, I want a "Highlight in mushaf" checkbox under the note field, so that I can make an ayah stand out on the page.
39. As a Quran reader, I want to highlight an ayah with an empty note, so that I don't have to write anything to mark it.
40. As a Quran reader, I want a highlight to be a soft accent wash behind the ayah, so that it stands out without the glyphs being recolored.
41. As a Quran reader, I want the highlight to look different from the selection, so that I never confuse the two.
42. As a Quran reader, I want highlights left out of share images, so that what I share is the clean ayah.
43. As a Quran reader, I want unchecking the box to remove the highlight, so that I can undo it where I set it.
44. As a Quran reader, I want a Highlights tab in Saved next to Bookmarks and Notes, so that I can find every highlighted ayah.
45. As a Quran reader, I want each highlight row to show the reference, the ayah and the note if there is one, so that I know why I marked it.
46. As a Quran reader, I want to tap a highlight and land on that ayah, so that I can read it in place.
47. As a Quran reader, I want a long press on a highlight to remove it, so that I can clear old ones from the list.

### Bookmarks

48. As a Quran reader, I want tapping Bookmark to open a sheet of my categories, so that I choose where the ayah goes.
49. As a Quran reader, I want each category row to show its color, name and count, so that I can tell them apart.
50. As a Quran reader, I want a "New category" row with a name field and colors, so that I can make a category without leaving the sheet.
51. As a Quran reader, I want picking a category to save the bookmark and close the sheet, so that bookmarking stays one tap after the first.
52. As a Quran reader, I want the sheet on a bookmarked ayah to tick its category and show "Remove bookmark", so that I can move or remove it.
53. As a Quran reader, I want the top bar's page bookmark to use the same sheet, so that pages and ayahs are bookmarked the same way.
54. As a Quran reader, I want to pick a category color from a fixed set of 8, so that every color reads well in every theme and both modes.
55. As a Quran reader, I want a bookmark to keep its own optional name, so that I can still label one ayah inside a category.
56. As a Quran reader, I want my existing bookmarks moved into a default "Bookmarks" category, so that nothing is lost.
57. As a Quran reader, I want "Bookmarks" never to be deletable, so that there is always somewhere to save.
58. As a Quran reader, I want to rename and recolor any category, "Bookmarks" too, so that it fits how I use it.
59. As a Quran reader, I want deleting a category to ask first and then remove its bookmarks, so that I can't delete a group by accident.
60. As a Quran reader, I want Saved's Bookmarks grouped under category headers, so that I see my groups at a glance.
61. As a Quran reader, I want a ribbon in the page margin beside the line where a bookmarked ayah ends, in its category's color, so that I see my bookmarks while reading without anything over the text.
62. As someone restoring a backup, I want my categories, bookmarks and highlights to come back, so that a new phone is the same as the old one.
63. As someone restoring an older backup, I want its bookmarks to land in "Bookmarks", so that an old file still restores.

### Recitation

64. As a listener, I want to choose between Alafasy, Al-Husary, Abdul Basit, Al-Minshawi and Maher Al-Muaiqly, so that I can listen in the voice I love.
65. As a listener, I want to open the reciter list from the reciter in the recitation sheet, so that it's where I already control playback.
66. As a listener, I want my reciter saved, so that it's the same next time.
67. As a listener, I want a download button in the recitation sheet's head for the surah and reciter I'm on, so that I can keep it for offline.
68. As a listener, I want the download to show its progress and then "Downloaded", so that I know when it's safe to go offline.
69. As a listener on a plane, I want a downloaded surah to play with no internet, so that recitation works anywhere.
70. As a listener, I want a Downloads page in More listing my surahs per reciter with their size, so that I can see what takes space.
71. As a listener, I want to delete a downloaded surah, so that I can free space.
72. As a listener, I want +10 s and −10 s buttons, so that I can repeat or skip a part of a long ayah.
73. As a listener, I want ±10 s to cross into the next or previous ayah, so that skipping near an ayah's end still works.
74. As a listener, I want the bar to show which ayah of the range is playing, so that I know where I am in the surah.
75. As a listener, I want to drag the bar and see "Ayah 45" under my finger, then jump there on release, so that I can move through a surah fast.
76. As a listener, I want the controls in the order repeat, previous, −10, play, +10, next, speed, so that play stays in the middle.
77. As a listener, I want the repeat button to cycle off, 2, 3, 5, 10 and surah loop, so that both repeating each ayah and looping the surah are one button.
78. As a memoriser, I want surah loop to play the range again from its start until I stop it or the sleep timer ends, so that I can keep a surah going.
79. As a listener, I want the credits to name each reciter and EveryAyah, so that their use is clear.

### Widgets and the live countdown

80. As a user, I want my widgets in the theme I chose, so that my home screen matches the app.
81. As a user, I want widgets to follow the app's mode, and Follow sky to flip at sunrise and maghrib on its own, so that they change with the day like the app.
82. As a user, I want the live countdown always in the theme's dark palette, so that it reads on the lock screen.
83. As an iOS user, I want the three widgets to match their designs line by line, so that they look as designed.
84. As an Android user, I want the same small, medium and large widgets as iOS, so that both phones get the same app.
85. As a user, I want the live countdown whenever the app isn't on screen, backgrounded or swiped away, so that the next prayer is always on my lock screen.
86. As a user, I want the countdown to roll to each next prayer, so that it never shows a passed one.
87. As a user, I want the countdown gone while the app is open, so that it doesn't repeat what's on screen.
88. As a user, I want the existing Prayer countdown switch to still turn it off, so that I can live without it.
89. As an iOS 18 to 25 user, I want the countdown to show "Maghrib · now" and wait for me to open the app when iOS doesn't let it start the next one, so that it's honest about the limit.

### Home

90. As a user on a 12-hour phone, I want the prayer strip in one row, so that Home looks as designed.
91. As a user on a 12-hour phone, I want the strip to drop AM/PM, so that the times fit, while the rest of the app keeps it.
92. As a user with large text, I want the strip to stack above text scale 1.4, so that nothing is cut.
93. As a user, I want Home's compact glass bar to carry the sky's glow behind it, rose at fajr, gold at asr, amber at maghrib and navy at isha, so that the header echoes the sky.
94. As a user, I want the top-glow switch in More to turn that glow off too, so that one switch rules every glow.

### Themes

95. As a user, I want Sahara Sand, Zaytun, Attar, Noor Midnight, Qiyam Dusk, Qiyam Copper, Qiyam Lapis and Qiyam Sand, so that I have all 16 explored themes.
96. As a user, I want every new theme to pass AA in light and dark, so that text stays readable.
97. As a user, I want the 16 swatches in 4 rows with the new ones after the current 8, so that the picker stays tidy.
98. As an Arabic user, I want every theme named in Arabic, so that the picker reads in my language.
99. As a user, I want each new theme to have its own sky, so that Home matches the theme.

### Loader

100. As a user, I want the self-drawing star wherever something loads, so that waiting feels like the brand.
101. As a user, I want a download's star drawn up to its percentage, so that I see how far it is.
102. As a user with reduce motion, I want the whole star breathing instead of drawing, so that it still shows life without motion.

### Azkar

103. As someone reading azkar, I want an "Aa" button on the Azkar page to pick the azkar font, so that I can read in the script I like.
104. As someone reading azkar, I want Amiri, Scheherazade New or Noto Naskh Arabic, so that I have a real choice.
105. As someone reading azkar, I want the choice to apply to azkar, duas and Tasbih, so that all my dhikr reads the same.
106. As a Quran reader, I want the azkar font kept apart from the Quran font, so that changing one never changes the other.
107. As someone reading azkar, I want verses inside azkar (Ayat al-Kursi, the Quls) to keep the Quran font, so that Quran text always looks like the Quran.

### Duas

108. As someone making dua, I want every Hisn al-Muslim chapter except morning and evening, so that I find a dua for my situation.
109. As someone making dua, I want each dua in Arabic with its source, so that I know where it comes from.
110. As someone making dua, I want Prayer, Distress, Illness, Weather and Food chips, and a filled Travel chip, so that I can find duas by situation.
111. As someone making dua, I want a Quranic duas chip with the Rabbana duas, so that I have the duas of the Quran in one place.
112. As someone making dua, I want each Quranic dua to show the Sahih International English and play its ayahs from EveryAyah, so that I understand and hear them.

## Implementation Decisions

### General

- One spec, one phase per area, built in the order of my list: A Adhan, B Calendar, C Study
  sheet, D Tafsir, E Search, F Notes, highlights and bookmarks, G Recitation, H Widgets and the
  live countdown, I Home, J Themes, K Loader, L Azkar font, M Duas. Each phase stops for my
  review.
- Built on `feature/enhancment-4`, on top of the committed TODO(ahmed) pass.
- The constitution holds everywhere: Quran glyphs are never recolored or overlapped, every wash
  is drawn behind them, no golden or screenshot tests, everything works offline except
  downloads, no backend, every licensed source credited.

### A. Adhan

- The three downloaded recordings (Aaqib Azeez, Andrewler, Synagda) leave the recording list,
  their strings and their credits. Madinah and the Malmö Fajr stay until a permitted pair
  arrives.
- The saved recording is stored by its enum name, so a removed name would fail to read. The
  database migration rewrites any removed recording to Madinah, and the files they downloaded
  are deleted from the phone.
- The `adhan-v1` release stays untouched.
- Two permission emails go into the release checklist with a `TODO(ahmed)`, one to Mishary
  Alafasy (the bundled pair) and one to Nasser Al-Qatami (the downloadable pair). Each asks for
  the standard and Fajr recordings as WAV, permission to ship them in a free app with no ads,
  and the credit line they want.
- When a permission arrives: Alafasy's pair replaces Madinah and the Malmö Fajr in the app, and
  Al-Qatami's pair goes into a new adhan release with sha256 checks, downloaded like before.
  Each recording keeps its own Fajr, its notification clips and its credit. A saved Madinah
  becomes Alafasy.

### B. Calendar

- The Prayer times tab's rows reuse the Home strip's mark from the prayer row state: ✓ for
  prayed or made up, a muted "In qada", nothing for future or unlogged, never on Sunrise.
- A row tap goes to the Prayer tab's existing day and prayer route.
- A ✓ in the success color follows "Prayer times" in the segment when all five of the selected
  day are prayed or made up. The dots stay.
- The coming up model takes today as well as the selected day. It still lists from the day
  after the selected day, and each pill counts from today: "Today", "in N days", or a muted
  "N days ago".

### C. Study sheet

- Only the ayah's study sheet (4.23) changes, every other sheet stays as it is.
- Two heights, 400 and 720 (720 capped to what fits under the status bar). Scrolling the
  content up first grows the sheet to 720, and only then scrolls the content. Dragging down goes
  720, 400, closed.
- The heights are named entries in the size manager.

### D. Tafsir

- The build tool's tafsir list gets Tabari (quran.com id 15) and Qurtubi (id 90). Each is built
  into one gzip like the others, with its sha256 in the tafsir files list.
- Both go in a new release, `tafsir-v2`, on `better-muslim-content`, uploaded with `gh` as part
  of this work. `tafsir-v1` stays as it is.
- The download, check, cache and picker work the same as Ibn Kathir and As-Sa'di.

### E. Search

- Built from 4.27: All, Ayah text and Translation chips, a "Jump to surah" card, results grouped
  by surah with the matched word washed in `primaryContainer` behind its glyphs.
- The search is one plain function over the Quran text and translation shipped in the app: a
  query in, the jump card (surah, page or ayah) and the grouped hits out. It strips diacritics
  and folds hamza and alef forms on both sides. No typo guessing.
- "p 50" means page 50, "2:255" means surah 2 ayah 255, a surah name in Arabic or English means
  that surah.
- The entry point is Quran home's search slot.
- The Root chip searches the Quranic Arabic Corpus' roots, credited with its GPL.

### F. Notes, highlights and bookmarks

- A note gets a highlight flag. A note may now be empty when it's highlighted, and a note with
  no text and no highlight is deleted.
- The highlight is the accent at low alpha, drawn behind the ayah the same way as the selection
  wash. Share images don't draw it.
- Saved gets a third tab, Highlights. A row tap opens the reader at the ayah, a long press
  removes the highlight.
- A new category table: name, one of 8 fixed colors, order. A bookmark points to exactly one
  category and keeps its own optional name. The bookmark's ribbon color moves to the category.
- The migration makes the default "Bookmarks" category in the primary color and moves every
  existing bookmark into it. Their old ribbon colors are dropped.
- The 8 colors are named entries in the theme system and pass AA for graphics on every theme's
  page in both modes.
- The bookmark picker is a sheet: categories with color, name and count, a "New category" row
  with a name field and the 8 colors, a tick and "Remove bookmark" when already bookmarked. Ayah
  and page bookmarks use it.
- "Bookmarks" can be renamed and recolored but never deleted. Deleting another category asks
  first, then removes its bookmarks.
- Saved's Bookmarks are grouped under category headers.
- The mushaf draws a small ribbon in the side margin beside the line where a bookmarked ayah
  ends, in its category's color. Nothing is drawn inside the text line.
- The backup file carries categories and highlights. An older backup restores its bookmarks
  into "Bookmarks".

### G. Recitation

- Per ADR 0001 the audio stays one EveryAyah file per ayah.
- The reciter becomes a setting with five values: Alafasy (default), Al-Husary, Abdul Basit
  (Murattal), Al-Minshawi (Murattal), Maher Al-Muaiqly. Each is its EveryAyah folder. The
  recitation files build their urls and cache paths from the reciter.
- A reciter list opens from the reciter in the recitation sheet. The credits name all five and
  EveryAyah.
- A downloaded surah is all its ayah files for one reciter on the phone, the bismillah too. The
  player plays from the phone when the file is there, otherwise from the network as now.
- The recitation sheet's head gets a download button for the current surah and reciter, with
  the star's progress, then "Downloaded". More gets a Downloads page listing surahs per reciter
  with size and delete.
- The bar shows "ayah n of total". Dragging shows "Ayah n" under the finger and seeks there on
  release.
- ±10 s seeks in the current ayah's audio and crosses into the next or previous ayah when it
  runs past either end.
- The controls row: repeat, previous, −10, play, +10, next, speed. Media controls are never
  mirrored.
- Repeat cycles off, 2, 3, 5, 10, surah loop, off. Surah loop plays the range from its start
  when it ends, until it's stopped or the sleep timer ends. The recitation queue owns this, the
  same as ayah repeat.

### H. Widgets and the live countdown

- The surface data sent to the widgets carries the theme's palette roles for light and dark,
  the app's mode and, for Follow sky, the moments it flips. The native widgets read colors from
  there instead of their hard-coded ones.
- The live countdown always uses the theme's dark palette.
- Constitution II's always-dark exception no longer covers the widgets. II and the
  architecture test's allow list are amended to match, with the version bumped as the
  governance section says.
- iOS widgets are checked line by line against 5.6 (widget1 is medium, widget2 large, widget3
  small).
- Android's three widgets become small 2×2, medium 4×2 and large 4×4, built from the same trees.
  The 4×1 is dropped.
- The live countdown starts when the app leaves the screen and ends when it comes back. It
  counts to the next prayer and rolls to each next one. It replaces the 2-hour countdown
  windows. The existing switch and having no place still mean none.
- iOS limits: a Live Activity ends after 8 hours. Before iOS 26 the app can't start one from the
  background, so on iOS 18 to 25 it shows "<prayer> · now" and waits for the app to open. On
  iOS 26 the next one starts by itself. Android's ongoing notification has none of these
  limits.

### I. Home

- The strip is one row up to text scale 1.4 and stacks above it, as the constitution says.
- On 12-hour phones the strip shows times without AM/PM. Everywhere else keeps it.
- Home's compact bar keeps its glass and gets the sky glow the other pages' titles have behind
  it. The top-glow switch turns it off. No colored hairline.

### J. Themes

- Eight new theme ids, in exploration order after the current eight: Sahara Sand, Zaytun,
  Attar, Noor Midnight, Qiyam Dusk, Qiyam Copper, Qiyam Lapis, Qiyam Sand.
- The exploration file gives 14 roles per mode. The other 13 roles are derived from each one's
  nearest current theme the way that theme derives them.
- Skies come from the palette's sky roles through the existing theme sky, so they need no extra
  values.
- The picker shows 16 swatches in 4 rows. Each theme gets English and Arabic names in both arb
  files.

### K. Loader

- One star loader in core replaces the oil drop everywhere it shows: tafsir download, study
  tabs, mini player, the recording sheet, the dev page and the loader gate.
- A 0.5 pt line, a 3.6 s draw with ease-in-out, the four strokes starting at 0, 400, 900 and
  1400 ms, an 800 ms rest, a 400 ms fade, then again.
- With a known progress the line is drawn up to the percentage.
- With reduce motion the whole star breathes.
- The timings are named entries in the motion tokens.

### L. Azkar font

- A new setting, the azkar font: Amiri (default, as today), Scheherazade New, Noto Naskh Arabic.
  Noto Naskh Arabic is added under the OFL with its credit.
- An "Aa" button on the Azkar page opens a sheet to pick it.
- It applies to the azkar, dua and Tasbih text. Verses inside azkar keep the Quran font, and
  the Quran's Display font is untouched.

### M. Duas

- The dua content gets every Hisn al-Muslim chapter except morning and evening, about 250
  duas, Arabic with source. English stays hidden as decided in 009.
- New categories: Prayer, Distress, Illness, Weather, Food. Travel gets its duas.
- A Quranic duas category holds the Rabbana duas as ayah references, shown with the Sahih
  International English the app already ships and played from EveryAyah.

### Schema

- The database goes past 13 in as many steps as the phases need: the removed recordings,
  categories and highlights, the reciter, the azkar font. Each step has its migration test.

## Testing Decisions

- A good test drives the thing from the outside the way the app does and checks what the user
  or the next layer sees. No private state, no widget internals, no goldens, no screenshot or
  PNG checks.
- Each area uses the test files that already exist:
  - Adhan: `adhan_settings_page_test`, `adhan_player_test`, and `migration_test` for the
    rewrite of removed recordings.
  - Calendar: `hijri_calendar_page_test` for the marks, the row tap and the ✓ by the title.
    `coming_up_test` for listing after the selected day and counting from today.
  - Study sheet: `study_tabs_test` and `ayah_sheet_test` for 400, growing to 720 before the text
    scrolls, and 720 to 400 to closed.
  - Tafsir: `tafsir_files_test` for Tabari and Qurtubi with their sha256.
  - Notes, highlights, bookmarks: `migration_test` and `app_database_test` for categories and
    the default one, `ayah_sheet_test` for the checkbox and the picker, `saved_page_test` for
    Highlights and the category headers, `backup_file_test` and `restore_test` for the new data
    and old backups.
  - Recitation: `recitation_queue_test` for the repeat cycle, surah loop, ±10 s across ayahs and
    the drag to an ayah. `recitation_files_test` for the five reciters' urls and a downloaded
    surah. `recitation_sheet_test` for the controls and the reciter list.
  - Widgets and the live countdown: `surface_data_test` and `write_surfaces_test` for the theme
    and mode sent out, and the countdown following the app leaving and coming back in place of
    the 2-hour windows.
  - Home: `home_page_test` and `break_ui_test` for one row up to 1.4, no AM/PM, and the glow
    with its switch.
  - Themes: `bm_theme_test`, `contrast_test` for AA on all 16 in both modes, `theme_page_test`
    for the 16 swatches.
  - Loader: `loader_gate_test`, replacing `oil_drop_test`, for progress and reduce motion.
  - Azkar font and duas: `azkar_page_test`, `dua_content_test` for sources and full categories,
    `duas_page_test`.
- One new piece is tested on its own: the Quran search function, in a unit test like
  `dua_search_test`, against the shipped text: "2:255", "p 50", surah names in both languages,
  no diacritics, every hamza form. The search page gets one widget test.
- `architecture_test`, `strings_manager_test` and `font_manager_test` stay green.
- Not tested in code: the Swift and Kotlin layouts of the widgets and the live countdown, and
  how the star and the glow look. I check those by running the app.

## Out of Scope

- Any adhan recording without the muezzin's or studio's permission, and deleting the
  `adhan-v1` release.
- Baghawi, al-Wasit and any other tafsir.
- Typo-tolerant search.
- Whole-surah audio files with timings (ADR 0001), and any reciter beyond the five.
- A free color wheel for categories, a bookmark in more than one category, and a bookmark icon
  inside the text line.
- Changing any sheet other than the study sheet.
- A countdown that restarts by itself on iOS before 26.
- English for the Hisn al-Muslim duas.
- A tablet layout.

## Further Notes

- The words follow `GLOSSARY.md`: prayer status, qada, made up, selected day, coming up, note,
  highlight, bookmark, category, reciter, downloaded surah, ayah repeat, surah loop, recording,
  live countdown, widget, echo.
- Phase A's second half waits on the muezzins' answers. Until then the app ships Madinah and
  the Malmö Fajr.
- A category is renamed, recolored and deleted from a long press on its row in the picker sheet,
  which opens the same form as New category, with Delete.
- The Quranic duas play in the reciter chosen for recitation.
- The work is split into the tickets in `tickets/`, one file each, blockers first. They replace
  speckit's plan and tasks for 010, the decisions above are the plan.
- The Root chip uses the Quranic Arabic Corpus, my call on 2026-10-31 since nothing else has a
  root for every word. What was checked first:
  - Quranic Arabic Corpus (corpus.quran.com): GPL v3, the whole app would have to be GPL.
  - QUL's "Word root" (qul.tarteel.ai/resources/morphology/76): its licence page says "We don't
    have copyright information for this resource", and QUL credits the morphology to Kais Dukes,
    so it's the corpus again.
  - q-ran/quran on GitHub: its data says CC BY 4.0, but it's taken from the corpus 0.4, a GPL work
    can't be put under CC BY by someone else.
  - Quranpedia's dumps: the root fields are the corpus 0.4 again, under the corpus' license.
  - MASAQ (Mendeley Data 9yvrzxktmr): CC BY and annotated from Tanzil, but its files have no root
    column, only the word, the segments, the tags and the i'rab.
  - hablullah/data-quran: CC BY-NC-ND, no derivatives and no commercial use.
