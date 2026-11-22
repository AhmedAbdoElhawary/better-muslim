# 20: Surah loop

**What to build:** The repeat button cycles off, 2, 3, 5, 10, surah loop, off. With surah loop the
range plays again from its start when it ends, until I stop it or the sleep timer ends.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] The button cycles off, 2, 3, 5, 10, surah loop and shows which one is on.
- [x] Surah loop starts the range again from its start, the whole surah by default, with the
      bismillah as on the first play.
- [x] The sleep timer still ends it, "end of surah" included.
- [x] Last read keeps following the playing ayah.
- [x] The recitation queue owns the loop, like ayah repeat. `recitation_queue_test` covers it.
