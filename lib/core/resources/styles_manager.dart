import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:flutter/material.dart';

/// for widgets that take a TextStyle (text fields, theme), pass fontSize already scaled with .sp
class GetTextStyle extends TextStyle {
  const GetTextStyle({
    required double super.fontSize,
    required super.fontWeight,
    super.fontVariations,
    super.color,
    super.height,
    super.leadingDistribution,
    super.fontStyle,
    super.decoration,
    super.letterSpacing,
    super.shadows,
    super.fontFeatures,
    super.fontFamily,
    super.fontFamilyFallback,
  });
}

/// the body fonts are variable, they only change weight through fontVariations
class GetLightStyle extends GetTextStyle {
  const GetLightStyle({
    required super.fontSize,
    super.color,
    super.height,
    super.fontStyle,
    super.decoration,
    super.letterSpacing,
    super.shadows,
    super.fontFamily,
    super.fontFamilyFallback,
  }) : super(
         fontWeight: FontWeightManager.light,
         fontVariations: const [FontVariation.weight(300)],
       );
}

class GetRegularStyle extends GetTextStyle {
  const GetRegularStyle({
    required super.fontSize,
    super.color,
    super.height,
    super.fontStyle,
    super.decoration,
    super.letterSpacing,
    super.shadows,
    super.fontFamily,
    super.fontFamilyFallback,
  }) : super(
         fontWeight: FontWeightManager.regular,
         fontVariations: const [FontVariation.weight(400)],
       );
}

class GetMediumStyle extends GetTextStyle {
  const GetMediumStyle({
    required super.fontSize,
    super.color,
    super.height,
    super.fontStyle,
    super.decoration,
    super.letterSpacing,
    super.shadows,
    super.fontFamily,
    super.fontFamilyFallback,
  }) : super(
         fontWeight: FontWeightManager.medium,
         fontVariations: const [FontVariation.weight(500)],
       );
}

class GetSemiBoldStyle extends GetTextStyle {
  const GetSemiBoldStyle({
    required super.fontSize,
    super.color,
    super.height,
    super.fontStyle,
    super.decoration,
    super.letterSpacing,
    super.shadows,
    super.fontFamily,
    super.fontFamilyFallback,
  }) : super(
         fontWeight: FontWeightManager.semiBold,
         fontVariations: const [FontVariation.weight(600)],
       );
}

class GetBoldStyle extends GetTextStyle {
  const GetBoldStyle({
    required super.fontSize,
    super.color,
    super.height,
    super.fontStyle,
    super.decoration,
    super.letterSpacing,
    super.shadows,
    super.fontFamily,
    super.fontFamilyFallback,
  }) : super(fontWeight: FontWeightManager.bold, fontVariations: const [FontVariation.weight(700)]);
}
