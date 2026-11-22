# Contract: routes, transitions and hero tags

## Routes (`core/router/app_router.dart`)

| Before | After |
| --- | --- |
| `Routes.credits` = `/credits` (Credits page) | removed |
| `Routes.licenses` = `/credits/licenses` (licenses list) | `Routes.acknowledgements` = `/acknowledgements`, the credits on top, then the licenses |
| `Routes.license(package)` = `/credits/licenses/:package` | `Routes.license(package)` = `/acknowledgements/:package` |

No deep link, notification payload or widget link used `/credits` (milestone 11's links are
`bettermuslim://open/...` for Home and the Prayer tab), so nothing else moves.

## Transitions

| Route | Transition | Reduce motion |
| --- | --- | --- |
| every `GoRoute` with a `builder` (a `MaterialPage`): Qada, the azkar sets, Tasbih, Duas, a category, Qibla, Theme, Adhan and reminders, the Hijri calendar, Acknowledgements, a license, the dev page | the theme's `BmPageTransitionsBuilder`: Flutter's Cupertino push, 500 ms, edge swipe back | a fade on `Interval(0, .3)` of the 500 ms (150 ms), the page under doesn't move |
| the shell (`CustomTransitionPage`, fade after Apply theme) | unchanged | unchanged |
| the onboarding steps (`CustomTransitionPage`) | unchanged, milestone 10 | unchanged |
| the adhan reveal (`CustomTransitionPage`) | unchanged, Motion 06 | unchanged |
| the tabs (`TabSwitcher`) | unchanged, Motion 16 | unchanged |
| sheets (`showBmSheet`) | unchanged, Motion 15 | unchanged |
| dialogs (`showBmDialog`) | scale `BmMotion.dialogFrom` (1.08) → 1 with a fade, decelerate, 300 ms in, 150 ms fade out | the 150 ms fade only |

`BmPageTransitionsBuilder` is set in `AppTheme._build` for `TargetPlatform.iOS` and
`TargetPlatform.android`, so every theme and both modes get it.

## Hero tags

Each tag is the destination's route path. A source and its target sit in a `TitleHero` with the
same tag. Under reduce motion every `TitleHero` is inside `HeroMode(enabled: false)`.

| Source (navigator) | Tag | Target |
| --- | --- | --- |
| More tile Qibla (More branch) | `Routes.qibla` | `QiblaBar`'s title (root) |
| More tile Hijri calendar (More branch) | `Routes.hijriCalendar` | the calendar's `CompactAppBar` title (root) |
| More tile Duas (More branch) | `Routes.duas` | Duas's `CompactAppBar` title (root) |
| More row Theme (More branch) | `Routes.theme` | Theme's `CompactAppBar` title (root) |
| More row Adhan and reminders (More branch) | `Routes.adhanSettings` | its `CompactAppBar` title (root) |
| Azkar tab row Morning, Evening (Azkar branch) | `Routes.azkarSet(set)` | the set's `CompactAppBar` title (Azkar branch) |
| Azkar tab row Tasbih (Azkar branch) | `Routes.tasbih` | `_TasbihBar`'s title (Azkar branch) |
| Duas category row (root) | `Routes.duaCategory(id)` | the category's `CompactAppBar` title (root) |

Home's azkar shortcuts have no tag: they `go` into the Azkar branch, a sibling navigator no hero
controller sees together with Home (research R9).

Only one widget per tag can be on a page at once: More shows each source once, the Azkar tab one
row per set, a category list one row per category.
