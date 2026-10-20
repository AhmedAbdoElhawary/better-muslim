# Contract: the surfaces channel

`MethodChannel('better_muslim/surfaces')`, from `packages/prayer_surfaces` (android and ios).
A plugin, so it exists in the app's engine, the background top-up's (workmanager) and mark
prayed's (flutter_local_notifications on iOS, adhan_alarms' headless engine on Android).

Dart side: `SurfacesChannel` in `lib/core/surfaces/surfaces_channel.dart`.

## Methods

| Method | Arguments | Does | Returns |
| --- | --- | --- | --- |
| `update` | `{json: String, force: bool}` | writes the file unless equal to it (or `force`), reloads every widget when written, then syncs the countdowns | null |
| `startNow` | none | dev only: the next prayer's countdown from now to its time, whatever the 2 hours | `true` if it started, `false` when the system refused (no permission, Live Activities off) |

Errors come back as `PlatformException(code: 'surfaces_failed', message: '<code>')` with only a short
code (the exception's class name on Android, the error's code on iOS), never a path (like `better_muslim/backup`). The writer catches them and reports them through
`CrashReporter.instance.recordError` with `{'reason': 'write surfaces'}`. A failed write leaves the last file in place.

## Sync (inside `update`, and on the native side's own alarms)

1. Read `countdowns` and `countdown`.
2. iOS:
   - end every activity whose prayer time has passed, whose window isn't in the file, or all of
     them when `countdown` is false or `place` is false
   - update the running one's content when it changed
   - iOS 16.2 to 18: start the window covering now if none runs, the app is in front and
     `ActivityAuthorizationInfo().areActivitiesEnabled`
   - iOS 26+: also schedule the later windows not scheduled yet, in order, until iOS refuses one
3. Android:
   - post or update the notification of the window covering now, cancel it when none does
   - arm the exact wakeup alarm for the next window's start
   - arm the minute tick when a widget exists or a countdown shows
   - nothing when notifications aren't allowed or the channel is off (the widget still updates)

## Called from

| Caller | When |
| --- | --- |
| `SurfacesBoot` | launch, resume, 500 ms after an input change, the boot's window timer |
| `callbackDispatcher` | every background top-up, before the notification permission check |
| `markFromPayload` | after mark prayed from a notification |
| dev page | "Refresh widgets" (`force: true`), "Start countdown now" |

Never from the design scenario.
