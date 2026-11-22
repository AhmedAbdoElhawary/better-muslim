# Contract: the shared share sheet

`lib/core/widgets/share/share_sheet.dart`

```dart
Future<void> showShareSheet(
  BuildContext context, {
  required ShareContent content,
  List<Widget> rows = const [],
  List<ShareOrnament> ornaments = ShareOrnament.patterns,
});
```

- `ShareContent` is what a feature gives:
  - `layout(ShareOptions options, Size card) → ShareLayout`, pure and cheap, called on every
    option change;
  - `paint(Canvas, Size, ShareOptions, ShareLayout)`, drawing the text inside the frame;
  - `footer(ShareOptions) → String`, the line next to the app name.
- `ShareLayout` is `(ShareSize size, double scale, bool fits, String? note)`. `note` shows under
  the preview (e.g. "Tafsir hidden for 2 ayahs").
- The sheet owns:
  - the preview;
  - the background swatches, Solid color, Ornament (and its picker), Font, size and app name;
  - the capture to a 1080-wide PNG;
  - `shareProvider`.

  It applies `ShareLayout.size` unless the user locked a size.
- The card ignores text scaling and uses `AppTheme.page(background.page, themeId)`.

## Users

| Feature | Content | Rows | Ornaments |
| --- | --- | --- | --- |
| Quran | `AyahShare(keys)`: runs, dividers, tafsir per ayah, the fit steps | text picker (Translation, Muyassar, Ibn Kathir, Sa'di) | patterns |
| Duas | `DuaShare(dua)`: Arabic, transliteration, translation, source | none | patterns + `frame_arch` |

- `ShareOptions` holds only what every content shares. Content-specific choices (the ayah's text
  source) live in the content object, and its `rows` rebuild it.

## Adding an ayah while choosing

`AyahShare.canAdd(keys + key) → bool` runs the same `layout` with the most forgiving options
(story, scale .7, no tafsir). False means a toast and the ayah stays unchecked. The first ayah
skips the check: if it doesn't fit alone, `layout` keeps shrinking below .7 until it does (FR-018).
