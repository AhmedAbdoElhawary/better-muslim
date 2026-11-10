# Feature Specification: Azkar voice

**Feature Branch**: `feature/quran-reading`

**Created**: 2026-11-09

**Status**: Clarified (grilled, Q1 to Q6, all recommendations)

## What I want

When an Azkar nudge comes, a calm voice says "أذكار الصباح" or "أذكار المساء", also with the app
closed.

## Decisions

- The voice is the notification's own sound, about 2 s, not a player on the notification. It
  follows silent, vibrate and Do Not Disturb by itself.
- Always the Arabic name, in both app languages. The notification's text stays in the app's
  language.
- A switch "Say the azkar's name" under "Azkar reminders" on the Azkar tab, on by default
  (db v28). Off, the nudge comes quiet as before.
- No vibration. iOS: active, not time sensitive (passive can't make a sound). Android: one channel
  per set (`azkar_morning`, `azkar_evening`) on the notification stream, the quiet `azkar` channel
  only while the switch is off. Evening still replaces morning.
- The dev page gets "Test morning azkar in 1 min" and "Test evening azkar in 1 min".

## The voice

Nothing ready online says only the set's name, the morning and evening recordings are the whole
azkar and for personal listening. So the two clips are Microsoft's neural Arabic voice Hamed
(ar-SA), read slowly and a little lower, trimmed, with a light room echo, levelled to the tones'
loudness (about -19 LUFS, peak -1.6 dB). `azkar_{morning,evening}.caf` in `ios/Runner/Sounds`,
`.m4a` in `res/raw`. Credited in Acknowledgements.

## On my phones

- [ ] Both test rows on Android and iOS, the phone locked and the app closed.
- [ ] Silent mode: no voice, the nudge still shows.
- [ ] The switch off: the next nudge comes quiet.
