# CLAUDE.md — Better Muslim (Flutter)

You are implementing an approved, high-fidelity design. Do not redesign, restyle, re-space or "improve" anything. When unsure, open the reference PNG and the exact layout tree and match them.

## Where everything is
- `flutter/`: copy its contents into the Flutter project root (`pubspec.yaml`, `l10n.yaml`, `assets/`, `lib/theme`, `lib/widgets`, `lib/l10n`). These files are final. Build on them; don't rewrite them.
- `reference/screens/*.png`, `reference/surfaces/*.png`: what each screen must look like (2×, 393 × 852 pt).
- `specs/screens/*.md`, `specs/surfaces/*.md`: exact layout tree of every screen with every style value, text and icon. Read `specs/HOW_TO_READ.md` first.
- `SCREENS.md`: per screen entry point, dynamic values, behaviour, navigation.
- `MOTION.md`: all animations, tiers, haptics, reduce motion, exact keyframes.
- `TOKENS.md`: CSS variable → Dart palette mapping. `OVERVIEW.md`: full design-system notes.
- `design/*.dc.html`: source designs; open in a browser with support.js beside them. `03 Components.dc.html` shows every component in every state.
- `store/`: final store screenshots, feature graphic, listing copy.

## Rules
1. Colors only from `context.bm` (BmPalette). Text styles only from `BmText`. Spacing, radius and sizes from `bm_tokens.dart`. Motion from `BmMotion`. No literal colors in widgets except surfaces the spec marks always-dark (adhan screen, system surfaces).
2. Icons only from `assets/icons` via `BmIcon`. Never Material Icons.
3. Spec units are logical px at 393 pt width. Horizontal: stretch with screen width, keep side margins. Vertical: keep fixed sizes; scroll if content is longer.
4. Text scale clamped at 2.0. Above 1.4 the countdown and prayer rows use stacked layouts.
5. RTL: use `EdgeInsetsDirectional` / `AlignmentDirectional`. Never mirror the sun arc, clock times, progress rings or media controls (wrap in `Directionality(textDirection: TextDirection.ltr)`). Arabic uses Eastern Arabic digits by default.
6. Quran text is never animated, overlapped, cropped or decorative. Mockups use Amiri Quran; production uses KFGQPC Hafs + QCF V2 (licensed separately; leave a TODO and use AmiriQuran until provided).
7. All copy comes from `lib/l10n/app_en.arb` / `app_ar.arb`. If a string is missing, add it to both using the wording in the spec.
8. Every animation has its reduce-motion fallback (MOTION.md). Haptics only through `BmHaptics`.
9. WCAG AA contrast in both modes. Minimum hit target 44 × 44.
10. Living Sky uses `BmSkyState` for the current time. For visual QA against the PNGs use `BmSkyMode.themeBase`.

## Build order (one milestone at a time; stop and show screenshots after each)
1. Setup: copy `flutter/`, run the `flutter pub add` line in pubspec.yaml, `dart run flutter_launcher_icons`, `dart run flutter_native_splash:create`. App runs with theme, fonts and the empty 5-tab shell.
2. Data: location, prayer times (`adhan`, Umm al-Qura default in KSA), Hijri (`hijri` + adjustment), settings persistence. A debug scenario provider freezing time to Thu 15 Oct 2026 16:32 Makkah so screens match the PNGs.
3. Home (4.01, 4.02, 4.16): Living Sky painter, live countdown, glow.
4. Prayer (4.04, 4.17): logging, ring, week strip, qada.
5. Notifications + Adhan (4.03, 5.1, 5.2): rolling 6-day schedule, per-prayer sound, full-screen route, Android MediaStyle.
6. Qibla (4.05, 4.06): compass, spring.needle, alignment logic, haptics.
7. Quran reader (4.07) with audio follow; Al-Fatiha sample until the dataset is wired.
8. Azkar + Tasbih (4.08), Duas (4.14).
9. More, Theme picker, Hijri calendar (4.09, 4.15, 4.13).
10. Onboarding (4.10–4.12).
11. Widgets (5.5–5.8), Live Activity + Dynamic Island (5.3, 5.4) as native extensions fed by home_widget.

## Definition of done (every screen)
- Side by side with its PNG at 393 × 852: same positions (±1 pt), sizes, colors, fonts, copy, icons.
- Works in dark and light, English and Arabic, text scale 1.0 and 2.0, reduce motion on and off.
- Animations match MOTION.md; haptics match its table.
- No hard-coded strings, colors or sizes outside the theme files.

## Content to source (not in this package)
- Quran text (Uthmani, e.g. Tanzil), translation (Sahih International in mockups), surah metadata.
- Per-ayah recitation audio with timing data.
- Adhan audio (licensed); notification clip ≤ 30 s.
- Azkar and duas with sources, transliteration, translation.
Until provided, use the sample content shown in the screens.
