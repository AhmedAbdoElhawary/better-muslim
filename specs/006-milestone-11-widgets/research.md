# Research: Milestone 11, Widgets and Live Activity

Checked on 2026-10-20 against the code on `feature/milestone-10` (milestones 2 to 6 and 8 to 10
built), the handoff (5.3 to 5.8, `design/07 System surfaces.dc.html` section 04, OVERVIEW.md,
TOKENS.md), the iOS project (SwiftPM plugins, no Podfile, 9 flavor configurations, iOS 15.0),
the Android project (minSdk 26, compileSdk 36, `allowBackup="false"`, every domain excluded in
`data_extraction_rules.xml`, `SCHEDULE_EXACT_ALARM`), `packages/adhan_alarms`, and the docs for
Jetpack Glance, ActivityKit (iOS 26 scheduled start), Android 16 Live Updates and app group
backups.

Points marked **(Q1)** to **(Q7)** change something the spec or the constitution says. I took
every recommendation on 2026-10-20 (plan.md, "Answered"), and the spec says so.

## R1. Where the code lives

- **Decision**:
  - `lib/core/surfaces/`: everything the Dart side writes, with no riverpod, because the
    notifications' background code needs it too (constitution I):
    - `surface_data.dart`: the pure builder. Store values and day times in, the JSON of
      contracts/surface-data.md out.
    - `surfaces_channel.dart`: the plugin's channel (contracts/surfaces-channel.md).
    - `write_surfaces.dart`: `writeSurfaces(db, ...)`, reads the store like `topUp` and hands the
      builder's JSON to the channel.
  - `lib/features/surfaces/presentation/surfaces_boot.dart`: the app side triggers, like
    `NotificationsBoot` (R5). The feature is clean as the constitution lists it ("home widgets and
    live activity"), with only `presentation/` (the shape test takes a subset).
  - `packages/prayer_surfaces/`: a local plugin, android and ios, so its channel exists in every
    engine: the app's, the background top-up's and mark prayed's (constitution stack rule). It
    writes the file, reloads the widgets and runs the countdowns. On Android it also holds the
    widget receiver, the alarms and the countdown notification.
  - `ios/PrayerWidgets/`: the widget extension (home widgets, accessories, Live Activity UI). An
    extension is an Xcode target of Runner, it can't live in a plugin.
  - `features/notifications/`: the switch row on Adhan and reminders, the two dev buttons, and two
    calls to `writeSurfaces` in `data/background.dart` (the top-up, mark prayed). They import core
    only.
  - `lib/bootstrap.dart`: `NotificationsBoot(child: SurfacesBoot(child: App()))`.
- **Rationale**: no feature imports another, the background and the app write the same data from
  one function.
- **Alternatives**: the writer in `features/surfaces/data/` (notifications would import a
  feature), the triggers folded into `NotificationsBoot` (widgets aren't notifications, and it
  would grow a second job).

## R2. A local plugin instead of home_widget and live_activities (Q5)

- **Decision**: no new pub package. `packages/prayer_surfaces` does the three things the packages
  would: write the data, reload the widgets, start and end the countdowns.
- **Rationale**:
  - home_widget keeps its data in `UserDefaults(suiteName:)` on iOS. The app group container is
    backed up to iCloud unless a file is in Caches or tmp or is excluded one by one (Apple DTS on
    the developer forums), and a preferences plist can't keep the exclusion flag, so FR-004 and
    SC-006 would fail. On Android it saves to SharedPreferences, which is fine but saves nothing
    over writing a file.
  - live_activities can't schedule a start (iOS 26), set the stale date this milestone relies on
    (R7), or run the Android countdown. Its iOS data also goes through `UserDefaults`.
  - Taps need no package: Flutter's deep linking (on by default since 3.27) hands the URL to
    go_router (R11).
  - The native widgets are mine to write either way, the packages only carry the data.
- **Cost**: the constitution's stack line names both packages for this milestone. Dropping them
  is approved (Q5): T001 replaces them with the plugin in the constitution (MINOR, 3.6.0).
- **Alternatives**: home_widget for the Android side only (one package for a file write), both
  packages with their storage patched (fighting the packages).

## R3. What the app works out and what the native side does

- **Decision**: Dart works out every moment's content ahead, the native side only picks and
  counts.
  - The builder writes **entries**: from the start of the stretch now is in (the last boundary
    at or before it, so writes in the same stretch are equal) to the end of the 7th prayer day, a
    new entry at
    every fajr, sunrise, dhuhr, asr, maghrib, isha and local midnight. Each holds everything a
    surface shows from that moment until the next entry, already in the app's language, digits and
    12/24 hour setting: the next prayer and its time, the strip of the prayer day with ticks, the
    bar's start and its label, sunrise and maghrib for the sun, the Hijri and date lines, the
    count, the reminder chip.
  - The builder uses the same functions as Home's providers: `prayerDayOf`, `DayTimes.next`,
    `periodAt`, `periodStart`, `HijriDate.of` on the local date as `DateLine` does. So the data
    and Home can't disagree (FR-003).
  - Native, at a moment: the last entry whose `from` has passed; minutes left
    `floor((at - now) / 60 s)` as the Prayer tab's `_NextChip`; bar share
    `clamp((now - barFrom) / (at - barFrom))` as `barShare`; sun share between sunrise and
    maghrib as `sunShare`, none at night (the dotted arc only, as Home). The rules are in
    contracts/native-surfaces.md.
- **Rationale**: one implementation of the prayer rules (Dart, tested against Home), three
  formulas mirrored natively. SC-001 is tested over the written data.
- **Alternatives**: raw times only and the rules again in Swift and Kotlin (three copies of the
  prayer day, period and next prayer rules, untestable from Dart).
- **After Isha** the next prayer is tomorrow's fajr, which isn't in the shown day (Isha's day,
  as Home's strip). The medium, large and Android widgets then highlight no cell and show every
  cell as past, while the header still names Fajr with its countdown **(Q6)**.

## R4. Where the data lives and how it stays private (FR-004, SC-006)

- **Decision**:
  - iOS: `surfaces.json` in the app group container
    (`containerURL(forSecurityApplicationGroupIdentifier:)`), written atomically with
    `.completeFileProtectionUntilFirstUserAuthentication` (the lock screen reads it while locked,
    so not `.complete`), then `isExcludedFromBackup = true` set again after every write, since an
    atomic write replaces the file and its flag. The group id comes from an `AppGroup` key in each
    target's Info.plist, set from an `APP_GROUP` build setting per flavor.
  - Android: `surfaces.json` in `filesDir`. `allowBackup="false"` and the existing
    `data_extraction_rules.xml` (every domain excluded) already keep it out of every backup.
    Credential encrypted storage, the launcher can't draw widgets before the first unlock anyway.
  - Only the fields of contracts/surface-data.md. No coordinates, no zone, no history, nothing of
    the database key. The test checks the exact key set.
- **Rationale**: the database stays sealed with its key, the surfaces get the least they need.

## R5. When the data is written (FR-002)

- **Decision**:
  - `SurfacesBoot`: once after launch, on every resume, and 500 ms after the last change of
    `_surfaceInputsProvider` (place and names, zone, method, Asr method, Hijri adjustment, digits,
    reminder, countdown switch) or of the `prayer_log` table (marking anywhere in the app, Reset
    prayer journey, Restore). The language and the 12/24 hour setting are the phone's, read again
    on resume, as `NotificationsBoot` does.
  - While the app is open, one `Timer` to the next countdown start or end, so iOS 16.2 to 18
    starts a countdown that begins while I'm in the app, and an open app ends it at the adhan's
    second.
  - Background top-up (`callbackDispatcher`): `writeSurfaces` before the notification permission
    check, so the widgets keep 7 days with notifications refused.
  - Mark prayed from a notification (`markFromPayload`, both platforms, app closed or in the
    background): `writeSurfaces` after the mark. SC-003's minute.
  - The plugin compares the new JSON with the file and skips the file write and the widget reload
    when they're equal. The countdowns are synced either way. Nothing in the file holds the write's
    moment, so a launch or resume inside the same stretch writes nothing.
  - The design scenario never writes: the boot returns early as `NotificationsBoot` does, and the
    scenario registers no top-up (FR-033).
- **Rationale**: the same inputs and rhythm as milestone 5, so the widgets and the notifications
  change together. Skipping equal writes keeps WidgetKit's reload budget for real changes.

## R6. iOS home widgets and lock screen accessories

- **Decision**:
  - One WidgetKit extension, `PrayerWidgets`, with three kinds: "Next prayer" (`.systemSmall`),
    "Today's prayers" (`.systemMedium`, `.systemLarge`) and the lock screen's "Next prayer"
    (`.accessoryCircular`, `.accessoryRectangular`, `.accessoryInline`, from iOS 16), plus the Live
    Activity (R7). A kind has one gallery description and FR-034 gives the lock screen its own.
    Deployment target 15.0 as the app (FR-032).
  - Timeline: one entry per countdown minute for the next 6 hours, aligned to the prayer time's
    seconds (the h:mm flips at `at - k minutes`), plus one at every data entry's `from`. Reload
    policy `.atEnd`, about 4 reloads a day, far inside the budget. Past the last entry the widget
    shows the out of date state (R12).
  - Each minute entry also places the sun and the ring, so nothing moves only on reload.
  - Fonts: the extension's Copy Bundle Resources point at the same files in `assets/fonts/` (no
    copies in git), listed under `UIAppFonts` in the extension's Info.plist. The variable fonts
    get their weight through the `wght` axis of a `UIFontDescriptor`, sizes are fixed
    (`Font(uiFont)`), so text size never grows the boxes (FR-029).
  - Arabic: `layoutDirection` from the data, Reem Kufi for the names and Noto Sans Arabic for the
    rest. The arc and the ring sit in a left to right environment (FR-026).
  - iOS 17+: `containerBackground(for: .widget)` with the tree's gradient, `contentMarginsDisabled`
    where the tree draws to the edge. iOS 15 and 16: the same gradient as the background.
  - Tinted and clear home screens, StandBy: `widgetAccentable()` on the sun, the highlight and the
    countdown, the rest follows the system.
  - Taps: `widgetURL` Home on every family, `Link` on each prayer cell of the medium and large
    (WidgetKit allows `Link` only there, which matches FR-023).
- **Rationale**: per minute entries are the only way to get h:mm and the moving sun on every iOS
  the app supports. `Text(timerInterval:)` always shows seconds, and the iOS 18 `.timer` format
  with minute precision writes "5 minutes" and was reported stuck on the developer forums.

## R7. iOS Live Activity and Dynamic Island (Q2, Q3, Q4, Q7)

- **Decision**:
  - `PrayerCountdownAttributes` (the prayer and its day) with a `ContentState` holding the strings
    of contracts/surface-data.md "countdown content" and the dates `barFrom` and `at`. The struct
    is written twice with the same name and fields, in the plugin and in the extension, because
    ActivityKit matches it by name and the extension can't link a plugin that needs Flutter.
  - Start: iOS 26 and later, the plugin schedules each countdown of the next 6 days with
    `Activity.request(attributes:content:pushType:nil, style: .standard, alertConfiguration:,
    start:)`, in order, stopping at the first one iOS refuses. Launch, resume, the top-up and mark
    prayed fill the queue again. The alert iOS requires is the prayer's name and "Next prayer ·
    {city}" with a silent sound file from the Runner bundle. If iOS lights the screen for Fajr's in
    the night, it comes back to me (spec assumption). iOS 16.2 to 18: requested on launch or
    resume inside a window, and by the boot's timer while the app is open.
  - `staleDate` = the prayer time. Past it the view shows "Now" in place of the countdown and the
    bar full. The plugin ends every activity whose prayer time has passed, or that isn't the
    current window, or when the switch is off, on every sync (FR-019, FR-020).
  - The countdown: `Text(timerInterval: barFrom...at, countsDown: true)`, h:mm:ss, drawn by the
    system to the second.
  - **The bar (Q2)**: a Live Activity can't run code, it moves only the system's timer text and
    the system's `ProgressView(timerInterval:)`. The plan uses that progress view, tinted gold on
    the 20% track, so the fill always matches Home's share with the app closed. The 14 pt sun at
    the fill's end can't follow it, so it is left out on iOS. Keeping the 5.3 bar with its sun
    would freeze both at the share of the last update, for most of the 2 hours.
  - **Compact island (Q3)**: the tree shows h:mm. The system can't draw a live h:mm in a Live
    Activity (R6), so compact shows the same h:mm:ss as the lock screen.
  - **Digits (Q4)**: the timer text is drawn by the system with the view's `locale`. The plan sets
    it from the data (`ar`, `ar@numbers=latn`, `en`), to be checked on the phone in the first
    task. If iOS ignores it, the countdown shows the phone's own digits, the same limit as Android
    (R9).
    Checked: not yet. Dev → Start countdown now in Arabic, once with Eastern and once with Western
    digits, then look at the lock screen and the island.
  - **iOS 16.1 (Q7)**: `ActivityContent` and `staleDate` start at 16.2. On 16.1 a countdown would
    sit at 0:00:00 after the adhan with the app closed, which FR-019 forbids. The plan starts Live
    Activities from 16.2.
  - The Dynamic Island: compact (star + countdown), minimal (star), expanded (5.4 with "{city} ·
    {method}" and the "Reminder {time}" chip only while the reminder is on). An iPhone without it
    gets the lock screen card and the banner (system).
  - On iOS 26 with the app closed, Maghrib's "Now" card can stay above Isha's countdown when Isha's
    starts at the adhan (Umm al-Qura's 90 minutes), until the app runs or a prayer is marked from a
    notification. Nothing ends it sooner without a server. Accepted (spec, analyze session).
  - Taps: `widgetURL` Home (FR-023).
- **Rationale**: the closest the system allows to 5.3 and 5.4 with no push and no server (FR-005).
- **Alternatives**: push updates (a server, FR-005), one long activity for two prayers (only one
  stale date, the second would sit at 0:00:00).

## R8. The Android widget (Q1)

- **Decision**:
  - **No Glance**. Glance's `FontFamily` takes a family name and finds only system fonts, and plain
    RemoteViews can't help either: the launcher inflates widget layouts in a restricted context,
    where `TextView` ignores `android:fontFamily` font resources. So the widget is an
    `AppWidgetProvider` whose content is drawn by `Canvas` in the app's process, where the app's
    fonts load (`Typeface.Builder` on the Flutter assets inside the APK,
    `flutter_assets/assets/fonts/`, with `'wght'` variation settings). Exact 5.8 fonts, sizes,
    colors and RTL.
  - Layout: a `FrameLayout` with the sky, which stretches to the box, the drawn layers pinned to
    its top and bottom edges, which never stretch and only shrink evenly, a small picture for the
    countdown, and 5 transparent click cells. A minute redraws every layer: a sized `RemoteViews`
    can't take `partiallyUpdateAppWidget`.
  - Sizes: the launcher's width holds, its height doesn't (an Oppo reports 151 for a box of 78, and
    shows a 2 x 2 only to 142 of its 172), so nothing but the sky uses the height, and the small
    widget is one square pinned to the top. From Android 12 the host picks the medium's version by its
    real box: under the header and the row together, 4 x 1 (the times row only). Before 12 the
    reported height picks it. `targetCellWidth/Height` and `minResizeWidth/Height` in
    `appwidget-provider`.
  - The move every minute: an exact **non wakeup** alarm (`RTC`) at the next countdown flip or
    entry change. It never wakes the phone: with the screen off it fires the moment the phone
    wakes, so the widget is right whenever it's seen, for almost no battery. Armed only while a
    widget exists or a countdown shows. Without the exact alarm permission it falls back to an
    inexact alarm and may move late.
  - Re-armed after `BOOT_COMPLETED`, `MY_PACKAGE_REPLACED`, `TIME_SET` and `TIMEZONE_CHANGED`
    (all allowed in the manifest).
  - TalkBack: one `contentDescription` on the root, rebuilt with the picture (FR-030).
  - Taps: a `PendingIntent` per prayer cell to the Prayer tab, the rest to Home (R11).
  - The picker's label and description in `res/values` and `res/values-ar` of the plugin (FR-034).
- **Rationale**: the only way to the design's fonts on Android. The picture is fixed size anyway
  (FR-029).
- **Alternatives**: XML layouts with the system fonts (much less Kotlin, but Roboto and the
  system serif instead of Schibsted Grotesk and Marcellus), text drawn to a picture per text view
  inside an XML layout (as much drawing code, more views).

## R9. The Android countdown (Q4)

- **Decision**:
  - An ongoing notification on its own channel `prayer_countdown` ("Prayer countdown",
    `IMPORTANCE_LOW`: no sound, no vibration, no heads up). Title "{prayer} {time}", text "Next
    prayer · {city}", `setWhen(at)` + `setUsesChronometer` + `setChronometerCountDown`: the system
    counts to the second. `setTimeoutAfter(at - now)` removes it at the adhan's second.
  - Started by an exact alarm at the next window's start (`setExactAndAllowWhileIdle`, wakeup, so
    it shows on a sleeping phone). The alarm at its end arms the next one, which starts at once
    when the next window begins at the same second (Isha after Maghrib).
  - The bar: `setProgress` on Android 15 and before. On Android 16 and later a Live Update:
    `setRequestPromotedOngoing(true)`, `Notification.ProgressStyle` with the sun as the tracker
    icon, `POST_PROMOTED_NOTIFICATIONS` in the plugin's manifest. The status bar chip shows the
    chronometer (FR-018). The minute tick (R8) updates the bar.
  - Not colorized, no custom view (both stop the promotion), so the notification uses the system's
    font, like every notification of milestone 5.
  - **Digits (Q4)**: the chronometer and the status chip are drawn by the system in the phone's
    own digits. English and Arabic with Eastern digits match. Arabic with the Western digits switch
    may show Eastern digits in that one countdown. The alternative is h:mm text redrawn each minute
    by the tick: my digits, but no seconds (FR-018 asks for them).
  - Taps: Home. No Mark prayed (FR-022).
  - No notification permission, or the channel turned off: no countdown, the widget still works
    (FR-021).
- **Rationale**: the platform's own countdown, exact and free, the same alarms milestone 5 uses.

## R10. The countdown windows (FR-014, FR-020)

- **Decision**: for each of the five prayers with a time, in the first 6 prayer days (the
  notifications' 6 days): start = the later of 2 hours before and the previous prayer's time
  (Fajr's previous is last night's Isha, Dhuhr's is Fajr, sunrise isn't a prayer), end = the
  prayer time. A prayer with no time (polar) has no window and doesn't count as a previous one.
  Windows never overlap by this rule, so one at a time follows.
- No windows without a place or with the switch off. The native side checks the system permission
  (FR-021).

## R11. Taps (FR-023)

- **Decision**: `bettermuslim://open/` for Home and `bettermuslim://open/prayer?day=…&prayer=…`
  (`Routes.prayerAt`) for a prayer. iOS: `widgetURL` and `Link` open the containing app, and the
  scheme is registered in Runner's Info.plist. Android: explicit `PendingIntent`s to
  `MainActivity` with the URI as data. Flutter's deep linking gives the path and query to go_router,
  so the onboarding redirect still applies.
- **Rationale**: no new channel or package, the routes already exist.

## R12. No place and out of date (FR-024)

- **Decision**: the data says `place: false` with no entries when the store has no place, and its
  entries end at the 7th prayer day's end (`until`). Each widget draws its frame and background
  with the mark and "Open Better Muslim to set your place" or "… update the times", the inline
  accessory "Open Better Muslim", the circular one the mark alone. No file yet (a new install,
  before the first write): the no place state. No countdown either way.

## R13. The switch (FR-013) and schema 7

- **Decision**: `settings.prayerCountdown` (bool, default true). It is in the backup like the
  reminder (`copyTables` copies the settings row whole). The row is `ToggleRow` in its own
  `GroupedSection` under the reminder's, on Adhan and reminders.

## R14. The dev page (FR-033)

- **Decision**: two rows on the dev notifications page, dev flavor only like the page itself:
  "Start countdown now" (the next prayer's countdown from now to its time, whatever the 2 hours)
  and "Refresh widgets" (`writeSurfaces` with the plugin's equal check skipped). English only, like
  the rest of the page.
- The spec's US4 test clears the place from the dev page, but FR-033 lists only these two rows.
  The no place state is checked with a fresh install before onboarding ends instead, no third row.

## R15. Strings (FR-034)

- **Decision**: the table's strings go into `StringsManager` and both arbs, plus two the table
  missed: the 5.8 tree's "Next · {city}" (`التالية · {city}`, the large widget's Arabic) and the
  plain "{prayer} {time}" of the inline accessory, the bar's labels and the Android title (the
  same in Arabic, the order follows the line's direction). English upper cases the city for
  "NEXT · {city}", as the tree. The iOS 26 alert reuses the prayer's name
  and "Next prayer · {city}". The gallery and picker texts live in the extension's
  `Localizable.strings` (en, ar) and the plugin's `strings.xml` (values, values-ar), since the
  system reads them before the app runs.

## R16. Access and contrast (FR-030, FR-031)

- **Decision**:
  - iOS: each widget is one accessibility element with a label filled per entry from
    `timeLeftSemantics` ("{hours} h {minutes} min until {prayer}") plus its time and the place. The
    Live Activity combines its texts in the order prayer, countdown, time, place (sort priorities),
    so the system timer is read live. The arc, sun, bar, ring and star are hidden.
  - Android: the widget's root `contentDescription` the same way. The notification is read by
    TalkBack as any notification.
  - Contrast of the trees' text colors on their backgrounds (dark values): lowest 4.6:1 (the
    medium's tick on its cell), labels 5.6:1, the rest above 6:1. All AA.

## R17. The Xcode target and the Apple account

- **Decision**: a one-off Ruby script with the `xcodeproj` gem (1.27 is installed) adds the
  `PrayerWidgets` app extension to Runner: the 9 flavor configurations, bundle id
  `$(Runner's id).widgets`, `APP_GROUP` per flavor on both targets, the app groups entitlement on
  both, `NSSupportsLiveActivities` in Runner's Info.plist, embedded in Runner, the font file
  references. The script isn't kept, the project file is the result.
- `TODO(ahmed)` where the account is needed: the three app groups
  (`group.com.elhawary.bettermuslim`, `.dev`, `.staging`), the three extension app ids, and the
  signing team on the new target.
