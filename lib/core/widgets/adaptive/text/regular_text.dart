part of 'adaptive_text.dart';

class RegularText extends _AdaptiveText {
  const RegularText(
    super.text, {
    super.fontSize = FontSizeManager.caption,
    super.color = ThemeEnum.text,
    super.font,
    super.family,
    super.translate,
    super.args,
    super.height,
    super.maxLines,
    super.textAlign,
    super.fontStyle,
    super.decoration,
    super.letterSpacing,
    super.shadows,
    super.tabularFigures,
    super.key,
  }) : super(fontWeight: FontWeightManager.regular);
}
