# Recitation and adhan licensing

Checked on 2026-10-30 against the owners' own pages. Where an old page is gone, the Wayback Machine
copy of that page is the source. This is my reading of public terms, not legal advice.

## 1. EveryAyah

**Today the site publishes no license or terms.** The home page (https://everyayah.com/) links
only to the data folders, the old index and a "Contact Us" that goes to Quran.com's help desk
(https://quran.zendesk.com/hc/en-us). There's no about page, terms page or license file in
https://everyayah.com/data/ or https://everyayah.com/data/Alafasy_128kbps/.

**It used to publish one: CC BY-NC 2.5 Canada.**

- Every reciter folder had a `000_license.html` saying "use of these MP3s is only allowed if you
  comply with the license details" and linking to `versebyversequran.com/site/license`. The
  Alafasy copy was still there in 2017
  (https://web.archive.org/web/20151108103731/http://www.everyayah.com:80/data/Alafasy_128kbps/000_license.html).
  Today it returns 404 (https://everyayah.com/data/Alafasy_128kbps/000_license.html).
- That license page just framed https://creativecommons.org/licenses/by-nc/2.5/ca/
  (https://web.archive.org/web/20120421132421/http://www.versebyversequran.com:80/site/license).
- The 2007 "About This Project" page says the files are free for "a Quran site or software" and
  "licensed under a Creative Commons Attribution-Noncommercial 2.5 Canada License"
  (https://web.archive.org/web/20111108112341/http://www.versebyversequran.com/site/about).
- The timing files still ship this disclaimer: "(C) VerseByVerseQuran.com. You must link back to
  our site from your product and web-site to use these timings"
  (https://everyayah.com/data/timings_files/000_disclaimer.txt).

**Who runs it:** the old footer reads "Copyright © 2012 Verse By Verse Quran (EveryAyah.com)", and
the menu linked to Quran.com. No person or company is named. WHOIS shows the domain from 2008 with
the registrant redacted. Today's contact link going to Quran.com's help desk suggests the
Quran.com people run it now, but nobody states that anywhere.

**Where the recordings came from, and reciter permission:** none of these pages says. EveryAyah
splits full-surah recordings into ayah files (its tools folder has the splitters,
https://everyayah.com/data/tools/), and some timing files name the source, e.g. "Abu Bakr
Ash-Shatree Seperate Mp3 Files From AudioIslamDotCom"
(https://everyayah.com/data/timings_files/). **I found no statement that Alafasy or any other
reciter gave permission.** A CC license from EveryAyah only covers rights EveryAyah holds. It can't
license the reciter's own performance.

## 2. Quran.com / Quran Foundation

**Quran Foundation API** (Developer Terms, last updated 2026-10-11,
https://api-docs.quran.foundation/legal/developer-terms/):

- "QF Content" includes audio. Developers get a revocable license to use the APIs "to develop and
  operate Applications that provide beneficial Quranic experiences to end users."
- **Free and even paid apps are allowed** without a separate license, as long as QF Content is only
  shown inside the app and isn't sold, sublicensed or redistributed as data. Redistribution (a
  dataset, feed, API or content package) needs a signed commercial license.
- **Caching:** content can't be kept more than 1 week unless it comes through the Content Sync
  APIs. Content Sync must re-sync at least every 7 days when the phone is online.
- Content Sync covers `recitations` (ayah audio files plus timing segments) and
  `chapter_recitations`
  (https://api-docs.quran.foundation/docs/tutorials/content-sync/getting-started/).
- Every call needs `x-client-id` and an access token. You get them by creating an app in the
  Developer Console and asking for production scopes (https://api-docs.quran.foundation/request-access/).
- You must have a public privacy policy and terms of use that meet QF's privacy requirements.
- A Quran Foundation credit is required for social-media videos and for bundled fonts and Mushaf
  images. The terms don't spell out a credit rule for audio in an app.
- The audio SDK page says "Audio returned by the APIs is QF Content" and points to the terms for
  "storage, offline playback, redistribution, or commercial use"
  (https://api-docs.quran.foundation/docs/sdk/javascript/audio/).
- Contact: developers@quran.com.
- **Reciter permissions: the terms say nothing about them.** The only words on this are "QF retains
  its rights in the APIs and QF Content it owns."

**Quran.com site terms** (https://quran.com/terms-and-conditions): content is "FOR YOUR PERSONAL,
NON-COMMERCIAL USE ONLY". Copying or distributing it needs "the prior written consent of
Quran.com". The API terms above are the developer route, the site terms aren't.

**QuranicAudio.com** (https://quranicaudio.com/about): "Mp3s on this site may be downloaded and
used for personal use free of charge. However, you may not use these files for commercial
purposes." It says files are "hand ripped from cds" or "downloaded from various other ... sites".
No reciter permission is claimed and nothing covers apps.

## 3. Mishary Alafasy's official channels

- alafasy.com is a parked "Domain for sale" page that frames bye.net. alafasy.me didn't respond.
- https://www.alafasy.co/ calls itself "Alafasy App (Official) by Sheikh Mishary Rashid Alafasy".
  It's run by ALAFASY BERHAD (202501010149), Subang Jaya, Malaysia, phone +603 8682 3105.
- Its terms (https://www.alafasy.co/terms-of-use) say: "All content and materials in the App,
  including Qur'an text, translations, audio ... are owned by Alafasy Berhad or licensed partners.
  Unauthorized use is strictly prohibited."
- **There's no statement allowing free reuse of his recitation or his adhan.**
- **Permission route:** the only email the site shows, on both the contact and terms pages, is
  ai@alafasy.co (https://www.alafasy.co/contact-us), plus the phone number above. That's the
  address for the pending Alafasy email in `RELEASE_TODO.md`.

## 4. Other sources

**Tanzil** (https://tanzil.net/docs/text_license): the Quran text is CC BY 3.0 with no changes
allowed. You must name Tanzil Project, link to tanzil.net and keep the copyright notice. Tanzil
publishes no audio license. Its credits list "Quran Recitations: Verse By Verse Quran Project",
i.e. EveryAyah (https://tanzil.net/docs/credits).

**Islamic Network / alquran.cloud** (https://alquran.cloud/terms-and-conditions):

- "All audio files used on this website and third party libraries own and retain their respective
  copyrights."
- The same page also says: "Recitations are licensed to us by the reciters or their estates for
  free, non-commercial redistribution ... You may bundle them into a commercial product, but please
  note that copyrights lie with the reciters and they may ask you to remove the conent."
- Their own forum contradicts the "licensed by the reciters" line.
  - meezaan wrote that most files "have been taken from everyayah.com or globalquran.com" and "There
    is no explicit right granted"
    (https://community.islamic.network/d/231-clarification-on-licensing-and-usage-rights-for-quran-recitation-api).
  - gokboru wrote that "the copyright still belongs to the translator and the reciter" and "There
    are no attribution requirements from our side"
    (https://community.islamic.network/d/257-commercial-use-of-quran-audio-text-via-your-cdnapi-educational-app).
  - On adhans, gokboru wrote "The mu'addhins who recited the adhans are likely the copyright
    owners, so you would need to contact them directly" (same thread).
  - In an earlier thread gokboru answered Yes/No/No to bundling an AlAdhan adhan in a free app
    (https://community.islamic.network/d/255).
- So the CDN (`cdn.islamic.network/quran/audio/...`) adds no rights beyond EveryAyah's.

**archive.org:** many Alafasy items carry a CC0 or Public Domain Mark, e.g. "Adzan Misyari Rasyid"
(https://archive.org/details/AdzanMisyariRasyid, CC0, uploader "muadzin") and the per-surah
"Mishary Rashed Alafasy" items (Public Domain Mark). These marks are set by uploaders who don't
own the recordings, so they grant nothing. I found no Alafasy item with a license from him or his
label.

## 5. Freely licensed alternatives

Licenses and durations below are the ones on each file page. None of the CC0 adhans name the
muezzin. Commons notes are the uploader's own claims.

### a) Quran recitation

| What | License | Notes |
| --- | --- | --- |
| Aaqib Azeez, uploaded as Atcovi, about 185 files (https://commons.wikimedia.org/wiki/Category:Recitations_of_the_Qur%27an_by_Aaqib_Azeez) | Most murattal files are **CC0**, e.g. Ya-Sin, Al-Kahf, Yunus (`{{self\|cc-zero}}`). Several mujawwad files are CC BY-SA 4.0. | "own work", "murattal, Hafs an Asim". Whole surahs, not per ayah, and not the full Quran. |
| Al-Minshawi, 115 files (https://commons.wikimedia.org/wiki/Category:Recitations_of_the_Qur%27an_by_Al_Minshawi) | Tagged `{{PD-Egypt}}` | Taken from mp3quran.net. Public domain is claimed under Egyptian law, which may not hold elsewhere. |

### b) Adhan, standard and Fajr

**I found no standard and Fajr pair by the same muezzin under an explicit free license.** What exists:

| File | License | Length | Muezzin | Fajr? |
| --- | --- | --- | --- | --- |
| [Eid al-Fitr Fajr azan at Malmö Mosque](https://commons.wikimedia.org/wiki/File:Eid_al-Fitr_Fajr_azan_at_Malm%C3%B6_Mosque_-_19_August_2012.webm) | CC BY 3.0, from the mosque's own YouTube channel, which shows "Creative Commons Attribution license (reuse allowed)" ([video](https://www.youtube.com/watch?v=0IHfm4Y82xA)); Commons YouTubeReview passed | 4:07 | Besim Azemi (in the title) | **Yes**, by title: "Fajr azan", "Ezani Sabahut", "Gryningsbön Azan" (dawn prayer) |
| [Beautiful adhan.ogg](https://commons.wikimedia.org/wiki/File:Beautiful_adhan.ogg) | **CC0** | 2:34 | unnamed, "own work" by Adam-synagda | Not stated, description is just "Adhan." |
| [The Adhan - Aaqib Azeez.mp3](https://commons.wikimedia.org/wiki/File:The_Adhan_-_Muslim_Call_to_Prayer_-_Aaqib_Azeez.mp3) | CC BY-SA 4.0 | 1:27 | Aaqib Azeez | Not stated |
| [Azan.ogg](https://commons.wikimedia.org/wiki/File:Azan.ogg) | CC BY-SA 4.0 | 3:03 | unnamed, by Andrewler | Not stated |
| [Adhan.ogg](https://commons.wikimedia.org/wiki/File:Adhan.ogg) | **CC0** | 0:42 | unnamed, by Aishatu98 | Not stated. Too short to be a full adhan. A CC0 [Iqamah.ogg](https://commons.wikimedia.org/wiki/File:Iqamah.ogg) by the same uploader exists. |
| [33937 ejaz215 call to prayer](https://commons.wikimedia.org/wiki/File:33937_ejaz215_call-to-prayer-from-the-prophet-s-mo.ogg) | CC BY 3.0 | 3:07 | unnamed, "from the prophet mosque" | Not stated |
| [Morning call to prayer, Bodufolhudhoo, Maldives](https://freesound.org/people/jrosin/sounds/861625/) (Freesound) | CC BY 4.0 | 4:45 | unnamed | **Yes**, by description: "This morning call marks Fajr". Field recording with crickets and AC hum. |
| [Early morning adhan, Balakong KL](https://freesound.org/people/aridtrax/sounds/863861/) (Freesound) | CC0 | 4:34 | unnamed | "Early morning", Fajr not named. "Loud exterior aircon unit". |
| [Dhuhr Adhan, Hamtramck MI](https://freesound.org/people/RJStefanski/sounds/255231/) (Freesound) | CC BY 3.0 | 2:43 | unnamed, loudspeaker | No, says Dhuhr |

Other notes:

- **The Madinah file the app used before is gone from Freesound.** ejaz215's 33937 now shows
  "Deleted sound" (https://freesound.org/people/ejaz215/sounds/33937/). The Commons copy keeps its
  CC BY 3.0 tag.
- The Malmö channel has a second adhan,
  ["Islamic Center Malmo - Athan, Ezani, Azan 2011"](https://www.youtube.com/watch?v=2Red8P1K-rE)
  (3:49). Its page shows no Creative Commons license, so it's under YouTube's standard license and
  the muezzin isn't named. With the mosque's written OK it would make a Malmö pair.
- Field recordings of a loudspeaker are licensed by the person who recorded them. The muezzin
  never licensed his performance. Studio "own work" uploads don't have that gap.
- No Commons or Freesound title or description says it contains "as-salatu khayrun min an-nawm".
  I only know a file is Fajr from its title or description. I haven't listened to any of them.

## What this means for the app

**Recitation.**

- EveryAyah publishes no license today. Its last published one was CC BY-NC 2.5 Canada, and no
  reciter's permission is documented anywhere. The app is free, has no ads, credits EveryAyah and
  links back, which fits the old BY-NC terms as far as EveryAyah's own rights go. It still has
  nothing from Alafasy himself.
- Adding the five EveryAyah reciters has the same gap for each one.
- The one documented route is the Quran Foundation API: free app allowed, client credentials,
  offline audio only through Content Sync with a sync every 7 days, a public privacy policy and
  terms. It still doesn't claim reciter consent, only "QF Content it owns".
- **Recommendation:**
  - Keep EveryAyah for Alafasy and add Alafasy's recitation to the same email as the adhan
    (ai@alafasy.co).
  - Pick the five new reciters from those whose rights are clearest, and email developers@quran.com
    asking which reciters Quran.com holds permission for.
  - Moving to the QF API only for its terms isn't worth it. It adds an account, keys and a weekly
    sync but doesn't fix the reciter question.

**Adhan.**

- The archive.org Alafasy pair has no license from anyone who owns it, and Alafasy Berhad's terms
  say "Unauthorized use is strictly prohibited". Keep the TODO and don't release with it unless
  ai@alafasy.co answers yes in writing.
- **Fallback that's clean today:**
  - Fajr: the Malmö Fajr azan (Besim Azemi, CC BY 3.0, credit "Islamic Center Malmö").
  - Standard: Beautiful adhan.ogg (CC0) or the Aaqib Azeez adhan (CC BY-SA 4.0, credit Aaqib
    Azeez / Atcovi; the trimmed clip has to stay CC BY-SA).
- That's two voices, not one.
- **Best path to a same-voice pair:**
  1. Ask Islamic Center Malmö to put its 2011 adhan under CC BY like the Fajr one.
  2. Or ask Aaqib Azeez (User:Atcovi on Commons, who already releases his recitation as CC0) to
     record a Fajr adhan under CC0.
