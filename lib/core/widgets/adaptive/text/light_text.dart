part of 'adaptive_text.dart';

class LightText extends _AdaptiveText {
  const LightText(
    super.text, {
    super.fontSize = FontSizeManager.body,
    super.color = ThemeEnum.text,
    super.font,
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
  }) : super(fontWeight: FontWeightManager.light);
}
