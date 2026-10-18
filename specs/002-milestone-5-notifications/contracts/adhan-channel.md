# Contract: the Android adhan channel

Between Dart (`features/notifications/data/adhan_channel.dart`) and Kotlin
(`android/app/src/main/kotlin/com/elhawary/bettermuslim/adhan/`). Android only, iOS never calls it.
Registered in `MainActivity.configureFlutterEngine`, next to nothing else (iOS's backup channel
lives in `AppDelegate`).

## Method channel `better_muslim/adhan`

| Method | Arguments | Returns | Effect |
| --- | --- | --- | --- |
| `schedule` | `List<Map>` alarm entries (data-model.md) | null | replaces every kept entry and alarm with these |
| `cancelAll` | none | null | removes every kept entry and alarm. Delivered notifications stay |
| `play` | one alarm entry, `fromMillis` | null | starts `AdhanService` for that entry at that offset, unless it already plays it. Checks the ringer first (research R4), returns `false` when it stayed quiet |
| `pause` / `resume` / `stop` | none | null | the playing adhan |
| `markPrayedAction` | `id` | null | drops Mark prayed from the media notification after the screen logged it |
| `length` | `asset` | int millis | the recording's duration |
| `dismiss` | `id` | null | removes a delivered plain notification (the plugin's `cancel` covers it too) |
| `launchPayload` | none | String or null | the payload of the notification that started the activity, once |

## Event channel `better_muslim/adhan/state`

A map every 500 ms while playing, and once on every change:

| Key | Type |
| --- | --- |
| `id` | int or null (idle) |
| `playing` | bool |
| `positionMillis` | int |
| `durationMillis` | int |
| `ended` | bool |

## Event channel `better_muslim/adhan/opened`

The payload string of a media or plain adhan notification tapped while the activity runs
(`onNewIntent`).

## Method channel `better_muslim/adhan/background`

Only in the headless engine of `MarkPrayedReceiver`. Dart calls `done` once the log write ended,
Kotlin destroys the engine (or after 20 s).

## Kotlin side

| Class | Role |
| --- | --- |
| `AdhanAlarms` | keeps the entries in private preferences, sets `setExactAndAllowWhileIdle` alarms, restores them after boot and update |
| `AdhanReceiver` | alarm fired, boot, package replaced. Ringer on → `AdhanService`, else the plain notification without sound |
| `AdhanService` | foreground service `mediaPlayback`: `MediaPlayer`, 1.5 s fade, audio focus, `MediaSessionCompat`, `MediaStyle` notification, custom actions Pause/Play, Mark prayed, Stop |
| `MarkPrayedReceiver` | runs `markPrayedInBackground([payload])` in a headless `FlutterEngine`, then updates the notification |

## Manifest

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>

<service android:name=".adhan.AdhanService" android:exported="false"
    android:foregroundServiceType="mediaPlayback"/>
<receiver android:name=".adhan.AdhanReceiver" android:exported="false">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
    </intent-filter>
</receiver>
<receiver android:name=".adhan.MarkPrayedReceiver" android:exported="false"/>
<!-- plus the plugin's ScheduledNotificationReceiver, ScheduledNotificationBootReceiver and
     ActionBroadcastReceiver -->
```

Gradle: `isCoreLibraryDesugaringEnabled = true`, `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")`,
`implementation("androidx.media:media:1.8.0")`, and `compileSdk` 35 or more.
