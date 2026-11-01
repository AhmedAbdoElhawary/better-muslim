# Contract: the surfaces channel

`MethodChannel('better_muslim/surfaces')`, from `packages/prayer_surfaces` (android and ios).
A plugin, so it exists in the app's engine, the background top-up's (workmanager) and mark
prayed's (flutter_local_notifications on iOS, adhan_alarms' headless engine on Android).

Dart side: `SurfacesChannel` in `lib/core/surfaces/surfaces_channel.dart`.

## Methods

| Method | Arguments | Does | Returns |
| --- | --- | --- | --- |
| `update` | `{json: String, force: bool}` | writes the file unless equal to it (or `force`), reloads every widget when written, then syncs the countdowns | null |

Errors come back as `PlatformException(code: 'surfaces_failed', message: '<code>')` with only a short
code (the exception's class name on Android, the error's code on iOS), never a path (like `better_muslim/backup`). The writer catches them and reports them through
`CrashReporter.instance.recordError` with `{'reason': 'write surfaces'}`. A failed write leaves the last file in place.

## The live countdown

It shows while the app is off screen and counts to the next prayer: the entry in force and its
`at`. The native side knows when the app leaves and comes back, Dart doesn't take part.

1. iOS (the plugin watches `willResignActive` and `didBecomeActive` once, whatever engine):
   - resign: start the entry in force when `countdown`, `place` and
     `ActivityAuthorizationInfo().areActivitiesEnabled`. iOS 26+ also schedules the next 4
     prayers, each starting at the previous one's time, until iOS refuses one
   - active: end every activity, scheduled ones too
   - `update`: end them all when `countdown` or `place` is false, update the running ones'
     content, and leave one past its time as "{prayer} · now" (iOS 18 to 25 can't start the next
     one from the background) until the app opens or a later one is showing. iOS ends any after 8
     hours
2. Android (the plugin watches the app's activity start and stop, a reboot or an update counts
   as off screen):
   - post or update the notification of the entry in force while off screen, cancel it on screen
   - arm the exact wakeup alarm at its `at`, where it rolls to the next prayer
   - arm the minute tick when a widget exists or a countdown shows
   - nothing when notifications aren't allowed or the channel is off (the widget still updates)

## Called from

| Caller | When |
| --- | --- |
| `SurfacesBoot` | launch, resume, 500 ms after an input change |
| `callbackDispatcher` | every background top-up, before the notification permission check |
| `markFromPayload` | after mark prayed from a notification |
| dev page | "Refresh widgets" (`force: true`) |

Never from the design scenario.
