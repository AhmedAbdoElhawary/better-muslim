# Tokens

All values are already in code: `flutter/lib/theme/`. This page maps the CSS variable names used in the design files and the layout trees to those Dart names.

| CSS var in design | Dart (BmPalette) | Material ColorScheme | Qiyam Emerald dark | Qiyam Emerald light |
|---|---|---|---|---|
| --bg | bg | surface | #000000 | #F1F0EB |
| --surface | surface | surfaceContainerLow | #07100D | #FFFFFF |
| --raised | raised | surfaceContainer | #0C1814 | #F7F6F2 |
| --variant | variant | surfaceContainerHighest | #13221D | #E6E5DE |
| --outline | outline | outlineVariant | #1C2C26 | #DAD9D0 |
| --outline2 | outlineStrong | outline | #4C5E57 | #8E928C |
| --text | text | onSurface | #D9D3C2 | #121513 |
| --text2 | text2 | onSurfaceVariant | #878C82 | #565B57 |
| --text3 | text3 | — | #7B8079 | #666A65 |
| --primary | primary | primary | #A88A52 | #10382E |
| --on | onPrimary | onPrimary | #000000 | #E9D7AE |
| --pc | primaryContainer | primaryContainer | #221C10 | #DCE7E1 |
| --onpc | onPrimaryContainer | onPrimaryContainer | #D9C08A | #10382E |
| --accent | accent | secondary | #4E9C80 | #7F6738 |
| --ac | accentContainer | secondaryContainer | #0E2620 | #F1E8D4 |
| --onac | onAccentContainer | onSecondaryContainer | #8FCDB4 | #5C4A26 |
| --success | success | — | #5FB389 | #2E6B4A |
| --warning | warning | — | #D2A04F | #8A5A12 |
| --error | error | error | #E07A6A | #A33A2E |
| --glow | glow | — | #A88A52 | #A88A52 |
| --sky1 / --sky2 / --sky3 | sky1 / sky2 / sky3 | — | #000000 / #04100C / #173328 | #0E1A16 / #1F3A30 / #8F7A52 |
| --onSky | onSky | — | #D9D3C2 | #E9D7AE |
| --sun | sun | — | #CDB27A | #E9D7AE |
| --stars | starOpacity | — | 0.8 | 0.6 |

Fonts in the design → Dart: 'Marcellus' → BmFont.display, 'Schibsted Grotesk' → BmFont.body, 'Reem Kufi' → BmFont.displayAr, 'Noto Sans Arabic' → BmFont.bodyAr, 'Amiri' → BmFont.dua, 'Amiri Quran' → BmFont.quran.
Spacing, radius, sizes, opacity, shadows, glass: `bm_tokens.dart`. Motion: `bm_motion.dart` and MOTION.md. Living Sky states and arc geometry: `bm_sky.dart`.
System surfaces (notifications, widgets, Live Activity) always use the dark Qiyam Emerald values, whatever theme the user picked.
