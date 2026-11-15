# Feature Specification: Qibla, feedback and rating

**Feature Branch**: `feature/enhance1`

**Created**: 2026-11-15

**Status**: Built, waiting for my review (grilled once, Q1 to Q12, all recommendations but Q11)

**Input**:

```text
- the qibla depends on the selected location, detect it always, and it's a little off even after
  Use my location. make it accurate from where the phone is and its angle
- remove the show app name switch, always show it on the share card
- when silent during prayer turns on, scroll down by itself
- a separate page for send feedback, sent to my email from inside the app
- a bottom sheet in the app for rating, not the play store
- remove acknowledgements
```

## Decisions

### Qibla

- Home's qibla card and the Qibla page use where the phone is, also when a city was picked by hand.
  Prayer times keep the picked city.
- No permission, location off or no fix in 10 s: the saved place, as before.
- The Qibla page follows a high accuracy position, every 10 m, only while it's on screen and the
  app is in front. Home takes one fix when it shows the card and keeps it while the app runs.
- The compass's declination comes from the same position, not the saved place. A city picked far
  away moved both the bearing and true north, that was the few degrees.
- Opening the Qibla page asks for location once while the phone still lets it (iOS once ever,
  Android until its second no). Home never asks.
- The place line names the nearest city of the offline list to the fix.
- The bearing is on the WGS84 ellipsoid (Vincenty), the sphere was up to 0.25° off. Tests hold it
  to 0.01° of 20 reference places and the declination to NOAA's WMM2025 test values.

### Share card

- The app name is always on the card. The Show app name switch and its string are gone.

### Silent during prayer

- Turning it on, also coming back from the phone's Do Not Disturb page with access, scrolls just
  enough to show Silent for, with the standard motion, a jump with reduce motion. Not when it's
  already shown, not when the page opens with it on.

### Feedback

- Send feedback in More opens its own page: a growing message field (required, 1,000 at most), an
  optional email for a reply, a line saying the version, phone and system go with it, and Send,
  off until there's text.
- Sent through Sentry's user feedback, queued offline and sent when back online. Sentry mails it
  to me (Settings → Notifications → User Feedback). Only release builds with a DSN send it. Nothing
  leaves the phone before Send. The mail draft and the Contact email are gone.
- After Send: a thank you toast and back to More.

### Rating

- Rate the app opens the store's own review sheet over the app (`in_app_review`), the stars go to
  the store. The store decides how often it shows, a tap can show nothing.
- Shown on iOS too, it needs no link. Share app still waits for the App Store link.

### Credits

- Changed after the build (ticket 07): every credit is on one Credits page from About, the
  Muyassar line under the tafsir moved there too. Only the names whose license or terms ask for
  credit: GeoNames, King Fahd Glorious Quran Printing Complex, Tanzil, Quranic Arabic Corpus, each
  with its use and license, text only, no tap and no links. No open source licenses card.
