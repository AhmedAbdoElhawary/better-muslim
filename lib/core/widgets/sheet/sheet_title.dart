import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the components' bottom sheet title, with its optional line under it
class SheetTitle extends StatelessWidget {
  const SheetTitle(
    this.title, {
    this.args = const {},
    this.subtitle,
    this.subtitleArgs = const {},
    this.translate = true,
    super.key,
  });

  /// StringsManager keys, or dates like the day sheet's with translate false
  final String title;
  final Map<String, String> args;
  final String? subtitle;
  final Map<String, String> subtitleArgs;
  final bool translate;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    return SymmetricPadding(
      horizontal: SpaceManager.s5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RegularText(
            title,
            args: args,
            translate: translate,
            font: FontEnum.display,
            fontSize: FontSizeManager.sheetTitle,
          ),
          if (subtitle != null) ...[
            const RSizedBox.vertical(SpaceManager.s1),
            RegularText(subtitle, args: subtitleArgs, translate: translate, color: ThemeEnum.text2),
          ],
          const RSizedBox.vertical(SpaceManager.s2),
        ],
      ),
    );
  }
}
