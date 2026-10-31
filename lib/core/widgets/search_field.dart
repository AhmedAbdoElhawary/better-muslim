import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/styles_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 4.14's search field, the location sheet and duas use it. filled is 4.27's quran search
class SearchField extends StatelessWidget {
  const SearchField({
    required this.hint,
    required this.onChanged,
    this.onSubmitted,
    this.controller,
    this.filled = false,
    super.key,
  });

  /// a StringsManager key
  final String hint;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;

  /// given, a clear button shows while there is text
  final TextEditingController? controller;

  /// variant fill with no ring, the text in amiri and arabic on the right
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final controller = this.controller;
    final text = controller?.text ?? '';
    TextStyle style(ThemeEnum color) => GetRegularStyle(
      fontSize: (filled ? FontSizeManager.searchField : FontSizeManager.body).sp,
      color: context.getColor(color),
      fontFamily: filled
          ? FontEnum.dua.arabic
          : isArabic
          ? FontEnum.body.arabic
          : FontEnum.body.latin,
      fontFamilyFallback: [if (isArabic || filled) FontEnum.body.latin else FontEnum.body.arabic],
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.getColor(filled ? ThemeEnum.variant : ThemeEnum.surface),
        borderRadius: BorderRadius.circular(
          (filled ? RadiusManager.searchField : RadiusManager.md).r,
        ),
        boxShadow: [
          if (!filled) BoxShadow(color: context.getColor(ThemeEnum.outline), spreadRadius: 1),
        ],
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: (filled ? SizeManager.hit : SizeManager.searchField).r,
        ),
        child: OnlyPadding(
          start: filled ? SpaceManager.searchFieldStart : SpaceManager.fieldSide,
          end: filled ? SpaceManager.searchFieldEnd : SpaceManager.fieldSide,
          child: Row(
            children: [
              BmIcon.ui(
                BmUiIcon.search,
                size: SizeManager.iconList.r,
                color: context.getColor(ThemeEnum.text2),
              ),
              RSizedBox.horizontal(filled ? SpaceManager.s2 : SpaceManager.fieldIconGap),
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: filled,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  style: style(ThemeEnum.text),
                  cursorColor: context.getColor(ThemeEnum.primary),
                  textInputAction: TextInputAction.search,
                  textAlignVertical: TextAlignVertical.top,

                  /// arabic sits on the right as 4.27 draws it, whatever the app's language
                  textDirection: filled && RegExp('[\u0600-\u06FF]').hasMatch(text)
                      ? TextDirection.rtl
                      : null,
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
              if (controller != null && text.isNotEmpty)
                _Clear(
                  onTap: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Clear extends StatelessWidget {
  const _Clear({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.tr(StringsManager.close),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: RSizedBox.square(
          dimension: SizeManager.hit,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.getColor(ThemeEnum.outlineStrong),
                shape: BoxShape.circle,
              ),
              child: RSizedBox.square(
                dimension: SizeManager.searchClear,
                child: Center(
                  child: BmIcon.ui(
                    BmUiIcon.close,
                    size: SizeManager.searchClearIcon.r,
                    color: context.getColor(ThemeEnum.bg),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
