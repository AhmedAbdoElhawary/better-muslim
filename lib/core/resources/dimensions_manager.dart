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
}

abstract final class RadiusManager {
  static const double sm = BmRadius.sm;
  static const double md = BmRadius.md;
  static const double row = BmRadius.row;
  static const double lg = BmRadius.lg;
  static const double sheet = BmRadius.sheet;
  static const double xl = BmRadius.xl;
  static const double pill = BmRadius.pill;
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

  /// tablets and foldables get the phone layout stretched to this, until they have their own design
  static const double maxContentWidth = 480;
}
