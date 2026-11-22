# 32: Tones and takbir only

**What to build:** On Adhan and reminders, a prayer on Tone opens a tone sheet like the adhan
sound sheet: the phone's own sound or one of four tones in the app, a tap picks and plays, save
keeps it. The adhan sound sheet gets Full adhan or Takbir only on top. Takbir only is the opening
"الله أكبر الله أكبر", the clip the notification already plays, so it needs no new audio, no adhan
screen and no native player.

**Blocked by:** nothing

**Status:** done

- [x] Each prayer keeps its own tone and its own adhan length (db v23), defaults phone and full.
- [x] Calm, Glass, Bright and Echo from akx/Notifications (CC0) are in `assets/audio/`,
      `res/raw/` and `ios/Runner/Sounds/`, credited in Acknowledgements.
- [x] Android gets one channel per tone, the phone tone keeps `adhan_<prayer>_tone`, so a sound
      changed in the phone's settings stays.
- [x] Takbir only goes through the plugin with the adhan channel's clip, iOS plays it in front
      too. Coming in with the app open or tapped, it opens no adhan screen.
- [x] The takbir preview plays the full file up to the clip's length (0:20, Fajr 0:22).
- [x] The row under the prayer says "Mishary Alafasy · takbir only", the tone row its tone.
