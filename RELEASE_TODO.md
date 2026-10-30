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

- [ ] Make the release keystore and `android/key.properties` (keyAlias, keyPassword, storeFile,
      storePassword), both stay out of git. Without them a local release build is debug signed.
      (`android/app/build.gradle.kts`)

## Store listings

- [ ] Once the app is on the App Store, put its link in `appStoreUrl`. Rate and Share on iOS stay
      hidden until then. (`lib/features/more/model/contact.dart`)
- [ ] The Play link is already set to `com.elhawary.bettermuslim`. Check it opens once the app is
      listed.

## Dua audio

- [ ] Send the email below to hisnmuslim.com.
- [ ] If they say yes, put the clips in `assets/duas/audio/` and their paths in
      `assets/duas/duas.json`. Listen shows on a dua by itself once it has a clip.
      (`lib/features/duas/model/dua.dart`)
- [ ] Add their credit line to `lib/features/more/model/credits.dart` if they give one.

> **Subject:** Permission to use Hisn al-Muslim audio in a free app
>
> Assalamu alaikum,
>
> I'm building Better Muslim, a free app for iOS and Android with no ads and no account, for prayer
> times, Quran, azkar and duas. The azkar and duas text comes from Hisn al-Muslim, and the app
> credits the book and links to hisnmuslim.com.
>
> May I include your audio recordings of the duas in the app? Each one would play from its dua
> card, with your site credited on the Acknowledgements page. If you have terms or a credit line
> you'd like me to use, I'll follow them exactly.
>
> JazakAllahu khairan,
> Ahmed Abdo Elhawary
> elhawarydev@gmail.com

## Check on my phones

- [ ] Android, Dev: More › dev page › Adhan check, all three lines should say yes. Then
      "Test adhan in 1 min" and listen to the full adhan with the screen off.
- [ ] Android: pick Aaqib Azeez in the adhan sound sheet, it downloads and plays.
- [ ] iOS, after the Apple account items: a downloaded recording plays its clip in the
      notification (the clip is saved to `Library/Sounds`).
- [ ] Turn on UI sounds in More and listen to the toggle, tasbih bead, tasbih complete, qibla
      aligned and Mark prayed. Swap any I don't like in `assets/audio/ui_*.m4a`, same names.

## Decide

- [ ] The Home sky scrim is 38% instead of the handoff's 28%, the least that keeps the bright
      skies AA while they drift. Keep it or go back. (`ThemeEnum.skyScrim` in
      `lib/core/resources/theme_manager.dart`)
- [ ] The welcome has a 52% scrim behind its text on every sky. Keep it or go back.
      (`ThemeEnum.welcomeScrim`)
- [ ] Listen is hidden on duas with no clip, the handoff shows it on every dua. Keep it hidden
      until the clips are in or show it.
