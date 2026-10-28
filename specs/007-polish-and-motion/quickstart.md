# Quickstart: checking milestone 12

Two parts, each checked on its own before the next starts.

## Before

```bash
flutter pub get
dart run build_runner build
```

No new pub package. build_runner regenerates the store for schema 8. The contact rows stay hidden
until the values in `lib/features/more/model/contact.dart` are set
(`grep -rn "TODO(ahmed)" lib/features/more`).

## 1. Tests (all offline)

```bash
dart format --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
```

Expected, among the rest:
- **Part 1**
  - `test/features/home/view/sky_contrast_test.dart`: the sky text and scrim meet AA over all 48
    skies, dark and light (FR-021). Written first.
  - `test/core/resources/theme_sky_test.dart`: Qiyam Emerald's 18 colors equal `bmSkyQiyamEmerald`;
    each theme's Isha is its dark sky1 to sky3; every state's sky3 hue is within a few degrees of
    the theme's (SC-004).
  - `test/drift/app_database/migration_test.dart`: v7 → v8 keeps every row, a v7 Alhamdulillah 12
    reads 0, 12, 0, the mode Hijri, the glow on.
  - `test/core/backup/backup_file_test.dart`: a v7 backup restores with its Tasbih count in place.
  - `test/features/hijri_calendar/model/calendar_month_test.dart`: both kinds' days, blanks, ends
    (1356/1, 1500/12, April 1937, October 2077) with every adjustment.
  - `test/features/hijri_calendar/model/coming_up_test.dart`: from 15 Oct 2026 (4 Jumada I 1448)
    "This month" holds the white days, Ramadan's first day is "Estimated", pills count from the
    selected day; from 28 Dhu al-Hijjah "Next year (1449)" with Islamic New Year first; in 1500 at
    the end "No more events"; a running event isn't listed; the Gregorian year walk.
  - `test/features/hijri_calendar/view/hijri_calendar_page_test.dart`: today selected with six times;
    a day tap changes the area and opens no sheet; the title switches modes and keeps the day; the
    header cycles days, months, years; Today dimmed and its tap; a Coming up tap selects and opens
    Events; Events dimmed with its x when empty; Arabic and text scale 2.0.
  - `test/features/azkar/model/tasbih_state_test.dart`: 100 taps from reset end at 33, 33, 34 and
    complete; a chip keeps counts; reset; the next tap after complete; a tap on a done dhikr; bead
    positions 0, 33, 101.
  - `test/features/azkar/view/tasbih_page_test.dart` and `azkar_set_page_test.dart`, with fake time:
    the move after 1 s; a tap in the wait; a swipe or a chip cancels; leaving cancels; Reset and
    Undo.
  - `test/features/more/more_page_test.dart`: no Credits; Acknowledgements and Version in ABOUT;
    CONTACT hidden with every value null and shown with fake values; the adjustment row after Adhan
    and reminders; Top glow toggles the setting.
  - `test/core/system/system_channel_test.dart`: `mail` and `device` arguments and results.
- **Part 2**
  - `test/core/router/page_transitions_test.dart`: a push on Android and iOS uses the Cupertino
    transition; with `disableAnimations` only a fade, and the page under doesn't move.
  - `test/core/widgets/bm_dialog_test.dart`: scale 1.08 at the start, 1 at the end, a fade only
    with reduce motion.
  - `test/core/widgets/segmented_test.dart`: the highlight moves between segments over frames; a
    dimmed segment still taps.
  - `test/core/widgets/title_hero_test.dart`: a push from a tagged row shows the flight shuttle
    mid way, none with reduce motion.
  - `test/core/widgets/large_title_test.dart`: scrolling half the collapse distance puts the title
    half way; letting go snaps; with reduce motion the old fade.
  - `test/core/resources/contrast_test.dart`: the bar title over the glow in 8 themes × 2 modes.
  - the architecture and strings tests stay green, with the new rule on `bmSkyQiyamEmerald`.

## 2. Part 1 on a phone, Dev or the design scenario

```bash
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=dart_define/dev.json
```

1. **Calendar** (design scenario): today (4 Jumada I 1448) selected, Prayer times under the grid.
   Tap 13: times change, Events shows Ayyam al-Bid. Coming up: "This year (1448)", "This month",
   later months, pills. Tap Ramadan's start: the grid slides to Ramadan 1448, 1 Ramadan selected,
   Events open.
2. Tap the title: "Gregorian calendar", October 2026, small Hijri days with "Rab II" on the 1st.
   The header reads "October 2026" over "Rabi II – Jumada I 1448". Restart: still Gregorian.
3. Tap the header twice: years. Pick 1449, Ramadan: Ramadan 1449 (Hijri mode). Today at full
   strength, tap it: back to today, dimmed.
4. Select a day with no event: the Events label dimmed with its x, it still opens.
5. More › PRAYER › Hijri date adjustment +1: the calendar's grid and Home's date move.
6. **Sky** (Dev with a place, the design scenario keeps each theme's base sky as before): on Home
   pick each of the 8 themes: each sky in its own hue, Emerald's the same as before. Set the phone's
   clock to each prayer: the states change. The theme preview and
   the welcome screen show the same sky. Adhan screen and widgets stay Emerald.
7. **Azkar**: the morning set, tap a count 1 card: the check, about 1 s, the next card. A count 3
   card: three taps then a quick tap moves without counting. Swipe back in the wait: no move.
8. **Tasbih**: Reset, tap 100 times: 33, 33, 34, each moving by itself, the string stops on the head
   bead, "Set complete". Tap: SubhanAllah 1. Count 10, pick Alhamdulillah, back: still 10. Kill the
   app, open: still 10. Reset then Undo: all back. Arabic: the string isn't mirrored.
9. **More**: CONTACT above ABOUT (with values set), Send feedback opens the mail draft with the
   subject and the version, phone and OS in the body. Without a mail app (simulator): the toast with
   the address. Acknowledgements: the credits, then the licenses. No Credits row.
10. Arabic and text scale 2.0 on the calendar, Tasbih and More: nothing cut, the pills go under the
    name when the row is narrow.

## 3. Part 2 on a phone, profile mode on an older phone too

```bash
flutter run --profile --flavor dev -t lib/main_dev.dart --dart-define-from-file=dart_define/dev.json
```

1. **Pushes**: on Android and iPhone open every page in contracts/routes.md and go back: the page
   slides in, the one under moves a third and dims. iOS: the edge swipe follows the finger and
   cancels when let go early. Android: the back gesture and button play it in reverse. Arabic:
   from the other side.
2. **Flights**: More › Qibla, Hijri calendar, Duas, Theme, Adhan and reminders; Azkar › Morning,
   Evening, Tasbih; a dua category: the title flies and lands in the bar, the swipe back flies it
   back. Mid push tap back: it turns around from where it is.
3. **Dialogs**: Reset prayer journey: it grows in from 1.08 with the scrim.
4. **FR-036**: walk the table screen by screen: nothing swaps in one frame (the no location card,
   the strip marks, a Prayer row opening, Qada rows, chips, swatches, the method sheet's check,
   backup's working to done, a toast).
5. **Titles**: scroll Prayer, Azkar and More slowly: the title shrinks into the bar with the finger,
   the subtitle fades, stop half way: it snaps. Scroll back: it comes out.
6. **Glow**: every page in FR-040 has it at the top, it stays when scrolling, the bar is see-through
   over it. More › Top glow off: gone everywhere, the bar plain glass, Home's sky the same.
7. **Reduce motion** (the phone's and the switch in More): pushes are short fades, no flight, no
   slide or scale, the title fades in as before, the bead string jumps.
8. **Performance**: DevTools' frame chart during pushes, flights, the title move and the month
   slide: no frame over budget on the older phone (SC-008). Tap during each: it answers at once
   (SC-009).
