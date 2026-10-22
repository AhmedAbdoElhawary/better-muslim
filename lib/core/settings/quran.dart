/// here and not in the quran feature, the settings table in core stores them
enum PageColor {
  followSky,
  paper,
  cream,
  night;

  /// follow sky takes the app's mode now, which may itself follow the sky or the phone
  PageColor resolve({required bool dark}) => switch (this) {
    PageColor.followSky => dark ? PageColor.night : PageColor.paper,
    _ => this,
  };
}

enum QuranLayout { mushaf, translation, both }

enum PageTurn { book, slide }

enum RibbonColor { primary, accent, neutral }
