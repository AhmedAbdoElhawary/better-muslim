# Quickstart: checking milestone 3

## Before

- Milestone 2 committed, `feature/milestone-3` cut from it.
- `flutter pub get`.

## Gates

```bash
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

`flutter test` includes the architecture test, `home_moment_test.dart`, `home_page_test.dart`,
`location_sheet_test.dart`, and the changed core tests (ticker, prayer day, useAuto, scenario).

## Against the PNGs (SC-001)

Run "Dev · design scenario" (VS Code or Android Studio), or:

```bash
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=dart_define/dev.json \
  --dart-define=SCENARIO=design
```

On an iPhone 15 size simulator (393 x 852), screenshot Home and put it next to:

| Phone set to | Compare with | Expect |
| --- | --- | --- |
| dark, English | `reference/screens/4.01-home.png` | NOW Asr, Maghrib in 1:24:00, bar 44%, Fajr and Dhuhr checked, Asr highlighted |
| light, English | `reference/screens/4.02-home-light.png` | same values, the sky's own palette, light cards |
| dark, Arabic | `reference/screens/4.16-home-ar.png` | mirrored, Eastern Arabic digits, arc on the left side, one shortcut row |

Within 1 pt: positions, sizes, colors, fonts, copy, icons. The scenario's clock stands still, so
the countdown stays at 1:24:00.

## Live checks (normal dev run)

| Check | How | Expect |
| --- | --- | --- |
| tick | watch the countdown next to the phone clock for a minute | changes on the same second, only changed digits slide |
| prayer time | set the phone clock to 1 minute before the next prayer | at the time: NOW, card, highlight move on, the sky changes over 1.8 s |
| glow | set the clock to 9 minutes before a prayer | the glow breathes, it is still at 11 minutes |
| night | set the clock after Maghrib | no sun, dotted arc, Isha and Fajr under it, stars on |
| prayer day | set the clock to 01:00 | NOW Isha, the strip still shows yesterday's day with Isha highlighted |
| reduce motion | turn it on in the phone or in the app | no drift, twinkle, pulse, breathing or slide, the sky change is a 0.3 s fade |
| power saving | Low Power Mode or Battery Saver on, reopen the app | the sky is still |
| text scale | 1.5 and 2.0 | the card stacks, the strip is 5 rows, nothing clipped |
| 12 hour | phone on 12 hour | "5:56 PM" fits in the strip, the card and the arc labels |
| screen reader | VoiceOver or TalkBack on the countdown | "1 h 24 min until Maghrib", no announcement every second |
| sheet | tap the pill, search "tanta" and "طنطا" in airplane mode | results with region and country, picking one updates Home within 1 s |
| use my location | deny location, tap "Use my location" | the message shows, nothing changes. Allow it: Home goes back to auto |
| no location | fresh install, deny location | sky with no sun, "No location yet", the card with both choices, no NOW and no strip |
| taps | tap the card, a strip cell, the verse, Continue reading, the azkar row | Prayer, Prayer, Quran, Quran, Azkar tabs |

Screenshots at the end of the milestone: phone and tablet, dark and light, English and Arabic.
