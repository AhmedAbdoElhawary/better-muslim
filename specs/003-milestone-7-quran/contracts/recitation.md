# Contract: Recitation files and player

## Files

- Address: `https://everyayah.com/data/Alafasy_128kbps/{SSS}{AAA}.mp3`, surah and ayah padded to
  3 digits. `TODO(ahmed)` at the constant.
- Bismillah before ayah 1 of every surah except 1 and 9: `001001.mp3`, washing the basmallah line.
- Stored at `{Application Support}/recitations/alafasy/{SSS}{AAA}.mp3`, the folder excluded with
  `BackupExclusion.exclude` on creation, never in the backup file.
- Written to `{name}.part`, renamed only when the bytes equal `Content-Length` and the first bytes
  are `ID3` or an MPEG frame sync (`0xFF 0xE0` mask). Otherwise deleted, and the next play fetches
  it again.
- https only, no added headers, no query string.
- One download at a time: the playing ayah, then the rest of the surah in order.

## `RecitationHandler` (audio_service)

```dart
abstract class Recitation {
  Stream<RecitationState> get state;           // idle, loading, playing, paused + ayah + position
  Future<void> play(AyahKey from, {AyahKey? to}); // to = end of surah by default
  Future<void> pause();
  Future<void> resume();
  Future<void> next();
  Future<void> previous();
  Future<void> setSpeed(double speed);         // 0.75 to 1.5
  Future<void> setRepeat(int times);           // 1, 2, 3, 5, 10
  Future<void> setPause(Duration gap);         // 0 to 5 s
  Future<void> setSleep(SleepTimer timer);     // off, minutes, end of surah
  Future<void> stop();
}
```

The tests use a fake; only `AudioServiceRecitation` touches the phone.

- Media item: title `{surah} · Ayah {n}` in the app's language and digits, artist the reciter.
- Controls on the lock screen and notification: previous, play or pause, next.
- A tap on the notification opens `Routes.quranPage(playing page)` with the playing ayah.
- `AudioService.init` runs only in the app's own run (`main_*.dart` through `bootstrap`), never in a
  background engine (workmanager, a notification's background isolate).
- Before it plays it claims `AudioUse.recitation`; it pauses when `AudioUse.adhan` is claimed.
- `audio_session` music config, like the other two players: interruptions and becoming noisy
  pause it, an interruption's end never resumes it.

## Android

- `MainActivity` extends `AudioServiceActivity`.
- Manifest: `com.ryanheise.audioservice.AudioService` (foreground service type `mediaPlayback`) and
  `MediaButtonReceiver`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK` permission.

## iOS

- `UIBackgroundModes` already has `audio`.
