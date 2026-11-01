# Left before release

Each item below also has a `TODO(ahmed)` where it lives, so `grep -rn "TODO(ahmed)"` finds them all.

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
- [ ] Back up both somewhere safe. Play App Signing can reset a lost upload key, but only after a
      support request.
- [ ] Put the keystore in the repo secrets so CI signs with it (`ANDROID_KEYSTORE_BASE64`,
      `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`).

## Content

- [ ] Upload `build/tafsir/tabari.json.gz` and `qurtubi.json.gz` to the `tafsir-v2` release of
      `better-muslim-content`. Their download fails until then.
      (`lib/features/quran/data/tafsir_files.dart`)

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
- [ ] Turn on UI sounds in More and listen to the toggle, tasbih bead, tasbih complete, qibla
      aligned and Mark prayed. Swap any I don't like in `assets/audio/ui_*.m4a`, same names.
- [ ] Listen on a few Hisn al-Muslim duas, each downloads from hisnmuslim.com once and then plays
      offline.
