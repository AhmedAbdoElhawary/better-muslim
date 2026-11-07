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

## Surfaces

**Reminder**:
The alert before a prayer, at the time set in "Reminder before each prayer". It comes whether the app is open or not.
_Avoid_: notification before the prayer, pre-adhan alert

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

## Shipping

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
