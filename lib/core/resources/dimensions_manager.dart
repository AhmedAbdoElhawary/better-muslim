import 'package:better_muslim/core/resources/design/bm_tokens.dart';

abstract final class SpaceManager {
  static const double s1 = BmSpace.s1;
  static const double s2 = BmSpace.s2;
  static const double s3 = BmSpace.s3;
  static const double s4 = BmSpace.s4;
  static const double s5 = BmSpace.s5;
  static const double s6 = BmSpace.s6;
  static const double s8 = BmSpace.s8;
  static const double s12 = BmSpace.s12;
  static const double screen = BmSpace.screen;
  static const double card = BmSpace.card;
  static const double navBarSide = 6;
  static const double navLabelGap = 3;

  /// home (4.01, 4.16), sky positions are in the 393 x 380 frame of the mockup
  static const double skyTextTop = 62;
  static const double skyTextSide = 14;
  static const double locationPillStart = 6;
  static const double locationPillEnd = 10;
  static const double nowTop = 22;
  static const double nowTopAr = 18;
  static const double nowUntilGap = 2;
  static const double skyLabelTop = 306;
  static const double skyLabelStart = 94;
  static const double skyLabelEndAr = 100;
  static const double skyLabelEdge = 14;
  static const double homeCardOverlap = 60;
  static const double homeGlowInset = 18;
  static const double homeCardGap = 14;
  static const double homeCardSide = 18;
  static const double nextCardTopAr = 14;
  static const double nextCardGap = 9;
  static const double adhanLineGap = 6;
  static const double stripSide = 14;
  static const double stripCellGap = 4;
  static const double stripCellTop = 10;
  static const double stripCellTopAr = 9;
  static const double stripCellBottomAr = 7;
  static const double stripCellInnerGapAr = 3;
  static const double verseCardTop = 14;
  static const double verseCardBottomAr = 10;
  static const double verseGap = 6;
  static const double shortcutGap = 14;
  static const double shortcutTextGap = 2;
  static const double shortcutTextGapAr = 1;
  static const double fieldSide = 14;
  static const double fieldIconGap = 10;
  static const double rowLineGap = 2;

  /// prayer (4.04, 4.17)
  static const double prayerTitleTop = 2;
  static const double prayerSubtitleTop = 6;
  static const double prayerSubtitleTopAr = 2;
  static const double weekTop = 18;
  static const double weekSide = 14;
  static const double weekCellGap = 5;
  static const double dayDotGap = 2;
  static const double summaryTop = 14;
  static const double summaryPaddingV = 14;
  static const double prayerRowGap = 14;
  static const double nowTagGap = 10;
  static const double chipSide = 10;
  static const double markStart = 9;
  static const double prayerGlowSide = 60;
  static const double prayerGlowTop = 170;
  static const double dayCompleteDots = 24;
  static const double dayCompleteRise = 6;

  /// adhan (4.03), positions are in the 393 x 852 frame of the mockup
  static const double adhanHaloTop = 400;
  static const double adhanSunTop = 500;
  static const double adhanHorizonTop = 540;
  static const double adhanHeaderTop = 120;
  static const double adhanHeaderGap = 10;
  static const double adhanNameTop = 8;
  static const double adhanProgressTop = 22;
  static const double adhanProgressGap = 10;
  static const double adhanCardTop = 572;
  static const double adhanCardV = 16;
  static const double adhanCardH = 18;
  static const double adhanCardGap = 6;
  static const double adhanReadDuaGap = 2;
  static const double adhanButtonsBottom = 44;
  static const double adhanButtonGap = 10;
  static const double adhanButtonIconGap = 8;
}

abstract final class RadiusManager {
  static const double sm = BmRadius.sm;
  static const double md = BmRadius.md;
  static const double row = BmRadius.row;
  static const double lg = BmRadius.lg;
  static const double sheet = BmRadius.sheet;
  static const double xl = BmRadius.xl;
  static const double pill = BmRadius.pill;
  static const double homeGlow = 36;
  static const double prayerBar = 2;
  static const double shortcutIcon = 12;
  static const double adhanBar = 2;
}

abstract final class SizeManager {
  static const double hit = BmSize.hit;
  static const double button = BmSize.button;
  static const double buttonLarge = BmSize.buttonLarge;
  static const double prayerRow = BmSize.prayerRow;
  static const double prayerRowMinor = BmSize.prayerRowMinor;
  static const double listRow = BmSize.listRow;
  static const double linkRow = BmSize.linkRow;
  static const double toggleW = BmSize.toggleW;
  static const double toggleH = BmSize.toggleH;
  static const double navPillW = BmSize.navPillW;
  static const double navPillH = BmSize.navPillH;
  static const double appBar = BmSize.appBar;
  static const double homeSkyHeight = BmSize.homeSkyHeight;
  static const double icon = 22;
  static const double iconList = 20;
  static const double iconChevron = 18;
  static const double iconInline = 16;
  static const double iconChip = 14;
  static const double iconChipSmall = 12;
  static const double locationPill = 32;
  static const double locationPillIcon = 18;
  static const double prayerBar = 3;
  static const double homeGlowBlur = 6;
  static const double skyScrimFade = 48;
  static const double stripMarkSlot = 12;
  static const double stripDot = 5;
  static const double shortcutIconBox = 40;
  static const double searchField = 46;
  static const double grabberW = 32;
  static const double grabberH = 4;
  static const double toast = 52;
  static const double pickerRow = 60;
  static const double pickerCheck = 22;

  /// prayer (4.04, 4.17)
  static const double rowTrailing = 96;
  static const double weekCell = 68;
  static const double dayDot = 4;
  static const double ring = 56;
  static const double ringStroke = 4;
  static const double markChip = 32;
  static const double stateChip = 26;
  static const double prayerGlow = 340;
  static const double dayCompleteDot = 10;
  static const double dayCompleteStar = 56;
  static const double dayCompleteRing = 72;

  /// adhan (4.03)
  static const double adhanSun = 84;
  static const double adhanSunBlur = 50;
  static const double adhanSunSpread = 18;
  static const double adhanHaloW = 420;
  static const double adhanHaloH = 280;
  static const double adhanStar = 34;
  static const double adhanProgress = 200;
  static const double adhanBar = 3;

  /// the + sheet's count holds 999 without the buttons moving
  static const double countValue = 72;

  /// tablets and foldables get the phone layout stretched to this, until they have their own design
  static const double maxContentWidth = 480;
}
