# Better Muslim

Prayer times, Quran, azkar and qibla for iOS and Android, English and Arabic. The rules are in the
constitution:

@.specify/memory/constitution.md

## Design handoff

`design_handoff_better_muslim/` is the approved design. Its code (theme, tokens, text, motion,
icons, sky) is already in `lib/core/resources/design/`, the sky painter in
`lib/features/home/view/widgets/`, fonts and icons in `assets/`, strings in `assets/l10n/` with
their keys in `StringsManager`.

- `reference/screens/*.png`, `reference/surfaces/*.png`: what each screen looks like. Only to look
  at, never compared against (no golden tests, no screenshot checks).
- `specs/screens/*.md`, `specs/surfaces/*.md`: exact layout trees. Read `specs/HOW_TO_READ.md`
  first.
- `SCREENS.md` (entry, dynamic values, behaviour), `MOTION.md` (animations, haptics, reduce
  motion), `TOKENS.md`, `OVERVIEW.md`, `design/*.dc.html` (open in a browser).
- `HANDOFF_CLAUDE.md`: the designer's original notes and build order. Its api rules
  (`context.bm`, `BmText`, copying `flutter/`) are replaced by the table below.

From the spec to the code:

| In the spec | In the code |
| --- | --- |
| `var(--x)` color role | `context.getColor(ThemeEnum.x)` (`--pc` = `primaryContainer`, see HOW_TO_READ) |
| Schibsted Grotesk / Noto Sans Arabic text | `RegularText`, `MediumText`, `SemiBoldText`... by weight |
| Marcellus / Reem Kufi text | `RegularText(..., font: FontEnum.display)` |
| copy | `StringsManager.x` (the arb key), `args: {...}` for `{placeholders}` |
| font size, line height, letter spacing | `FontSizeManager.role`, `LineHeightManager.role`, `LetterSpacingManager.role` (BmText names) |
| padding, gap, radius, size | adaptive paddings, `RSizedBox`, `SpaceManager`, `RadiusManager`, `SizeManager` |
| a value only one component uses | a named entry in the manager first (like `SpaceManager.navBarSide`) |
| `ICON outline/x`, `ICON ui/x` | `BmIcon(BmIconName.x)`, `BmIcon.ui(BmUiIcon.x)` |
| animation, haptic | `BmMotion` + `MOTION.md`, `BmHaptics` |

- Always-dark surfaces (adhan screen, system surfaces) may use literal colors: add that one file
  to the allow list at the top of `test/architecture_test.dart`.
- Text scale is clamped at 2.0 in `App`. Above 1.4 the countdown and prayer rows stack.
- Living Sky follows `BmSkyState`. The design scenario shows the theme's base sky.
- Quran mockups use Amiri Quran. Production needs KFGQPC Hafs + QCF V2 (licensed separately).

## Milestones

1. Setup: core, theme, fonts, l10n, 5-tab shell, icons, splash. **Done, waiting for my review.**
2. Data: location, prayer times (Umm al-Qura in KSA), hijri, settings in drift, and a debug
   scenario that freezes time at Thu 15 Oct 2026 16:32 Makkah, a fixed moment for tests and demos.
   **Done, waiting for my review.**
3. Home: Living Sky, live countdown and glow, the prayer day strip, verse and shortcuts, the
   location sheet with offline city search. **Done, waiting for my review.**
4. Prayer: logging, qada, method sheet. **Done, waiting for my review.**
5. Notifications and adhan: the 6 day schedule with reminders, the adhan screen (4.03), the full
   adhan on Android from `packages/adhan_alarms`, Mark prayed from every notification, the
   background top-up, a dev page from More. **Done, waiting for my review.**
6. Qibla: compass, alignment, haptics. **Done, waiting for my review.**
7. Quran reader: moved to after 11, it's almost an app of its own. The spec waits in
   `specs/003-milestone-7-quran/` with Q1 to Q10 open. Until then the Quran tab stays a placeholder.
8. Azkar, Tasbih and Duas: the Azkar tab, both sets, Tasbih, Duas with save, share and Listen ready
   for clips, the azkar nudges. **Done, waiting for my review.**
9. More, Theme and Hijri calendar: every setting, the 8 themes with Follow sky, the calendar with its
   events and adjustment, the Adhan and reminders page, Reset prayer journey and Credits. **Done,
   waiting for my review.**
10. to 11. as in `HANDOFF_CLAUDE.md`.

## Run

VS Code (Run and Debug) and Android Studio (run configurations) both have Dev, Staging and Prod.
Terminal, same on iOS and Android:

```bash
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=dart_define/dev.json
```

## Before saying done

```bash
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```
