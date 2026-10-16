# Screens index

Each screen has: a reference PNG (`reference/screens/`), an exact layout tree (`specs/screens/`), and its source in `design/06 Screens.dc.html`. Build each screen until it matches its PNG at 393 × 852 (iPhone 15) in both modes. Scenario everywhere: Thursday 15 Oct 2026, 16:32 Makkah, Umm al-Qura. Fajr 04:58, Sunrise 06:15, Dhuhr 12:05, Asr 15:27, Maghrib 17:56, Isha 19:26. 4 Jumada I 1448. Fajr and Dhuhr logged.

Navigation: root = bottom bar with 5 tabs (Home, Prayer, Quran, Azkar, More), each tab keeps its own navigator (IndexedStack). Tab switch = Motion 16 (fade through 300 ms). Pushed pages use the compact app bar (56 pt, back chevron 44 × 44). Screens with large titles (Prayer times, More) collapse into the compact bar on scroll.

## 4.01 Home
- Reference: `reference/screens/4.01-home.png` · Spec: `specs/screens/4.01-home.md`
- Entry: Tab Home
- Dynamic values: cd = countdown h:mm:ss to next prayer, ticks every second (Motion 04: each digit slides 300 ms standard).
- Behaviour: Location pill → location sheet. Next-prayer card → Prayer tab. Strip cell → Prayer tab scrolled to that prayer. Verse card → Quran reader at that ayah. Continue reading → Quran reader at last position. Evening azkar → Azkar.

## 4.02 Home · light
- Reference: `reference/screens/4.02-home-light.png` · Spec: `specs/screens/4.02-home-light.md`
- Entry: Same screen in light mode
- Dynamic values: Same as 4.01.
- Behaviour: Same as 4.01. The sky keeps its own palette in light mode.

## 4.03 Adhan
- Reference: `reference/screens/4.03-adhan.png` · Spec: `specs/screens/4.03-adhan.md`
- Entry: Full-screen route pushed over anything at prayer time (foreground) or from the notification
- Dynamic values: Adhan progress (position / duration of the audio).
- Behaviour: Stop adhan → stops audio, pops. Mark prayed → logs the prayer (Motion 07 haptic), keeps playing. Read dua → dua sheet. Enter: Motion 06 (circle reveal 520 ms decelerate from the sun position, text +300 ms).

## 4.04 Prayer
- Reference: `reference/screens/4.04-prayer.png` · Spec: `specs/screens/4.04-prayer.md`
- Entry: Tab Prayer
- Dynamic values: asrPrayed/asrOpen = log state of the current prayer; prayedN = count today; ringOff = ring stroke offset (circumference 150.8 × (1 − n/5)); cdShort = h:mm to the next prayer.
- Behaviour: Mark on the current prayer → log it: chip morphs to "Prayed" (Motion 07), ring animates 300 ms, week dot fills. Tap "Prayed" again → undo (toast with Undo, 4 s). Past unlogged prayer shows "Add to qada". Summary card → qada list. Day cell → that day. Pin → location. Sliders → calculation method sheet. Fifth prayer → Motion 08 Day complete.

## 4.05 Qibla · turning
- Reference: `reference/screens/4.05-qibla-turning.png` · Spec: `specs/screens/4.05-qibla-turning.md`
- Entry: More › Qibla tile
- Dynamic values: heading from the compass; instruction text "Turn N° right/left" = shortest signed difference to the Qibla bearing.
- Behaviour: Dial (ticks, letters, Kaaba marker) rotates by −heading. Needle follows with spring.needle, shortest path across 0/360. Entering ±10° → selection haptic once.

## 4.06 Qibla · aligned
- Reference: `reference/screens/4.06-qibla-aligned.png` · Spec: `specs/screens/4.06-qibla-aligned.md`
- Entry: Same route, state aligned
- Dynamic values: aligned = |diff| ≤ 3° for 400 ms.
- Behaviour: On align: ring + top tick turn accent, two pulses (Motion 10), success haptic once per alignment, title "Facing the Qibla", subtitle "Hold steady". Leaving ±5° returns to turning state.

## 4.07 Quran reader
- Reference: `reference/screens/4.07-quran-reader.png` · Spec: `specs/screens/4.07-quran-reader.md`
- Entry: Tab Quran › surah
- Dynamic values: playing ayah index; audio progress.
- Behaviour: Tab bar hidden. Swipe = page turn (Motion 13, RTL order). Tap ayah = toggle actions row (Play, Tafsir, Save, Note, Share). Playing ayah highlighted in primaryContainer and auto-scrolled (Motion 14). Mini player: play/pause, repeat, next ayah. Aa → text size sheet. Bookmark toggles. Quran text is never animated, overlapped or cropped by controls.

## 4.08 Tasbih
- Reference: `reference/screens/4.08-tasbih.png` · Spec: `specs/screens/4.08-tasbih.md`
- Entry: Tab Azkar › Tasbih
- Dynamic values: n = count, target = 33/33/34 for the three dhikr, off = ring offset (716.3 × (1 − n/target)), done = n ≥ target, dk0..2 = which dhikr.
- Behaviour: Whole lower area is the tap target: n+1, bead strip springs 44 px (Motion 11), light haptic. At target: ring full, glow, "Set complete", set-complete haptic (Motion 12). Next tap after done → next dhikr, n = 1. Reset icon → n = 0, first dhikr. Chips select the dhikr.

## 4.09 More
- Reference: `reference/screens/4.09-more.png` · Spec: `specs/screens/4.09-more.md`
- Entry: Tab More
- Dynamic values: Values come from settings.
- Behaviour: Tiles → Qibla, Hijri calendar, Duas. Rows push their settings pages; toggles change instantly with a selection haptic.

## 4.10 Welcome
- Reference: `reference/screens/4.10-welcome.png` · Spec: `specs/screens/4.10-welcome.md`
- Entry: First launch, after splash
- Dynamic values: Live sky state for the current hour.
- Behaviour: Get started → 4.11. Restore from backup → file picker. Enter: Motion 01 (launch) ends here; the sun rises from the horizon.

## 4.11 Location
- Reference: `reference/screens/4.11-location.png` · Spec: `specs/screens/4.11-location.md`
- Entry: Onboarding step 1 of 3
- Dynamic values: —
- Behaviour: Use my location → OS location permission → compute times → 4.12. Choose a city → searchable city list → 4.12. Step dots at top.

## 4.12 Notifications
- Reference: `reference/screens/4.12-notifications.png` · Spec: `specs/screens/4.12-notifications.md`
- Entry: Onboarding step 2 of 3
- Dynamic values: Per-prayer sound selection; defaults Adhan for Fajr and Maghrib, Tone for the rest.
- Behaviour: Segmented controls change the choice. Allow notifications → OS permission → step 3 (theme, = 4.15 without back button) → Home. Not now → skip permission, keep choices.

## 4.13 Hijri calendar
- Reference: `reference/screens/4.13-hijri-calendar.png` · Spec: `specs/screens/4.13-hijri-calendar.md`
- Entry: More › Hijri calendar
- Dynamic values: Month grid from the Umm al-Qura table + user adjustment (−2…+2 days). Today highlighted. White days (13–15) dotted.
- Behaviour: Arrows change month. Day tap → day sheet with prayer times and events. Date adjustment → stepper sheet.

## 4.14 Duas
- Reference: `reference/screens/4.14-duas.png` · Spec: `specs/screens/4.14-duas.md`
- Entry: More › Duas
- Dynamic values: Dua list by category; search over Arabic, transliteration and translation.
- Behaviour: Chips filter. Listen plays audio. Save bookmarks. Share → image card. Row → dua detail.

## 4.15 Theme
- Reference: `reference/screens/4.15-theme.png` · Spec: `specs/screens/4.15-theme.md`
- Entry: More › Theme (and onboarding step 3)
- Dynamic values: Selected theme id, mode (dark/light/followSky). The preview renders the Home snippet with the chosen palette.
- Behaviour: Swatch tap → preview updates instantly (no apply needed to preview). Dark/Light changes the preview mode. Apply theme → saves, app rebuilds MaterialApp theme with a 300 ms crossfade.

## 4.16 Home · Arabic
- Reference: `reference/screens/4.16-home-ar.png` · Spec: `specs/screens/4.16-home-ar.md`
- Entry: Home with locale ar
- Dynamic values: Same as 4.01, Eastern Arabic digits.
- Behaviour: Same as 4.01. Layout mirrored; arc, clock times and progress bars stay LTR (wrap in Directionality(ltr)).

## 4.17 Prayer · Arabic
- Reference: `reference/screens/4.17-prayer-arabic.png` · Spec: `specs/screens/4.17-prayer-arabic.md`
- Entry: Prayer with locale ar
- Dynamic values: Same as 4.04, Eastern Arabic digits.
- Behaviour: Same as 4.04. Week reads from Sunday on the right.

## System surfaces
Reference PNGs in `reference/surfaces/`, exact trees in `specs/surfaces/`, implementation table in `design/07 System surfaces.dc.html` section 04. These are native code (Swift WidgetKit / ActivityKit, Kotlin Glance / notifications), fed by data the Flutter app writes to the App Group / SharedPreferences (7 days of times).
