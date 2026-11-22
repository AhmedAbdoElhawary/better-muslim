# Better Muslim — handoff for Claude Code

Start with `CLAUDE.md` and put it at the root of the Flutter repo so Claude Code reads it automatically.

- `flutter/pubspec.yaml`, `l10n.yaml`: fonts, assets, l10n, launcher icon and splash config, package list.
- `flutter/assets/fonts/`: Marcellus, Schibsted Grotesk, Reem Kufi, Noto Sans Arabic, Amiri, Amiri Quran (TTF + OFL licenses).
- `flutter/assets/icons/outline|filled/`: 18 brand icons (SVG 24×24). `icons/ui/`: 29 UI icons.
- `flutter/assets/brand/`: symbol in all colorways and optical sizes, 6 living-sky symbols, English wordmark (outlined SVG), Arabic wordmark (PNG @3x), lockups.
- `flutter/assets/ornaments/`: ayah markers, juz marker, dividers, frames, patterns.
- `flutter/assets/app_icon/`: SVG masters + PNGs (iOS light/dark/tinted, Android adaptive + monochrome, Play 512, splash, notification icon per density).
- `flutter/lib/theme/`: colors (8 themes, light + dark), text, tokens, motion, sky, theme, icons, haptics. `lib/widgets/sky_header_painter.dart`. `lib/l10n/`: EN + AR strings.
- `reference/`: PNG of every screen and surface. `specs/`: exact layout tree per screen.
- `SCREENS.md`, `MOTION.md`, `TOKENS.md`, `OVERVIEW.md`.
- `store/`: App Store 1290×2796 (6 EN + 2 AR), Play 1080×2160, feature graphic, LISTING.md.
- `design/`: source design files.

Recorded decisions: main theme #9 Qiyam Emerald (other 7 derived via `BmPalette.derive`). Home sun arc center x 249 (RTL 144), radius 118, horizon y 300. Night: no sun, labels Isha / Fajr. Follow sky = light Sunrise→Maghrib. Confirm the Hijri mapping against Umm al-Qura at build time.
