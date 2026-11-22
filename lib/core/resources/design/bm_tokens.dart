import 'package:material_ui/material_ui.dart';

abstract final class BmSpace {
  static const s1 = 4.0,
      s2 = 8.0,
      s3 = 12.0,
      s4 = 16.0,
      s5 = 20.0,
      s6 = 24.0,
      s8 = 32.0,
      s12 = 48.0;
  static const screen = 16.0; // side margin on every screen
  static const card = 16.0; // default card padding (14–18 in specific cards, see SCREENS.md)
}

abstract final class BmRadius {
  static const sm = 10.0, md = 14.0, row = 16.0, lg = 20.0, sheet = 24.0, xl = 28.0, pill = 999.0;
  static const phoneDevice = 54.0; // only for mockups, never used in the app
}

abstract final class BmSize {
  static const hit = 44.0; // minimum hit target
  static const button = 48.0; // components; full-width CTAs on screens are 52
  static const buttonLarge = 52.0;
  static const prayerRow = 62.0;
  static const prayerRowMinor = 44.0; // Sunrise
  static const listRow = 52.0;
  static const linkRow = 64.0;
  static const toggleW = 52.0, toggleH = 32.0;
  static const navPillW = 56.0, navPillH = 32.0;
  static const statusBar = 54.0; // iOS safe-area top on iPhone 15 (use MediaQuery in code)
  static const appBar = 56.0;
  static const homeSkyHeight = 380.0;
}

abstract final class BmOpacity {
  static const disabled = .38, pressed = .12, focus = .10, scrimLight = .48, scrimDark = .64;
}

abstract final class BmShadow {
  /// Light mode raised card.
  static const lightRaised = [
    BoxShadow(color: Color(0x5910382E), blurRadius: 28, offset: Offset(0, 10), spreadRadius: -14),
  ];

  /// Dark mode hero card glow (next-prayer card only).
  static const darkGlow = [BoxShadow(color: Color(0x47A88A52), blurRadius: 32, spreadRadius: -8)];
}

abstract final class BmGlass {
  static const blurSigma = 20.0;
  static const surfaceOpacity = .20; // on the sky: Color(0xFF07100D) at 55%
  static const highlightOpacity = .12; // 1px top inner highlight, white
}
