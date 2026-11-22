# 18: Download a surah, and the Downloads page

**What to build:** The recitation sheet's head has a download button for the surah and reciter
I'm on. It shows its progress, then "Downloaded", and that surah plays with no internet. More gets
a Downloads page listing my downloaded surahs per reciter with their size, and I can delete one.

**Blocked by:** 16

**Status:** done

- [x] A download fetches every ayah file of the surah for that reciter, the bismillah too, each
      checked like a played file.
- [x] A surah counts as downloaded only when every file is on the phone.
- [x] The button shows the core loader's progress, then "Downloaded".
- [x] Losing the connection stops with the existing offline message, keeps what's done, and
      tapping again goes on from there.
- [x] A downloaded surah plays fully with no internet.
- [x] More › Downloads lists surahs per reciter with their size and a delete, with an empty
      state.
- [x] The files stay out of the phone's backup like the other recitation files.
- [x] `recitation_files_test` covers a surah download and its delete.
