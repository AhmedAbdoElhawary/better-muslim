// GENERATED from the design files. Do not edit values by hand; they are the approved design.
// Main theme: #9 Qiyam Emerald (exact values). Other themes: parked alternates, derived roles.
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

@immutable
class BmPalette {
  final Color bg;
  final Color surface;
  final Color raised;
  final Color variant;
  final Color outline;
  final Color outlineStrong;
  final Color text;
  final Color text2;
  final Color text3;
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color accent;
  final Color accentContainer;
  final Color onAccentContainer;
  final Color success;
  final Color warning;
  final Color error;
  final Color onError;
  final Color glow;
  final Color sky1;
  final Color sky2;
  final Color sky3;
  final Color onSky;
  final Color sun;
  final double starOpacity;

  /// only the reader's palettes have it, the app themes take paper or night by brightness
  final BmPageColors? page;

  /// outside the reader a page color follows the app's mode (research R5)
  BmPageColors get pageColors =>
      page ?? (bg.computeLuminance() < .5 ? BmPagePalette.night.page! : BmPagePalette.paper.page!);
  const BmPalette({
    required this.bg,
    required this.surface,
    required this.raised,
    required this.variant,
    required this.outline,
    required this.outlineStrong,
    required this.text,
    required this.text2,
    required this.text3,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.accent,
    required this.accentContainer,
    required this.onAccentContainer,
    required this.success,
    required this.warning,
    required this.error,
    required this.onError,
    required this.glow,
    required this.sky1,
    required this.sky2,
    required this.sky3,
    required this.onSky,
    required this.sun,
    required this.starOpacity,
    this.page,
  });

  /// Used for the parked alternate themes, which were designed with 14 key colors.
  /// Container / outline roles are derived the same way the design board derives them.
  factory BmPalette.derive({
    required Brightness brightness,
    required Color bg,
    required Color surface,
    required Color primary,
    required Color onPrimary,
    required Color accent,
    required Color text,
    required Color text2,
    required Color sky1,
    required Color sky2,
    required Color sky3,
    required Color onSky,
    required Color glow,
    required Color sun,
    required double starOpacity,
  }) {
    final dark = brightness == Brightness.dark;
    Color mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;
    return BmPalette(
      bg: bg,
      surface: surface,
      raised: mix(surface, text, dark ? .04 : .02),
      variant: mix(surface, text, dark ? .08 : .06),
      outline: mix(surface, text, dark ? .04 : .1),
      outlineStrong: mix(surface, text, dark ? .32 : .42),
      text: text,
      text2: text2,
      text3: mix(text2, surface, .1),
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: mix(surface, primary, dark ? .16 : .14),
      onPrimaryContainer: dark ? mix(primary, text, .35) : primary,
      accent: accent,
      accentContainer: mix(surface, accent, dark ? .16 : .14),
      onAccentContainer: dark ? mix(accent, text, .4) : mix(accent, text, .25),
      success: dark ? const Color(0xFF5FB389) : const Color(0xFF2E6B4A),
      warning: dark ? const Color(0xFFD2A04F) : const Color(0xFF8A5A12),
      error: dark ? const Color(0xFFE07A6A) : const Color(0xFFA33A2E),
      onError: dark ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
      glow: glow,
      sky1: sky1,
      sky2: sky2,
      sky3: sky3,
      onSky: onSky,
      sun: sun,
      starOpacity: starOpacity,
    );
  }

  /// the 300 ms crossfade when the theme or the mode changes
  static BmPalette lerp(BmPalette a, BmPalette b, double t) => BmPalette(
    bg: Color.lerp(a.bg, b.bg, t)!,
    surface: Color.lerp(a.surface, b.surface, t)!,
    raised: Color.lerp(a.raised, b.raised, t)!,
    variant: Color.lerp(a.variant, b.variant, t)!,
    outline: Color.lerp(a.outline, b.outline, t)!,
    outlineStrong: Color.lerp(a.outlineStrong, b.outlineStrong, t)!,
    text: Color.lerp(a.text, b.text, t)!,
    text2: Color.lerp(a.text2, b.text2, t)!,
    text3: Color.lerp(a.text3, b.text3, t)!,
    primary: Color.lerp(a.primary, b.primary, t)!,
    onPrimary: Color.lerp(a.onPrimary, b.onPrimary, t)!,
    primaryContainer: Color.lerp(a.primaryContainer, b.primaryContainer, t)!,
    onPrimaryContainer: Color.lerp(a.onPrimaryContainer, b.onPrimaryContainer, t)!,
    accent: Color.lerp(a.accent, b.accent, t)!,
    accentContainer: Color.lerp(a.accentContainer, b.accentContainer, t)!,
    onAccentContainer: Color.lerp(a.onAccentContainer, b.onAccentContainer, t)!,
    success: Color.lerp(a.success, b.success, t)!,
    warning: Color.lerp(a.warning, b.warning, t)!,
    error: Color.lerp(a.error, b.error, t)!,
    onError: Color.lerp(a.onError, b.onError, t)!,
    glow: Color.lerp(a.glow, b.glow, t)!,
    sky1: Color.lerp(a.sky1, b.sky1, t)!,
    sky2: Color.lerp(a.sky2, b.sky2, t)!,
    sky3: Color.lerp(a.sky3, b.sky3, t)!,
    onSky: Color.lerp(a.onSky, b.onSky, t)!,
    sun: Color.lerp(a.sun, b.sun, t)!,
    starOpacity: lerpDouble(a.starOpacity, b.starOpacity, t)!,
    page: BmPageColors.lerp(a.pageColors, b.pageColors, t),
  );
}

/// the mushaf's own roles from K.PAGE in _gen/kit.js
@immutable
class BmPageColors {
  final Color page;
  final Color ink;
  final Color ink2;
  final Color ornament;
  final Color ornamentSoft;
  final Color selectionWash;
  final Color followWash;
  final Color hidden;
  final Color gutter;
  const BmPageColors({
    required this.page,
    required this.ink,
    required this.ink2,
    required this.ornament,
    required this.ornamentSoft,
    required this.selectionWash,
    required this.followWash,
    required this.hidden,
    required this.gutter,
  });

  static BmPageColors lerp(BmPageColors a, BmPageColors b, double t) => BmPageColors(
    page: Color.lerp(a.page, b.page, t)!,
    ink: Color.lerp(a.ink, b.ink, t)!,
    ink2: Color.lerp(a.ink2, b.ink2, t)!,
    ornament: Color.lerp(a.ornament, b.ornament, t)!,
    ornamentSoft: Color.lerp(a.ornamentSoft, b.ornamentSoft, t)!,
    selectionWash: Color.lerp(a.selectionWash, b.selectionWash, t)!,
    followWash: Color.lerp(a.followWash, b.followWash, t)!,
    hidden: Color.lerp(a.hidden, b.hidden, t)!,
    gutter: Color.lerp(a.gutter, b.gutter, t)!,
  );
}

/// the oil drop loader's gradient, the same in every theme (11 Motion v2)
const bmOilLight = Color(0xFFD9BE86);
const bmOilDark = Color(0xFF8C7444);
const bmOilRipple = Color(0xFFF1E3C4);

/// 4.30's emerald and sky backgrounds for a shared ayah, the same in every theme
const bmShareEmerald = Color(0xFF10382E);
const bmShareSky1 = Color(0xFF14121C);
const bmShareSky2 = Color(0xFF6A4436);
const bmShareSky3 = Color(0xFFC98E5E);

/// the reader's palettes, K.PAGE in _gen/kit.js. roles K.PAGE leaves out come from Qiyam Emerald
abstract final class BmPagePalette {
  static const paper = BmPalette(
    bg: Color(0xFFE9E2D1),
    surface: Color(0xFFFBF7EE),
    raised: Color(0xFFF4EEE0),
    variant: Color(0xFFEAE2CF),
    outline: Color(0xFFDDD3BC),
    outlineStrong: Color(0xFF9A917D),
    text: Color(0xFF1C1A15),
    text2: Color(0xFF5C5648),
    text3: Color(0xFF6A6456),
    primary: Color(0xFF10382E),
    onPrimary: Color(0xFFE9D7AE),
    primaryContainer: Color(0xFFE8DCBC),
    onPrimaryContainer: Color(0xFF43361A),
    accent: Color(0xFF7F6738),
    accentContainer: Color(0xFFEFE4CB),
    onAccentContainer: Color(0xFF5C4A26),
    success: Color(0xFF2E6B4A),
    warning: Color(0xFF8A5A12),
    error: Color(0xFFA33A2E),
    onError: Color(0xFFFFFFFF),
    glow: Color(0xFFA88A52),
    sky1: Color(0xFF0E1A16),
    sky2: Color(0xFF1F3A30),
    sky3: Color(0xFF8F7A52),
    onSky: Color(0xFFE9D7AE),
    sun: Color(0xFFE9D7AE),
    starOpacity: 0.6,
    page: BmPageColors(
      page: Color(0xFFF6F0E1),
      ink: Color(0xFF1B1912),
      ink2: Color(0xFF6B6352),
      ornament: Color(0xFFA88A52),
      ornamentSoft: Color(0xFFCDBB92),
      selectionWash: Color(0x42A88A52),
      followWash: Color(0x1A10382E),
      hidden: Color(0xFFE9DFC8),
      gutter: Color(0x29503C14),
    ),
  );

  /// cream, sepia, green and navy have no design, they're mine to check on the phone (R12)
  static final cream = _on(
    paper,
    page: const Color(0xFFF4E9CF),
    ink: const Color(0xFF1E1A10),
    ink2: const Color(0xFF665A3E),
    hidden: const Color(0xFFE7D9B8),
    gutter: const Color(0x2E5A4416),
  );

  static final sepia = _on(
    paper,
    page: const Color(0xFFE9D8BA),
    ink: const Color(0xFF2A1D0E),
    ink2: const Color(0xFF5E4A30),
    hidden: const Color(0xFFDCC7A3),
    gutter: const Color(0x33583A18),
  );

  static final green = _on(
    paper,
    page: const Color(0xFFE5EDDD),
    ink: const Color(0xFF13201A),
    ink2: const Color(0xFF46594C),
    hidden: const Color(0xFFD3DFCB),
    gutter: const Color(0x29284A30),
  );

  static final navy = _on(
    night,
    page: const Color(0xFF0B1322),
    ink: const Color(0xFFD6DCE8),
    ink2: const Color(0xFF8A93A6),
    hidden: const Color(0xFF17223A),
    gutter: const Color(0x99000000),
  );

  /// paper or night on another page: its chrome moves by the page's own step so the reader's
  /// bars keep their relation to the page, the ornaments mix like tint below
  static BmPalette _on(
    BmPalette from, {
    required Color page,
    required Color ink,
    required Color ink2,
    required Color hidden,
    required Color gutter,
  }) {
    final was = from.page!;
    Color shift(Color color) => Color.from(
      alpha: color.a,
      red: (color.r + page.r - was.page.r).clamp(0, 1),
      green: (color.g + page.g - was.page.g).clamp(0, 1),
      blue: (color.b + page.b - was.page.b).clamp(0, 1),
    );
    final dark = from.bg.computeLuminance() < .5;
    return BmPalette(
      bg: shift(from.bg),
      surface: shift(from.surface),
      raised: shift(from.raised),
      variant: shift(from.variant),
      outline: shift(from.outline),
      outlineStrong: shift(from.outlineStrong),
      text: shift(from.text),
      text2: shift(from.text2),
      text3: shift(from.text3),
      primary: from.primary,
      onPrimary: from.onPrimary,
      primaryContainer: from.primaryContainer,
      onPrimaryContainer: from.onPrimaryContainer,
      accent: from.accent,
      accentContainer: from.accentContainer,
      onAccentContainer: from.onAccentContainer,
      success: from.success,
      warning: from.warning,
      error: from.error,
      onError: from.onError,
      glow: from.glow,
      sky1: from.sky1,
      sky2: from.sky2,
      sky3: from.sky3,
      onSky: from.onSky,
      sun: from.sun,
      starOpacity: from.starOpacity,
      page: BmPageColors(
        page: page,
        ink: ink,
        ink2: ink2,
        ornament: _legible(dark ? Color.lerp(from.glow, page, .18)! : from.glow, page, ink),
        ornamentSoft: Color.lerp(from.glow, page, dark ? .68 : .47)!,
        selectionWash: was.selectionWash,
        followWash: was.followWash,
        hidden: hidden,
        gutter: gutter,
      ),
    );
  }

  /// base in another app theme: the paper and ink stay, the tints come from theme. qiyam emerald
  /// is the theme K.PAGE was drawn in, so it gets base back exactly
  static BmPalette tint(BmPalette base, BmPalette theme) {
    if (theme.primary == base.primary && theme.accent == base.accent && theme.glow == base.glow) {
      return base;
    }
    final page = base.page!;
    final dark = base.bg.computeLuminance() < .5;
    final ornament = dark ? Color.lerp(theme.glow, page.page, .18)! : theme.glow;
    return BmPalette(
      bg: base.bg,
      surface: base.surface,
      raised: base.raised,
      variant: base.variant,
      outline: base.outline,
      outlineStrong: base.outlineStrong,
      text: base.text,
      text2: base.text2,
      text3: base.text3,
      primary: theme.primary,
      onPrimary: theme.onPrimary,
      primaryContainer: theme.primaryContainer,
      onPrimaryContainer: theme.onPrimaryContainer,
      accent: theme.accent,
      accentContainer: theme.accentContainer,
      onAccentContainer: theme.onAccentContainer,
      success: base.success,
      warning: base.warning,
      error: base.error,
      onError: base.onError,
      glow: theme.glow,
      sky1: base.sky1,
      sky2: base.sky2,
      sky3: base.sky3,
      onSky: base.onSky,
      sun: base.sun,
      starOpacity: base.starOpacity,
      page: BmPageColors(
        page: page.page,
        ink: page.ink,
        ink2: page.ink2,

        /// the mixes K.PAGE's ornaments are of qiyam emerald's glow and the page
        ornament: identical(base, paper) || identical(base, night)
            ? ornament
            : _legible(ornament, page.page, page.ink),
        ornamentSoft: Color.lerp(theme.glow, page.page, dark ? .68 : .47)!,
        selectionWash: theme.glow.withValues(alpha: page.selectionWash.a),
        followWash: (dark ? theme.accent : theme.primary).withValues(alpha: page.followWash.a),
        hidden: page.hidden,
        gutter: page.gutter,
      ),
    );
  }

  /// my palettes have no design to keep, so their ornament goes toward the ink until 3:1
  static Color _legible(Color ornament, Color page, Color ink) {
    final paper = page.computeLuminance();
    double ratio(Color color) {
      final luminance = color.computeLuminance();
      return (math.max(luminance, paper) + .05) / (math.min(luminance, paper) + .05);
    }

    var color = ornament;
    for (var t = .05; ratio(color) < 3 && t <= 1; t += .05) {
      color = Color.lerp(ornament, ink, t)!;
    }
    return color;
  }

  static const night = BmPalette(
    bg: Color(0xFF000000),
    surface: Color(0xFF07100D),
    raised: Color(0xFF0C1814),
    variant: Color(0xFF13221D),
    outline: Color(0xFF1C2C26),
    outlineStrong: Color(0xFF4C5E57),
    text: Color(0xFFD9D3C2),
    text2: Color(0xFF878C82),
    text3: Color(0xFF7B8079),
    primary: Color(0xFFA88A52),
    onPrimary: Color(0xFF000000),
    primaryContainer: Color(0xFF221C10),
    onPrimaryContainer: Color(0xFFD9C08A),
    accent: Color(0xFF4E9C80),
    accentContainer: Color(0xFF0E2620),
    onAccentContainer: Color(0xFF8FCDB4),
    success: Color(0xFF5FB389),
    warning: Color(0xFFD2A04F),
    error: Color(0xFFE07A6A),
    onError: Color(0xFF000000),
    glow: Color(0xFFA88A52),
    sky1: Color(0xFF000000),
    sky2: Color(0xFF04100C),
    sky3: Color(0xFF173328),
    onSky: Color(0xFFD9D3C2),
    sun: Color(0xFFCDB27A),
    starOpacity: 0.8,
    page: BmPageColors(
      page: Color(0xFF070B09),
      ink: Color(0xFFD9D3C2),
      ink2: Color(0xFF878C82),
      ornament: Color(0xFF8C7444),
      ornamentSoft: Color(0xFF3A3222),
      selectionWash: Color(0x38A88A52),
      followWash: Color(0x294E9C80),
      hidden: Color(0xFF17211C),
      gutter: Color(0x99000000),
    ),
  );
}

enum BmThemeId { noor, livingSky, andalus, iznik, qiyam, qiyamEmerald, moonlight, qiyamRose }

class BmThemeDef {
  final BmThemeId id;
  final String name;
  final BmPalette dark;
  final BmPalette light;
  const BmThemeDef(this.id, this.name, this.dark, this.light);
}

final Map<BmThemeId, BmThemeDef> bmThemes = {
  BmThemeId.qiyamEmerald: const BmThemeDef(
    BmThemeId.qiyamEmerald,
    'Qiyam Emerald',
    BmPalette(
      bg: Color(0xFF000000),
      surface: Color(0xFF07100D),
      raised: Color(0xFF0C1814),
      variant: Color(0xFF13221D),
      outline: Color(0xFF1C2C26),
      outlineStrong: Color(0xFF4C5E57),
      text: Color(0xFFD9D3C2),
      text2: Color(0xFF878C82),
      text3: Color(0xFF7B8079),
      primary: Color(0xFFA88A52),
      onPrimary: Color(0xFF000000),
      primaryContainer: Color(0xFF221C10),
      onPrimaryContainer: Color(0xFFD9C08A),
      accent: Color(0xFF4E9C80),
      accentContainer: Color(0xFF0E2620),
      onAccentContainer: Color(0xFF8FCDB4),
      success: Color(0xFF5FB389),
      warning: Color(0xFFD2A04F),
      error: Color(0xFFE07A6A),
      onError: Color(0xFF000000),
      glow: Color(0xFFA88A52),
      sky1: Color(0xFF000000),
      sky2: Color(0xFF04100C),
      sky3: Color(0xFF173328),
      onSky: Color(0xFFD9D3C2),
      sun: Color(0xFFCDB27A),
      starOpacity: 0.8,
    ),
    BmPalette(
      bg: Color(0xFFF1F0EB),
      surface: Color(0xFFFFFFFF),
      raised: Color(0xFFF7F6F2),
      variant: Color(0xFFE6E5DE),
      outline: Color(0xFFDAD9D0),
      outlineStrong: Color(0xFF8E928C),
      text: Color(0xFF121513),
      text2: Color(0xFF565B57),
      text3: Color(0xFF666A65),
      primary: Color(0xFF10382E),
      onPrimary: Color(0xFFE9D7AE),
      primaryContainer: Color(0xFFDCE7E1),
      onPrimaryContainer: Color(0xFF10382E),
      accent: Color(0xFF7F6738),
      accentContainer: Color(0xFFF1E8D4),
      onAccentContainer: Color(0xFF5C4A26),
      success: Color(0xFF2E6B4A),
      warning: Color(0xFF8A5A12),
      error: Color(0xFFA33A2E),
      onError: Color(0xFFFFFFFF),
      glow: Color(0xFFA88A52),
      sky1: Color(0xFF0E1A16),
      sky2: Color(0xFF1F3A30),
      sky3: Color(0xFF8F7A52),
      onSky: Color(0xFFE9D7AE),
      sun: Color(0xFFE9D7AE),
      starOpacity: 0.6,
    ),
  ),
  BmThemeId.noor: BmThemeDef(
    BmThemeId.noor,
    'Noor',
    BmPalette.derive(
      brightness: Brightness.dark,
      bg: const Color(0xFF07130F),
      surface: const Color(0xFF0F201B),
      primary: const Color(0xFFC9A65A),
      onPrimary: const Color(0xFF0B1612),
      accent: const Color(0xFF3FA584),
      text: const Color(0xFFEDE8DA),
      text2: const Color(0xFF9AA8A1),
      sky1: const Color(0xFF030C09),
      sky2: const Color(0xFF0C2C24),
      sky3: const Color(0xFF3D6550),
      onSky: const Color(0xFFEDE8DA),
      glow: const Color(0xFFC9A65A),
      sun: const Color(0xFFF2D59A),
      starOpacity: 1,
    ),
    BmPalette.derive(
      brightness: Brightness.light,
      bg: const Color(0xFFF3F1EA),
      surface: const Color(0xFFFFFFFF),
      primary: const Color(0xFF0F4A3C),
      onPrimary: const Color(0xFFF6F0DF),
      accent: const Color(0xFF86672A),
      text: const Color(0xFF13201C),
      text2: const Color(0xFF55625D),
      sky1: const Color(0xFF0F3D33),
      sky2: const Color(0xFF2E6E5A),
      sky3: const Color(0xFFD8BD84),
      onSky: const Color(0xFFFFFFFF),
      glow: const Color(0xFFC9A65A),
      sun: const Color(0xFFFFE7B5),
      starOpacity: 0.5,
    ),
  ),
  BmThemeId.livingSky: BmThemeDef(
    BmThemeId.livingSky,
    'Living Sky',
    BmPalette.derive(
      brightness: Brightness.dark,
      bg: const Color(0xFF0B0D1C),
      surface: const Color(0xFF151833),
      primary: const Color(0xFFE7A988),
      onPrimary: const Color(0xFF1A1630),
      accent: const Color(0xFF8E95E8),
      text: const Color(0xFFECE9F2),
      text2: const Color(0xFFA3A3BD),
      sky1: const Color(0xFF070A1D),
      sky2: const Color(0xFF1D2452),
      sky3: const Color(0xFF6B4D7E),
      onSky: const Color(0xFFECE9F2),
      glow: const Color(0xFFE7A988),
      sun: const Color(0xFFFFE1C4),
      starOpacity: 1,
    ),
    BmPalette.derive(
      brightness: Brightness.light,
      bg: const Color(0xFFF5F2F0),
      surface: const Color(0xFFFFFFFF),
      primary: const Color(0xFF2F3570),
      onPrimary: const Color(0xFFFFFFFF),
      accent: const Color(0xFFA65A36),
      text: const Color(0xFF1B1C2E),
      text2: const Color(0xFF5E5F73),
      sky1: const Color(0xFF2C3168),
      sky2: const Color(0xFF9A6F98),
      sky3: const Color(0xFFF1BFA4),
      onSky: const Color(0xFFFFFFFF),
      glow: const Color(0xFFE7A988),
      sun: const Color(0xFFFFE9CF),
      starOpacity: 0.4,
    ),
  ),
  BmThemeId.andalus: BmThemeDef(
    BmThemeId.andalus,
    'Andalus',
    BmPalette.derive(
      brightness: Brightness.dark,
      bg: const Color(0xFF1A110E),
      surface: const Color(0xFF261915),
      primary: const Color(0xFFE07B57),
      onPrimary: const Color(0xFF24120C),
      accent: const Color(0xFF6FB3A2),
      text: const Color(0xFFF3E7DC),
      text2: const Color(0xFFB7A193),
      sky1: const Color(0xFF140B0A),
      sky2: const Color(0xFF4A1F1A),
      sky3: const Color(0xFF9C4429),
      onSky: const Color(0xFFF3E7DC),
      glow: const Color(0xFFE07B57),
      sun: const Color(0xFFFFC98F),
      starOpacity: 0.8,
    ),
    BmPalette.derive(
      brightness: Brightness.light,
      bg: const Color(0xFFF6EFE6),
      surface: const Color(0xFFFFFAF4),
      primary: const Color(0xFFA4472B),
      onPrimary: const Color(0xFFFFF6EE),
      accent: const Color(0xFF2F6B5E),
      text: const Color(0xFF2A1C16),
      text2: const Color(0xFF6E5A4F),
      sky1: const Color(0xFF6C2E2A),
      sky2: const Color(0xFFC66A43),
      sky3: const Color(0xFFF1C08E),
      onSky: const Color(0xFFFFF6EE),
      glow: const Color(0xFFE07B57),
      sun: const Color(0xFFFFE3B8),
      starOpacity: 0.2,
    ),
  ),
  BmThemeId.iznik: BmThemeDef(
    BmThemeId.iznik,
    'Iznik',
    BmPalette.derive(
      brightness: Brightness.dark,
      bg: const Color(0xFF060C1F),
      surface: const Color(0xFF0E1834),
      primary: const Color(0xFF6E95F2),
      onPrimary: const Color(0xFF071030),
      accent: const Color(0xFF3CC7C5),
      text: const Color(0xFFE6EEFA),
      text2: const Color(0xFF93A3BF),
      sky1: const Color(0xFF040921),
      sky2: const Color(0xFF102663),
      sky3: const Color(0xFF1F7E95),
      onSky: const Color(0xFFE6EEFA),
      glow: const Color(0xFF3CC7C5),
      sun: const Color(0xFFE4FBFF),
      starOpacity: 1,
    ),
    BmPalette.derive(
      brightness: Brightness.light,
      bg: const Color(0xFFF2F5F8),
      surface: const Color(0xFFFFFFFF),
      primary: const Color(0xFF1C3F94),
      onPrimary: const Color(0xFFFFFFFF),
      accent: const Color(0xFF127A80),
      text: const Color(0xFF0E1A33),
      text2: const Color(0xFF4E5B73),
      sky1: const Color(0xFF142D73),
      sky2: const Color(0xFF2F6CB8),
      sky3: const Color(0xFF8FD3D6),
      onSky: const Color(0xFFFFFFFF),
      glow: const Color(0xFF3CC7C5),
      sun: const Color(0xFFF2FCFF),
      starOpacity: 0.4,
    ),
  ),
  BmThemeId.qiyam: BmThemeDef(
    BmThemeId.qiyam,
    'Qiyam',
    BmPalette.derive(
      brightness: Brightness.dark,
      bg: const Color(0xFF000000),
      surface: const Color(0xFF0D0C0A),
      primary: const Color(0xFFA88A52),
      onPrimary: const Color(0xFF000000),
      accent: const Color(0xFF9A865E),
      text: const Color(0xFFD9D1C0),
      text2: const Color(0xFF8A8273),
      sky1: const Color(0xFF000000),
      sky2: const Color(0xFF0A0907),
      sky3: const Color(0xFF2A2216),
      onSky: const Color(0xFFD9D1C0),
      glow: const Color(0xFFA88A52),
      sun: const Color(0xFFCDB27A),
      starOpacity: 0.7,
    ),
    BmPalette.derive(
      brightness: Brightness.light,
      bg: const Color(0xFFF2F0EC),
      surface: const Color(0xFFFFFFFF),
      primary: const Color(0xFF2A2620),
      onPrimary: const Color(0xFFE9D7AE),
      accent: const Color(0xFF7F6738),
      text: const Color(0xFF141210),
      text2: const Color(0xFF5D5850),
      sky1: const Color(0xFF1A1814),
      sky2: const Color(0xFF3A3326),
      sky3: const Color(0xFF8F7A52),
      onSky: const Color(0xFFE9D7AE),
      glow: const Color(0xFFA88A52),
      sun: const Color(0xFFE9D7AE),
      starOpacity: 0.6,
    ),
  ),
  BmThemeId.moonlight: BmThemeDef(
    BmThemeId.moonlight,
    'Moonlight',
    BmPalette.derive(
      brightness: Brightness.dark,
      bg: const Color(0xFF000000),
      surface: const Color(0xFF0B0C0E),
      primary: const Color(0xFFA3A9B5),
      onPrimary: const Color(0xFF000000),
      accent: const Color(0xFFB7A57E),
      text: const Color(0xFFD6D8DC),
      text2: const Color(0xFF858992),
      sky1: const Color(0xFF000000),
      sky2: const Color(0xFF08090C),
      sky3: const Color(0xFF20242C),
      onSky: const Color(0xFFD6D8DC),
      glow: const Color(0xFFA3A9B5),
      sun: const Color(0xFFDADDE3),
      starOpacity: 0.9,
    ),
    BmPalette.derive(
      brightness: Brightness.light,
      bg: const Color(0xFFF0F0EF),
      surface: const Color(0xFFFFFFFF),
      primary: const Color(0xFF23252B),
      onPrimary: const Color(0xFFDADDE3),
      accent: const Color(0xFF5E6573),
      text: const Color(0xFF111214),
      text2: const Color(0xFF585B62),
      sky1: const Color(0xFF15171C),
      sky2: const Color(0xFF2E323B),
      sky3: const Color(0xFF8C93A0),
      onSky: const Color(0xFFE4E6EA),
      glow: const Color(0xFFA9AEB8),
      sun: const Color(0xFFE4E6EA),
      starOpacity: 0.6,
    ),
  ),
  BmThemeId.qiyamRose: BmThemeDef(
    BmThemeId.qiyamRose,
    'Qiyam Rose',
    BmPalette.derive(
      brightness: Brightness.dark,
      bg: const Color(0xFF000000),
      surface: const Color(0xFF0E090B),
      primary: const Color(0xFFC48A9A),
      onPrimary: const Color(0xFF000000),
      accent: const Color(0xFFC9A06E),
      text: const Color(0xFFDDD1D4),
      text2: const Color(0xFF8F8288),
      sky1: const Color(0xFF000000),
      sky2: const Color(0xFF0E070B),
      sky3: const Color(0xFF33182A),
      onSky: const Color(0xFFDDD1D4),
      glow: const Color(0xFFC48A9A),
      sun: const Color(0xFFE8C1C9),
      starOpacity: 1,
    ),
    BmPalette.derive(
      brightness: Brightness.light,
      bg: const Color(0xFFF3EFEF),
      surface: const Color(0xFFFFFFFF),
      primary: const Color(0xFF2C1C24),
      onPrimary: const Color(0xFFEBC3CC),
      accent: const Color(0xFF8C4F62),
      text: const Color(0xFF150E11),
      text2: const Color(0xFF60545A),
      sky1: const Color(0xFF1C1217),
      sky2: const Color(0xFF3D2430),
      sky3: const Color(0xFF9A6A76),
      onSky: const Color(0xFFEBC3CC),
      glow: const Color(0xFFC48A9A),
      sun: const Color(0xFFEBC3CC),
      starOpacity: 0.5,
    ),
  ),
};

/// Order shown in the theme picker (4.15).
const bmThemeOrder = [
  BmThemeId.qiyamEmerald,
  BmThemeId.qiyam,
  BmThemeId.noor,
  BmThemeId.livingSky,
  BmThemeId.iznik,
  BmThemeId.andalus,
  BmThemeId.moonlight,
  BmThemeId.qiyamRose,
];
