# 30: All of Hisn al-Muslim

**What to build:** Duas gets every Hisn al-Muslim chapter except morning and evening, which are in
Azkar: about 250 duas in Arabic with their source. New chips Prayer, Distress, Illness, Weather
and Food join the others, and Travel gets its duas.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] Each chapter is a category in the dua content with its Arabic and English name, its duas
      and their sources.
- [x] English stays hidden, as decided in 009.
- [x] Each chapter's chip is the one it fits: Home, Travel, Sleep, Prayer, Distress, Illness,
      Weather or Food. Eating moves from Home to Food. A chapter that fits none shows under All
      only.
- [x] The new chips have their strings in both arb files.
- [x] Dua search finds the new duas.
- [x] `dua_content_test` checks every dua has a source and every chip has duas.
      `duas_page_test` covers the new chips.
- [x] Listen downloads each dua's clip from hisnmuslim.com once, checked by its sha256, and plays
      it offline after.
