import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';

/// here and not in the quran feature, the settings table in core stores them
enum PageColor {
  followSky,
  paper,
  cream,
  sepia,
  green,
  night,
  navy;

  bool get dark => this == PageColor.night || this == PageColor.navy;

  /// a StringsManager key
  String get label => switch (this) {
    PageColor.followSky => StringsManager.followSky,
    PageColor.paper => StringsManager.paper,
    PageColor.cream => StringsManager.cream,
    PageColor.sepia => StringsManager.sepia,
    PageColor.green => StringsManager.green,
    PageColor.night => StringsManager.night,
    PageColor.navy => StringsManager.navy,
  };

  /// follow sky takes the app's mode now, which may itself follow the sky or the phone
  PageColor resolve({required bool dark}) => switch (this) {
    PageColor.followSky => dark ? PageColor.night : PageColor.paper,
    _ => this,
  };
}

enum QuranLayout { mushaf, translation, both }

enum PageTurn { book, slide }

enum RibbonColor { primary, accent, neutral }

/// the mushaf and share font, picked in Display (FR-011, FR-026)
enum QuranFont {
  amiri(StringsManager.fontAmiri, FontEnum.quran),
  kfgqpc(StringsManager.fontKfgqpc, FontEnum.kfgqpc),
  scheherazade(StringsManager.fontScheherazade, FontEnum.scheherazade);

  const QuranFont(this.label, this.font);

  final String label;
  final FontEnum font;

  String get family => font.arabic;
}
