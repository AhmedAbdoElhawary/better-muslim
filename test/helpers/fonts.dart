import 'package:flutter/services.dart';

/// the families in pubspec.yaml, for tests that measure text the way the app draws it
Future<void> loadAppFonts() async {
  const fonts = {
    'Marcellus': ['assets/fonts/Marcellus-Regular.ttf'],
    'SchibstedGrotesk': ['assets/fonts/SchibstedGrotesk-Variable.ttf'],
    'ReemKufi': ['assets/fonts/ReemKufi-Variable.ttf'],
    'NotoSansArabic': ['assets/fonts/NotoSansArabic-Variable.ttf'],
    'Amiri': ['assets/fonts/Amiri-Regular.ttf', 'assets/fonts/Amiri-Bold.ttf'],
    'AmiriQuran': ['assets/fonts/AmiriQuran-Regular.ttf'],
    'KfgqpcHafs': ['assets/fonts/KfgqpcHafs.ttf'],
  };
  for (final MapEntry(key: family, value: files) in fonts.entries) {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(rootBundle.load(file));
    }
    await loader.load();
  }
}
