# Contract: the system channel

Between Dart (`core/system/system_channel.dart`) and the phone:
- iOS: `AppDelegate.swift`, registered like the backup and power channels.
- Android: `MainActivity.configureFlutterEngine`, next to `better_muslim/power`.

## Method channel `better_muslim/system`

| Method | Arguments | Result |
| --- | --- | --- |
| `openNotificationSettings` | none | `null`. Opens the app's notification settings on the phone |
| `openUrl` | `{"url": String}`, https only | `true` when something opened it, `false` otherwise |
| `version` | none | `"1.0.0 (12)"`: version name, a space, the build number in brackets |

No other errors. An unknown method answers not implemented.

## iOS

- `openNotificationSettings`: `UIApplication.openNotificationSettingsURLString` on iOS 16 and up,
  `UIApplication.openSettingsURLString` on iOS 15.
- `openUrl`: `UIApplication.shared.open(url)`, the completion's success is the result.
- `version`: `CFBundleShortVersionString` and `CFBundleVersion` from the main bundle.

## Android

- `openNotificationSettings`: `Settings.ACTION_APP_NOTIFICATION_SETTINGS` with
  `Settings.EXTRA_APP_PACKAGE`, `FLAG_ACTIVITY_NEW_TASK`.
- `openUrl`: `Intent.ACTION_VIEW` with the uri. No app to handle it → `false`.
- `version`: `packageManager.getPackageInfo(packageName, 0)`, `versionName` and `longVersionCode`.

## Dart side

`SystemChannel` with three static methods. `openUrl` refuses anything that isn't https before it
reaches the phone (constitution VII). Tests mock the channel with
`TestDefaultBinaryMessengerBinding`.
