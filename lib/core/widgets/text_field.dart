import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/resources/design/bm_tokens.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/styles_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the components' text field (03 Inputs), the backup sheets use it
class BmTextField extends StatefulWidget {
  const BmTextField({
    required this.label,
    required this.onChanged,
    this.hint,
    this.obscure = false,
    this.error,
    this.errorArgs = const {},
    this.enabled = true,
    this.textInputAction,
    this.onSubmitted,
    super.key,
  });

  /// StringsManager keys
  final String label;
  final String? hint;
  final String? error;
  final Map<String, String> errorArgs;

  final ValueChanged<String> onChanged;
  final bool obscure;
  final bool enabled;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<BmTextField> createState() => _BmTextFieldState();
}

class _BmTextFieldState extends State<BmTextField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
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
    return Opacity(
      opacity: widget.enabled ? 1 : BmOpacity.disabled,
      child: Column(
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
                    focusNode: _focus,
                    enabled: widget.enabled,
                    obscureText: widget.obscure,
                    autocorrect: !widget.obscure,
                    enableSuggestions: !widget.obscure,
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                    textInputAction: widget.textInputAction,
                    style: style(ThemeEnum.text),
                    cursorColor: context.getColor(ThemeEnum.primary),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: widget.hint == null ? null : context.tr(widget.hint!),
                      hintStyle: style(ThemeEnum.text3),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (error != null) ...[
            const RSizedBox.vertical(SpaceManager.textFieldGap),
            Semantics(
              liveRegion: true,
              child: RegularText(
                error,
                args: widget.errorArgs,
                fontSize: FontSizeManager.fieldError,
                color: ThemeEnum.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
