# Launch on Google Play

Every answer Play Console asks for, in the order I meet them. The App Store part comes with the iOS
lane.

My account is personal and newer than 13 Nov 2023, so production waits for a closed test: at least
12 testers opted in for 14 days in a row.

## 1. Before the first upload

- [x] The keystore (`~/.android-keys/better-muslim-upload.jks`) and `android/key.properties` are
      backed up off this Mac, in iCloud Drive as `better-muslim-keys.dmg` (encrypted).
- [x] The privacy policy is approved and live at
      `https://ahmedabdoelhawary.github.io/better-muslim-content/privacy/`, and the row in More ›
      About opens it.
- [ ] Sentry project: Settings › Security & Privacy › "Prevent Storing of IP Addresses" is on, and an
      alert emails me on a new issue.
- [ ] Screenshots and the feature graphic are redone for Android, see "Graphics" in
      `design_handoff_better_muslim/store/LISTING.md`, and the slots in "Graphics" below.

## 2. The build

1. `feature/release-prep` merges into `develop` with the `release: v1.0.0-dev.6` marker, the dev
   app reaches App Distribution.
2. PR `develop` → `staging`. The integration journeys run there, the staging app reaches App
   Distribution.
3. PR `staging` → `production`. CI tags `v1.0.0`, builds it through Shorebird, uploads the symbols
   to Sentry, sends the production app to App Distribution and puts the `.aab` on the GitHub
   release.
4. Download that `.aab` from the `v1.0.0` release. Play only ever gets this file, never a local
   build.

## 3. Create the app

- App name: `Better Muslim: Prayer & Quran`
- Default language: English (United States), Arabic added as a translation
- App or game: App
- Free or paid: Free
- Declarations: both ticked

## 4. App signing

On the first upload, let Google create the app signing key (the default). My keystore stays the
upload key.

A production build installed from App Distribution is signed with my upload key, so the Play build
can't update it. Uninstall it once before installing from Play. That wipes what is on the phone.

## 5. App content

### Privacy policy

`https://ahmedabdoelhawary.github.io/better-muslim-content/privacy/`

### Ads

No, the app has no ads.

### App access

All functionality is available without special access.

### Content rating

- Category: Reference, News, or Educational
- Violence, sexual content, bad language, drugs, gambling: No to all
- Users interact or share content with each other in the app: No. Sharing an ayah opens the
  phone's share sheet, nothing is shared inside the app
- Shares the user's location with others: No
- Digital purchases: No

It should come out as Everyone / PEGI 3.

### Target audience

- Ages: 13–15, 16–17, 18 and over. Under 13 brings in the Families policy and its rules for every
  SDK in the app.
- Could the store listing appeal to children: No

### News app

No.

### Health, financial features, government app

No to all.

### Advertising ID

No, the app doesn't use the advertising ID. No SDK in it adds `AD_ID`.

### Data safety

- Does the app collect or share any of the required user data types: Yes
- Is all collected data encrypted in transit: Yes
- Can users ask for their data to be deleted: No. There is no account and crash reports aren't
  linked to a person. The policy says how to write to me.

Collected, never shared (Sentry and Shorebird work for me, so they don't count as sharing):

| Data type | Required or optional | Why |
| --- | --- | --- |
| App info and performance › Crash logs | Optional, the crash reports switch | Analytics |
| App info and performance › Diagnostics | Optional, the crash reports switch | Analytics |
| Device or other IDs | Required, Shorebird's install id has no switch | App functionality, Analytics |
| Personal info › Email address | Optional, only if written on the feedback page | Developer communications |
| App activity › Other user-generated content | Optional, the feedback message | Developer communications |

Not collected: location. It is used only on the phone for prayer times and the Qibla, and Play
doesn't count data that never leaves the phone. Same for the prayer log, notes, bookmarks and what
someone reads.

### Foreground services

Play lists each type the manifest declares. For each: what it does, what breaks without it, and a
video link (unlisted YouTube or a Drive link anyone can open).

**Media playback**, use case: Media playback

> The Quran recitation the user starts from the reader keeps playing with the screen locked, with a
> media notification to pause and stop it. The full adhan the user picked for a prayer plays at that
> prayer's time with a notification to stop it, like an alarm clock. Without it the recitation stops
> when the screen locks and the adhan is cut off after a few seconds.

Video, about 40 seconds:
1. Open a surah, tap play, lock the phone, show the notification with pause and stop.
2. More › Adhan and reminders, pick the full adhan for a prayer.
3. Dev build › More › Notifications (dev) › Test adhan in 1 min, show the adhan playing with its
   notification, tap Stop.

**Data sync**, use case: Network transfer, upload or download

> A download the user starts (a reciter's recitation, a tafsir or a Mushaf style) goes on when the
> user leaves the app, with a notification that shows the progress and can pause or cancel it.
> Without it the download stops as soon as the app is in the background.

Video, about 30 seconds:
1. Start a reciter or tafsir download.
2. Go to the home screen, pull down the notification with its progress.
3. Tap Pause, then go back to the app and see it waiting.

**Location**, only if Play lists it

> The app doesn't run a location foreground service. The location library declares one that the app
> never starts, and the app doesn't ask for FOREGROUND_SERVICE_LOCATION. Location is read only while
> the app is open, for prayer times and the Qibla.

### Exact alarms

Nothing to declare. The app asks for `SCHEDULE_EXACT_ALARM`, which the person allows in the phone's
settings. Play only restricts `USE_EXACT_ALARM`, which the app doesn't use.

## 6. Store listing

Copy everything from the "Google Play" part of `design_handoff_better_muslim/store/LISTING.md`,
English under the default language and Arabic under the Arabic translation.

- App category: Lifestyle
- Contact email: elhawarydev@gmail.com
- Website: optional, the LinkedIn link from More
- Countries: all

### Graphics

Everything below goes straight into Play Console › Grow users › Store presence › Main store
listing. None of it is in git (`design_handoff_better_muslim/store/` is ignored).

| Slot | Size | English | Arabic |
| --- | --- | --- | --- |
| App icon | 512 × 512 PNG | `assets/app_icon/png/play_store_512.png` | same |
| Feature graphic | 1024 × 500, no transparency | `[ ] my file` | `[ ] my file` |
| Phone screenshots, 2 to 8 | 1080 × 2160 | `[ ] 1` `[ ] 2` `[ ] 3` `[ ] 4` `[ ] 5` `[ ] 6` | `[ ] 1` `[ ] 2` `[ ] 3` `[ ] 4` `[ ] 5` `[ ] 6` |
| 7-inch and 10-inch tablet | optional | skip, the app has no tablet layout yet | skip |

## 7. Internal test

1. Testing › Internal testing › create a release with the `.aab`.
2. Add my own Google account as a tester, install from the opt-in link.
3. Run through it on the phone: onboarding, a prayer's adhan, a recitation with the screen off, a
   download, the widget, the countdown notification, Rate.

## 8. Closed test, 14 days

1. Testing › Closed testing › create a track, add at least 12 testers by email (a Google Group is
   easiest). Firebase App Distribution testers don't count, they have to opt in on Play.
2. Promote the internal release to it. This one goes through review, so it can take a few days.
3. Send the opt-in link. The 14 days count from when 12 people have opted in. Stopping or pausing
   the track resets them, a tester leaving doesn't.
4. During the test, ship one harmless Shorebird patch with the `hotfix` skill and check it reaches
   my phone. That is the rehearsal before real users.
5. Read Play's pre-launch report and the Sentry issues from the testers.
6. After 14 days: Dashboard › Apply for production. It asks how the test went, what testers said
   and what changed.

## 9. Production

- Release the same `v1.0.0` (or the newest closed test build) to production as a staged rollout:
  20% first.
- After a few days with no new crashes in Sentry, go to 100%.
- Then check the Play link in More › Share opens the listing.
