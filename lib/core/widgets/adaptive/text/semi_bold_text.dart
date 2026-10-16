part of 'adaptive_text.dart';

class SemiBoldText extends _AdaptiveText {
  const SemiBoldText(
    super.text, {
    super.fontSize = FontSizeManager.title,
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
    super.key,
  }) : super(fontWeight: FontWeightManager.semiBold);
}
