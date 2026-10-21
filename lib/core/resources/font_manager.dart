import 'package:better_muslim/core/resources/design/bm_text.dart';
import 'package:flutter/material.dart';

abstract final class FontFamilyManager {
  static const String display = BmFont.display;
  static const String body = BmFont.body;
  static const String displayAr = BmFont.displayAr;
  static const String bodyAr = BmFont.bodyAr;
  static const String dua = BmFont.dua;
  static const String quran = BmFont.quran;
}

/// the text widgets pick the latin or arabic family by the app language
enum FontEnum {
  body(latin: FontFamilyManager.body, arabic: FontFamilyManager.bodyAr),

  /// the design uses it only at weight 400, so with RegularText
  display(latin: FontFamilyManager.display, arabic: FontFamilyManager.displayAr),

  /// amiri for duas and azkar, in both languages
  dua(latin: FontFamilyManager.dua, arabic: FontFamilyManager.dua),

  // TODO(ahmed): switch to KFGQPC Hafs once licensed, the mushaf text must render in the licensed font.
  quran(latin: FontFamilyManager.quran, arabic: FontFamilyManager.quran);

  const FontEnum({required this.latin, required this.arabic});
  final String latin;
  final String arabic;
}

abstract final class FontWeightManager {
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
}

/// the BmText roles as const values, font_manager_test fails if they drift from BmText
abstract final class FontSizeManager {
  static const double hero = 52;
  static const double adhanTitle = 60;
  static const double largeTitle = 34;
  static const double onboardingTitle = 32;
  static const double cardTitle = 32;
  static const double qiblaTitle = 30;
  static const double monthTitle = 24;
  static const double prayerName = 21;
  static const double prayerNameMinor = 17;
  static const double notifPrayerName = 18;
  static const double counter = 80;
  static const double wordmark = 42;
  static const double countdown = 26;
  static const double title = 17;
  static const double bodyLarge = 16;
  static const double body = 15;
  static const double bodyStrong = 15;
  static const double button = 15;
  static const double time = 16;
  static const double timeSmall = 15;
  static const double secondary = 14;
  static const double caption = 13;
  static const double label = 12;
  static const double labelStrong = 12;
  static const double overline = 11.5;
  static const double sectionLabel = 12;
  static const double tabLabel = 11;
  static const double tabLabelSelected = 11;
  static const double chip = 12;
  static const double heroAr = 52;
  static const double titleAr = 32;
  static const double prayerNameAr = 21;
  static const double accentAr = 22;
  static const double adhanAr = 40;
  static const double bodyAr = 15;
  static const double captionAr = 13;
  static const double duaAr = 24;
  static const double dhikrAr = 40;
  static const double quranAr = 26;

  /// home values with no BmText role
  static const double skyLabel = 11;
  static const double cardNote = 12.5;
  static const double nextPrayerAr = 16;

  /// components and prayer values with no BmText role
  static const double sheetTitle = 22;
  static const double rowSubtitle = 12.5;
  static const double rowValue = 13.5;
  static const double nowTag = 11;
  static const double dayComplete = 20;

  /// the adhan screen's dua line
  static const double adhanDua = 22;

  /// the qibla cards' distance and accuracy
  static const double qiblaValue = 20;

  /// tasbih (4.08), duas (4.14) and the components' azkar card
  static const double dhikrMeaning = 13.5;
  static const double dhikrChip = 12.5;
  static const double duaChip = 13.5;
  static const double zikrAr = 26;
  static const double zikrTranslation = 13.5;

  /// theme (4.15) and the snippet in its preview
  static const double swatchName = 11.5;
  static const double snippetPrayer = 28;
  static const double snippetCountdown = 22;
  static const double snippetPlace = 11.5;
  static const double snippetNow = 10.5;
  static const double snippetTab = 10.5;
  static const double snippetVerse = 24;

  /// hijri calendar (4.13)
  static const double weekday = 11.5;
  static const double calendarGregorian = 10.5;
  static const double dialogBody = 14.5;

  /// the components' text field error line (03 Inputs)
  static const double fieldError = 12.5;

  /// quran (09 Quran). pages 3 to 604 step down from quranPage until the widest line fits
  static const double quranPage = 22.5;
  static const double mushafHeader = 15;
  static const double ayahMarker = 13;
  static const double quranTag = 11;
  static const double cartouche = 19;
  static const double surahName = 15.5;
  static const double surahNameAr = 21;
  static const double quranStudy = 24;
  static const double tafsir = 19;
  static const double tafsirChip = 13.5;

  /// the mini player and recitation (4.25)
  static const double miniPlayerTitle = 14.5;
  static const double reciterInitials = 16;
  static const double repeatBadge = 10;

  /// 4.30's card in design points, scaled down by SizeManager.shareFit to fit the whole ayah
  static const double shareAyah = 25;
  static const double shareTranslation = 14;
  static const double shareFooter = 11;

  /// the translation layout (4.07). each display step moves the arabic by 2 and the translation by 1
  static const double surahHeader = 28;
  static const double verseMarker = 12;
  static const double verseTranslation = 14;
  static const double arabicStep = 2;
  static const double translationStep = 1;
}

abstract final class LineHeightManager {
  static const double hero = 1.1;
  static const double adhanTitle = 1.0;
  static const double largeTitle = 1.1;
  static const double onboardingTitle = 1.15;
  static const double cardTitle = 1.0;
  static const double qiblaTitle = 1.15;
  static const double monthTitle = 1.2;
  static const double prayerName = 1.2;
  static const double prayerNameMinor = 1.2;
  static const double notifPrayerName = 1.2;
  static const double counter = 1.0;
  static const double wordmark = 1.1;
  static const double bodyLarge = 1.55;
  static const double body = 1.5;
  static const double bodyStrong = 1.4;
  static const double secondary = 1.55;
  static const double caption = 1.45;
  static const double label = 1.3;
  static const double labelStrong = 1.3;
  static const double heroAr = 1.35;
  static const double titleAr = 1.3;
  static const double prayerNameAr = 1.3;
  static const double accentAr = 1.3;
  static const double adhanAr = 1.3;
  static const double bodyAr = 1.6;
  static const double captionAr = 1.6;
  static const double duaAr = 1.9;
  static const double dhikrAr = 1.7;
  static const double quranAr = 2.2;

  /// home values with no BmText role
  static const double cardTitleAr = 1.2;
  static const double nextPrayerAr = 1.0;
  static const double skyLabelAr = 1.2;
  static const double verseTranslation = 1.5;
  static const double adhanDua = 1.8;
  static const double qiblaHint = 1.5;
  static const double snippetVerse = 2.3;
  static const double comingUpDay = 1.2;
  static const double dialogTitle = 1.25;
  static const double dialogBody = 1.55;

  /// 4.11 and 4.12's body under the title
  static const double stepBody = 1.6;

  /// 58 pt mushaf lines at 22.5 pt
  static const double quranPage = 58 / 22.5;
  static const double quranStudy = 2;
  static const double tafsir = 1.95;

  static const double shareAyah = 1.9;
  static const double shareTranslation = 1.5;

  static const double surahHeader = 1.5;
  static const double verseCell = 1.55;
  static const double verseMarker = 1;
}

abstract final class LetterSpacingManager {
  static const double wordmark = .42;
  static const double overline = 1.6;
  static const double sectionLabel = 1.44;

  /// .12em of the 11 pt NOW tag on the prayer rows
  static const double nowTag = 1.32;

  /// .18em of the 12 pt adhan header
  static const double adhanHeader = 2.16;

  /// the snippet's NOW, .14em of 10.5 pt
  static const double snippetNow = 1.47;

  /// the snippet's countdown, .01em of 22 pt
  static const double snippetCountdown = .22;

  /// .12em of 4.18's 11 pt continue reading tag
  static const double quranTag = 1.32;

  /// .06em of 4.29's 11 pt AUTO tag
  static const double autoTag = .66;
}
