# Better Muslim

Prayer times, Quran, azkar and qibla on the phone. These are the words the app and its specs use.

## Prayer

**Prayer status**:
What the log says about one prayer on one day: prayed, made up, in qada, or nothing yet.
_Avoid_: state, result

**Qada**:
A missed prayer kept on the list to pray later.
_Avoid_: debt, missed list

**Made up**:
A qada prayer that has since been prayed. It counts as prayed for the day.

**Now window**:
The first 20 minutes after a prayer's time, while the app shows that prayer as now. The prayer is still on time after it, until the next prayer comes.
_Avoid_: prayer period, iqamah time

**Highlighted prayer**:
The prayer Home and the Prayer tab point at: the prayer in its now window, otherwise the next prayer.
Shown as now in its now window, as next otherwise.
_Avoid_: selected prayer, current prayer

**Boundary**:
A time when what the app shows changes on its own: a prayer time, the end of its now window, sunrise, maghrib, local midnight.
_Avoid_: reminder, tick, timer

## Calendar

**Selected day**:
The day tapped in the calendar. It may be today, a past day or a future day.
_Avoid_: current day

**Coming up**:
The events after the selected day, each counted in days from today.

## Quran

**Note**:
One private text written on one ayah.

**Highlight**:
An ayah set to stand out on the mushaf page, set from its note. It may have no note text.
_Avoid_: mark, color, selection

**Bookmark**:
A saved ayah or page. It is in exactly one category and may have its own name.

**Category**:
A named, colored group of bookmarks. "Bookmarks" is the one that always exists.
_Avoid_: ribbon color, folder, tag

**Bookmarked number**:
A bookmarked ayah's number, with a ribbon in its category's color behind it.
_Avoid_: bookmark wash, highlight, page ribbon

**Page ribbon**:
The ribbon hanging from the mushaf page's top edge, in the color of the page's newest bookmark.

**Page color**:
The paper the mushaf is drawn on: White, Paper, Cream, Sepia, Green, Night, Navy, or the app's mode.
_Avoid_: theme, page theme

**Translation**:
The meaning under each ayah in the Translation layout and on its Ayah sheet, one picked from those in the app. Al-Muyassar and al-Jalalayn count as one for Arabic, though they are short tafsirs.
_Avoid_: tafsir (for the picked one)

**Ayah sheet**:
The sheet with one ayah's translation and what I can do with it: play, tafsir, bookmark, note, share, copy.
_Avoid_: actions, ayah menu

**Reader controls**:
The top bar and the dock over the mushaf page.
_Avoid_: app bar, navigation bar, chrome

**Turn strip**:
The strip at each side of the mushaf page that turns it on a tap. The left one goes to the next page and the right one to the previous, in both languages.
_Avoid_: tap zone, margin

**Kashida**:
A joining stroke between two letters drawn longer, so a mushaf line fills its width instead of leaving wide gaps between words.
_Avoid_: stretch, tatweel

**Print**:
An edition of the Madinah Mushaf, 1421H or 1405H. It fixes which words sit on which page and line, and so the page numbers.
_Avoid_: edition, version, layout

**Mushaf style**:
How the mushaf page draws its words: Text, Printed page, Tajweed colors or Old print. Text is the font picked in Display on the 1421H print's lines. The other three draw every word as its print does, in the King Fahd Complex's QCF page fonts: Printed page (QCF V2) and Tajweed colors (QCF V4) the 1421H print, Old print (QCF V1) the 1405H print.
_Avoid_: QCF V2, QCF V4, QCF V1 (as a style's name), font (for a printed style), mushaf font, mushaf theme

**Tajweed key**:
The eight colors of the Tajweed colors style with the rule each one marks, printed at the foot of the page on both sides of the page number. It grows and shrinks with the mushaf size, half as much as the words.
_Avoid_: tajweed legend, tajweed footer

**Reciter**:
The voice the recitation plays in.
_Avoid_: qari, sheikh, sound

**Downloaded surah**:
A surah whose whole recitation by one reciter is on the phone, so it plays offline.

**Ayah repeat**:
Each ayah in the range plays a number of times before the next one.

**Surah loop**:
The range plays again from its start when it ends, until stopped.
_Avoid_: repeat surah

## Adhan

**Recording**:
One muezzin's adhan, always with his own Fajr version.
_Avoid_: sound, voice, track

**Prayer sound**:
How one prayer reaches the phone: Adhan, Tone or Silent. It sets the sound of its Reminder and of its time. Silent still shows both.
_Avoid_: tab, alert type

**Takbir**:
The opening "Allahu akbar" of a Recording, about 20 seconds. It plays with the Reminder of a prayer on Adhan, never at the prayer time.
_Avoid_: takbir only, clip

**Full adhan**:
The whole Recording, played at the time of a prayer on Adhan. Where the phone can't play it, the time comes with no sound.

## Surfaces

**Reminder**:
The alert before a prayer, at the time set in "Reminder before each prayer". It comes whether the app is open or not.
_Avoid_: notification before the prayer, pre-adhan alert

**Azkar nudge**:
The alert a while after Fajr for the morning set and after Asr for the evening set. A calm voice says the set's name, unless that is turned off. It never buzzes, and the next one replaces it.
_Avoid_: azkar notification, azkar reminder

**Live countdown**:
The next prayer counting down from its Reminder until its time. An ongoing notification on Android, where it is the Reminder itself. A Live Activity on iOS, which only starts as the app leaves.
_Avoid_: live activity (for both), countdown widget

**Widget**:
A home screen tile: small, medium or large.

## Design

**Arc**:
The half circle in Home's sky. Sunrise to Maghrib by day, Maghrib to Sunrise by night.
_Avoid_: half circle

**Arc label**:
The name and time of a point on the arc, beside it.
_Avoid_: arc text, point name

**Sky event**:
A short moment in Home's sky: a burst, a shooting star, a rock or a glint. One comes on its own every few seconds, and one answers a tap on the sky.
_Avoid_: sky animation, effect

**Glint**:
The warm spark that leaves the sun, or the three stars by night. A tapped one starts at the tap.
_Avoid_: burst, sparkle

**Home bar**:
The compact glass bar at the top of Home. It shows the next prayer and its countdown once the card has gone under it.
_Avoid_: app bar, compact bar, glass bar

**Flight**:
The next prayer's name and countdown leaving the card for the Home bar as the page scrolls. It starts when the card reaches the Home bar.
_Avoid_: collapse, transition

**Echo**:
The sky's color carried outside the sky as a trace, like a glow behind a header.
_Avoid_: repeat, sky copy

**Theme**:
One of the 8 palettes the app is drawn in, like Moonlight or Iznik. Each has a light and a dark side.
_Avoid_: mode, skin

**Mode**:
Which side of the theme the app shows: Dark, Light, Follow sky or Follow phone. Follow phone is where a new install starts.
_Avoid_: theme, appearance

**Follow sky**:
The mode that is light from Sunrise until Maghrib and dark from Maghrib until Sunrise. Before there is a place, it is the phone's light or dark.
_Avoid_: auto, day and night

**Follow phone**:
The mode that is light or dark whenever the phone is, and switches the moment the phone does.
_Avoid_: follow system, system default

## Launch

**Cold open**:
Opening the app when it isn't running, after a reboot, a swipe from recents or the phone closing it, from the icon, a widget or a notification. It ends when Home is drawn whole.
_Avoid_: initial open, first open, startup

**Resume**:
Coming back to the app while it is still running in the background.
_Avoid_: warm open, reopen

## Shipping

**App name**:
The name under the icon: Better Muslim, or مسلم أفضل on a phone in Arabic. It follows the phone's language, never the app's Language setting.
_Avoid_: display name, label

**Version tag**:
The name CI gives one merge, like v1.0.0-stag.1. Everything that ships comes from one.
_Avoid_: release, build tag

**Tester build**:
A build of one flavor for the people testing it, never for the public.
_Avoid_: release, beta

**Store release**:
A version that reaches people through Google Play or the App Store.
_Avoid_: release, production build

**Patch**:
A Dart-only update to a Store release that arrives with no store update.
_Avoid_: hotfix, code push, update
