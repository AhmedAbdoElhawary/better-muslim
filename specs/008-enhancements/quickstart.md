# Quickstart: checking the enhancements

## Before

```bash
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

Run Dev on an iPhone and an Android phone:

```bash
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=dart_define/dev.json
```

For Android sharpness, run in profile mode too:

```bash
flutter run --profile --flavor dev -t lib/main_dev.dart --dart-define-from-file=dart_define/dev.json
```

## Phase A, quick fixes

1. **More title**: in More, switch to العربية and scroll. The title moves from the right into the
   bar's center. Switch back to English and scroll again: it moves from the left.
2. **Toasts**:
   - Quran → long press an ayah, share, then tap Square on a long ayah: the toast is above the
     sheet.
   - Reset prayer journey: the toast after it is above everything.
3. **Glass nav bar**: scroll each tab. The content shows blurred under the bar, and the last row
   scrolls fully above it. Turn the top glow off and on: the tint changes.
4. **Dialog**: More → Reset prayer journey. The page behind blurs in, then out on close.
5. **Splash**: kill the app and start it cold on both phones (and Android 12+). The symbol is
   sharp and bigger.
6. **Verse**: the design scenario shows the verse for 15 Oct 2026. Debug time → next day: a
   different verse. Tap: the reader opens on it.

## Phase B, share

1. Long press 2:255 → tap 2:256, 2:257, then turn to 3:18 and tap it → Share (4). The card shows
   one block, a divider, then 3:18. The footer reads "Al-Baqarah 255–257 · Āl ʿImrān 18".
2. Pick Muyassar: the card goes to story, then tafsir hides from 3:18 with the note.
3. Try adding 2:282 with tafsir on: a toast, and it's not added.
4. Change Font, Ornament, Solid color and background: the preview and the shared image match.
5. Duas → any dua → Share: the same sheet, with the arch frame among the ornaments.
6. Study tabs → Ibn Kathir: download with progress, then text. Airplane mode + restart: it's
   still there. In share pick Sa'di: it downloads, then shows, cut at a sentence end if long.

## Phase C, reader

1. On the Android phone, the four sharpness runs from research R11. Write down what each shows.
2. Display → Font → each font: lines justified, none past the frame, on pages 1, 2, 50, 300, 604.
3. Display → each palette, in dark and light, in two themes.
4. Book mode: drag the bottom corner slowly, then a flick, then a short drag. Check the first
   and last page. Reduce motion gives the crossfade.
5. Profile mode on the Android phone: turn 20 pages with the performance overlay on. No red bars
   (SC-007).

## Phase D, Home arc

1. Design scenario (16:32): Sunrise, Dhuhr (top), Asr and Maghrib with dots, the sun between Asr
   and Maghrib, rays turning.
2. Debug time 23:00: Maghrib, Isha, Last third, Fajr, Sunrise, with the three stars before Last
   third.
3. Debug time 17:55 → wait past Maghrib: the wheel turns. Do the same around Sunrise.
4. Text scale 2.0, Arabic, Western digits on and off, reduce motion on: a crossfade, nothing
   moves.
