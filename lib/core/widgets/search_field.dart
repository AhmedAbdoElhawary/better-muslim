import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/styles_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 4.14's search field, the location sheet and duas use it
class SearchField extends StatelessWidget {
  const SearchField({required this.hint, required this.onChanged, super.key});

  /// a StringsManager key
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    TextStyle style(ThemeEnum color) => GetRegularStyle(
      fontSize: FontSizeManager.body.sp,
      color: context.getColor(color),
      fontFamily: isArabic ? FontEnum.body.arabic : FontEnum.body.latin,
      fontFamilyFallback: [if (isArabic) FontEnum.body.latin else FontEnum.body.arabic],
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.getColor(ThemeEnum.surface),
        borderRadius: BorderRadius.circular(RadiusManager.md.r),
        boxShadow: [BoxShadow(color: context.getColor(ThemeEnum.outline), spreadRadius: 1)],
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: SizeManager.searchField.r),
        child: SymmetricPadding(
          horizontal: SpaceManager.fieldSide,
          child: Row(
            children: [
              BmIcon.ui(
                BmUiIcon.search,
                size: SizeManager.iconList.r,
                color: context.getColor(ThemeEnum.text2),
              ),
              const RSizedBox.horizontal(SpaceManager.fieldIconGap),
              Expanded(
                child: TextField(
                  onChanged: onChanged,
                  style: style(ThemeEnum.text),
                  cursorColor: context.getColor(ThemeEnum.primary),
                  textInputAction: TextInputAction.search,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    isCollapsed: false,

                    /// the whole height is the hit, not only the line of text
                    constraints: BoxConstraints(minHeight: SizeManager.hit.r),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: context.tr(hint),
                    hintStyle: style(ThemeEnum.text2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
