# Handoff: Better Muslim — Flutter app (iOS + Android)

## Overview
Better Muslim is a premium Islamic companion app: prayer times and adhan, prayer logging, Qibla, Quran reader with audio, azkar/tasbih, duas, Hijri calendar, widgets and Live Activity. The signature idea is the **Living Sky**: the Home header is a sky gradient that follows the real sun position for the user's location through six sky states (Fajr, Duha, Dhuhr, Asr, Maghrib, Isha). Main theme: **#9 Qiyam Emerald** (true-black dark, warm paper light). No account, no ads, everything computed on device.

## About the design files
The `.dc.html` files in `design/` are **design references built in HTML** — they show intended look, copy and behaviour. They are not production code. Recreate them in **Flutter** (Material 3 + ThemeExtensions), following the token and component structure described here. Open any file directly in a browser (keep `support.js` next to them). Each file has a Tweaks panel (e.g. Dark/Light, Reduce motion).

## Fidelity
**High fidelity.** Colors, type, spacing, radii, motion timings and copy are final. Recreate pixel-accurately at iPhone 15 (393 × 852 pt). Android uses the same layouts with platform-native system surfaces.

## Files (read in this order)
| File | Contents |
|---|---|
| design/01 Brand.dc.html | Logo (8-point star window + horizon + sun arc), app icons iOS/Android, 6 sky states, Noor motif, type, 18 icons (outline + filled), ornaments, voice, sound |
| design/04 Themes - Exploration.dc.html | 16 explored themes; #9 Qiyam Emerald is main. Parked alternates: #6 Qiyam, #1 Noor, #2 Living Sky, #4 Iznik, #3 Andalus, #11 Moonlight, #16 Qiyam Rose |
| design/02 Tokens.dc.html | Color roles light/dark with Flutter ColorScheme mapping, BmSky, type scale EN + AR, spacing, radius, elevation/glass, opacity, motion tokens, Dart code |
| design/03 Components.dc.html | Every component with states (default, pressed, focused, selected, disabled, loading, error, empty), Dark/Light switch, theme picker |
| design/Theme Snippet.dc.html | Small Home snippet driven by CSS vars; used for theme previews |
| design/05 Motion.dc.html | 16 animations live, 3 motion tiers, spec table, haptics map, choreography rules, reduce-motion rules |
| design/06 Screens.dc.html | 17 screens: Home (dark/light), Adhan, Prayer, Qibla ×2, Quran reader, Tasbih, More, onboarding ×3, Hijri calendar, Duas, Theme, Arabic Home + Prayer |
| design/07 System surfaces.dc.html | iOS notifications, Android shade (MediaStyle adhan), Live Activity, Dynamic Island, widgets S/M/L, lock accessories, Android 4×2, implementation table |
| design/08 Store.dc.html | Store screenshots EN/AR, feature graphic, icons, listing copy, metadata |

## Design tokens

### Color — Qiyam Emerald
| Role (token) | Flutter | Dark | Light |
|---|---|---|---|
| color.bg | ColorScheme.surface | #000000 | #F1F0EB |
| color.surface | surfaceContainerLow | #07100D | #FFFFFF |
| color.surfaceRaised | surfaceContainer | #0C1814 | #F7F6F2 |
| color.variant | surfaceContainerHighest | #13221D | #E6E5DE |
| color.outline | outlineVariant | #1C2C26 | #DAD9D0 |
| color.outlineStrong | outline | #4C5E57 | #8E928C |
| color.text | onSurface | #D9D3C2 | #121513 |
| color.text2 | onSurfaceVariant | #878C82 | #565B57 |
| color.text3 | BmColors.textTertiary | #7B8079 | #666A65 |
| color.primary | primary | #A88A52 | #10382E |
| color.onPrimary | onPrimary | #000000 | #E9D7AE |
| color.primaryContainer | primaryContainer | #221C10 | #DCE7E1 |
| color.onPrimaryContainer | onPrimaryContainer | #D9C08A | #10382E |
| color.accent | secondary | #4E9C80 | #7F6738 |
| color.accentContainer | secondaryContainer | #0E2620 | #F1E8D4 |
| color.onAccentContainer | onSecondaryContainer | #8FCDB4 | #5C4A26 |
| color.success | BmColors.success | #5FB389 | #2E6B4A |
| color.warning | BmColors.warning | #D2A04F | #8A5A12 |
| color.error | error | #E07A6A | #A33A2E |
| color.glow | BmColors.glow | #A88A52 | #A88A52 |

Sky (BmSky, Home header, 3 stops top→bottom): dark Isha `#000000 → #04100C → #173328`, light `#0E1A16 → #1F3A30 → #8F7A52`. Text on sky: dark #D9D3C2, light #E9D7AE. Sun #CDB27A (dark) / #E9D7AE (light). Store/system sky states: Fajr `#05080F→#14243A→#4A5C70→#8A8F92`, Duha `#0C1F1A→#1F4A3E→#6E9A86`, Dhuhr `#0A1A16→#173328→#4E7A64`, Asr `#1A1A12→#3A3A26→#8F7A52→#B89A68`, Maghrib `#14121C→#2A1F2A→#6A4436→#A8714C` (adhan screen uses `#14121C→#2A1F2A→#6A4436→#C98E5E`), Isha as above.

Every theme is one Dart file (`lib/theme/tokens/<theme>.dart`) producing light + dark BmThemeData. Alternate theme values are in `03 Components.dc.html` (logic class, `T` map).

### Typography
- Latin display: **Marcellus** 400 — screen titles 34/1.1, hero prayer 52, card titles 21–32
- Body/UI: **Schibsted Grotesk** 400/500/600 — body 15/1.5, labels 12–13, buttons 15/500, tabular numerals for all times
- Arabic display: **Reem Kufi** 400/500; Arabic UI: **Noto Sans Arabic** 400–600
- Duas: **Amiri** 22–40, line-height 1.7–1.9
- Quran: mockups use Amiri Quran 26/2.2; **production must use KFGQPC Hafs (Uthmani) + QCF V2 page fonts**
- Text scale clamped to 2.0; countdown and prayer rows switch to stacked layouts above 1.4

### Spacing, radius, elevation
- Spacing (4 pt grid): 4, 8, 12, 16, 20, 24 (+ 32, 48 for sections). Screen side margin 16; card padding 14–18
- Radius: sm 10, md 14 (buttons, inputs, rows), lg 20 (cards), xl 28 (sheets top), pill 999; phone list rows 16
- Dark: no shadows. Depth = lighter surface + 1 px outline; hero next-prayer card adds glow `0 0 32px -8px rgba(168,138,82,.28)`
- Light: `0 10px 28px -14px rgba(16,56,46,.35)` for raised cards
- Glass on sky: blur σ20, surface 55%, top highlight 12% white
- Opacity: disabled 0.38, pressed overlay 0.12, focus 0.10, scrim 0.48 light / 0.64 dark
- Hit targets ≥ 44 pt; buttons 48–52 tall

### Motion tokens (BmMotion)
Durations micro 150, standard 300, emphasized 520, ambient 6000 ms. Curves: standard Cubic(.2,0,0,1), decelerate (.05,.7,.1,1), accelerate (.3,0,.8,.15), breathe (.37,0,.63,1), sacred (.4,0,.2,1). Springs (mass 1, `SpringDescription.withDampingRatio`): gentle stiffness 180 ζ 0.90 (≈520 ms), snappy 420 / 0.80 (≈380 ms), needle 120 / 0.55 (≈1030 ms).

## Screens
Scenario used everywhere: Thursday 15 Oct 2026, 16:32 Makkah, Umm al-Qura; Fajr 04:58, Sunrise 06:15, Dhuhr 12:05, Asr 15:27, Maghrib 17:56, Isha 19:26; 4 Jumada I 1448. Times are 24 h.

Root navigation: bottom bar with 5 tabs — Home, Prayer, Quran, Azkar, More. Bar: surface color, 1 px top outline, selected tab = 56×32 pill in primaryContainer + filled icon + 600 label.

- **4.1/4.2 Home** — Sky header 380 pt tall with stars (dark), dotted sun arc (radius 136.5, horizon at y 300), sun dot at real solar position, location pill (glass), date + Hijri, "NOW / Asr" (Marcellus 52). Next-prayer card overlaps sky by 60 pt: "Next prayer", Maghrib (Marcellus 32), live countdown h:mm:ss (26/500, primary), progress bar 3 pt, reminder line. Then 5-cell prayer strip (current highlighted, logged ones show a success check), Verse of the day card, Continue reading / Evening azkar card.
- **4.3 Adhan** — full-screen Maghrib sky, sun on horizon at y 540, star mark, Arabic + English prayer name (Reem Kufi 40 / Marcellus 60), adhan progress, glass card with the dua after adhan, buttons Mark prayed (glass) + Stop adhan (primary, #F6EAD6 on #1E1A26).
- **4.4 Prayer** — large title "Prayer times", week strip (7 days, 5 dots each = prayers logged), summary card with progress ring (r 24, stroke 4), prayer rows 62 pt (Sunrise 44 pt, not loggable). Current row uses primaryContainer. Mark action → "Prayed" chip; ring/count/week dots update. Missed prayers → qada list.
- **4.5/4.6 Qibla** — dial 300 pt, ticks every 5°, cardinal letters counter-rotated, Kaaba marker at bearing, needle springs (spring.needle). Instruction "Turn 14° right". Aligned (±3° held 400 ms): ring turns accent, pulses twice, label "Facing the Qibla", success haptic once. Distance + compass accuracy cards.
- **4.7 Quran reader** — tab bar hidden; surah header card; verse cells (Arabic right-aligned, ayah-number star medallion, translation 14/1.55); playing ayah in primaryContainer; mini player (raised surface, 2 pt progress). Never crop an ayah under controls.
- **4.8 Tasbih** — dhikr chips (SubhanAllah 33, Alhamdulillah 33, Allahu Akbar 34), Arabic in Amiri 40, ring r 114 stroke 5, count Marcellus 80; whole lower area is the tap target; bead strip springs 44 pt per tap; at target: ring full + glow + "Set complete", next tap advances to next dhikr.
- **4.9 More** — tiles (Qibla, Hijri calendar, Duas) + grouped settings: Prayer, Appearance (Theme, Light and dark: Follow sky, Reduce motion), Sound and touch (Haptics, UI sounds).
- **4.10–4.12 Onboarding** — Welcome on the Living Sky; Location primer before OS dialog (Use my location / Choose a city); Notifications per prayer (Adhan / Tone / Silent; defaults Adhan for Fajr + Maghrib) before OS permission.
- **4.13 Hijri calendar** — Hijri day large, Gregorian small, white days dotted in accent, month starts labelled "estimated", date adjustment ±days. *Verify the 1 Jumada I 1448 = 12 Oct 2026 mapping against Umm al-Qura.*
- **4.14 Duas** — search, category chips, dua card (Arabic, transliteration, translation, source), list.
- **4.15 Theme** — live preview, Dark / Light / Follow sky, 8 theme swatches, Apply.
- **4.16/4.17 Arabic** — full RTL mirror; Eastern Arabic digits (setting to switch). **Do not mirror**: sun arc, clock times, progress rings, media controls (wrap in `Directionality(ltr)`).

## Interactions and motion
| # | Animation | Screen | Trigger | Duration | Curve / spring | Reduce motion | Flutter |
|---|---|---|---|---|---|---|---|
| 01 | App launch | Splash | Cold start, until Home first frame | 1200 ms | sacred · decelerate | Logo fades in, 300 ms. No sun rise. | flutter_native_splash → AnimationController(1200 ms) with staggered Interval curves |
| 02 | Living Sky | Home | While Home is visible | 6000 ms loop | breathe | Static gradient for the current sky state | CustomPainter on a Ticker inside RepaintBoundary; paused via AppLifecycleListener |
| 03 | Sky change | Home, widgets | Prayer time boundary | 1800 ms | sacred | 300 ms crossfade | TweenAnimationBuilder<BmSkyStops>, lerping gradient stops |
| 04 | Countdown tick | Home | Every second | 300 ms | standard | Instant digit swap | AnimatedSwitcher per digit with SlideTransition; Timer aligned to the wall clock |
| 05 | Prayer glow | Home card | Final 10 min before a prayer | 6000 ms loop | breathe | Static glow at 50% | AnimationController.repeat(reverse: true) driving BoxShadow |
| 06 | Adhan reveal | Adhan, full screen | Prayer time in foreground, or notification tap | 520 ms + 520 ms text (300 ms offset) | decelerate | 300 ms fade | ClipPath with a circle-reveal clipper; FadeTransition + SlideTransition for text |
| 07 | Mark prayed | Prayer | Tap check | 380 ms (+220 ms check) | spring.snappy · standard | Fill crossfade, 150 ms | SpringSimulation for scale; PathMetric.extractPath for the check stroke |
| 08 | Day complete | Prayer | Fifth prayer marked | 1400 ms | standard · spring.gentle | Star fades in, 300 ms | Staggered controller; ScaleTransition driven by SpringSimulation |
| 09 | Qibla needle | Qibla | Heading update (low-pass filtered) | ≈1030 ms settle | spring.needle | Standard 300 ms, no overshoot | Compass stream → SpringSimulation on angle; shortest path across 0°/360° |
| 10 | Qibla aligned | Qibla | Within ±3° for 400 ms | 900 ms × 2 | decelerate | Color change only | AnimatedContainer border + ScaleTransition ring; once per alignment |
| 11 | Tasbih bead | Tasbih | Tap anywhere | 380 ms | spring.snappy | Beads step instantly; counter swaps | SpringSimulation on strip offset; a new tap retargets from current velocity |
| 12 | Set complete | Tasbih | Count reaches 33, 99 or target | 300 ms ring + 700 ms burst | standard · decelerate | Ring fills, no burst | TweenAnimationBuilder on sweep angle; 8-particle CustomPainter |
| 13 | Page turn | Quran reader | Swipe or edge tap | 300 ms | standard | 150 ms crossfade | PageView(reverse: true) for RTL order; 30% parallax in a custom transformer |
| 14 | Ayah follow | Quran reader | Recitation timing cue | 300 ms | standard | Highlight jumps | AnimatedPositioned over line rects from the QCF glyph layout |
| 15 | Bottom sheet | Global | Open picker or settings; dismiss | ≈520 ms in · 300 ms out | spring.gentle · accelerate | 150 ms fade in place | showModalBottomSheet with sheetAnimationStyle; SpringSimulation on drag release |
| 16 | Tab switch | Root navigation | Tab tap | 300 ms | standard (shared axis) | 150 ms crossfade | NavigationBar + IndexedStack; FadeThroughTransition (animations package) |

Tiers: **Ambient** (time-driven loops, 30 fps, paused off-screen, no haptics), **Responsive** (touch/sensor, 150–380 ms, interruptible — always retarget springs, never queue), **Ceremonial** (adhan, completions, 520–1800 ms, one at a time; adhan > completions > responsive > ambient). Ambient loops stop in background and Low Power Mode / Battery Saver.

Reduce motion = `MediaQuery.disableAnimationsOf(context) || prefs.reduceMotion`: travel becomes 150–300 ms crossfades, springs become standard 300 ms, loops freeze on the current sky; state changes and haptics remain.

### Haptics
| Event | When | iOS | Android | Flutter | Sound |
|---|---|---|---|---|---|
| Tasbih bead | Every count | Impact .light | CLOCK_TICK | HapticFeedback.lightImpact() | Bead |
| Set complete | 33, 99 or target reached | Notification .success | CONFIRM | mediumImpact() ×2, 80 ms apart | Complete |
| Mark prayed | Check filled | Impact .light | CONFIRM | HapticFeedback.lightImpact() | — |
| Day complete | Fifth prayer marked | Notification .success | CONFIRM | HapticFeedback.mediumImpact() | Complete |
| Qibla approach | Needle enters ±10°, once | Selection | CLOCK_TICK | HapticFeedback.selectionClick() | — |
| Qibla aligned | Within ±3° for 400 ms, once per alignment | Notification .success | CONFIRM | HapticFeedback.mediumImpact() | Aligned |
| Sheet detent | Sheet snaps to a detent on drag release | Selection | SEGMENT_TICK (API 34+) | HapticFeedback.selectionClick() | — |
| Toggle, segmented | Value changes | Selection | CLOCK_TICK | HapticFeedback.selectionClick() | — |
| Page turn | Page settles (off by default) | Selection | CLOCK_TICK | HapticFeedback.selectionClick() | Page |
| Prayer reminder | Pre-prayer notification | System notification | Channel vibration pattern | flutter_local_notifications channel | Reminder |
| None | Living Sky, countdown, sky change, adhan reveal, tabs, sheets opening | — | — | — | — |

## System surfaces
| Surface | When | iOS | Android | Flutter |
|---|---|---|---|---|
| Adhan notification | Each prayer | Time-sensitive; ≤30 s clip, full adhan in app | High-importance channel per prayer; MediaStyle while adhan plays (foreground service) | flutter_local_notifications zonedSchedule; rolling 6 days (iOS 64-pending limit), top up on launch / background fetch |
| Reminder | X min before (default 10) | Passive | Default channel | separate category |
| Live Activity | 2 h before each prayer → adhan | ActivityKit, `Text(timerInterval:)` | Ongoing notification + Chronometer | live_activities + Swift extension |
| Widgets | Always | WidgetKit, timeline entry per prayer boundary, `Text(date, style: .timer)` | Jetpack Glance, Chronometer, AlarmManager at boundaries | home_widget; app writes 7 days of times to App Group / SharedPreferences |
| Lock screen | Always | accessoryCircular / Rectangular / Inline | (use widget) | shared extension |
System surfaces always use the dark Qiyam Emerald night sky regardless of theme.

## State
- `location` (lat, lng, city, auto/manual), `method` (default Umm al-Qura in KSA, else by region), `asrMadhab`, `hijriAdjust` (−2…+2)
- `prayerTimes` computed on device (e.g. `adhan` Dart package), recomputed on location change > 30 km and at midnight
- `log`: map date → set of prayers prayed; `qada` count
- `notifications`: per prayer {Adhan | Tone | Silent}, reminderMinutes
- `theme` (BmTheme id), `themeMode` {dark, light, followSky}, `reduceMotion`, `haptics`, `uiSounds`, `digits` {eastern, western}
- `quran`: last read (surah, ayah), bookmarks, notes, reciter, playback rate
- `tasbih`: current dhikr, count, targets
All persisted locally (e.g. Hive/Isar). No backend required.

## Content rules
- Quran text: never decorative, never overlapped, cropped or animated inside the text block. Mockups only show Al-Fatiha.
- No people or animals in imagery; no music (adhan and recitation only).
- WCAG AA contrast in both modes.
- No streaks, guilt or reward claims in copy.

## Assets
- Logo, app icon and 18 icons are drawn as SVG in `01 Brand.dc.html` (copy the path data; 24 × 24 grid, stroke 1.25, round caps/joins).
- Fonts: Google Fonts (Marcellus, Schibsted Grotesk, Reem Kufi, Noto Sans Arabic, Amiri). Quran fonts: KFGQPC (licensed separately).
- Adhan / recitation audio: to be sourced and licensed; UI sounds spec in Brand (−24 LUFS).
