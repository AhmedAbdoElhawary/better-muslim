# Contract: what milestone 3 adds to or changes in core

Later milestones build on these, so their names and meaning stay as written here.

## Providers

| Provider | Type | Gives | Users after Home |
| --- | --- | --- | --- |
| `prayerDayProvider` | `Provider<DateTime>` | the location's date, yesterday before today's Fajr. Notifies only when it changes | Prayer (4), adhan (5) |
| `prayedProvider` | `Provider.autoDispose.family<Set<Prayer>, DateTime>` | the prayers logged on a prayer day. `{}` until milestone 4 fills it from the store | Prayer (4), adhan (5) |
| `tickerProvider` | `StreamProvider<DateTime>` (changed) | now, on every whole second of the wall clock | Prayer (4), Qibla (6) |

Both new providers match `specs/002-milestone-4-prayer/contracts/prayer-log.md`.

## Location

| Call | Before | After |
| --- | --- | --- |
| `LocationController.useAuto()` | `Future<void>`, sets auto first, asks only with no saved location | `Future<bool>`. Asks for "while using" when denied, saves auto only with a fix and a place, false on denied, off or no fix with nothing changed |

`choose(place)` and `refresh()` stay as they are.

## Design system

| Addition | Where | Meaning |
| --- | --- | --- |
| `ThemeEnum.onSkyBright` | `theme_manager.dart` | text on the sunrise, Dhuhr and Asr skies, `#FFFFFF` at 92% |
| `ThemeEnum.skyScrim` | `theme_manager.dart` | the black 28% scrim behind header text on bright skies |
| `ThemeEnum.glass`, `ThemeEnum.glassHighlight` | `theme_manager.dart` | the location pill on the sky: `rgba(7,16,13,.4)` and a 10% white top line |
| `context.starOpacity` | `theme_manager.dart` | the palette's star opacity, so features never read `context.bm` |
| `FontEnum.quran` | `font_manager.dart` | Amiri Quran for Latin and Arabic, until KFGQPC Hafs is licensed |
| `tabularFigures` | the weight text widgets | default false, true for every time and the countdown |
| `context.isLargeText` | `extensions/window_size.dart` | text scale above 1.4, where rows stack |
| named sizes | `dimensions_manager.dart`, `font_manager.dart` | every Home-only number from 4.01 / 4.16 gets a name (overlap 60, glow inset 18, pill 32, bar 3, strip radius 14, shortcut box 40, ...) |

## Widgets

| Widget | Where | Shape |
| --- | --- | --- |
| `showBmSheet<T>(context, {required WidgetBuilder builder})` | `core/widgets/sheet/bm_sheet.dart` | Motion 15 in and out, the grabber, a 64% scrim, the selection haptic on a detent, a 150 ms fade with reduce motion. Same name and file as milestone 4's plan |
| `SearchField({required hint, required onChanged})` | `core/widgets/search_field.dart` | 4.14's field: 46 pt, radius 14, surface, outline, search icon 20, hint 15 text2. Duas (8) uses it too |
| `BmButton.primary(label, {onPressed, busy})`, `BmButton.secondary(...)` | `core/widgets/bm_button.dart` | 4.11's buttons: 52 pt, radius 14, `primary` fill with `onPrimary` text, or a 1 px `outlineStrong` border with `text`, 15 / 500, full width. The adhan screen (5) and onboarding (10) use them too |

## App

- `App`'s builder sets `disableAnimations` to the OS flag or `settings.reduceMotion`. Every
  widget reads `MediaQuery.disableAnimationsOf(context)` for reduce motion. The copy needs
  `MediaQuery.of`, and `app.dart` is the only file the architecture test allows it in.
- `dayTimesProvider`'s body is a top-level `computeDayTimes(ref, date)`, so an override can fall
  back to the real calculation.
- `designScenarioOverrides()`:
  - overrides `dayTimesProvider` for 15 Oct 2026 with the handoff's times, instead of
    `todayTimesProvider`
  - adds `prayedProvider(15 Oct 2026) = {fajr, dhuhr}`

## Native

| Channel | Method | iOS | Android |
| --- | --- | --- | --- |
| `better_muslim/power` | `isPowerSaving` → bool | `ProcessInfo.processInfo.isLowPowerModeEnabled` | `PowerManager.isPowerSaveMode` |

Read through `core/power/power_saving.dart` (`powerSavingProvider`, re-read on resume).

## Strings

Each goes into `StringsManager` and both arb files:

| Key | English | Arabic |
| --- | --- | --- |
| `fajrAr`, `duhaAr`, `dhuhrAr`, `asrAr`, `maghribAr`, `ishaAr` | الفجر, الضحى, الظهر, العصر, المغرب, العشاء | the same |
| `ishaLabel` | Isha {time} | العشاء {time} |
| `fajrLabel` | Fajr {time} | الفجر {time} |
| `morningAzkar` | Morning azkar | أذكار الصباح |
| `morningAzkarSub` | After Fajr · {done} of {total} | بعد الفجر · {done} من {total} |
| `timeLeftSemantics` | {hours} h {minutes} min until {prayer} | {hours} س {minutes} د حتى {prayer} |
| `searchCity` | Search for a city | ابحث عن مدينة |
| `noPlacesFound` | No places found | لا توجد أماكن |
| `locationFailed` | Couldn't get your location. Check that location is on, or choose a city. | تعذّر تحديد موقعك. تأكد أن الموقع مفعّل، أو اختر مدينة. |
| `noLocationBody` | Prayer times need your location or a city. | أوقات الصلاة تحتاج موقعك أو مدينة. |
