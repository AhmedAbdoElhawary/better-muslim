import 'package:flutter/material.dart';

/// Families declared in pubspec.yaml.
abstract final class BmFont {
  static const display = 'Marcellus'; // Latin display, weight 400 only
  static const body = 'SchibstedGrotesk'; // variable, use fontVariations for weight
  static const displayAr = 'ReemKufi'; // variable
  static const bodyAr = 'NotoSansArabic'; // variable
  static const dua = 'Amiri';
  static const quran = 'AmiriQuran'; // mockup font. Production: KFGQPC Hafs + QCF V2 page fonts.
}

FontWeight _w(double v) => FontWeight.values[((v / 100).round() - 1).clamp(0, 8)];
TextStyle _s(
  String f,
  double size,
  double weight, {
  double? height,
  double? ls,
  List<FontFeature>? feat,
}) => TextStyle(
  fontFamily: f,
  fontSize: size,
  height: height,
  letterSpacing: ls,
  fontWeight: _w(weight),
  fontVariations: [FontVariation('wght', weight)],
  fontFeatures: feat,
);
const _tab = [FontFeature.tabularFigures()];

/// Every text style used in the screens. Sizes are logical pixels at 393 pt width.
abstract final class BmText {
  // Display (Marcellus)
  static final hero = _s(BmFont.display, 52, 400, height: 1.1); // Home "Asr"
  static final adhanTitle = _s(BmFont.display, 60, 400, height: 1.0); // Adhan "Maghrib"
  static final largeTitle = _s(BmFont.display, 34, 400, height: 1.1); // screen large titles
  static final onboardingTitle = _s(BmFont.display, 32, 400, height: 1.15);
  static final cardTitle = _s(BmFont.display, 32, 400, height: 1.0); // next-prayer card name
  static final qiblaTitle = _s(BmFont.display, 30, 400, height: 1.15);
  static final monthTitle = _s(BmFont.display, 24, 400, height: 1.2);
  static final prayerName = _s(BmFont.display, 21, 400, height: 1.2); // prayer rows
  static final prayerNameMinor = _s(BmFont.display, 17, 400, height: 1.2); // Sunrise row
  static final notifPrayerName = _s(BmFont.display, 18, 400, height: 1.2);
  static final counter = _s(BmFont.display, 80, 400, height: 1.0, feat: _tab); // Tasbih
  static final wordmark = _s(BmFont.display, 42, 400, height: 1.1, ls: .42);

  // Body (Schibsted Grotesk)
  static final countdown = _s(BmFont.body, 26, 500, feat: _tab);
  static final title = _s(BmFont.body, 17, 600); // compact app bar title
  static final bodyLarge = _s(BmFont.body, 16, 400, height: 1.55);
  static final body = _s(BmFont.body, 15, 400, height: 1.5);
  static final bodyStrong = _s(BmFont.body, 15, 500, height: 1.4);
  static final button = _s(BmFont.body, 15, 500);
  static final time = _s(BmFont.body, 16, 500, feat: _tab);
  static final timeSmall = _s(BmFont.body, 15, 500, feat: _tab);
  static final secondary = _s(BmFont.body, 14, 400, height: 1.55);
  static final caption = _s(BmFont.body, 13, 400, height: 1.45);
  static final label = _s(BmFont.body, 12, 400, height: 1.3);
  static final labelStrong = _s(BmFont.body, 12, 500, height: 1.3);
  static final overline = _s(BmFont.body, 11.5, 400, ls: 1.6); // "NOW", uppercase, .14em
  static final sectionLabel = _s(BmFont.body, 12, 400, ls: 1.44); // "PRAYER", uppercase, .12em
  static final tabLabel = _s(BmFont.body, 11, 400);
  static final tabLabelSelected = _s(BmFont.body, 11, 600);
  static final chip = _s(BmFont.body, 12, 500, feat: _tab);

  // Arabic
  static final heroAr = _s(BmFont.displayAr, 52, 400, height: 1.35);
  static final titleAr = _s(BmFont.displayAr, 32, 400, height: 1.3);
  static final prayerNameAr = _s(BmFont.displayAr, 21, 400, height: 1.3);
  static final accentAr = _s(BmFont.displayAr, 22, 400, height: 1.3); // "العصر" next to the hero
  static final adhanAr = _s(BmFont.displayAr, 40, 400, height: 1.3);
  static final bodyAr = _s(BmFont.bodyAr, 15, 400, height: 1.6);
  static final captionAr = _s(BmFont.bodyAr, 13, 400, height: 1.6);
  static final duaAr = _s(BmFont.dua, 24, 400, height: 1.9);
  static final dhikrAr = _s(BmFont.dua, 40, 400, height: 1.7);
  static final quranAr = _s(BmFont.quran, 26, 400, height: 2.2); // never animate, overlap or crop
}

/// Clamp dynamic type like the spec: max 2.0. Above 1.4 the countdown and prayer rows stack.
const bmMaxTextScale = 2.0;
const bmStackedLayoutTextScale = 1.4;
