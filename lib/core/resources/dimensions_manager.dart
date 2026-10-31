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
  static const double arcLabelGap = 6;
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
  static const double segmentIconGap = 4;

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
  static const double stepperGap = 24;

  /// the components' dialog
  static const double dialogBodyTop = 10;
  static const double dialogActionsTop = 22;
  static const double dialogShadowY = 20;

  /// welcome (4.10) and the first screen, positions are in the 393 x 852 frame of the mockup
  static const double welcomeHorizon = 452;
  static const double welcomeMarkTop = 248;
  static const double welcomeTitleTop = 500;
  static const double welcomeTaglineGap = 12;
  static const double welcomeTextSide = 24;
  static const double welcomeButtonsSide = 20;
  static const double welcomeButtonsBottom = 46;
  static const double welcomeButtonGap = 8;

  /// around the sun's rest spot, so a thumb that lands a little off still grabs it
  static const double welcomeGrabMargin = 22;

  /// the first screen's "swipe up to begin" over the home indicator
  static const double swipeHintBottom = 22;
  static const double swipeHintMinInset = 12;

  /// the steps (4.11, 4.12), in the same frame
  static const double stepRise = 14;
  static const double stepDotsTop = 66;
  static const double stepDotGap = 6;
  static const double stepContentTop = 118;
  static const double stepContentSide = 24;
  static const double stepTitleGap = 12;
  static const double stepIconTitleGap = 8;

  /// from the body to the card, so the card lands at the tree's 372 (4.11) and 288 (4.12)
  static const double stepBodyCardGap = 36;
  static const double stepCardSide = 16;
  static const double stepCardGap = 12;
  static const double stepRowV = 14;
  static const double stepButtonsSide = 20;
  static const double stepButtonsBottom = 46;
  static const double locationButtonGap = 10;
  static const double notificationsButtonGap = 8;
  static const double locationFootnoteTop = 4;

  /// the components' text field (03 Inputs)
  static const double textFieldSide = 16;
  static const double textFieldGap = 7;

  /// the mushaf page (4.19), positions in the 393 x 852 frame of _gen/quran.js. the page is never
  /// mirrored, so these are left and right
  static const double mushafFrameLeft = 18;
  static const double mushafFrameRight = 24;
  static const double mushafFrameTop = 92;
  static const double mushafFrameBottom = 78;
  static const double mushafFrameInner = 5;
  static const double mushafHeaderLeft = 30;
  static const double mushafHeaderRight = 36;
  static const double mushafHeaderTop = 60;
  static const double mushafNumberBottom = 30;
  static const double mushafLine = 58;

  /// pages 3 to 604 split the frame's inner height into 15 bands, about this at 393 pt
  static const double mushafBand15 = 45;
  static const double openingArchLeft = 34;
  static const double openingArchTop = 120;
  static const double openingCartoucheLeft = 62;
  static const double openingCartoucheRight = 68;
  static const double openingCartoucheTop = 196;
  static const double openingTextLeft = 54;
  static const double openingTextRight = 60;
  static const double openingTextTop = 262;
  static const double secondCartoucheLeft = 46;
  static const double secondCartoucheRight = 52;
  static const double secondCartoucheTop = 124;
  static const double secondBasmalaTop = 178;
  static const double secondBasmalaLine = 52;
  static const double cartoucheStar = 14;
  static const double cartoucheStarTop = 15;
  static const double secondTextTop = 250;
  static const double ayahWashV = 5;
  static const double ayahWashH = 2;
  static const double ayahMarkerGap = 2;
  static const double cartoucheNameTop = 3;
  static const double mushafNumberTop = 2;

  static const double mushafTextInset = 10;
  static const double foreEdgeStripe = 2.5;

  /// the selected ayah stays this far above the sheet
  static const double ayahLift = 24;
  static const double ribbonLeft = 44;

  /// between the margin ribbons, the fore-edge and the frame
  static const double marginRibbonGap = 2;

  /// the page as a card under the controls (4.21), the next page peeks this far from it
  static const double pageCardLift = 24;
  static const double pagePeekGap = 14;
  static const double dockTop = 16;
  static const double dockSide = 22;
  static const double dockButtonsTop = 4;
  static const double dockButtonsSide = 8;
  static const double dockLabelGap = 4;

  /// quran home (4.18)
  static const double quranTitleTop = 62;
  static const double quranTitleStart = 20;
  static const double quranTitleEnd = 12;
  static const double continueCardTop = 14;
  static const double continueCardStart = 16;
  static const double continueCardEnd = 14;
  static const double continueGap = 16;
  static const double continueLineGap = 3;
  static const double quranToolsTop = 90;
  static const double quranToolGap = 8;
  static const double quranToolIconGap = 7;
  static const double quranIndexTop = 18;
  static const double surahRowGap = 14;
  static const double surahRowLineGap = 2;
  static const double quranHeaderGap = 2;
  static const double quranCardGap = 14;
  static const double sheetHeadStart = 20;
  static const double sheetHeadEnd = 16;
  static const double sheetHeadTop = 6;
  static const double sheetHeadGap = 12;

  /// the ayah sheets (4.22, 4.23)
  static const double ayahTranslationTop = 14;
  static const double ayahTranslationSide = 20;
  static const double ayahCreditGap = 6;

  /// the mini player and recitation (4.25)
  static const double miniPlayerSide = 12;
  static const double miniPlayerBottom = 30;
  static const double miniPlayerStart = 10;
  static const double miniPlayerEnd = 8;
  static const double miniPlayerLineGap = 1;
  static const double recitationProgressTop = 16;
  static const double recitationControlsTop = 14;
  static const double recitationControlsSide = 26;
  static const double repeatBadgeEnd = -10;
  static const double repeatBadgeTop = -6;
  static const double repeatBadgeH = 4;
  static const double repeatBadgeV = 1;
  static const double ayahActionsTop = 18;
  static const double ayahActionGap = 8;
  static const double ayahActionIconGap = 7;
  static const double studyButtonGap = 8;
  static const double studyCardTop = 14;
  static const double studyCardSide = 14;
  static const double studyCardPadTop = 10;
  static const double studyCardPadBottom = 8;
  static const double studyTabsTop = 16;
  static const double tafsirTextTop = 14;
  static const double tafsirTextSide = 22;
  static const double tafsirCreditTop = 10;
  static const double studyCardGap = 10;
  static const double studyCardV = 12;
  static const double studyCardLineGap = 4;

  /// the page goes up this far as it recedes behind the large sheet
  static const double pageRecedeLift = 16;

  /// 4.29, the saved rows and the note cards
  static const double savedGap = 10;
  static const double savedRowStart = 16;
  static const double savedRowEnd = 14;
  static const double savedRibbonGap = 14;
  static const double savedLineGap = 2;
  static const double recentNoteTop = 22;
  static const double categoryHeaderTop = 22;
  static const double noteCardV = 14;
  static const double noteCardSide = 16;
  static const double noteLineGap = 6;

  /// 4.30's preview card and the controls under it
  static const double shareCardPad = 24;
  static const double shareCardGap = 14;
  static const double shareFooterSide = 20;
  static const double shareFooterBottom = 16;
  static const double shareLogoGap = 6;
  static const double sharePreviewTop = 16;
  static const double shareSwatchTop = 18;
  static const double shareSwatchGap = 18;
  static const double shareSwatchLabelGap = 6;
  static const double shareButtonsTop = 14;
  static const double shareNoteTop = 10;
  static const double choosingBarV = 10;

  /// the ayah keeps clear of the footer by this much from the card's bottom
  static const double shareFooterReserve = 44;

  /// display (4.31)
  static const double displaySwatchesTop = 10;
  static const double displayRowsTop = 18;

  /// the translation layout (4.07)
  static const double surahHeaderBottom = 6;
  static const double surahHeaderTop = 16;
  static const double surahHeaderBottomPad = 14;
  static const double verseCellTop = 12;
  static const double verseCellSide = 18;
  static const double verseCellBottom = 14;
  static const double verseMarkerGap = 10;

  /// search (4.27)
  static const double searchBarTop = 6;
  static const double searchFieldStart = 12;
  static const double searchFieldEnd = 10;
  static const double searchSection = 18;
  static const double searchHitTop = 10;
  static const double searchHitGap = 10;
  static const double searchWashSide = 3;
  static const double searchHintSide = 20;
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
  static const double stepDot = 3;
  static const double stepIconTile = 20;
  static const double ayahWash = 9;
  static const double pageCard = 16;
  static const double mushafFrame = 2;
  static const double miniPlayer = 22;
  static const double recitationBar = 2;
  static const double repeatBadge = 6;
  static const double pageThumb = 5;
  static const double quranTool = 18;
  static const double dockButton = 17;
  static const double mushafPlaceholder = 6;

  /// 4.30's preview, the shared image itself has square corners
  static const double sharePreview = 22;
  static const double displaySwatch = 12;
  static const double verseCell = 18;
  static const double searchField = 12;
  static const double searchJumpIcon = 12;
  static const double searchWash = 6;
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
  static const double arcPointDot = 4;

  /// the night marker's three stars, each this far from the marker's point
  static const double arcStar = 7;
  static const double arcStarSpread = 5;
  static const double stripMarkSlot = 12;
  static const double stripDot = 5;
  static const double shortcutIconBox = 40;
  static const double searchField = 46;
  static const double grabberW = 32;
  static const double grabberH = 4;
  static const double toast = 52;
  static const double pickerRow = 60;
  static const double pickerCheck = 22;
  static const double circleIndicatorSize = 14;

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

  static const double beadMarker = 32;
  static const double beadHead = 34;
  static const double tassel = 20;
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

  /// the blur behind an open sheet or dialog
  static const double backdropBlur = 10;

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

  /// welcome (4.10)
  static const double welcomeSun = 44;
  static const double welcomeSunBlur = 40;
  static const double welcomeSunSpread = 14;
  static const double welcomeMark = 88;
  static const double welcomeArcRadius = 100.5;
  static const double welcomeTaglineWidth = 300;

  /// the steps (4.11, 4.12)
  static const double stepDot = 6;
  static const double stepDotWide = 22;
  static const double stepIconTile = 64;
  static const double stepIcon = 30;
  static const double stepRowIcon = 40;

  /// the components' text field (03 Inputs)
  static const double textField = 52;
  static const double textFieldFocus = 2;

  /// the mushaf page (4.19), in the 393 x 852 frame of _gen/quran.js
  static const double mushafDesignHeight = 852;
  static const double mushafCorner = 16;
  static const double mushafCornerStar = 14;
  static const double mushafFrameStroke = 1.1;
  static const double mushafFrameInnerStroke = .6;
  static const double mushafNumber = 36;
  static const double openingArchW = 319;
  static const double openingArchH = 612;
  static const double cartoucheW = 263;
  static const double cartoucheWideW = 295;
  static const double cartoucheH = 44;
  static const double spine = 34;
  static const double foreEdge = 5;
  static const double ayahMarker = 26;
  static const double ribbonW = 18;
  static const double ribbonH = 96;

  /// where the ribbon's notch is cut, a share of its height
  static const double ribbonNotch = .84;
  static const double ribbonShadowY = 2;
  static const double ribbonShadowBlur = 6;

  /// a bookmarked ayah's ribbon in the page margin, beside its last line
  static const double marginRibbonW = 6;
  static const double marginRibbonH = 18;

  /// K.STAR's stroke on the page number and the surah rows, the arch's two lines, the marker's
  static const double starStroke = .9;
  static const double archStroke = .9;
  static const double archInnerStroke = .5;

  /// 1.4 in the marker's 40 box, at 26 pt
  static const double ayahMarkerStroke = .91;
  static const double foreEdgeLine = 1;

  /// pages not shipped yet show these neutral bars, like page 2 of 09 Quran
  static const double mushafPlaceholder = 11;

  /// the controls (4.21) and the sheets, sheet heights from their tops in the 852 frame
  static const double readerTopBar = 112;
  static const double dock = 170;
  static const double dockButtonW = 52;
  static const double dockButtonH = 34;
  static const double scrubber = 28;
  static const double scrubberTrack = 3;
  static const double scrubberTick = 7;
  static const double scrubberThumb = 22;
  static const double scrubberThumbShadow = 4;
  static const double scrubberThumbShadowY = 1;
  static const double pageCardScale = .84;

  /// a tap on this share of the page's left side turns to the next page
  static const double turnEdge = .12;
  static const double pageCardShadowBlur = 60;
  static const double pageCardShadowY = 30;
  static const double pageCardShadowSpread = -24;
  static const double pageRecede = .92;

  /// the book turn's curl (research R13): fold radius, how much darker the back is, how high the
  /// corner lifts at mid turn, the shadow on the page underneath
  static const double curlRadius = 32;
  static const double curlBackShade = .06;
  static const double curlTilt = 72;
  static const double curlShadow = .35;
  static const double glassBlur = 24;
  static const double glassSaturation = 1.5;
  static const double sheetMax = 740;
  static const double ayahSheet = 400;
  static const double studySheet = 400;
  static const double studySheetFull = 720;
  static const double recitationSheet = 452;
  static const double miniPlayer = 64;
  static const double miniPlayerIcon = 20;
  static const double reciterAvatar = 44;
  static const double recitationBar = 4;
  static const double recitationPlay = 64;
  static const double recitationIcon = 26;
  static const double recitationRepeatIcon = 24;
  static const double recitationRow = 46;
  static const double miniPlayerShadowBlur = 40;
  static const double miniPlayerShadowY = 16;
  static const double miniPlayerShadowSpread = -12;
  static const double displaySheet = 584;
  static const double sheetIconButton = 36;
  static const double sheetIcon = 18;
  static const double ayahAction = 74;
  static const double ayahCreditIcon = 14;
  static const double studyMarker = 26;
  static const double tafsirChip = 34;
  static const double sheetShadowBlur = 60;
  static const double sheetShadowY = -24;
  static const double sheetShadowSpread = -20;

  /// the scrim over the receded page
  static const double pageDim = .28;

  /// black54, the scrim behind a container transform
  static const double containerScrim = .54;

  /// quran home (4.18)
  static const double pageThumbW = 60;
  static const double pageThumbH = 85;
  static const double thumbFrameStroke = .8;
  static const double thumbCartoucheStroke = .7;
  static const double thumbLine = 1.5;
  static const double thumbSpine = 6;
  static const double thumbShadowBlur = 16;
  static const double thumbShadowY = 6;
  static const double thumbShadowSpread = -6;
  static const double continueButton = 44;
  static const double quranTool = 76;
  static const double surahRow = 60;
  static const double surahStar = 36;
  static const double surahStarGlyph = 34;

  /// the shared ayah image, square and story
  static const double shareSquare = 1080;
  static const double shareStory = 1920;

  /// the oil drop loader (11 Motion v2), no falling drop below oilDropMin
  static const double oilDrop = 48;
  static const double oilDropMin = 32;
  static const double oilDropInline = 24;
  static const double oilDropSmall = 16;

  /// tablets and foldables get the phone layout stretched to this, until they have their own design
  static const double maxContentWidth = 480;

  /// 4.29's row and its small ribbon
  static const double savedRow = 68;
  static const double savedRibbonW = 16;
  static const double savedRibbonH = 30;
  static const double savedRibbonNotch = .8;

  /// the dot before a category's header in Saved
  static const double categoryDot = 8;

  /// 4.30's card in design points, captured at shareSquare pixels wide
  static const double shareAyahCard = 300;
  static const double shareStar = 16;
  static const double shareLogo = 14;
  static const double shareSwatch = 44;
  static const double shareSwatchRow = 90;
  static const double shareSwatchRing = 2;
  static const double shareSwatchGapRing = 3;
  static const double sharePreviewShadowY = 20;
  static const double sharePreviewShadowBlur = 40;
  static const double sharePreviewShadowSpread = -20;

  /// the card's text shrinks in these steps, then story, then tafsir goes (FR-017)
  static const List<double> shareFit = [1, .9, .8, .7];

  /// below the last step only a first ayah that fits nowhere keeps shrinking (FR-018)
  static const double shareFitStep = .05;
  static const double shareOrnamentOpacity = .10;
  static const double shareDivider = 10;

  /// display (4.31)
  static const double displaySwatch = 76;

  /// each page swatch's width in the scrolling row, so seven of them still peek past the edge
  static const double displaySlot = 84;
  static const double displayFontSwatch = 56;
  static const double displayLabel = 84;
  static const double displayRing = 4;
  static const double displayRingGap = 2;

  /// the translation layout (4.07), its marker drawn in a 40 box
  static const double surahOrnamentLine = 40;
  static const double surahOrnament = 14;
  static const double verseMarker = 32;
  static const double verseMarkerBox = 40;
  static const double verseMarkerRing = 12;
  static const double verseMarkerStroke = 1.2;
  static const double verseMarkerStar = .9;

  /// search (4.27)
  static const double searchClear = 20;
  static const double searchClearIcon = 12;
  static const double searchJumpIcon = 40;
  static const double searchRow = 46;
  static const double searchRowNumber = 24;
  static const double searchChevron = 18;
}
