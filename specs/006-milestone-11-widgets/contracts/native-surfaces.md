# Contract: what the native side works out

The same few rules in Swift (`ios/PrayerWidgets/`, `packages/prayer_surfaces/ios/`) and Kotlin
(`packages/prayer_surfaces/android/`). Everything else is read from contracts/surface-data.md.

## At a moment `now`

| Value | Rule | Same as in Dart |
| --- | --- | --- |
| state | no file or `place` false → no place. `now >= until` or a higher `version` → out of date. Else ready | — |
| entry | the last entry with `from <= now` | — |
| minutes left | `floor((at - now) / 60 000)`, never below 0 | `_NextChip` on the Prayer tab |
| h:mm | `"{minutes / 60}:{minutes % 60, 2 digits}"`, digits mapped when `eastern` | `_NextChip` |
| in h:mm | `texts.inDuration` with `{duration}` = h:mm | `_NextChip` |
| bar share | `clamp((now - barFrom) / (at - barFrom), 0, 1)`, none when `barFrom` is null | `barShare` |
| sun share | `(now - sunrise) / (maghrib - sunrise)` rounded to 0.001, only when `sunrise <= now <= maghrib` | `sunShare` |
| ring share | the bar share | 5.7 circular |
| spoken line | `texts.timeLeft` with hours, minutes (digits mapped) and `name`, then `atTime`, then the city | `Countdown` semantics |

## When to draw again

- the next h:mm flip: `at - (minutes left) * 60 000`
- the next entry's `from`
- `until`
- whichever comes first. iOS puts them in the timeline, Android arms the non wakeup tick.

## The live countdown

The entry in force while the app is off screen (contracts/surfaces-channel.md). None with the
switch off or no place.

## Never mirrored

The arc, the sun, the bar, the ring and every clock time and countdown are laid out left to
right in Arabic too. The strip's cells, the headers and the rows follow the language.

## Taps

| Surface | Opens |
| --- | --- |
| small widget, accessories, Live Activity, Dynamic Island, Android countdown | `bettermuslim://open/` |
| a prayer cell of the medium, large and Android widgets | `bettermuslim://open/prayer?day={entry.day}&prayer={strip[i].prayer}` |
| the rest of those widgets | `bettermuslim://open/` |

## Colors and fonts

- The dark Qiyam Emerald values and the trees' own values, in one file per platform
  (`SurfaceColors.swift`, `res/values/surfaces_colors.xml`), whatever theme I picked (FR-025).
- Schibsted Grotesk, Marcellus, Noto Sans Arabic, Reem Kufi from `assets/fonts/`. Weights through
  the `wght` axis. Fixed sizes from the trees, never scaled by the phone's text size.
- Icons: the star mark, `ui/check` and `outline/adhan` from `assets/icons/`, as vector assets
  (asset catalog on iOS, vector drawables on Android). The sun is a drawn circle with its glow.
