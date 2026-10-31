# 02: Drop the three downloaded recordings

**What to build:** The adhan sheet lists only Madinah, with the Malmö Fajr at Fajr. Aaqib Azeez,
Andrewler and Synagda are gone from the app. Anyone who had one of them picked gets Madinah after
the update, and the files they downloaded are deleted from the phone.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] The recording list, the adhan settings page and the recording sheet show Madinah only.
- [x] Their strings leave `StringsManager` and both arb files, their lines leave the credits.
- [x] The saved recording is stored by its enum name, so a database step rewrites every saved
      removed recording to Madinah before the enum loses them. `migration_test` covers it.
- [x] Their downloaded files and notification clips are deleted from the phone on the first
      launch after the update.
- [x] The `adhan-v1` release is untouched.
- [x] `adhan_settings_page_test` and `adhan_player_test` pass with the shorter list.
