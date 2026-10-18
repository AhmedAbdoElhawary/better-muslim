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
}

abstract final class LetterSpacingManager {
  static const double wordmark = .42;
  static const double overline = 1.6;
  static const double sectionLabel = 1.44;

  /// .12em of the 11 pt NOW tag on the prayer rows
  static const double nowTag = 1.32;

  /// .18em of the 12 pt adhan header
  static const double adhanHeader = 2.16;
}
