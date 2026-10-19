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
  static const double adhanTextRise = 10;

  /// dua card (4.14), the adhan's dua sheet uses it too
  static const double duaCardH = 18;
  static const double duaGap = 10;

  /// qibla (4.05, 4.06), each gap from the tree's top to the bottom of the element above
  static const double qiblaTitleTop = 26;
  static const double qiblaTitleGap = 6;
  static const double qiblaDialTop = 76;
  static const double qiblaCardsTop = 50;
  static const double qiblaHintTop = 33;
  static const double qiblaHintSide = 24;
  static const double qiblaCardsSide = 16;
  static const double qiblaCardGap = 10;
  static const double qiblaCardV = 14;
  static const double qiblaCardH = 16;
  static const double qiblaCardLineGap = 2;
  static const double accuracyDotGap = 8;

  /// tasbih (4.08), each gap from the tree's top to the bottom of the element above. the chips'
  /// 44 pt hit box is 4 taller than the chip on each side
  static const double tasbihChipsTop = 8;
  static const double chipGap = 6;
  static const double tasbihDhikrTop = 24;
  static const double dhikrLineGap = 2;
  static const double tasbihAreaTop = 44;

  /// to and from the 36 pt focus ring, the strip's box
  static const double tasbihStripGap = 40;
  static const double tasbihHintGap = 24;
  static const double beadGap = 16;
  static const double counterGap = 6;
  static const double barTitleGap = 1;
  static const double navBadgeTop = 4;
  static const double navBadgeEnd = 14;

  /// the components' azkar card
  static const double zikrCardV = 18;
  static const double zikrFooterTop = 10;

  /// duas (4.14)
  static const double duaChipSide = 14;
  static const double duaRowsTop = 44;
  static const double duaCardBottom = 6;
  static const double duaActionsTop = 2;
  static const double duaActionGap = 6;
  static const double categoryRowEnd = 14;

  /// the share card has no design, inside the arch's shoulders
  static const double shareCardTop = 96;
  static const double shareCardSide = 32;

  /// more (4.09) and the components' grouped list rows
  static const double moreTitleTop = 2;
  static const double moreSubtitleTop = 6;
  static const double moreTilesTop = 20;
  static const double moreSectionsTop = 22;
  static const double tileGap = 10;
  static const double tilePadding = 14;
  static const double sectionGap = 20;
  static const double sectionLabelGap = 8;
  static const double listRowStart = 16;
  static const double listRowEnd = 14;
  static const double listRowGap = 14;

  /// the components' segmented control, 4.15's and 4.12's smaller one
  static const double segmentTrack = 3;
  static const double segmentGap = 2;
  static const double segmentSmallSide = 10;

  /// theme (4.15), each gap from the tree's top to the bottom of the element above
  static const double previewTop = 8;
  static const double previewSnippetTop = 18;
  static const double previewChipStart = 12;
  static const double previewChipBottom = 10;
  static const double previewChipH = 10;
  static const double previewChipV = 4;
  static const double modeTop = 14;
  static const double swatchesTop = 16;
  static const double swatchRowGap = 12;
  static const double swatchColumnGap = 10;
  static const double swatchInset = 7;
  static const double swatchNameGap = 6;
  static const double swatchCheck = 5;
  static const double themeNoteTop = 26;

  /// the snippet inside the preview (Theme Snippet.dc.html)
  static const double snippetTopH = 20;
  static const double snippetTopV = 16;
  static const double snippetNowTop = 12;
  static const double snippetCardOverlap = 58;
  static const double snippetCardSide = 14;
  static const double snippetCardH = 16;
  static const double snippetCardTop = 14;
  static const double snippetCardBottom = 15;
  static const double snippetCardGap = 7;
  static const double snippetStripTop = 14;
  static const double snippetCellV = 9;
  static const double snippetCellGap = 3;
  static const double snippetVerseTop = 12;
  static const double snippetVerseBottom = 15;
  static const double snippetVerseLineTop = 6;
  static const double snippetTranslationTop = 8;

  /// hijri calendar (4.13), each gap from the tree's top to the bottom of the element above
  static const double monthHeaderTop = 8;
  static const double monthNameGap = 2;
  static const double gridTop = 22;
  static const double gridSide = 12;
  static const double gridGap = 2;
  static const double comingUpTop = 12;
  static const double comingUpLabelSide = 4;
  static const double comingUpRowV = 12;
  static const double adjustmentTop = 20;
  static const double stepperGap = 24;

  /// the components' dialog
  static const double dialogBodyTop = 10;
  static const double dialogActionsTop = 22;
  static const double dialogShadowY = 20;
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
  static const double qiblaMarker = 3;
  static const double qiblaNeedle = 1;
  static const double zikrBar = 2;
  static const double tileIcon = 12;
  static const double segmentTrack = 12;
  static const double segment = 9;
  static const double segmentSmallTrack = 11;
  static const double segmentSmall = 8;
  static const double swatchPill = 4;
  static const double snippet = 30;
  static const double snippetVerse = 18;
  static const double dayCell = 14;
  static const double dialog = 28;
  static const double dialogAction = 12;
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
  static const double adhanHorizon = 1;
  static const double adhanSunBlur = 50;
  static const double adhanSunSpread = 18;
  static const double adhanHaloW = 420;
  static const double adhanHaloH = 280;
  static const double adhanStar = 34;
  static const double adhanProgress = 200;
  static const double adhanBar = 3;

  /// qibla (4.05, 4.06), radii and lengths on the 300 pt dial
  static const double qiblaDial = 300;
  static const double qiblaTickOuter = 146;
  static const double qiblaTickMajor = 18;
  static const double qiblaTickMinor = 8;
  static const double qiblaTickMajorStroke = 1.5;
  static const double qiblaTickMinorStroke = 1;
  static const double qiblaLetterRadius = 108;
  static const double qiblaMarker = 16;
  static const double qiblaMarkerLine = 3;
  static const double qiblaMarkerStroke = 1.5;
  static const double qiblaNeedle = 106;
  static const double qiblaNeedleWidth = 2;
  static const double qiblaNeedleHead = 12;
  static const double qiblaHub = 10;
  static const double qiblaTopTick = 16;
  static const double qiblaTopTickWidth = 2;
  static const double qiblaTopTickGap = 6;
  static const double qiblaRing = 1;
  static const double qiblaRingAligned = 1.5;
  static const double qiblaGlow = 420;
  static const double accuracyDot = 8;

  /// tasbih (4.08), the ring is r 114 with a 5 stroke in its 240 box
  static const double tasbihRing = 240;
  static const double tasbihRingArc = 233;
  static const double tasbihRingStroke = 5;
  static const double tasbihGlow = 340;

  /// the count keeps inside the ring up to this text scale
  static const double counterMaxTextScale = 1.3;
  static const double burstParticle = 6;
  static const double burstReach = 92;
  static const double bead = 28;
  static const double beadFocus = 36;
  static const double beadFocusStroke = 1.5;
  static const double beadLine = 1;
  static const double chip = 36;
  static const double navBadge = 7;
  static const double navBadgeRing = 2;
  static const double toggleKnobOff = 20;
  static const double toggleKnobOn = 24;
  static const double toggleRingOff = 1.5;

  /// the components' azkar card
  static const double zikrBarW = 90;
  static const double zikrBarH = 3;

  /// duas (4.14) and the components' empty state
  static const double duaAction = 48;
  static const double categoryRow = 56;
  static const double emptyIcon = 56;
  static const double emptyIconStroke = 1.4;

  /// the shared dua image, at 3x
  static const double shareCard = 360;

  /// the + sheet's count holds 999 without the buttons moving
  static const double countValue = 72;

  /// more (4.09) and the components' grouped list rows
  static const double divider = 1;
  static const double tile = 92;
  static const double tileIconBox = 36;

  /// the components' segmented control, 4.15's and 4.12's smaller one
  static const double segment = 38;
  static const double segmentSmall = 30;

  /// theme (4.15)
  static const double preview = 300;
  static const double previewFade = 70;
  static const double swatch = 60;
  static const double swatchCheck = 18;
  static const double swatchPillW = 18;
  static const double swatchPillH = 7;
  static const double swatchRing = 2.5;

  /// the snippet inside the preview (Theme Snippet.dc.html), on its own 300 pt width
  static const double snippet = 300;
  static const double snippetSky = 176;
  static const double snippetHorizon = 150;
  static const double snippetSun = 14;
  static const double snippetSunBlur = 18;
  static const double snippetSunSpread = 6;
  static const double snippetGlowInset = 16;

  /// hijri calendar (4.13)
  static const double weekdayRow = 22;
  static const double dayCell = 54;
  static const double dayMark = 4;
  static const double dayMarkTop = 44;
  static const double fastMark = 10;
  static const double todayRing = 1.5;
  static const double comingUpDay = 46;

  /// the components' dialog and the adhan sound sheet
  static const double dialog = 320;
  static const double dialogShadowBlur = 60;
  static const double radio = 22;
  static const double radioDot = 11;
  static const double radioRing = 2;
  static const double radioRingOff = 1.5;
  static const double playButton = 44;
  static const double sliderTrack = 4;
  static const double sliderThumb = 22;

  /// tablets and foldables get the phone layout stretched to this, until they have their own design
  static const double maxContentWidth = 480;
}
