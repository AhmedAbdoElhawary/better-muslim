# 03: Ship the permitted recordings

**What to build:** Once a muezzin says yes and I put his WAV files in the repo, his pair goes in.
Alafasy's standard and Fajr adhan ship inside the app and replace Madinah and the Malmö Fajr.
Al-Qatami's pair is the downloadable alternative. Each Fajr plays its own muezzin's Fajr.

**Blocked by:** 01, 02, and my WAV files with the written permission. Each pair can go in alone
when its answer comes.

**Status:** done, Alafasy only. No Fajr adhan of Al-Qatami exists, so his pair is dropped

- [x] Alafasy's pair is bundled, encoded like the current files, with its notification clips for
      iOS and Android.
- [x] Madinah and the Malmö Fajr leave the app, the strings and the credits. A database step
      moves a saved Madinah to Alafasy.
- [x] ~~Al-Qatami's pair and its clips are in a new adhan release with their sha256, downloaded and
      checked like the old downloads.~~ Dropped, there's no Fajr of his to pair with it.
- [x] Fajr always plays the chosen recording's own Fajr, never another muezzin's.
- [x] The credit names Mishary Rashid Alafasy for the adhan and Fajr.
- [x] The emails and their `TODO(ahmed)` are gone.
