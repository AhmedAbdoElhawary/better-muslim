# Contract: adhan recordings

What each recording ships as and how a prayer's choice reaches the phone. `AdhanRecording` lives
in `core/settings/adhan_recording.dart`.

## The six recordings

| Value | Name key | Sheet line | Full asset | Fajr full | iOS clip, Android raw |
| --- | --- | --- | --- | --- | --- |
| makkah | adhanOfMakkah | Full adhan · 3:52 | adhan_makkah.m4a | adhan_makkah_fajr.m4a | adhan_makkah_clip, adhan_makkah_fajr_clip |
| madinah | recordingMadinah | Full adhan · 4:10 | Makkah's until supplied | Makkah's | Makkah's |
| alAqsa | recordingAlAqsa | Full adhan · 3:31 | Makkah's | Makkah's | Makkah's |
| cairo | recordingCairo | Full adhan · 3:44 | Makkah's | Makkah's | Makkah's |
| istanbul | recordingIstanbul | Full adhan · 4:02 | Makkah's | Makkah's | Makkah's |
| takbir | recordingTakbir | Short · 0:12 | Makkah's | Makkah's | Makkah's |

- The sheet's length comes from the Brand board, the adhan screen's progress from the file.
- One `TODO(ahmed)` above the enum: each recording gets its own four files, named
  `adhan_{name}.m4a`, `adhan_{name}_fajr.m4a`, `adhan_{name}_clip` and `adhan_{name}_fajr_clip`
  (`.caf` in `ios/Runner/Sounds/`, `.m4a` in `android/app/src/main/res/raw/`), clips 30 s or less.

## Android channels

| Prayer's choice | Channel id | Sound |
| --- | --- | --- |
| Adhan with recording r | `adhan_{prayer}_adhan_{r}` | `r.clipOf(prayer)` |
| Tone | `adhan_{prayer}_tone` | the phone's default |
| Silent | `adhan_{prayer}_silent` | none, no vibration |

On every apply each prayer keeps exactly one channel: the other Tone, Silent and Adhan channels
of that prayer, including the milestone 5 id `adhan_{prayer}_adhan`, are deleted. The phone's
settings then list one entry per prayer.

## Native alarm entry

`entryOf(alert, texts, recording)`: `asset` is `recording.fullAsset(prayer)`, `channel` the id
above, `mediaSubtitle` the recording's name. Everything else as in milestone 5.

## Payload

Unchanged. The recording is read from the settings when the adhan plays, so notifications
scheduled before the update keep working.
