import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/styles_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/bm_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the components' text field (03 Inputs)
class BmTextField extends StatefulWidget {
  const BmTextField({
    required this.label,
    required this.onChanged,
    this.hint,
    this.error,
    this.textInputAction,
    this.onSubmitted,
    this.initial,
    this.maxLines = 1,
    this.autofocus = false,
    super.key,
  });

  /// StringsManager keys
  final String label;
  final String? hint;
  final String? error;

  final ValueChanged<String> onChanged;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  /// the text it opens with, a bookmark's name or a note being changed
  final String? initial;

  /// null grows with the text, a note
  final int? maxLines;
  final bool autofocus;

  @override
  State<BmTextField> createState() => _BmTextFieldState();
}

class _BmTextFieldState extends State<BmTextField> {
  final _focus = FocusNode();
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    TextStyle style(ThemeEnum color) => GetRegularStyle(
      fontSize: FontSizeManager.body.sp,
      color: context.getColor(color),
      fontFamily: isArabic ? FontEnum.body.arabic : FontEnum.body.latin,
      fontFamilyFallback: [if (isArabic) FontEnum.body.latin else FontEnum.body.arabic],
    );
    final error = widget.error;
    final ring = error != null
        ? (ThemeEnum.error, SizeManager.textFieldFocus)
        : _focus.hasFocus
        ? (ThemeEnum.primary, SizeManager.textFieldFocus)
        : (ThemeEnum.outlineStrong, SizeManager.divider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RegularText(widget.label, color: ThemeEnum.text2),
        const RSizedBox.vertical(SpaceManager.textFieldGap),
        DecoratedBox(
          decoration: BoxDecoration(
            color: context.getColor(ThemeEnum.bg),
            borderRadius: BorderRadius.circular(RadiusManager.md.r),
            border: Border.all(
              color: context.getColor(ring.$1),
              width: ring.$2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: SizeManager.textField.r),
            child: HorizontalPadding(
              padding: SpaceManager.textFieldSide,
              child: Center(
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  autofocus: widget.autofocus,
                  maxLines: widget.maxLines,
                  keyboardType: widget.maxLines == 1 ? null : TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  textInputAction: widget.textInputAction,
                  style: style(ThemeEnum.text),
                  cursorColor: context.getColor(ThemeEnum.primary),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: widget.maxLines == 1
                        ? EdgeInsets.zero
                        : REdgeInsets.symmetric(vertical: SpaceManager.s3),
                    hintText: widget.hint == null ? null : context.tr(widget.hint!),
                    hintStyle: style(ThemeEnum.text3),
                  ),
                ),
              ),
            ),
          ),
        ),
        BmSwitcher(
          child: error == null
              ? const SizedBox.shrink()
              : TopPadding(
                  key: ValueKey(error),
                  padding: SpaceManager.textFieldGap,
                  child: Semantics(
                    liveRegion: true,
                    child: RegularText(
                      error,
                      fontSize: FontSizeManager.fieldError,
                      color: ThemeEnum.error,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
