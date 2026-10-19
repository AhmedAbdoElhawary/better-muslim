import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/resources/design/bm_text.dart';
import 'package:better_muslim/core/resources/design/bm_tokens.dart';
import 'package:flutter/material.dart';

/// Access with `context.bm` anywhere below MaterialApp.
class BmColors extends ThemeExtension<BmColors> {
  final BmPalette p;
  const BmColors(this.p);
  @override
  BmColors copyWith({BmPalette? p}) => BmColors(p ?? this.p);
  @override
  BmColors lerp(BmColors? other, double t) =>
      other == null ? this : BmColors(BmPalette.lerp(p, other.p, t));
}

extension BmContext on BuildContext {
  BmPalette get bm => Theme.of(this).extension<BmColors>()!.p;
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;
}

ThemeData bmThemeData(BmPalette p, Brightness b) {
  final scheme = ColorScheme(
    brightness: b,
    surface: p.bg,
    onSurface: p.text,
    surfaceContainerLowest: p.bg,
    surfaceContainerLow: p.surface,
    surfaceContainer: p.raised,
    surfaceContainerHigh: p.raised,
    surfaceContainerHighest: p.variant,
    onSurfaceVariant: p.text2,
    primary: p.primary,
    onPrimary: p.onPrimary,
    primaryContainer: p.primaryContainer,
    onPrimaryContainer: p.onPrimaryContainer,
    secondary: p.accent,
    onSecondary: b == Brightness.dark ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
    secondaryContainer: p.accentContainer,
    onSecondaryContainer: p.onAccentContainer,
    error: p.error,
    onError: p.onError,
    outline: p.outlineStrong,
    outlineVariant: p.outline,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: b,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.bg,
    fontFamily: BmFont.body,
    splashFactory:
        NoSplash.splashFactory, // pressed state = 12% overlay, no ripple (see Components)
    highlightColor: p.primary.withAlpha((255 * BmOpacity.pressed).round()),
    dividerColor: p.outline,
    extensions: [BmColors(p)],
    textTheme: TextTheme(bodyMedium: BmText.body.copyWith(color: p.text)),
  );
}

enum BmThemeMode { dark, light, followSky }

/// followSky: light from Sunrise until Maghrib, dark from Maghrib until Sunrise.
Brightness resolveBrightness(
  BmThemeMode m, {
  required DateTime now,
  required DateTime sunrise,
  required DateTime maghrib,
}) {
  switch (m) {
    case BmThemeMode.dark:
      return Brightness.dark;
    case BmThemeMode.light:
      return Brightness.light;
    case BmThemeMode.followSky:
      return (now.isAfter(sunrise) && now.isBefore(maghrib)) ? Brightness.light : Brightness.dark;
  }
}
