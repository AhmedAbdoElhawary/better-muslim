import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/styles_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

part 'bold_text.dart';
part 'light_text.dart';
part 'medium_text.dart';
part 'regular_text.dart';
part 'semi_bold_text.dart';

/// the only Text in the app, so translation, font scaling, theme colors and the arabic fonts
/// can't be skipped. each weight defaults to the size the screens use most with it
class _AdaptiveText extends StatelessWidget {
  const _AdaptiveText(
    this.text, {
    required this.fontWeight,
    required this.fontSize,
    required this.color,
    this.font = FontEnum.body,
    this.family,
    this.translate = true,
    this.args = const {},
    this.height,
    this.maxLines,
    this.textAlign,
    this.fontStyle,
    this.decoration,
    this.letterSpacing,
    this.shadows,
    this.tabularFigures = false,
    super.key,
  });

  /// a StringsManager key, or the text itself when translate is false (times, numbers, names)
  final String text;
  final FontWeight fontWeight;
  final double fontSize;
  final ThemeEnum? color;
  final FontEnum font;

  /// a downloaded font in place of [font], like a qcf page's
  final String? family;
  final bool translate;
  final Map<String, String> args;
  final double? height;
  final int? maxLines;
  final TextAlign? textAlign;
  final FontStyle? fontStyle;
  final TextDecoration? decoration;
  final double? letterSpacing;
  final List<Shadow>? shadows;

  /// every time and the countdown, so digits keep their width while they change
  final bool tabularFigures;

  @override
  Widget build(BuildContext context) {
    final color = this.color;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Text(
      translate ? context.tr(text, args) : text,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      textAlign: textAlign,
      style: GetTextStyle(
        fontSize: fontSize.sp,
        fontWeight: fontWeight,
        fontVariations: [FontVariation.weight(fontWeight.value.toDouble())],
        color: color == null ? null : context.getColor(color),
        height: height,

        /// the specs are css, which splits a line height evenly above and below the text
        leadingDistribution: TextLeadingDistribution.even,
        fontStyle: fontStyle,
        decoration: decoration,
        letterSpacing: letterSpacing,
        shadows: shadows,
        fontFeatures: tabularFigures ? const [FontFeature.tabularFigures()] : null,
        fontFamily: family ?? (isArabic ? font.arabic : font.latin),

        /// an arabic word inside english text (or the reverse) still gets the design font
        fontFamilyFallback: [if (isArabic) font.latin else font.arabic],
      ),
    );
  }
}
