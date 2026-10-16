part of 'adaptive_text.dart';

class MediumText extends _AdaptiveText {
  const MediumText(
    super.text, {
    super.fontSize = FontSizeManager.bodyStrong,
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
  }) : super(fontWeight: FontWeightManager.medium);
}
