# Left before release

Each item below also has a `TODO(ahmed)` where it lives, so `grep -rn "TODO(ahmed)"` finds them all.
The Play Console answers and the release steps are in `.github/LAUNCH.md`.

## Apple developer account

- [ ] Create the app groups `group.com.elhawary.bettermuslim`, `.dev` and `.staging`, and add them
      to the app ids. Without them the widgets read nothing. (`ios/Runner/Runner.entitlements`)
- [ ] Turn on Time Sensitive Notifications for the app ids. Without it iOS delivers the adhan as a
      normal notification. (`ios/Runner/Runner.entitlements`)
- [ ] Register the widget extension app ids (`com.elhawary.bettermuslim.widgets`, `.dev.widgets`,
      `.staging.widgets`), add the same three app groups to them, and pick the signing team on the
      PrayerWidgets target in Xcode. (`ios/PrayerWidgets/Info.plist`,
      `ios/PrayerWidgets/PrayerWidgets.entitlements`)
- [ ] Note the Team ID, it goes into the project after this.

## Android

- [x] The upload keystore is `~/.android-keys/better-muslim-upload.jks`, its passwords are in
      `android/key.properties`. Both stay out of git.
- [x] Back up both somewhere safe, done in iCloud Drive as `better-muslim-keys.dmg` (encrypted). Play App Signing can reset a lost upload key, but only after a
      support request.
- [ ] Declare the media playback and data sync foreground services in Play Console, each with a
      video. (`android/app/src/main/AndroidManifest.xml`)

## Store listings

- [ ] Once the app is on the App Store, put its link in `appStoreUrl`. Rate and Share on iOS stay
      hidden until then. (`lib/features/more/model/contact.dart`)
- [ ] The Play link is already set to `com.elhawary.bettermuslim`. Check it opens once the app is
      listed.

## Check on my phones

- [ ] Android, Dev: More › dev page › Adhan check, all three lines should say yes. Then
      "Test adhan in 1 min" and listen to Alafasy's full adhan with the screen off.
- [ ] A phone that ran the app at `572b14b` has a v15 database that never had the highlight,
      categories or reciter steps, reinstall the app on it.
- [ ] Listen on a few Hisn al-Muslim duas, each downloads from hisnmuslim.com once and then plays
      offline.
